function [xypts,xyzpts]=collectBirds_v15(birds,opts)
% function [xypts,xyzpts]=collectBirds_v15(birds,opts)
%
% inputs:
%   birds - struct variable with several cell arrays including the uv
%     coordinates
%   opts - struct variable with several small values and other data in it;
%     set on a per-trial basis
%
% This function takes individual xy points from image stacks and attempts
% 3D association using the DLT coeficients file loaded by the UI.  It uses
% input t to eliminate poor fits, and associates remaining candidates based
% on the minimum DLT rmse.  Only points visible in all three cameras, below
% t, are included.
%
% 2012-06-25 Brandon Jackson, modified from original script by Ty Hedrick
% 2013-10-09 Ty Hedrick, modified from Brandon's version
% 2013-10-16 Ty Hedrick, _v4 created, checks 2 & 3 camera matches
% 2014-01-06 Ty Hedrick, _v5 created, uses different input structure
% 2014-01-07 Ty Hedrick, _v5p created (parallel _v5)
% 2014-10-27 Ty Hedrick, _v6 - quick rewrite for swifts
% 2014-11-05 Ty Hedrick, _v7 - handles [x,y,u,v,area] inputs in dpts
% 2014-11-13 Ty Hedrick, _v8 - some cleanup for general purpose use
% 2014-12-19 Ty Hedrick, _v9 - implements the additive noise voting layer
% 2015-01-03 Ty Hedrick, _v10 - v9 cleanups without additive noise
% 2015-01-31 Ty Hedrick, _v11 - remove more additive noise, use dpts2
% 2015-05-19 Ty Hedrick, collectSwallows_v1 forked from collectBirds_v11,
%   scrapped background point distance check
% 2015-06-26 Ty Hedrick, collectBirds_v12 forked from collectSwallows_v1,
% cleanup and generalization for n cameras
% 2015-07-02 Ty Hedrick, collectBirds_v13 - rewrite core 2D-->3D routines
% to use two cameras together to get a 3D point before choosing other
% compatible 2D points
% 2015-07-02 Ty Hedrick collectBirds_v14 - another substantial rewrite for
% speed in cases with mCams < nCams
% 2015-07-15 Ty Hedrick collectBirds_v14 - modified to also tag the 2D
% points interpolated from 3D values by encoding them as XXXX.YY000123;
% This format can later be detected after track formation and avoids the
% memory overhead of creating a tracking array. Can later be ID'd with
% operations like this one: find(abs(rem(foo,0.00001)-0.00000123)< 1e-32)
% 2015-07-30 Ty Hedrick collectBirds_v15 - uses realRMSE instead of rmse in
% identifying matching points
% 2015-09-22 Ty Hedrick _v15, now uses gcp instead of matlabpool if
% available

% dpts = cell array of 3 cell arrays each with points from swallowScanner_v1
% coefs = DLT coefficients
% threshold = DLT threshold for matching points - defaults to 8
% maxbirds = maximum number of birds to track
% startFrame = starting frame
% endFrame = end frame

% number of cameras
nCams=birds.numCams;

% minimum number of cameras for a 3D point
mCams=opts.minNumCams;

% DLT reconstruction threshold
t=opts.dltThreshold;

% check for a parallel pool
if exist('gcp','file')==2
  if isempty(gcp('nocreate'))==false
    gotPool=true;
  else
    gotPool=false;
  end
else
  if matlabpool('size')>0
    gotPool=true;
  else
    gotPool=false;
  end
end
  

% for or parfor loop over each frame
if gotPool
  uv=birds.uvData2; % break these out to avoid passing structs in parfor
  coefs=birds.dltCoefs;
  parfor i=opts.startFrame:opts.endFrame %3750
    
    [xypts{i},xyzpts{i}]=collectBirds_v15pint_shim(uv{i},coefs,nCams,t,mCams);
    
    % progress indicator
    fprintf('.')
    if rem(i,85)==0
      fprintf('\n')
    end
    
  end
else % no matlabpool available
  tic
  for i=opts.startFrame:opts.endFrame
    
    [xypts{i},xyzpts{i}]=collectBirds_v15pint_shim(birds.uvData2{i},birds.dltCoefs,nCams,t,mCams);
    
    % progress indicator
    fprintf('.')
    if rem(i,85)==0
      fprintf('\n')
    end
    
  end
  toc
end

disp('Processing uv camera points to xyz 3D points complete, ready for track joining.')

function [xypts,xyzpts]=collectBirds_v15pint_shim(dpts,coefs,nCams,t,mCams)

% for each frame

xypts=zeros(0,nCams*2);
xyzpts=zeros(0,4);

% get all valid points
[xypts]=collectBirds_v15pint(dpts,coefs,nCams,t,mCams);

[a]=dlt_reconstruct_fast(coefs,xypts);
b=rrmse(coefs,xypts,a);

% additionally penalize rows with only 2 cameras
idx=find(sum(isfinite(xypts),2)<5);
b(idx)=b(idx)+1;

% combine data for output
xyzpts=[a,b];

% extrapolate uv points for any missing cameras
if mCams < nCams
  for i=1:nCams
    idx=find(isnan(xypts(:,i*2)));
    foo=dlt_inverse(coefs(:,i),xyzpts(idx,1:3));
    foo=round(foo*100)/100 + 0.00000123; % add tag
    xypts(idx,i*2-1:i*2)=foo;
  end
end


function [xypts]=collectBirds_v15pint(dpts,coefs,nCams,t,mCams)

% max epipolar distance
%epDist=t*2.5; %default is 2.5 (this is the correct value for using realRMSE)
epDist=t*1.5; % (for the epipolar) - seems that these are not identical in all cases?
epDist2=t*4.5; % (for the radius) - epDist / 2 mods mad on 2015-11-09

% Collect for consideration - all centroids for each camera in this frame
for j=1:nCams
  pcent{j}=dpts{j}(:,1:2);
end

% for each centroid in each camera, look for a match in the set of centroids
% from the other cameras (if only going for all-way matches, only use 1st
% camera as a base)

% check to see if we are looking for < all-way matches
if mCams < nCams
  iterator=nCams;
else
  iterator=1;
end

cl=binarycombinations(nCams);
cCnt=sum(cl,2);
idx=find(cCnt>=mCams);

camListNoShift=1:nCams;
for i=1:numel(idx)
  camList{i}=find(cl(idx(i),:)==true);
end

cnt=1; % counter for position in final list of points
b1=[]; % empty final array

for II=1:numel(camList)
  % focal camera is k
  k=camList{II}(1);
  
  % for each centroid in the focal camera
  for j=1:size(pcent{k},1)
    %disp(j)
    % candidate point in focal camera & rest of cp cell array
    cp=[];
    cp{1}=pcent{k}(j,:);
    for i=2:nCams
      cp{i}=[];
    end
    
    % counter for cell array that stores individual combination sets for
    % point pairs
    b1tempCellCnt=1;
    
    if isnan(cp{1}(1))==false % do not consider the case where the focal camera is NaN
      
      % find candidate points in 2nd camera by epipolar match
      idx=[];
      [m,b]=partialdlt(cp{1}(1,1),cp{1}(1,2),coefs(:,k),coefs(:,camList{II}(2)));
      d=pldist2(m,b,pcent{camList{II}(2)});
      idx=find(d<epDist);
      if isempty(idx)
        % no data - this iteration can't work, do nothing
      else
        cp{2}=pcent{camList{II}(2)}(idx,1:2);
        
        
        % Now we have a focal point in cp{1} and some additional
        % epipolar-compatible points in cp{2}.  Next we need to find all reprojection
        % compatible points in the remaining cameras for each point in cp{i}
        for l=1:size(cp{2},1) % for each point
          % setup cp2 array which will be used to do combinations within
          % this set
          clear cp2
          cp2{1}=cp{1};
          for ii=2:numel(camList{II})
            cp2{ii}=[];
          end
          cp2{2}=cp{2}(l,:);
          
          % get a 3D point
          [xyz]=dlt_reconstruct_fast(coefs(:,[k,camList{II}(2)]),[cp{1},cp{2}(l,:)]);
          
          % get the real rmse
          rmse=rrmse(coefs(:,[k,camList{II}(2)]),[cp{1},cp{2}(l,:)],xyz);
          
          for m=3:numel(camList{II}) % for each remaining camera
            if rmse<=t % epipolar constraint not perfect especially with larger distances so check rmse here
              % reproject in 2D
              [uv] = dlt_inverse(coefs(:,camList{II}(m)),xyz);
              
              % find reprojection-compatible points in camera m
              foo = twoDdist(uv,pcent{camList{II}(m)},epDist2);
              cp2{m}=[cp2{m};foo];
            end
          end
          
          % Get and store valid combos
          b1tempArray{b1tempCellCnt}=makeCombos(cp2,camList{II},nCams,mCams);
          b1tempCellCnt=b1tempCellCnt+1;
        end
        
        
        % create b1temp from b1tempArray
        tSize=0;
        for ii=1:b1tempCellCnt-1
          tSize=tSize+size(b1tempArray{ii},1);
        end
        b1temp=zeros(tSize,nCams*2);
        tCnt=0;
        for ii=1:b1tempCellCnt-1
          b1temp(tCnt+1:tCnt+size(b1tempArray{ii},1),:)=b1tempArray{ii};
          tCnt=tCnt+size(b1tempArray{ii},1);
        end
        
        %disp(size(b1))
        %tic
        [xyz] = dlt_reconstruct_fast(coefs,b1temp);
        
        % get the real rmse
        rmse=rrmse(coefs,b1temp,xyz);
        %toc
        
        % count cameras
        camCount=sum(isfinite(b1temp),2)/2;
        
        % penalize rmse for rows with only 2 cameras
        rmse(camCount <= 2)=rmse(camCount <= 2)+1;
        
        % find points below the DLT reconstruction residual threshold & with
        % the requisite number of cameras (or more)
        idx=find(rmse<=t & camCount >= mCams);
        
        % append good rows
        if numel(idx)>0
          b1(cnt:cnt+numel(idx)-1,:)=b1temp(idx,:);
          cnt=cnt+numel(idx);
        end
      end
      
    end
  end
  
end

% remove any duplicate rows
b1=unique(b1,'rows');

% Scan for sub-count duplications where a subset of the cameras were used
% to create a 2nd 3D point
if (mCams < nCams) && isempty(b1)==false
  
  % point counts
  pCount=sum(isfinite(b1(:,1:2:end)),2);
  
  % identify cases where a subset of another point appears elsewhere in the
  % array - these subsets are termed dupes
  %
  % dupe tag array
  dupes=false(size(b1,1),1);
  
  % for each point
  for i=1:size(b1,1)
    % setup comparison array
    cArray=repmat(b1(i,:),size(b1,1),1);
    
    % get differences between original and comparison rows & sum
    dScore=nansum(abs(cArray-b1),2);
    
    % find cases with no difference not including NaNs
    idx=find(dScore==0);
    
    % get list of similar rows & their point counts, sort and call
    % everything but the last (max point count) row a duplicate; tag for
    % removal
    if numel(idx)>1 % always one duplicate - the current row
      foo=sortrows([idx,pCount(idx)],2);
      dupes(foo(1:end-1,1))=true;
    end
  end
  
  % remove sub-duplicate rows
  b1(dupes==true,:)=[];
  
end
xypts=b1;
if isempty(xypts)
  xypts=zeros(0,nCams*2);
end



function [d] = pldist2(m,b,xy)

% function [d] = pldist2(m,b,xy)
%
% Distance of points in array xy (n,2) from the line specified by slope m,
% y intercept b

if numel(xy)>0
  d=abs(m*xy(:,1)-xy(:,2)+b)./(m^2+1)^0.5;
else
  d=[];
end

function [uvGood] = twoDdist(uv1,uv2,epDist)

% function [uvGood] = twoDdist(uv1,uv2,epDist)
%
% Returns the set of uv2 that is within epDist of uv1

uv1=repmat(uv1,size(uv2,1),1);
d=rnorm(uv1-uv2);
uvGood=uv2(d<=epDist,:);

function b1new=makeCombos(cp,camList,nCams,mCams)

% Build an array of all possible combinations of qualifying points
% base point & second camera
b1temp=repmat(cp{1},size(cp{2},1),1);
b1temp(:,3:4)=cp{2};
for i=3:numel(camList)
  % additions
  foo=reshape(repmat(cp{i}',size(b1temp,1),1),2,numel(cp{i})/2*size(b1temp,1))';
  
  % expand array
  b1temp=repmat(b1temp,numel(cp{i})/2,1);
  
  % make additions
  b1temp(:,i*2-1:i*2)=foo;
end

% fix layout of b1temp to match original order
b1new(:,camList*2-1)=b1temp(:,(1:numel(camList))*2-1);
b1new(:,camList*2)=b1temp(:,(1:numel(camList))*2);
b1new(b1new==0)=NaN;
b1new(:,end+1:nCams*2)=NaN; % pad to full camera array size

% clean out cases that don't meet the minimum number of cameras
camCount=sum(isfinite(b1new),2)/2;
b1new(camCount<mCams,:)=[];
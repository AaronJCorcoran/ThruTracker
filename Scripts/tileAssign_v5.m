function [assignments,unassignedTracks,unassignedDetections] = tileAssign_v5(xy,xyz,fooXY,fooXYZ,trackNewness,trackLength,opts)

% [assignments,unassignedTracks,unassignedDetections] = tileAssign_v5(xy,xyz,fooXY,fooXYZ,trackNewness,trackLength,opts)
%
% Tiles optimal assignment by position in the horizontal direction of
% camera 1
%
% _v1 - initial version
% _v2 - adds adaptive tile width
% _v2sw - re-tuned for swallows with IDT cameras
% _v3 - adds option to turn tiling on or off
% Modified 09-01-2019 to work with only xy if xyz is not provided

% initialize assignments
assignments=zeros(0,3);

% set bin size based on most densely populated band
imgWidth = opts.imageSize{1}(1);
binWidth = imgWidth/4;
n=hist(xy(:,1),imgWidth/binWidth);

if opts.tileAssignments==true
  if max(n)<140
    tbreaks(:,1)=0:binWidth:(imgWidth-binWidth);
    tbreaks(:,2)=tbreaks(:,1)+binWidth*2;
    tbreaks(1,1)=tbreaks(1,1)-20; % fix edge in case of distortion past 0
  elseif max(n)<280
    tbreaks(:,1)=0:binWidth/2:(imgWidth-binWidth/2);
    tbreaks(:,2)=tbreaks(:,1)+binWidth;
    tbreaks(1,1)=tbreaks(1,1)-20; % fix edge in case of distortion past 0
  else
    tbreaks(:,1)=0:binWidth/4:(imgWidth-binWidth/4);
    tbreaks(:,2)=tbreaks(:,1)+binWidth/2;
    tbreaks(1,1)=tbreaks(1,1)-20; % fix edge in case of distortion past 0
  end
else
  % if we are not tiling, set one line of breaks that encompasses all
  % possible values for the first camera
  tbreaks=[-inf,inf];
end

for i=1:size(tbreaks,1)
  
  % get indices into observations (idx1) and track predictions (idx2) that
  % fit within the current tile in the first camera, this assumes that if
  % they are in the tile in camera 1 they are also in the tile in all other
  % cameras
  idx1=find(xy(:,1)>=tbreaks(i,1) & xy(:,1)<=tbreaks(i,2));
  idx2=find(fooXY(:,1)>=tbreaks(i,1) & fooXY(:,1)<=tbreaks(i,2));
  
  if numel(idx1)>0 & numel(idx2)>0
    % create a cost matrix
    cost=zeros(numel(idx2),numel(idx1));
    
    % populate cost matrix
    for j=1:numel(idx2)
      %diffXYZ = xyz(idx1,1:3) - repmat(fooXYZ(idx2(j),1:3), [numel(idx1),1]);
      diffXY = xy(idx1,1:opts.nCams*2) - repmat(fooXY(idx2(j),1:opts.nCams*2), [numel(idx1),1]);
      % scrub NaNs
      mdiffXY=nanmean(diffXY,1)*0;
      mdiffXY(isnan(mdiffXY))=0;
      for k=1:size(diffXY,2)
        diffXY(isnan(diffXY(:,k)),k)=mdiffXY(k);
      end
      
      % set preliminary cost for the associations
      %cost(j,:)=sqrt(sum(diffXYZ.^2 , 2))/opts.xyzJoiningDivisor+sqrt(sum(diffXY.^2 , 2))/(4*opts.nCams*opts.xyJoiningDivisor);
        cost(j,:)=sqrt(sum(diffXY.^2 , 2));
    end
    
    % process joinging bias
    if isfield(opts,'joiningBias')==false
      opts.joiningBias=1; % bias toward adding to long tracks
    end
    if opts.joiningBias==1 % bias toward adding to long tracks
      % adjust cost for track length - longer tracks do better
      fcost=-1*(min(1,(trackLength(idx2)./60)));
      cost=repmat(fcost,1,size(cost,2))+cost+1;
    elseif opts.joiningBias==2 % bias toward splitting for new tracks
      % adjust cost for track newness
      fcost=5*ones(size(cost,1),1)./(trackNewness(idx2).^3./14^3+1);
    
      % add track newness related costs to existing costs
      cost=repmat(fcost,1,size(cost,2))+cost;
    else
      % no bias either way, do nothing
    end
    
    
    % set cost threshold for non-assignment
    cost(cost>opts.badMatchThreshold)=Inf; % was 10, testing 15
    
    % get assignments
    as=[];
    as(:,1)=1:numel(idx2);
    [as(:,2)]=assignmentoptimal(cost);
    as(as(:,2)==0,:)=[]; % clean out unassigned cases
    if isempty(as)==false
      as(:,3)=cost(as(:,1)+(as(:,2)-1)*size(cost,1));
      
      % total assignments
      assignments=[assignments;[idx2(as(:,1)),idx1(as(:,2)),as(:,3)]];
    end
  end
end

% reduce to unique cases
assignments=unique(assignments,'rows');

% find unassigned detections
unassignedDetections=setdiff(1:size(xy,1),assignments(:,2));

% identify collisions
%  collisions in tracks
d1=diff(assignments(:,1));
idx1=find(d1==0);
collisions=assignments([idx1;idx1+1],:);
assignments([idx1;idx1+1],:)=[];

%  collisions in detections
assignments=sortrows(assignments,2);
d1=diff(assignments(:,2));
idx1=find(d1==0);
collisions=[collisions;assignments([idx1;idx1+1],:)];
assignments([idx1;idx1+1],:)=[];

% create final cost matrix
idx2=collisions(:,1); % tracks
idx1=[collisions(:,2);unassignedDetections']; % detections
if numel(idx1)>0 & numel(idx2)>0
  cost=zeros(numel(idx2),numel(idx1));
  for j=1:numel(idx2)
    %diffXYZ = xyz(idx1,1:3) - repmat(fooXYZ(idx2(j),1:3), [numel(idx1),1]);
    diffXY = xy(idx1,1:opts.nCams*2) - repmat(fooXY(idx2(j),1:opts.nCams*2), [numel(idx1),1]);
    
    % scrub NaNs
    mdiffXY=nanmean(diffXY,1)*0;
    mdiffXY(isnan(mdiffXY))=0;
    for k=1:size(diffXY,2)
      diffXY(isnan(diffXY(:,k)),k)=mdiffXY(k);
    end
    
    %cost(j,:)=sqrt(sum(diffXYZ.^2 , 2))/opts.xyzJoiningDivisor+sqrt(sum(diffXY.^2 , 2))/(4*opts.nCams*opts.xyJoiningDivisor);
    cost(j,:) =sqrt(sum(diffXY.^2 , 2))
  end
  
  % process joining bias
  if isfield(opts,'joiningBias')==false
    opts.joiningBias=2; % traditional behavior - split tracks
  end
  if opts.joiningBias==1 % bias toward adding to long tracks
    % adjust cost for track length - longer tracks do better
    fcost=-1*(min(1,(trackLength(idx2)./60)));
    cost=repmat(fcost,1,size(cost,2))+cost+1;
  elseif opts.joiningBias==2 % bias toward splitting for new tracks
    % adjust cost for track newness
    fcost=5*ones(size(cost,1),1)./(trackNewness(idx2).^3./14^3+1);
    
    % add track newness related costs to existing costs
    cost=repmat(fcost,1,size(cost,2))+cost;
  else
    % no bias either way, do nothing
  end
  
  % get final assignments
  as=[];
  as(:,1)=1:numel(idx2);
  [as(:,2)]=assignmentoptimal(cost);
  as(as(:,2)==0,:)=[]; % clean out unassigned cases
  as(:,3)=cost(as(:,1)+(as(:,2)-1)*size(cost,1));
  as(as(:,3)>opts.badMatchThreshold,:)=[]; % clean out costs that are too high
  
  % merge with existing assignments
  assignments=[assignments;[idx2(as(:,1)),idx1(as(:,2)),as(:,3)]];
end

% get unassigned tracks & detections
unassignedTracks=setdiff(1:size(fooXY,1),assignments(:,1))';
unassignedDetections=setdiff(1:size(xy,1),assignments(:,2))';

% final sort
assignments=sortrows(assignments,1);
1;
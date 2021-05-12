function [dets,opts] = UVto3D_v1(dets, opts,threads)

% function [birds,opts,imgMasks] = birdUVto3D_v4(optionsFile,threads)
%
% First fully generalized UV detection to 3D track MATLAB program for the
% various bird projects.  There are a lot of necessary entries and instead
% of being passed as arguments to the function these are given in an
% options file which is processed at startup.  This file provides values
% for the following inputs:
%
% opts.dataDir                % for the analysis as a whole
% opts.distCoefsFile{}        % for each camera, path relative to data
% opts.dltCoefsFile           % for the analysis as a whole, path relative to dataDir
% opts.detectionsFile{}       % for each camera, path relative to dataDir
% opts.movieFile{}            % for each camera, path relative to dataDir
% opts.useMask                % for the analysis as a whole
% opts.maskFile               % for the analysis as a whole, path relative to dataDir
% opts.frameRate              % for the analysis as a whole
% opts.imageSize{}            % for each camera
% opts.offsets{}              % for each camera
% opts.dltThreshold{}         % for each camera
% opts.startFrame             % for the analysis as a whole
% opts.endFrame               % for the analysis as a whole
% opts.tileAssignments        % for the analysis as a whole
% opts.minNumCams             % for the analysis as a whole
% opts.maxBirdsToTrack        % for the analysis as a whole (at any given frame)
% opts.minimumTrackLength     % for the analysis as a whole
% opts.maximumGapLength       % for the analysis as a whole
% opts.filterFrequency        % for the analysis as a whole
% opts.subFrameInterpolation  % for the analysis as a whole
% opts.prefix                 % for the analysis as a whole
%
% threads specifies the number of matlabpool threads to use in processing
%
% The completed analysis is saved to a [prefix]_birdTracks.mat file in the
% same location as the options file
%
% Ty Hedrick, 2015-06-25
%
% _v2 2015-07-30 - uses realRMSE instead of the algebraic rmse for
% identifying good points in the 2D to 3D step.
%
% _v3 2015-09-22 - uses parpool instead of matlabpool if available
%
% _v4 2016-07-01 - uses the improved 2D --> 3D mapping routines developed
% for the flyBox
%
% UVto3D_v1.m 2019-09-01 was modified from birdsUVto3D_v4, written by Dr. Tyson
% Hedrick

opts.vInfo=4.0; % version of birdUVto3D

% Initialize and collect options if they're not in oFile
if isstr(opts)
  % Initialize options inputs as empty
  opts.distCoefsFile=[];
  opts.dltCoefs=[];
  opts.detectionsFile=[];
  opts.frameRate=[];
  opts.imageSize=[];
  opts.offsets=[];
  opts.dltThreshold=[];
  opts.startFrame=[];
  opts.endFrame=[];
  opts.tileAssignments=[];
  opts.minNumCams=[];
  opts.prefix=[];
  
  % intialize empty imgMasks
  imgMasks=[];
  
  % run the options file to get the trial-specific settings
  run(oFile)
end

% initialize other processing options
opts.procDate=datestr(now);

% load uv datafiles - expected format is [frame,u,v,area] or
% [frame,u,v,udot,vdot,area] with Python frame numbering and u,v
% coordinates
dets.numCams=numel(opts.movieFilename);

% load DLT coefficients
%birds.dltCoefs=importdata([opts.dataDir,filesep,opts.dltCoefsFile]);

% load distortion coefficients
%{
for i=1:dets.numCams
  if isempty(opts.distCoefsFile{i})==false
    load([opts.dataDir,filesep,opts.distCoefsFile{i}]);
    dets.camd{i}=camd;
    dets.camud{i}=camud;
    clear camd camud
  else
    dets.camd{i}=[];
    dets.camud{i}=[];
  end
end
%}

% get image masks
%{
if opts.useMask & isempty(opts.maskFile)
  for i=1:dets.numCams
    [mov,fname]=mediaRead(opts.movieFile{i},1,true,false);
    imgMasks{i}=vidMask_v1(mov);
  end
elseif opts.useMask
  load(opts.maskFile)
end
%}

% Process the points:
% 1) fix frame numbers
% 2) flip coordinates
% 3) undistort
%
% Fix frame numbers given offsets
%for i=1:dets.numCams
%  if ~isempty(dets.uvData{i}) && opts.offsets(i) ~=0
%    dets.uvData{i}(:,1)=dets.uvData{i}(:,1) - opts.offsets(i);
%  end
%end
%
% Flip vertical coordinate to put origin in lower left of image
%{
for i=1:dets.numCams
  if isempty(dets.uvData{i})==false
    dets.uvData{i}(:,3)=abs(dets.uvData{i}(:,3)-opts.imageSize{i}(2));
    
    % apply masks
    if opts.useMask
      for j=1:size(dets.uvData{i},1)
        foo=ceil(dets.uvData{i}(j,2:3));
        if imgMasks{i}(foo(2),foo(1))==0
          dets.uvData{i}(j,:)=NaN;
        end
      end
      idx=find(isnan(dets.uvData{i}(:,1)));
      dets.uvData{i}(idx,:)=[];
    end
  end
end
%}
%
% Undistort
%{
for i=1:dets.numCams
  if isempty(dets.camud{i})==false & isempty(dets.uvData{i})==false
    dets.uvData{i}(:,2:3)=applyTform(dets.camud{i},dets.uvData{i}(:,2:3));
  end
end
%}

% Set analysis range (or correct input values)
%

% correct inputs to the actual data extent
for i=1:dets.numCams
  bStart(i,1)=min(dets.uvData{i}(:,1));
  bEnd(i,1)=max(dets.uvData{i}(:,1));
end
opts.startFrame=max([opts.startFrame;bStart]);
opts.endFrame=min([opts.endFrame;bEnd]);

% Copy points into cell arrays for easier downstream use, new column order in each
% array is [x,y,area] or just [x,y] if no area provided
%
% New fast method %AJC note: this approach has problems when there are
% frames with no data. Going back to a simpler approach.
%{
for j=1:dets.numCams
  foo=diff(dets.uvData{j}(:,1));
  idx=find(foo>0); % rows where the frame # changes
  vals=dets.uvData{j}(idx+1,1); % value it is changing to
  
  for i=opts.startFrame:opts.endFrame
    idx2=find(vals<=i);
    %idx3=find(vals==i+1); was used as idx(idx3),[2:4])
    try
      dets.uvData2{i}{j}=dets.uvData{j}(idx(idx2(end))+1:idx(find(vals>i,1)),2:3); %Changed from 2:4 % This seems to be a problem when some frames have no detections
    catch
      dets.uvData2{i}{j}=zeros(0,3);
    end
  end
end
%}


%Alternative method that Aaron wrote for converting uvData to uvData2
%dets.uvData2 = cell(length(opts.endFrame),1);
% uvData2 is an array of xy points for each {frame}{camNumber}
dets.uvData2 = cell(opts.endFrame,dets.numCams);
for j = 1:dets.numCams
        foo=diff(dets.uvData{j}(:,1));
        idx=find(foo>0); % rows where the frame # changes
        vals=dets.uvData{j}(idx,1); % value it is changing from
        idx = [0; idx];
        for i = 1:length(idx)-1
            dets.uvData2{vals(i)}{j} = dets.uvData{j}(idx(i)+1:idx(i+1),2:4);
        end
       
        if ~isempty(vals)
            dets.uvData2{vals(end)}{j} = dets.uvData{j}(idx(end)+1:end,2:4);  %Save last set of detections
        end
        % Now add empty values for frames without data
        for i = opts.startFrame:length(dets.uvData2)
            if isempty(dets.uvData2{i})
                dets.uvData2{i} = {[]}; %Likely need to update when using multiple cameras
            end
        end
end
%% Get the number of detections in each camera in each frame
for i=opts.startFrame:opts.endFrame
  for j=1:dets.numCams
    dets.nDetect(i,j)=size(dets.uvData2{i}{j},1);
  end
end

% Enforce maxdets; sort by decreasing detection size
for i=opts.startFrame:opts.endFrame
  % sort
  % dets.uvData2{i}{j}=flipud(sortrows(dets.uvData2{i}{j},3));  %This
  % assumes ares is in uvData2(:,3)
  
  % keep only up to maxBirds detections
  for j=1:dets.numCams
      if isfield(opts,'maxBirdsToTrack')
        if dets.nDetect(i,j)>opts.maxBirdsToTrack
          dets.uvData2{i}{j}=dets.uvData2{i}{j}(1:opts.maxBirdsToTrack,:);
        end
      end
  end
end

%% Get 3D points

if nargin > 2
    if threads > 1
        if exist('gcp','file')==2
          if isempty(gcp('nocreate'))
            pp=parpool(threads);
            myPool=true;
          else
            pp=gcp();
            myPool=false;
          end
        else
          if parpool('size')==0 % 0 to create a pool if needed, 1 to not do so (for debugging)
            parpool('open',threads)
            myPool=true;
          else
            myPool=false;
          end
        end
    else 
    myPool = false;
    end
else 
    myPool = false;
end

tic
% map 2D to 3D
%[dets.xypts,dets.xyzpts]=collectShorebirds_v1(dets,opts);
%Shortcut if only doing 2D for one camera
xypts = cell(1,length(dets.uvData2));
uvData2 = dets.uvData2;
for i = opts.startFrame:length(uvData2)
    try
        xypts{i} = uvData2{i}{1}(:,1:2);
    catch
        1;
    end
end
dets.xypts = xypts;
clear uvData2 xypts;
toc


% count 3D points
%for i=opts.startFrame:opts.endFrame
%  dets.nXYZ(i,1)=size(dets.xyzpts{i},1);
%end
%disp('XYZ points extracted')

% reset startFrame if necessary
%idx=find(dets.nXYZ>0);
%opts.startFrame=max([idx(1),opts.startFrame]);
opts.endFrame = min(opts.endFrame,length(dets.xypts));
% Join xy to tracks
if threads > 1
    
    %Split chunks based on frames
    block_width = (opts.endFrame - opts.startFrame)/threads;
    blocks = round(opts.startFrame:block_width:opts.endFrame);
    starts = blocks(1:end-1)+1;
    ends = blocks(2:end);
    
    %Split chunks based on number of detections
    block_width = length(dets.uvData{1})/threads;
    %ends = dets.uvdata(round(block_width:block_width:length(dets.uvData{1}(:,1))));
    idx = round(block_width:block_width:length(dets.uvData{1}(:,1)));
    ends = dets.uvData{1}(idx,1)';
    starts = [1, ends(1:end-1)];

    parfor (i = 1:length(starts),threads)
        blockout{i} = fcns.Join2D_v1(dets,opts,starts(i),ends(i));
    end
    dets.blockout = blockout;
end
    dets.blockout{1} = fcns.Join2D_v1(dets,opts);
    fcns.out_to_uvdata;
if myPool
  if exist('gcp','file')==2
    delete(pp);
  else
    parpool('close')
  end
end    
    
% Join xyz & xy to tracks
%[dets,outXYd] = clusterBirdsJ_v1(dets,opts,threads);
%dets.outXYd=outXYd;

% Calculate some useful derivatives from the 3D data
%[dets] = birdDerivatives_v1(dets,opts,threads);

% export 2D data
if 0 % dets.tnum>0
  dets.offsets=opts.offsets;
  %exportBirds_v4(birds,opts.dataDir,[opts.prefix,'_gen5_'],max(birds.uvData{1}(:,1)),true)
  save('dets3.mat','dets','opts','-v7.3');
end
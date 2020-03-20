function [birds,opts,imgMasks] = birdUVto3D_v4ajc(oFile,threads)

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

opts.vInfo=4.0; % version of birdUVto3D

% Initialize and collect options if they're not in oFile
if isstr(oFile)
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
else
  opts=oFile;
end

% initialize other processing options
opts.procDate=datestr(now);
opts.nCams=numel(opts.imageSize);

% load uv datafiles - expected format is [frame,u,v,area] or
% [frame,u,v,udot,vdot,area] with Python frame numbering and u,v
% coordinates
birds.numCams=numel(opts.detectionsFile);
for i=1:birds.numCams
  foo=importdata([opts.dataDir,filesep,opts.detectionsFile{i}]);
  if isstruct(foo)
    birds.uvData{i}=foo.data;
  else
    birds.uvData{i}=foo;
  end
  clear foo
  
  % ajc changed this to use optic flow for
  % remove unnecessary columns - udot,vdot are poorly detected enough that
  % incorporating them into the analysis does not help
  if opts.subframeInterpolation
        if size(birds.uvData{i},2)>4
            flow = birds.uvData{i}(:,4:5);
            %birds.uvData{i}=birds.uvData{i}(:,[1,2,3,6]);
            birds.uvData{i}(:,2:3) = birds.uvData{i}(:,2:3)+opts.subframe(i).*flow;
        end
  end
end

% load DLT coefficients
birds.dltCoefs=importdata([opts.dataDir,filesep,opts.dltCoefsFile]);

% load distortion coefficients
for i=1:birds.numCams
  if isempty(opts.distCoefsFile{i})==false
    load([opts.dataDir,filesep,opts.distCoefsFile{i}]);
    birds.camd{i}=camd;
    birds.camud{i}=camud;
    clear camd camud
  else
    birds.camd{i}=[];
    birds.camud{i}=[];
  end
end

% get image masks
if opts.useMask & isempty(opts.maskFile)
  for i=1:birds.numCams
    [mov,fname]=mediaRead(opts.movieFile{i},1,true,false);
    imgMasks{i}=vidMask_v1(mov);
  end
elseif opts.useMask
  load(opts.maskFile)
end

% Process the points:
% 1) fix frame numbers
% 2) flip coordinates
% 3) undistort
%
% Fix frame numbers given offsets & the python-matlab 0 vs 1 base numbering
for i=1:birds.numCams
  if isempty(birds.uvData{i})==false
    birds.uvData{i}(:,1)=birds.uvData{i}(:,1) - opts.offsets(i);
  end
end
%
% Flip vertical coordinate to put origin in lower left of image
for i=1:birds.numCams
  if isempty(birds.uvData{i})==false
    %Try not flipping
      %birds.uvData{i}(:,3)=abs(birds.uvData{i}(:,3)-opts.imageSize{i}(2));
    
    % apply masks
    if opts.useMask
      for j=1:size(birds.uvData{i},1)
        foo=ceil(birds.uvData{i}(j,2:3));
        if imgMasks{i}(foo(2),foo(1))==0
          birds.uvData{i}(j,:)=NaN;
        end
      end
      idx=find(isnan(birds.uvData{i}(:,1)));
      birds.uvData{i}(idx,:)=[];
    end
  end
end
%
% Undistort
for i=1:birds.numCams
  if isempty(birds.camud{i})==false & isempty(birds.uvData{i})==false
    birds.uvData{i}(:,2:3)=applyTform(birds.camud{i},birds.uvData{i}(:,2:3));
  end
end

% Set analysis range (or correct input values)
%
% Set plausible inputs if none are given
if isempty(opts.startFrame)
  opts.startFrame=min(birds.uvData{1}(:,1));
end
if isempty(opts.endFrame)
  opts.endFrame=max(birds.uvData{1}(:,1));
end
%
% correct inputs to the actual data extent
for i=1:birds.numCams
  bStart(i,1)=min(birds.uvData{i}(:,1));
  bEnd(i,1)=max(birds.uvData{i}(:,1));
end
opts.startFrame=max([opts.startFrame;bStart]);
opts.endFrame=min([opts.endFrame;bEnd]);


% Copy points into cell arrays for easier downstream use, new column order in each
% array is [x,y,area]
%
% New fast method
for j=1:birds.numCams
  foo=diff(birds.uvData{j}(:,1));
  idx=find(foo>0); % rows where the frame # changes
  vals=birds.uvData{j}(idx+1,1); % value it is changing to
  
  for i=opts.startFrame:opts.endFrame
    idx2=find(vals<=i);
    %idx3=find(vals==i+1); was used as idx(idx3),[2:4])
    try
      birds.uvData2{i}{j}=birds.uvData{j}(idx(idx2(end))+1:idx(vals==i+1),[2:4]);
    catch
      birds.uvData2{i}{j}=zeros(0,3);
    end
  end
end

% Get the number of detections in each camera in each frame
for i=opts.startFrame:opts.endFrame
  for j=1:birds.numCams
    birds.nDetect(i,j)=size(birds.uvData2{i}{j},1);
  end
end

% Enforce maxbirds; sort by decreasing detection size
for i=opts.startFrame:opts.endFrame
  % sort
  birds.uvData2{i}{j}=flipud(sortrows(birds.uvData2{i}{j},3));
  
  % keep only up to maxBirds detections
  for j=1:birds.numCams
    if birds.nDetect(i,j)>opts.maxBirdsToTrack
      birds.uvData2{i}{j}=birds.uvData2{i}{j}(1:opts.maxBirdsToTrack,:);
    end
  end
end

% Get 3D points
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

tic
% map 2D to 3D
%[birds.xypts,birds.xyzpts]=collectShorebirds_v1(birds,opts);
[birds.xypts,birds.xyzpts]=collectBirds_v15(birds,opts);

toc
birds.numCams = length(opts.detectionsFile);
if myPool
  if exist('gcp','file')==2
    delete(pp);
  else
    matlabpool('close')
  end
end

% count 3D points
for i=opts.startFrame:opts.endFrame
  birds.nXYZ(i,1)=size(birds.xyzpts{i},1);
end
disp('XYZ points extracted')

% reset startFrame if necessary
idx=find(birds.nXYZ>0);
opts.startFrame=max([idx(1),opts.startFrame]);

% debug
% save debug_has_3D_points

% Join xyz & xy to tracks
[birds,outXYd] = clusterBirdsJ_v1(birds,opts,threads);
birds.outXYd=outXYd;

% Calculate some useful derivatives from the 3D data
[birds] = birdDerivatives_v1(birds,opts,threads);

% export 2D data
if birds.tnum>0
  birds.offsets=opts.offsets;
  %exportBirds_v4(birds,opts.dataDir,[opts.prefix,'_gen5_'],max(birds.uvData{1}(:,1)),true)
  save('birds3.mat','birds','opts','-v7.3');
end
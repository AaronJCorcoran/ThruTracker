%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This example tests C++ MEX-file backgroundSubtractorOCV. The MEX function
% uses BackgroundSubtractorMOG2 class in OpenCV. This example shows how to
% use background/foreground segmentation algorithm to find the moving cars
% in a video stream.
%
% Copyright 2014 The MathWorks, Inc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

% Create video reader object
%[vidfile vidfolder] = uigetfile();
vidfolder = 'S:\Projects\BridgeRecordings\';
vidfile = 'Burnsville Bridge_Bat Exit_215Ft_20200820.avi';
hsrc = vision.VideoFileReader([vidfolder vidfile], ...
                                  'ImageColorSpace', 'Intensity', ...
                                  'VideoOutputDataType', 'uint8');


%hsrc = vision.VideoFileReader('visiontraffic.avi', ...
%                                  'ImageColorSpace', 'RGB', ...
%                                  'VideoOutputDataType', 'uint8');
                              
% Create background/foreground segmentation object
varThreshold = 35; %16 was initial %75 Too high for bridge test
hfg = backgroundSubtractor(5, varThreshold, false); 

% Create blob analysis object
hblob = vision.BlobAnalysis(...
    'CentroidOutputPort', false, 'AreaOutputPort', false, ...
    'BoundingBoxOutputPort', true, 'MinimumBlobArea', 20);

% Create video player object
hsnk = vision.VideoPlayer('Position',[100 100 660 400]);
frameCnt = 1;

% Make Video of output
vidout = VideoWriter('VideoOut_35b.avi')
open(vidout);
while ~isDone(hsrc)
  % Read frame
  frame  = step(hsrc);
  
  %Smooth image with gaussian filter
  frame = imgaussfilt(frame, 2, 'FilterSize',5);
  
  % Compute foreground mask
  fgMask = getForegroundMask(hfg, frame);
  bbox   = step(hblob, fgMask);
  
  % Reset background model
  % This step just demonstrates how to use reset method
  if (frameCnt==10)
      reset(hfg);
  end
  
  % draw bounding boxes around cars
  out    = insertShape(frame, 'Rectangle', bbox, 'Color', 'White');
  
  % view results in the video player
  step(hsnk, out);
  frameCnt = frameCnt + 1;
  writeVideo(vidout,out);
end

release(hfg);
release(hsnk);
release(hsrc);
close(vidout);

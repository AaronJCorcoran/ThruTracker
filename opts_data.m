% thruTracker opts file

%opts.projectDir = 'C:\Data\' % Default project directory is path where opts file is
%stored. You can also set it here. The project directory is where data
%folder will will be made and saved

%opts.movieFilename={'\Videos\A65sc-496_77105-000079-293_23_00_03_438_RR_3_bat_clip.wmv'};    %File names of movies for this project. Can be the full path name, or a path relative to project directory
opts.detector = 'optic flow';     % Options include 'optic flow' and 'background subtraction' although background subtraction requires further testing
opts.minObjectArea = 5;           % objects that have a pixel area less than this value will be filtered
opts.maxObjectArea = 500;         % objects that have a pixel area greater than this value will be filtered
opts.startFrame = 1;              % first frame to analyze.
opts.endFrame   = nan;          % last frame to analyze. Set to NaN if all frames
opts.turbine= true;               % Is there a wind turbine present? set to true or false
opts.subtractBackground = true;   % Use background subtraction for object detection? Need to check if this is currently used
opts.turbine_detector = 'edge';   % Use 'NN' for neural network2 or 'edge' for edge detection
opts.headerrows = 513:532;        % Specify rows where header info is saved (513:532 for Flir A65; 1:25 for Axis

% Number of threads for parallel processing. Specify 1 to not use parrallel
% processing, or 999 to use all available processors. Note: visualization
% of detections is only possible when threads are set to 1.
opts.threads = 1;                 
opts.saveFileName = 'TestNN_20200109.mat';  % Filename where data will be saved. Needs to end with ".mat"

%% 2D tracking options
opts.minimumTrackLength = 5;        % Must have at least this many detections across frames to accept as a track
opts.maximumGapLength = 8;          % Maxium number of frames between detections to keep track going
opts.badMatchThreshold = 50;        % Maximum distance between projected location and actual location to accept as part of track. 
% I'm using badMatchThreshold = 50 for Flir A65 cameras that recorded with
% highly variable frame rates. Should be able to use lower values when
% frame rate is consistent
opts.tileAssignments = false;       % Keep as false unless detection dozens or more animals at a time
opts.nCams = 1;                     % Number of cameras (Should be able to determine automatically using moviefilenames above)
opts.maxBirdsToTrack = 100;         % Maximum number of animals to track at a given time
opts.joiningBias=1;                 % Keep at 1 to bias toward making longer tracks



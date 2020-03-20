% birdUVto3D_v2 options file (also works with later birdUVto3D_ versions)
%
opts.dataDir=fileparts(mfilename('fullpath'));
opts.distCoefsFile={'../Calibrations/Cam1-Cam4_Calibration07092015_cam1Tforms.mat', ...
  '../Calibrations/Cam1-Cam4_Calibration07092015_cam2Tforms.mat'};
opts.dltCoefsFile=['../Calibration/Cam1-Cam4_Calibration07092015_dltCoefs.csv'];
opts.detectionsFile={['blue2_39000.csv'],['red2_39000.csv'],['green2_39000.csv']};
opts.movieFile={['../Blue/2.MOV'],['../Red/2.MOV'],['../Green/2.MOV']};
opts.useMask=false;
opts.maskFile=[];
opts.frameRate=[29.97];
opts.imageSize={[1920,1080],[1920,1080],[1920,1080]};      
opts.offsets=[0,386,-1074];        
opts.dltThreshold=4;   
opts.startFrame=39300;
opts.endFrame=39350;
opts.tileAssignments=true;
opts.minNumCams=2;
opts.maxBirdsToTrack=inf;
opts.minimumTrackLength = 3;
opts.maximumGapLength = 10;
opts.filterFrequency = 8;
opts.subframeInterpolation = false;
opts.subframe = [0,0,0];   % added by ajc 2017-08-19
opts.prefix='20170417_S2_fr39000d_';

% new stuff for birdUVto3D_v4
opts.frameStep=1;
opts.extrapUV=true;
opts.enforceFlyBox=false;
opts.joiningBias=3; % 1 = join, 2 = split, 3 = neutral
opts.xyzJoiningDivisor=5; % larger --> less weight on 3D info for track forming
opts.xyJoiningDivisor=1; % larger --> less weight on 2D info for track forming
opts.badMatchThreshold=5; % larger --> allow larger leaps in track joining

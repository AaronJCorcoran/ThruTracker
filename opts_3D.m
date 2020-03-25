% birdUVto3D_v2 options file (also works with later birdUVto3D_ versions)
% Test notes for GitHub Testing
% Second change, adding notes for change
opts.dataDir=fileparts(mfilename('fullpath'));
opts.distCoefsFile={'../Calibrations/Cam1-Cam4_Calibration07092015_cam1Tforms.mat', ...
                    '../Calibrations/Cam1-Cam4_Calibration07092015_cam2Tforms.mat'};
opts.dltCoefsFile=['../Calibrations/Cam1-Cam4_Calibration07092015_dltCoefs.csv'];
opts.detectionsFile={['Cam1_uvdata.csv'],['Cam4_uvdata.csv']};
opts.movieFile={['../Blue/2.MOV'],['../Red/2.MOV']};
opts.useMask=false;
opts.maskFile=[];
opts.frameRate=50;
opts.imageSize={[2000,1080],[2000,1080]};      
opts.offsets=[0,0];        
opts.dltThreshold=10;   
opts.startFrame=1;
opts.endFrame=1000;
opts.tileAssignments=false;
opts.minNumCams=2;
opts.maxBirdsToTrack=inf;
opts.minimumTrackLength = 5;
opts.maximumGapLength = 10;
opts.filterFrequency = 8;
opts.subframeInterpolation = false; 
opts.subframe = [0,0];   % added by ajc 2017-08-19
opts.prefix='FieldTest1_';

% new stuff for birdUVto3D_v4
opts.frameStep=1;
opts.extrapUV=true;
opts.enforceFlyBox=false;
opts.joiningBias=1; % 1 = join, 2 = split, 3 = neutral
opts.xyzJoiningDivisor=5; % larger --> less weight on 3D info for track forming
opts.xyJoiningDivisor=1; % larger --> less weight on 2D info for track forming
opts.badMatchThreshold=20; % larger --> allow larger leaps in track joining

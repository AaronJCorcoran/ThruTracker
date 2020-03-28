function [uvdata, clouds] = opflow_par_shim(vid,opts, app)
threads = opts.threads;

% Get number of frames
nFrames = vid.Duration * vid.FrameRate;
nFrames = opts.endFrame - opts.startFrame + 1;

%Split up frames into chunks
frames_per_core = round(nFrames/threads);
end_frames = frames_per_core:frames_per_core:nFrames;
end_frames(threads) = nFrames;     %make sure last frame ends at correct frame
start_frames = [1 end_frames(1:end-1)+1];
end_frames = end_frames + opts.startFrame-1;
start_frames = start_frames + opts.startFrame-1;

% Set up VideoReaders
vidpar = {};
for i = 1:threads
    vidpar{i} = VideoReader(opts.movieFilename{1});
    opts_thread{i} = opts;
    opts_thread{i}.startFrame = start_frames(i);
    opts_thread{i}.endFrame = end_frames(i);
end

%Setup and run in parallel
uvdata_thread = {};
clouds_thread = {};
tic

%for i = 1:threads
%   [uvdata_thread{i}, clouds_thread{i}] = fcns.opflow_detect(vidpar{i},opts_thread{i},app);
%end
pseudo_app.se1 = app.se1;
pseudo_app.se3 = app.se3;
pseudo_app.seBuffer = app.seBuffer;
pseuod_app.net = app.net;
for i = 1:threads
    thread_list{i} = i;
end
parfor(i = 1:threads,threads)
%for i = 1:threads
   [uvdata_thread{i}, clouds_thread{i}] = fcns.opflow_detect(vidpar{i},opts_thread{i},pseudo_app, thread_list{i});
end

toc
uvdata = [];
clouds = [];

% Put the pieces back together
for i = 1:threads
    uvdata = [uvdata;uvdata_thread{i}];
    clouds = [clouds; clouds_thread{i}];
end
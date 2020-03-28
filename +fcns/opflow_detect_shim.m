function [uvdata, clouds] =  opflow_detect_shim(app, opts, threads)
% Shim function for parrallelizing optic flow detector
debugging = false;
if debugging
    %threads = 1;
end
%Initialize output variables;
uvdata = [];
clouds = [];

startFrame = opts.startFrame;      %First frame to process
endFrame = opts.endFrame;          %Last frame to process
NFrames = endFrame-startFrame-1;   %Total N frames to process
frames_per_thread = 100;            %Approximate number of frames to process on each thread
chunkNframes = frames_per_thread*threads;   %Total number of frames to process on all cores at one time
%Note: a "chunk" is a set of frames that will be read and then split into
%threads to process
Nchunks = ceil(NFrames/chunkNframes);  %Split video into this many chunks 
endFrames = round(chunkNframes:chunkNframes:NFrames) + startFrame -1;
startFrames = [startFrame (endFrames(1:end-1) +1)];

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

% Process chunks in a loop
for i = 1:Nchunks
    disp(['Processing chunk ', num2str(i), ' out of ', num2str(Nchunks)]); 
    tic
    chunk_frames = endFrames(i)-startFrames(i)+1; %Number of frames in this chunk
    
    % advance to frame before startFrame
    app.v.CurrentTime= (startFrames(i)-1)*(1/app.v.frameRate);
    
    % read all frames in the chunk
    frames = nan(opts.imageSize(2),opts.imageSize(1),chunk_frames);
    tic
    for j = 1:chunk_frames
        frame = app.v.readFrame();
        frame(opts.headerrows,:,:) = [];        %Crop header
        frame = mean(frame,3);
        frames(:,:,j) = frame;
    end
    toc
    disp('frames read, now processing in parrallel');
    %Now split frames to process in parallel
    threadNframes = round(chunk_frames/threads);        %Number of frames per thread
    threadEndFrames = threadNframes:threadNframes:chunk_frames;
    threadStartFrames = [1 (threadEndFrames(1:end-1))]; %Deliberately overlapping start and end frames by 1
    opts = app.opts;
    %Process frames in parrallel
    if debugging
        for k = 1:threads
                [uvdata_thread{k},cloud_thread{k}] = fcns.opflow_detect([],opts,...
                    frames(:,:,threadStartFrames(k):threadEndFrames(k)));
                if ~isempty(uvdata_thread{k})
                    uvdata_thread{k}(:,1) = uvdata_thread{k}(:,1) + threadStartFrames(k);
                end
        end
    elseif 0
        for k = 1:threads
           framesc{k} = frames(:,:,threadStartFrames(k):threadEndFrames(k));
        end
        parfor k = 1:threads
                [uvdata_thread{k},cloud_thread{k}] = fcns.opflow_detect([],opts,...
                    framesc{k});
               % uvdata_thread{k}(:,1) = uvdata_thread{k}(:,1) + threadStartFrames(k);
        end
        %for k = 1:threads
        %    uvdata_thread{k}(:,1) = uvdata_thread{k}(:,1) + threadStartFrames(k);
        %end
    else
        % Test for shifting parrallization downstream
        [uvdata_thread,cloud_thread] = fcns.opflow_detect([],opts,...
                    frames);
    end
    
    %for k = 1:threads
    %    uvdata = [uvdata; uvdata_thread{k}];
    %    clouds = [clouds; cloud_thread{k}];
    %end
    %Reassemble uvdata and clouds
    toc
    disp([num2str(chunk_frames) ' processed']);
end

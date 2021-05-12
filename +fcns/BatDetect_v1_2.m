function [uvdata, clouds] = BatDetect_v1_2(v, app, opts)
        %% Program for detecting objects in videos
        % 
        % determine frames to analyze
        startFrame = opts.startFrame;
        endFrame = opts.endFrame;
        
        % advance to frame before startFrame
        v.CurrentTime= (startFrame-1)*(1/v.FrameRate);

        % initialize output
        uvdata=[];

        % read first frame
        if isstruct(v)  %cine file format
            last_frame = cineRead(opts.movieFilename{1},1);
            last_frame = last_frame./max(last_frame(:));
            low_high = stretchlim(last_frame,[0.1,0.999]);  %Determine low and high crop values for whole video
            last_frame = imadjust(last_frame,low_high,[]);  %Crop low and high pixel values
            last_frame = uint8(last_frame*256);     %Convert to 8-bit
        else % VideoReader format
            last_frame=v.readFrame();
            last_frame(opts.headerrows,:,:) = [];        %Crop header
            last_frame = mean(last_frame,3);    %Average intensity values
        end
        
        %Initialize clouds variable
        clouds = nan(endFrame,1);
        %se3=strel('disk',3);
        se = strel('disk',round(opts.smoothingPixels/2)); %for closing operation
        % work through the frames in a loop
        
        % Create background/foreground segmentation object
        %varThreshold = 12; %16 was initial %75 Too high for bridge test
        if strcmp(app.opts.detector,'openCV')
            hfg = backgroundSubtractor(opts.backgroundFrames, opts.sensitivity, false);
            openCVdetector = true;
        else %use Matlab detector
            openCVdetector = false; %Indicator that openCV is not available.
            detector = vision.ForegroundDetector(...
               'InitialVariance', 30^2,...
               'NumTrainingFrames', 50,...
               'MinimumBackgroundRatio', opts.sensitivity,...
               'LearningRate',opts.backgroundFrames); %Use this as a substitute value;
        end
         hblob = vision.BlobAnalysis(...
    'CentroidOutputPort', true, 'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, 'MinimumBlobArea', opts.minObjectArea,'MaximumBlobArea',opts.maxObjectArea,'MaximumCount',1500);
        
        for i=startFrame:endFrame

            % grab the current frame
            if isstruct(v) % Cine format
                frame = cineRead(opts.movieFilename{1},i);
                frame = frame./max(frame(:));
                frame = imadjust(frame,low_high);  %Crop low and high pixel values
                frame = uint8(frame*256);     %Convert to 8-bit
            else
                if hasFrame(v) %videoReader format
                    frame=v.readFrame();
                    frame(opts.headerrows,:,:) = [];        %Crop header
                    %frame = mean(frame,3);
                else
                    % assume if we couldn't read a frame that we're at the end
                    disp('unexpected end of video')
                    return
                end
            end
            

            %{
            [frame_sub, turbine_pixels, dets.clouds(i)] = fcns.getFrameSub(frame, last_frame, app.opts,se3);
            
            %foreground = frame_sub> opts.thresh;
            frame_sub(frame_sub<=0) = 0;
            
            %Smooth image with gaussian filter
            frame_sub = imgaussfilt(frame_sub, 2, 'FilterSize',5); 
            
            % Set threshold dynamically
            foo = frame_sub(:);
            foo = foo(foo>0);
            if length(foo) > 15000
                foo = datasample(foo,10000,'Replace',false); %Take subsample of image for noise analysis
            end
            pd = fitdist( foo,'Weibull');    %Exclude zero values
            thresh = icdf(pd,0.99999) + 0.5;    %Added 0.5 for extra buffer
            foreground = frame_sub> thresh;
            %}
            % Compute foreground mask
            
            %Smooth image with gaussian filter
            
            if size(frame,3) > 1
                frame = rgb2gray(frame);
            end
            
            % filter size needs to be odd!
            if opts.smoothingPixels > 1
                if ~mod(opts.smoothingPixels,2)
                    filtSize = opts.smoothingPixels +1;
                else
                    filtSize = opts.smoothingPixels;
                end
                    frame = imgaussfilt(frame, 2, 'FilterSize',filtSize);
            end
            if openCVdetector
                foreground = getForegroundMask(hfg, frame);
            else
                foreground = detector(frame);
            end
            
            turbine_pixels = [];
 
            %Perform a morphological close operation on the image.

            foreground = imclose(foreground,se);
            % get area stats
            % stats=regionprops(foreground,'centroid','area','solidity');
            [stats2.Area, stats2.Centroid] = step(hblob,foreground);
            
            %stats2.Area=cat(1,stats.Area);
            %stats2.Centroid=cat(1,stats.Centroid);
            %stats2.Solidity=cat(1,stats.Solidity);
            %app.dets.stats2{i} = stats2;              %Save for later 

            % search for bat-like objects & store
            %idxd=find(stats2.Area > opts.minObjectArea &...
            %          stats2.Area < opts.maxObjectArea   &...
            %          stats2.Solidity > 0.7);
    

            last_frame=frame;
                  
            if 1 % numel(stats2.Area)>0 && numel(stats2.Area)<20 % anything above 20 detections is likely bad background & noise
                %Apply binary model to filter turbines, clouds, etc
                %Scale to max value
                if opts.NNfilter
                    Y = nan(length(stats2.Area),1);
                    for j = 1:length(stats2.Area)
                        img = crop_image(frame,stats2.Centroid(j,:),50,50);
                        %img = img./max(img(:));
                        img = rescale(img,0,1,'InputMin',min(img(:)),'InputMax',max(img(:)));
                        img = repmat(img,1,1,3);
                        Y(j) = predict(app.net,img);
                    end
                    idx = find(Y>0.3);
                    stats2.Centroid = stats2.Centroid(idx,:);
                    stats2.Area = stats2.Area(idx);
                end
                uvdata=[uvdata;[stats2.Area*0+i,double(stats2.Centroid),stats2.Area]];
            else
                stats2.Centroid = [];
                stats2.Area = [];
            end


            if opts.threads==1
                % plot every 10th frame if display toggle is on
                if mod(i,10)==0 && strcmp(app.DisplayImagesSwitch.Value, 'On')
                    plotDetections(app, frame, i, stats2.Centroid, turbine_pixels, foreground)
                    app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};
                elseif mod(i,100)==0
                    app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};  %Update every 100th frame
                    pause(0.01)
                    drawnow 
                end
                drawnow limitrate
            end
        end     %for loop
        1;
end         %bat_detector_v1
        

function dets = BatDetect_v1_2(app, opts)
        %% Program for detecting objects in videos
        % 
        % determine frames to analyze
        startFrame = opts.startFrame;
        endFrame = opts.endFrame;
        
        % advance to frame before startFrame
        app.v.CurrentTime= (startFrame-1)*(1/app.v.frameRate);

        % initialize output
        dets.uvdata=[];

        % read first frame
        last_frame=app.v.readFrame();
        last_frame(opts.headerrows,:,:) = [];        %Crop header
        last_frame = mean(last_frame,3);    %Average intensity values
        %Initialize clouds variable
        dets.clouds = nan(endFrame,1);
        se3=strel('disk',3);
        % work through the frames in a loop
        for i=startFrame:endFrame

            % grab the current frame
            if hasFrame(app.v)
                frame=app.v.readFrame();
                frame(opts.headerrows,:,:) = [];        %Crop header
                frame = mean(frame,3);
            else
                % assume if we couldn't read a frame that we're at the end
                disp('unexpected end of video')
                return
            end
            
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
            
            % get area stats
            stats=regionprops(foreground,'centroid','area','solidity');
            stats2.Area=cat(1,stats.Area);
            stats2.Centroid=cat(1,stats.Centroid);
            stats2.Solidity=cat(1,stats.Solidity);
            %app.dets.stats2{i} = stats2;              %Save for later 

            % search for bat-like objects & store
            idxd=find(stats2.Area > opts.minObjectArea &...
                      stats2.Area < opts.maxObjectArea   &...
                      stats2.Solidity > 0.7);
    
            if numel(idxd)>0 && numel(idxd)<8 % anything above 4 detections is likely bad background & noise
                dets.uvdata=[dets.uvdata;[idxd*0+i,stats2.Centroid(idxd,:)]];
                stats2.Centroid = stats2.Centroid(idxd,:);
            end

            % current frame becomes previous frame
            last_frame=frame;

            % plot every 10th frame if display toggle is on
            if mod(i,10)==0 && strcmp(app.DisplayImagesSwitch.Value, 'On')
                plotDetections(app, frame, i, stats2, turbine_pixels, foreground)
                app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};
            elseif mod(i,100)==0
                app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};  %Update every 100th frame
                pause(0.01)
                drawnow 
            end
            drawnow limitrate
        end     %for loop
end         %bat_detector_v1
        

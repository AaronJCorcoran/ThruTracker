function detections = BatDetector_v1(app)
        
        % determine frames to analyze
        startFrame = app.opts.startFrame;
        endFrame = app.opts.endFrame;
        
        % advance to frame before startFrame
        app.v.CurrentTime= (startFrame-1)*(1/app.v.frameRate);

        % initialize output
        detections=[];

        % setup erode/dilate element

        se1=strel('disk',1);
        se2=strel('disk',2);
        se3=strel('disk',3);
        
        % read first frame
        a=app.v.readFrame();
        a(app.opts.headerrows,:,:) = [];        %Crop header
        ag = mean(a,3);         %Convert thermal to grayscale
        ag = ag./255;           %First frame in grayscale from 0 to 1
            
        % work through the frames in a loop
            for i=startFrame:endFrame
                
                % grab the current frame
                if hasFrame(app.v)
                    b=app.v.readFrame();
                    b(app.opts.headerrows,:,:) = [];        %Crop header
                    bg = mean(a,3);
                    bg = bg./255;   % current frame in grayscale from 0 to 1
                else
                    % assume if we couldn't read a frame that we're at the end
                    disp('unexpected end of video')
                    return
                end
                
                % get the difference between this frame and the previous one
                %c=b(:,:,1)-a(:,:,1);
                c = mean(b,3) - mean(a,3);      %Using average intensity
                %bwB=b(:,:,1)>20;
                
                % Find turbine by converting image to foreground and
                % background
                BW = imbinarize(bg);        % Auto threshold image
                if app.opts.subtractBackground
                    BW(c>60) = 1;               % Add moving parts
                end
                BWd = imdilate(BW,se3);     % Black and white dilated image
                
                stats=regionprops(BWd,'area','pixelidxlist');
                area=cat(1,stats.Area);
                
                if app.opts.turbine
                    idx_t=find(area==max(area));      % Index of the turbine in current image
                    %app.dets.turbine_pixels{i} = uint32(stats(idx_t(1)).PixelIdxList);    % indexes of pixels of the turbines
                    turbine_pixels = stats(idx_t(1)).PixelIdxList;
                end
                
                % find areas that are bright on the absolute scale or brighter than the
                % previous image
                if app.opts.subtractBackground
                    bwB=bg>120/255 | c>60;     % Could adjust this to do a rolling scan for background subtraction
                else
                    bwB=bg>120/255;
                end
                
                % check to see if it is too cloudy for scanning, keep going if fewer
                % than 100,000 background pixels found.  The turbine is typically about
                % 30k pixels, so this leaves a lot of wiggle room for moderately cloudy
                % skies
                if sum(sum(bwB))>100000
                    if mod(i,100)==0
                         app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)], ['Too cloudy, skipping frame']};
                         imshow(b,'Parent',app.UIAxes);
                         cla(app.UIAxes2);
                         drawnow
                    end
                    a=b; 
                    continue
                end
                    
                % dilate to clump things & get the area and pixels of each blob; pick
                % the largest one - this is the turbine & will be removed later
                bwB2=imdilate(bwB,se2);
                
                %bw=(c(:,:,1)>20);
                
                % now find regions that are brighter than the previous image; remove
                % the turbine from this set of regions
                bw=(c>60);
                
                if app.opts.turbine
                    bw(stats(idx_t(1)).PixelIdxList)=0;
                end
                
                % erode and dilate to smooth & join
                bw2=imdilate(bw,se2);
                %app.dets.bw2{i} = bw2;
                
                % get area stats
                stats=regionprops(bw2,'centroid','area','solidity');
                stats2.Area=cat(1,stats.Area);
                stats2.Centroid=cat(1,stats.Centroid);
                stats2.Solidity=cat(1,stats.Solidity);
                %app.dets.stats2{i} = stats2;              %Save for later 
                
                % search for bat-like objects & store
                idxd=find(stats2.Area > app.opts.minObjectArea &...
                          stats2.Area<app.opts.maxObjectArea   &...
                          stats2.Solidity > 0.7);
                      
                if numel(idxd)>0 && numel(idxd)<4 % anything above 4 detections is likely bad background & noise
                    app.dets.uvdata=[app.dets.uvdata;[idxd*0+i,idxd*0+app.v.CurrentTime,stats2.Centroid(idxd,:)]];
                end
               
                % current frame becomes previous frame
                a=b;
                
                % report progress
                if i > 5380
                    1;
                end
                % plot every 10th frame if display toggle is on
                if mod(i,10)==0 && strcmp(app.DisplayImagesSwitch.Value, 'On')
                    plotDetections(app, b, i, stats2, turbine_pixels, bw2)
                    app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};
                elseif mod(i,100)==0
                    app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};  %Update every 100th frame
                    pause(0.01)
                    drawnow 
                end
                drawnow limitrate
            end     %for loop
        end         %bat_detector_v1
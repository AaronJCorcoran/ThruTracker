function [frame_sub, turbine_pixels,clouds] = getFrameSub(frame, last_frame, opts, se3)
    
        % get the difference between this frame and the previous one
        try
            frame_sub = frame - last_frame;     
        catch
            %Frames likely different sizes
            frame_sub = [];
            return
        end
            % Find turbine by converting image to foreground and
        % background
        foreground = frame>60;             % Fixed threshold is intentionally low to get turbine blades at odd angles

        if opts.subtractBackground
            foreground(frame_sub>opts.thresh) = 1;               % Add moving parts
        end
        
        % setup erode/dilate element
        
        foreground = imdilate(foreground,se3);     % Black and white dilated image including moderately bright objects and moving objects
        %frame_sub = imdilate(frame_sub, se3);
        
        stats=regionprops(foreground,'area','pixelidxlist');
        area=cat(1,stats.Area);

        if opts.turbine
            idx_t=find(area==max(area));      % Index of the turbine in current image
            %app.dets.turbine_pixels{i} = uint32(stats(idx_t(1)).PixelIdxList);    % indexes of pixels of the turbines
            turbine_pixels = stats(idx_t(1)).PixelIdxList;
        end

        clouds = sum(sum(foreground));

        % now find regions that are brighter than the previous image; remove
        % the turbine from this set of regions
        if opts.turbine
            frame_sub(stats(idx_t(1)).PixelIdxList)=0;
        end
end
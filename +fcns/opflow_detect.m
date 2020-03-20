function [uvdata, clouds] = opflow_detect (vid, opts, app, thread)
%% Program for detecting objects in videos using optic flow
%

startFrame = opts.startFrame;
endFrame = opts.endFrame;

% advance to frame before startFrame
vid.CurrentTime= (startFrame-1)*(1/vid.frameRate);

% read first frame
last_frame = vid.readFrame();
try
    last_frame(opts.headerrows,:,:) = [];        %Crop header
catch
    msgbox('Wrong Header Rows; Change header rows option and try again');
    return
end
    last_frame = mean(last_frame,3);    %Average intensity values
frames_provided = false;


% initialize output
uvdata=[];

%Initialize clouds variable and optic flow
clouds = nan(endFrame,1);

%Initialize Optic Flow
opticFlow = opticalFlowHS;
opticFlow.MaxIteration = 1;
opticFlow.Smoothness = 1;
flow = estimateFlow(opticFlow,last_frame);

% Get turbine for first frame
%se3 = strel('disk',3);
last_turbine = fcns.getTurbineShim(last_frame,app.se3,app.seBuffer);

% work through the frames in a loop
for i=startFrame+1:endFrame
    if frames_provided
        frame = frames(:,:,i);  %Was using this for trying to run in parrallel
    else
        % grab the current frame
        if hasFrame(vid)
            frame=vid.readFrame();
            frame(opts.headerrows,:,:) = [];        %Crop header
            frame_rgb = frame;      %Save copy of original color image
            frame = mean(frame,3);
        else
            % assume if we couldn't read a frame that we're at the end
            disp('unexpected end of video')
            %dets.uvData{1} = uvdata;
            return
        end
    end
    % Measure of cloud cover
    clouds(i) = sum(frame(:)>60);
    
    % Get optic flow
    flow = estimateFlow(opticFlow,frame);
    
    % Find turbine
    if strcmp(opts.turbine_detector, 'edge')
        [turbine_pixels, turbine_image] = fcns.getTurbineShim(frame,app.se3,app.seBuffer);
    elseif strcmp(opts.turbine_detector,'NN')
        %app.net = load("TurbineNetwork1.mat")
        [turbine_pixels, turbine_image] = fcns.getTurbineNN(frame_rgb,app.se3,app.net,app.seBuffer);
    else
        %disp('No turbine detector specified')
        turbine_pixels = [];
        turbine_image = [];
    end
    
    if ~isempty(turbine_pixels)
        %[turbine_pixels, turbine_image] = fcns.getTurbineShim(frame,app.se1);
        turbine_image(last_turbine) = 1;
        all_turbine = union(turbine_pixels, last_turbine);

        last_turbine = turbine_pixels;
        turbine_pixels = find(turbine_image==1);
        [x,y] = ind2sub(size(frame),turbine_pixels);
    end
    
    % Get Optic Flow Magnitude
    %magf = flow.Magnitude;
    
    % Or use simple background subtraction
    magf = frame - last_frame;
    magf (magf < 0) = 0.001;
    
    %Set turbine values to 0
    if ~isempty(turbine_pixels)
        magf(turbine_image==1) = -0.1;   %Set values of turbine = 
    end
    
    %Apply gaussian filter, should be close to size of minimum expected
    %object diameter
    magf = imgaussfilt(magf,2,'FilterSize',3);   

    % Set threshold dynamically
    foo = magf;
    foo = foo(:);
    foo(foo<0) = [];
    %foo(all_turbine) = [];
    foo(foo==0) = 0.001;
    
    %Take subsample of image for noise analysis
    if length(foo) > 15000
        foo = datasample(foo,10000,'Replace',false); 
    end
    pd = fitdist( foo,'Weibull');    %Exclude zero values
    if strcmp(opts.DetectionSensitivity, 'High')
        thresh = icdf(pd,0.999) + 0.2;
    elseif strcmp(opts.DetectionSensitivity,'Medium')
        thresh = icdf(pd,0.9999) + 0.2;
    elseif strcmp(opts.DetectionSensitivity,'Low')
        thresh = icdf(pd,0.99999) + 0.2;
    end
    %thresh = icdf(pd,0.99999) + 0.3;    % More conservative option
    %thresh = icdf(pd,0.9999) + 0.1;    %Added 0.5 for extra buffer  %Changed to be more sensitive on 11/26/2019. Set this as an option?
    
    thresh = max([thresh, 0.5]); % Make sure optic flow is at least 1.5
    %pixels This appeared to be too stringent
    
    %Find foreground
    foreground = magf > thresh;

    % Get Foreground objects
    stats=regionprops(foreground,'centroid','area','PixelList','BoundingBox');
    brightness_d = nan(size(stats));    %Difference in brightness between this and last frame
    brightness = nan(size(stats));      %Absolute max brightness in this frame
    
    %Determine brightness difference for each blob
    for j = 1:length(stats)
        foo = sub2ind(size(foreground),stats(j).PixelList(:,2),stats(j).PixelList(:,1));
        brightness_d(j) = median( frame(foo) - last_frame(foo) );
        brightness(j) = max(frame(foo));
    end
    
    areas=cat(1,stats.Area);
    centroids=cat(1,stats.Centroid);
    bbox = cat(1,stats.BoundingBox);
    data = [areas centroids brightness_d brightness bbox];   %Compile areas and centroids to keep data together

   
    if ~isempty(data)
        
        %Remove points that are darker in current frame than in last frame
        %{
        idx = find(data(:,4) < -1);
        if ~isempty(idx)
          data(idx,:) = [];   
        end
        %}
        % Filter based on area
        idxd=find(data(:,1) > opts.minObjectArea &...
                  data(:,1) < opts.maxObjectArea);
        data = data(idxd,:);
        
        %Sort data in descending order by area
        data = sortrows(data,"descend");
        
        %Only keep five top biggest points
        if size(data,1) > 5
             data = data(1:5,:);
             %data = []; % Too many detections, likely clouds
        end
        
        
        
        %Remove smaller points that are nearby to larger points (typically
        %an artifact of optic flow on thermal data
        %{
        k = 1;
        d_thresh = 30;
        while k < size(data,1)
            %Find distances of all points after current point
            distances = fcns.rnorm(data(k+1:end,2:3)-data(k,2:3));
            
            % Find points within threshold from first 
            idx = find(distances < d_thresh);
            if ~isempty(idx)
                %Remove nearby points
                data (k + idx,:) = []; 
            end
            k = k+1; %Increment k
        end
        %}
        
        % Filter smaller objects that are within a set distance from larger
        % objects. These appear to be artifacts.
        
        %Check for distance of each centroid to turbine
        %{
        turb_dist = nan(size(data,1),1);
        for j = 1:size(data,1)
            turb_dist(j) = min(fcns.rnorm([data(j,2)-y, data(j,3)-x]));
        end
        
        if ~isempty(turb_dist)
            data(turb_dist < 5,:) = [];
        end
        %}
        
        %if numel(idxd)>0 && numel(idxd)<6 % anything above 5 detections is likely bad background & noise
            % Save data
            % First column is the frame
            % Second and third columns are centroids
            % Fourth Column: Area
            % Fifth column: absolute max brightness
            %               Frame                      centroid     area
            uvdata=[uvdata;[zeros(size(data,1),1)+i-1, data(:,2:3), data(:,1), data(:,5)]];
        %end
    end

    % current frame becomes previous frame
    last_frame=frame; %Not used here
    
    if opts.threads ==1 %Can't update if processing in parrallel
        % plot every 10th frame if display toggle is on
        if mod(i,10)==0 && strcmp(app.DisplayImagesSwitch.Value, 'On')
            if isempty(data)
                plotDetections(app, last_frame, i, [], [], magf);
            else
                plotDetections(app, last_frame, i, data(:,2:3), [], magf)
            end
            app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};
            drawnow limitrate
        elseif mod(i,100)==0
            app.ProgressTextArea.Value = {['Frame ' num2str(i) ' of ' num2str(endFrame)]};  %Update every 100th frame
            pause(0.01)
            drawnow limitrate
        end
    else
        if mod(i-startFrame,100)==0
            disp([num2str(i-startFrame) ' out of ' num2str(endFrame-startFrame + 1) ' frames processed in thread ' num2str(thread)]);
        end
    end
    
end     %for loop
%dets.uvData{1} = uvdata;    %Will need to change for multiple cameras


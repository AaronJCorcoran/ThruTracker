function [data_table] = TrackCalcs(dets)
%Cell array with frames, x & y for each track
tracks = cell(max(dets.tracks2D),1);

%Track parameters
sinuosity = nan(size(tracks));
track_speed = nan(size(tracks));
track_movement = nan(size(tracks));
track_area = nan(size(tracks));
track_brightness = nan(size(tracks));
start_frame = nan(size(tracks));
end_frame = nan(size(tracks));

uvDatasum = sum(dets.uvData{1}(:,1:3),2);

% Process tracks
for i = 1:length(tracks)
    % Find detections for this track
    idx = find(dets.tracks2D==i);
    
    % Nx3 matrix with frame, X, Y data
    tracks{i} = dets.uvdata(idx,:);
    
    start_frame(i) = tracks{i}(1,1);
    end_frame(i) = tracks{i}(end,1);
    
    % track_sum is used as an identifier to find same detections in uvData
    % detections. Likely a better solution is available for this problem.
    track_sum = sum(tracks{i},2);
    
    % Variables for Track area and brightness information
    this_areas = nan(length(tracks{i}),1);
    this_brights = nan(length(tracks{i}),1);
    
    % Cycle through each detection for this track and find corresponding
    % 2D detection data
    for j = 1:length(tracks{i})
        idx = find(uvDatasum==track_sum(j),1);

        %Save area and brightness information for each 2D detection
        if ~isempty(idx)    %There was a wierd error where occasionally it was not finding the detection
            this_areas(j) = dets.uvData{1}(idx,4);
            %this_brights(j) = dets.uvData{1}(idx,5);
        end
    end
    % Take averages of area and brightness values
    track_area(i) = nanmean(this_areas);
    %track_brightness(i) = nanmean(this_brights);
    
    %Calculate track flight parameters
    XY = tracks{i}(:,2:3);
    %Total point-by-point track length
    total_length = sum(fcns.rnorm(diff(XY)));
    %straight-line distance from first detection to last detection 
    end_length = norm(XY(end,:)-XY(1,:));
    
    sinuosity(i) = end_length/total_length;
    
    %Pixel speed based on total distance traveled
    track_speed(i) = total_length/ (tracks{i}(end,1) - tracks{i}(1,1));
    
    %Pixel speed based on net distance traveled
    track_movement(i) = end_length / (tracks{i}(end,1) - tracks{i}(1,1));
end

data_table = table( (1:length(tracks))' ,start_frame,end_frame,dets.trackID,track_area,track_speed,track_movement,sinuosity);
data_table.Properties.VariableNames{1} = 'Track_Number';
data_table.Properties.VariableNames{2} = 'Start_frame';
data_table.Properties.VariableNames{3} = 'End_frame';
data_table.Properties.VariableNames{4} = 'Classification';
data_table.Properties.VariableNames{5} = 'Mean_pixels';
%data_table.Properties.VariableNames{6} = 'Mean_brightness';
data_table.Properties.VariableNames{6} = 'Pixel_speed';
data_table.Properties.VariableNames{7} = 'Net_Movement_speed';
data_table.Properties.VariableNames{8} = 'Sinuosity';

%new_IDs = zeros(size(app.dets.trackID));
%idx = find(sinuosity> 0.8 & track_movement > 2);
%new_IDs(idx) = 

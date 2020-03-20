function [Alt,meanAlt,maxAlt] = getAlt_v2(trackXYZ)

% function [Alt,meanAlt,maxAlt] = getAlt_v2(trackXYZ)
% Calculates altitude for display in Bat Turbine Visualizer
% 
% Input:
% trackXYZ - XYZ points for track selected from track menu in GUI
%
% Output:
% Alt - instantaneous altitude measured at each frame
% meanAlt - mean altitude of the track
% maxAlt - maximum measured altitude of the track
%
% 20180504 - J. Rader


    % find the altitude 
    Alt=trackXYZ(:,3);
    
    % find the mean altitude of the track
    meanAlt=mean(Alt);

    % find the maximum altitude of the track
    maxAlt=max(Alt);

end
function [trackGS,meanGS,medianGS,maxGS,minGS] = getGS_v2(trackXYZ,fps)

% function [trackGS,meanGS,medianGS,maxGS,minGS] = getGS_v2(trackXYZ,fps)
% Calculates ground speed, and summarizes for display in Bat Turbine Visualizer
% 
% Input:
% trackXYZ - XYZ points for track selected from track menu in GUI
% fps - Frame rate of the camera
%
% Output:
% trackGS - instantaneous ground speed measured at each frame
% meanGS - average ground speed of the track
% maxGS - 90th percentile of measured ground speed in the track
% minGS - 10th percentile of measured ground speed in the track
%
% 20180427 - J. Rader
    
    % Calculate ground speed, the numeric derivative of the track
    trackGS=rnorm(diff(trackXYZ)*fps);
    
    % Find the mean ground speed
    meanGS=mean(trackGS);
    
    % Find the mean ground speed
    medianGS=median(trackGS);
    
    % Find the 90th percentile of track ground speed to estimate maxGS
    maxGS=prctile(trackGS,90);
    
    % Find the 10th percentile of track ground speed to estimate minGS
    minGS=prctile(trackGS,10);
end
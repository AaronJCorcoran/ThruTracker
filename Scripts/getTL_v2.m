function [trackframes,tracktime,tracklen, sinuosity] = getTL_v2(trackXYZ,fps)

% function [trackframes,tracktime,tracklen] = getTL_v2(trackXYZ,fps)
% Calculates track length in frames for display in Bat Turbine Visualizer
% 
% Input:
% trackXYZ - XYZ points for track selected from track menu in GUI
% fps - Frame rate of the camera
%
% Output:
% trackframes - the length of the track in frames
% track time - the time, in seconds, of the track
% tracklen - the length of the track in meters
%
% 20180426 - J. Rader
    
    % Get track length in number of frames
    trackframes=length(trackXYZ(:,1));
    
    % Get track length in seconds
    tracktime=trackframes/fps;
    
    % Measure the distance the bat traveled
    tracklen=measPolyLine_v1(trackXYZ(:,1),trackXYZ(:,2),trackXYZ(:,3));
    
    %
    startEndLength = norm(trackXYZ(end,:) - trackXYZ(1,:));
    
    sinuosity = tracklen/startEndLength;
end
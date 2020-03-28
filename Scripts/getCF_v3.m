function [rho,cf,meanCF,medianCF,maxCF] = getCF_v3(trackXYZ,fps)

% function [rho,cf,meanCF,maxCF] = getCF_v3(trackXYZ,fps)
% Calculates centripetal force for display in Bat Turbine Visualizer
% 
% Input:
% trackXYZ - XYZ points for track selected from track menu in GUI
% fps - frame rate of the camera
%
% Output:
% rho - radius of curvature
% cf - instantaneous centripetal force measured at each frame
% meanCF - average centripetal force for the entire track
% maxCF - maximum centripetal force measured within the track
%
% 20180426 - J. Rader
% 20180521 - J. Rader: v3, changed maxCF calculation to 90th percentile to
% eliminate erroneously high values in the display, added median cf
% calculation to the output

    % find where the track is defined
    trackXYZ_trim=trimTrack_v1(trackXYZ);
    idx=find(isfinite(trackXYZ_trim(:,1)));
    
    % interpolate gaps within the range over which the pt is defined
    trackXYZ_trim(idx(1):idx(end),:)=splineinterp_v2(trackXYZ_trim(idx(1):idx(end),:),'linear');
    
    % Get a numeric derivative of the track
    trackXYZd=diff(trackXYZ_trim)*fps;
    
    % Get a second derivative
    trackXYZd2=diff(trackXYZd)*fps;
    
    % Calculate radius of curvature and mass-specific centripetal force
    [rho,cf] = turn_v1(trackXYZd,trackXYZd2);
    
    % Take a mean
    meanCF = mean(cf);
    
    % Take a median, so that it's less sensitive to outliers
    medianCF = median(cf);
    
    % Find the max centripetal force
    maxCF = prctile(cf,90);
end
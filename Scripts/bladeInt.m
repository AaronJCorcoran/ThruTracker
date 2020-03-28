function [dist2hub,minDist,intBlade] = bladeInt(trackXYZ,turbXYZ)

% function [dist2hub,minDist,intBlade] = bladeInt(trackXYZ,turbXYZ)
% Calculates distance to the turbine hub at each frame, track minimum 
% distance to the hub, and finds tracks that enter the zone of interference
% with turbine blades
% 
% Input:
% trackXYZ - XYZ points for track selected from track menu in GUI
% turbXYZ - XYZ points clicked for the hub and nacelle of the turbine
%
% Output:
% dist2hub - euclidean distance between bat and hub in each frame
% minDist - minimum measured distance between bat and hub for track
% intBlade - binary indicator, 1 if bat track enters blade intereference 
%   zone, 0 if it doesn't
%
% 20180507 - J. Rader
% 
% This function specifically used for toggling the interference switch since
% it does quick calculation across tracks for interference. For calculation of min
% distance to blade plane and all other track summary metrics bladeInt_v2
% is used - 20180619 - Pranav Khandelwal

% Find the mean Z of the turbine points, set that as Z for both
turbXYZ_n=turbXYZ;
turbXYZ_n(:,3)=mean(turbXYZ(:,3));

% Grab the hub and nacelle points
hubPt=turbXYZ_n(1,1:3);
nacPt=turbXYZ_n(2,1:3);

% Find distance between each track point and the hub point
for i=1:length(trackXYZ)
    dist2hub(i,:)=norm(trackXYZ(i,:)-hubPt(1,:));
end

% Find the minimum distances to the hub in the tack
minDist=min(dist2hub);

% Find out if the track crosses the blade plane (Y-axis in the turbine 
% frame of reference), and if yes, find out if it crosses the zone of
% interference (|Y|<45 m)
idx=find(abs(trackXYZ(:,1))<0.5); % find bats that enter a 1 m X-axis zone around the hub
idx2=find(dist2hub(idx)<45); % find points that are within the radius of the blades
% Assign binary condition to indicate interference
if length(idx2)>0
    intBlade=1;
else
    intBlade=0;
end
end
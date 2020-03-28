function [dist2hub,minDist,bladeDist,minBD,intBlade] = bladeInt_v2(trackXYZ,turbXYZ)
%
% function [dist2hub,minDist,bladeDist,intBlade] = bladeInt_v2(trackXYZ,turbXYZ)
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
% bladeDist - euclidean distance between bat and nearest point on blade
% disc
% minBD - euclidean distance of the closest approach to the blade disc
%
% 20180507 - J. Rader - intial version
% 20180618 - J. Rader - v2
% 20180619 - Pranav Khandelwal - minBD was not assigned as an output, added
% in function output

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

% Create a pointcloud with 10000 random points within the blade disc
bladepts=[];
for t=1:10000 %loop until doing 10000 points inside the circle
    [y z]=circPts(hubPt(:,2),hubPt(:,3),45);
    bladepts(t,1)=hubPt(:,1);
    bladepts(t,2)=y;
    bladepts(t,3)=z;
end

% Find the nearest neighbor between bat points and the blade disk points
[Idx,bladeDist] = knnsearch(bladepts, trackXYZ);
minBD = min(bladeDist);

% Find out if the track crosses the blade plane (Y-axis in the turbine
% frame of reference), and if yes, find out if it crosses the zone of
% interference (|Y|<45 m)
idx=find(abs(trackXYZ(:,1))<0.5); % find bats that enter a 1 m X-axis zone around the hub, changed from 0.25 to 0.5m on 20180619
idx2=find(dist2hub(idx)<45); % find points that are within the radius of the blades
% Assign binary condition to indicate interference
if length(idx2)>0
    minBD=0;
    intBlade=1;
else
    intBlade=0;
end

end

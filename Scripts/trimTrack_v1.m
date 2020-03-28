function [tpts]=trimTrack_v1(pts)
%
% function to trim the track to the beginning of track till end of the
% track. Even if the first row has only one non-empty entry, that will be
% taken as the starting point of the track.
%
% Input:
%       pts - array of pts
% Output:
%       tpts - trimmed pts
%
% 20180507 - Pranav Khandelwal



nanindex=find(isnan(pts)==0); % find the index corresponding to data points
[i,j]=ind2sub(size(pts),nanindex); % matrix location of all the non-zero values
minrow=min(i);maxrow=max(i); % finding the start and end row location of track data points
tpts=pts(minrow:maxrow,:);
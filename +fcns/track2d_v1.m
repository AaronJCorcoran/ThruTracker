function tracks = track2d_v1(uvdata)
%% This program assigns 2D detections to tracks in a sequence
% input: 
% dets Xx4 file with frames, times, X and Y coordinates
% 
% output: 
% tracks: Xx1 array with track numbers that are associated with each row in
% dets.

tracks = nan(size(uvdata,1),1);

tracks(1) = 1;
frame_gap = 10;     %Number of frames to allow between points to still be part of same track
%Very simple track assignment based on gap between frames. Lumps all points
for i = 2:size(uvdata,1)
    
    if uvdata(i,1)-uvdata(i-1,1) < frame_gap
        %jum
        tracks(i) = tracks(i-1);
    else
        tracks(i) = tracks(i-1) + 1;     
    end
    
end
uvdata = [];
tracks = [];
track_offset = 0;

for j = 1:length(dets.blockout)
    for i = 6:6:size(dets.blockout{j},2)
    foo = [];
    [foo(:,1),jj,foo(:,2)] = find(dets.blockout{j}(:,i-1));
    foo(:,3) = nonzeros(dets.blockout{j}(:,i));
    uvdata = [uvdata; foo];
    tracks = [tracks; repmat(i/6 + track_offset,nnz(dets.blockout{j}(:,i)),1)];
    end
    track_offset = track_offset + i/6; 
end

dets.tracks2D = tracks;
dets.uvdata = uvdata;
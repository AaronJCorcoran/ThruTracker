% Script for getting some track variables and comparing them to
% manually-tracked data

[man, man_text] = xlsread('66958_287_manually_watched.xlsx'); %Read manual data note: man(:,2) is track start

% Index of whether each manual detection was a bat
bat = strcmp(man_text(2:end,5), 'y');
 
for i = 2:length(man_text)
  idx = strfind(man_text{i,6},'bird');
  if isempty(idx)
      bird(i-1) = false;
  else
      bird(i-1) = true;
  end
end    
%tracks = track2d_v1(dets.uvdata); %copy tracks to simple variable
tracks = dets.tracks2D;
trackN = nan(1,length(tracks));   %Track length
for i = 1:length(trackN)
trackN(i) = length(find(dets.tracks2D==i));
end

track_start = nan(max(tracks),1); %Frame of track start
for i = 1:length(trackN)
idx = find(dets.tracks2D==i,1);
if ~isempty(idx)
    track_start(i) = dets.uvdata(idx,1);
end
end


% now, for each manual track, look for closest auto track start
man_auto_diff = nan(1,length(man));
for i = 1:length(man)
    man_auto_diff(i) = min( abs( man(i,2) - track_start) );
    %Find closest manual track
end

% For each detected track, find distance to closest manually-detected track
auto_track_dist = nan(size(track_start));
man_idx = nan(size(track_start));
auto_class = nan(size(track_start));
for i = 1:length(track_start)
    [auto_track_dist(i), man_idx(i)] = min( abs( man(:,2) - track_start(i) ));
    auto_class(i) = bat(man_idx(i)); % 1 = bat; 0 = moth; nan = no manual detection
    
    if bird(man_idx(i))
        auto_class(i) = 2;
    end
    
    if auto_track_dist(i) > 20
        auto_class(i) = nan;
    end
end

missed_tracks = find(man_auto_diff > 50);
missed_track_starts = man(missed_tracks,2);

man_clouds = dets.clouds(man(:,2));

bat_idx = find(bat==1);
not_bat_idx = find(bat==0);
bat_clear_idx = find(bat==1 & man_clouds < 1e5);
overall_bat_detect_rate = length(find(man_auto_diff(bat_idx)<30))/length(bat_idx);
disp(['% Bats detected overall: ' num2str(overall_bat_detect_rate)]);
bat_detect_clear = length(find(man_auto_diff(bat_clear_idx)<30))/length(bat_clear_idx);
disp(['% Bats detected when clear: ' num2str(bat_detect_clear)]);
missed_bats = find(man_auto_diff(bat_idx)>30);
missed_bats_clear = find(man_auto_diff(bat_clear_idx)>30);
missed_bats_start = man(bat_idx(missed_bats),2);
missed_bats_clear_start = man(bat_clear_idx(missed_bats_clear),2);
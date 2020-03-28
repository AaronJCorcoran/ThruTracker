function [tmp_batCell,tmp_batInt,updt_day,updt_site,updt_set,updt_trt]=batCell_lookup_v2(usr_day,usr_site,usr_set,usr_trt,batCell)
%
%function [summ,tmp_batCell,updt_day,updt_site,updt_set,updt_trt,updt_track]=batCell_lookup_v2(usr_day,usr_site,usr_set,usr_trt,usr_track,batCell)
%
% look up batCell to make a cell based on the options chosen by the user 
% 
% Input: user selected options and the master batCell
% Output: updated items for each of the GUI selection fields
%       summ - summary of all metrics calculated
%       tmp_batCell- updated batCell based on user selection
%
% 20180616 - Pranav Khandelwal - removed summ calcuation and track list
% 20180618 - Pranav Khandelwal - added bat interference calculation
%
%% get all parts of bat cell
day=batCell(:,2);
site=batCell(:,3);
set=batCell(:,4);
trt=batCell(:,5);
trackName=batCell(:,7);

%% get matching idx
% for days
if strcmp(usr_day,'all')
    idx_day=1:numel(day);
else idx_day=find(strcmp(day,usr_day));
end
% for sites
if strcmp(usr_site,'all')
    idx_site=1:numel(site);
else idx_site=find(strcmp(site,usr_site));
end
% for set
if strcmp(usr_set,'all')
    idx_set=1:numel(set);
else idx_set=find(strcmp(set,usr_set));
end
% for treatment
if strcmp(usr_trt,'all')
    idx_trt=1:numel(trt);
else idx_trt=find(strcmp(trt,usr_trt));
end

% get the idx of common tracks
idx_comm=intersect(intersect(intersect(idx_day,idx_site),idx_set),idx_trt);

% get updated values to display
tmp_batCell=batCell(idx_comm,:);

% get interference of tracks - added 20180618
for i=1:size(tmp_batCell,1)
    [~,~,tmp_batInt(i)]=bladeInt(tmp_batCell{i,11},tmp_batCell{i,12});
end

% populate the drop down and track lists 
opt_all={'all'};
updt_day=[opt_all;unique(tmp_batCell(:,2))];
updt_site=[opt_all;unique(tmp_batCell(:,3))];
updt_set=[opt_all;unique(tmp_batCell(:,4))];
updt_trt=[opt_all;unique(tmp_batCell(:,5))];
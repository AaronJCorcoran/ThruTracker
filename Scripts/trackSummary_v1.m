function [summ]=trackSummary_v1(tmp_batCell)
%
% function [summ]=trackSummary_v1(tmp_batCell)
%
% calculate track metrics for the Bat tracks selected by the user
%
% Input:
%       tmp_batCell - updated batCell based on user selection
% Output:
%       summ - metrics of Bat tracks in struct form
%
% 20180507 - Pranav Khandelwal
% 20180730 - Pranav Khandelwal - added code to take into account empty
% tmp_batCell

% is tmp_batCell is empty
if isempty(tmp_batCell)
    summ=[];
else % tmp_batCell is not empty
    % get track metrics
    for i=1:size(tmp_batCell,1)
        if isempty(tmp_batCell{i,6})
            summ(i).trackFrames=nan;
            summ(i).trackTime=nan;
            summ(i).trackLen=nan;
            summ(i).gs_inst=nan;
            summ(i).gs_avg=nan;
            summ(i).gs_max=nan;
            summ(i).gs_min=nan;
            summ(i).gs_med=nan;
            summ(i).rho=nan;
            summ(i).cf=nan;
            summ(i).cf_mean=nan;
            summ(i).cf_max=nan;
            summ(i).cf_med=nan;
            summ(i).alt=nan;
            summ(i).alt_avg=nan;
            summ(i).alt_max=nan;
            summ(i).dist2hub=nan;
            summ(i).dist2hub_min=nan;
            summ(i).bladeDist=nan;
            summ(i).minBD=nan;
            summ(i).intBlade=nan;
            summ(i).sinuosity = nan;
        else
            % track length
            [trackFrames,trackTime,trackLen, sinuosity]=getTL_v2(tmp_batCell{i,11},30);
            % ground speed
            [gs_inst,gs_avg,gs_med,gs_max,gs_min]=getGS_v2(tmp_batCell{i,11},30);
            % get CF
            [rho,cf,cf_mean,cf_med,cf_max]=getCF_v3(tmp_batCell{i,11},30);
            % get altitude
            [alt,alt_avg,alt_max]=getAlt_v2(tmp_batCell{i,11});
            % get distance to hub
            [dist2hub,dist2hub_min,bladeDist,minBD,intBlade] = bladeInt_v2(tmp_batCell{i,11},tmp_batCell{i,12});
            % get sinuosity
            
            
            % make a struct
            summ(i).trackFrames=trackFrames;
            summ(i).trackTime=trackTime;
            summ(i).trackLen=trackLen;
            summ(i).gs_inst=gs_inst;
            summ(i).gs_avg=gs_avg;
            summ(i).gs_max=gs_max;
            summ(i).gs_min=gs_min;
            summ(i).gs_med=gs_med;
            summ(i).rho=rho;
            summ(i).cf=cf;
            summ(i).cf_mean=cf_mean;
            summ(i).cf_max=cf_max;
            summ(i).cf_med=cf_med;
            summ(i).alt=alt;
            summ(i).alt_avg=alt_avg;
            summ(i).alt_max=alt_max;
            summ(i).dist2hub=dist2hub;
            summ(i).dist2hub_min=dist2hub_min;
            summ(i).bladeDist=bladeDist;
            summ(i).minBD=minBD;
            summ(i).intBlade=intBlade;
            summ(i).sinuosity = sinuosity;
        end
    end
    
end
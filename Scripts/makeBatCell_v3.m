function [show_logFile,logFile,batCell]=makeBatCell_v3(batFile,wtbar)
%
% function [batCell]=makeBatCell_v3(batFileName)
%
% takes all bat files and splits the name into date, site, set and
% treatment to make a struct. The tracks for each treatment are then split
% into individual tracks and saved.
%
% Input:
%       batFileName - complete bat file struct obtained using dir command
% Output:
%       batCell - cell of all bat tracks
%
% 20180505 - Pranav Khandelwal
% 20180727 - Pranav Khandelwal - file parts/names are selected based on
% location of '_' in the filename instead of looking for phrases in the
% file name as was done in makeBatCell_v2

% log operations

logFile=sprintf('BatVis_v3 - Track import log - %s',datetime); % initialize log file


% create batCell to store pts
batCell={};
batCell_removed={};
% get tracks, smooth and make batCell
nBatFile=numel(batFile);
%%%
logFile=sprintf('%s\n\nFound %d Bat tracks to import -',logFile,nBatFile); % log #Bat tracks
%%%
for i=1:nBatFile
    spts={}; % reset smooth pts cell
    tmp_trackNum={}; % reset track names
    spts_transRot={}; % reset trans rot tracks
    file_ci=batFile(i); % get each file struct
    folder=file_ci.folder; % get folder path
    fileName_ci=file_ci.name; % get file name
    fileName_pts=replace(fileName_ci,'CI','pts');
    fileName_turbine=replace(fileName_pts,'bat','turbine');
    filePath_ci=fullfile(folder,fileName_ci); % make full file path for CI file
    filePath_pts=fullfile(folder,fileName_pts); % make full file path for pts file
    filePath_turbine=fullfile(folder,fileName_turbine); % make turbine full file path
 
 
    % get turbine pts
    if strcmp(filePath_turbine(end-2:end),'csv')
        turbFile=importdata(filePath_turbine);
    else
        turbFile=sp2full(sparseRead(filePath_turbine));
    end
    
    if isstruct(turbFile)
        turb_pts=turbFile.data;
    else
        turb_pts = turbFile;
    end
    turb_pts_split=splitClickedPts_v1(turb_pts,size(turb_pts,2)/3);
    turb_pts_split_trim=cellfun(@(x) trimTrack_v1(x),turb_pts_split,'UniformOutput',false);
    turb=[];
    for k=1:numel(turb_pts_split_trim)
        hub_nacelle=turb_pts_split_trim{k};
        % find angle to rotate hub-nacelle vector so that it aligns with +X
        vec_turb=diff(hub_nacelle); % vector for turbine
        rot_turb_ang=atan2(vec_turb(2),vec_turb(1)); % get angle for rotation
        rot_turb=angleaxisRotation(hub_nacelle,repmat([0,0,1],size(hub_nacelle,1),1),rot_turb_ang); % rotate
        transBy=rot_turb(1,:);
        % trans and rot hub-nacelle pts
        transRot_turb=rot_turb-transBy;
        % store as struct
        turb(k).hub_nacelle=hub_nacelle;
        turb(k).vec=vec_turb;
        turb(k).rot_ang=rot_turb_ang;
        turb(k).transBy=transBy;
        turb(k).transRot_turb=transRot_turb;
    end
    turb_cell=struct2cell(turb); % make cell for storing in batCell
    
    % get file parts
    fileParts=strsplit(fileName_ci,'_');
    
    % get name of each file part
    bat_date=fileParts{2};
    bat_site=fileParts{3};
    bat_set=fileParts{4};
    bat_treat=fileParts{5};
    
    % make tmp bat file part cell
    tmp_batCell_id={filePath_pts,bat_date,bat_site,bat_set,bat_treat};
    
    % get bat tracks for each file
    
    if strcmp(filePath_pts(end-2:end),'csv')
        batPtsFile=importdata(filePath_pts);
    else
        batPtsFile=sp2full(sparseRead(filePath_pts));
    end
    
    
    if isstruct(batPtsFile)
        pts=batPtsFile.data; % get pts
    else
        pts = batPtsFile;
    end
    
    nCols_pts=size(pts,2); % #cols
    nPts=nCols_pts/3; % #bat tracks clicked
    pts_split=splitClickedPts_v1(pts,nPts); % split pts/bat tracks into cells
    pts_split_trim=cellfun(@(x) trimTrack_v1(x),pts_split,'UniformOutput',false);
    
    % get CI

    if strcmp(filePath_ci(end-2:end),'csv')
        batPtsFile_ci=importdata(filePath_ci);
    else
        batPtsFile_ci=sp2full(sparseRead(filePath_ci));
    end
    
    if isstruct(batPtsFile_ci)
        pts_ci=batPtsFile_ci.data;
    else
        pts_ci = batPtsFile_ci;
    end
    pts_split_ci=splitClickedPts_v1(pts_ci,nPts); % split ci into cells
    pts_split_ci_trim=cellfun(@(x) trimTrack_v1(x),pts_split_ci,'UniformOutput',false);
    
    % generate track ids
    ids_track=num2cell(1:nPts)';
    
    % create tmp_batCell containing raw pts
    tmp_batCell1=[repmat(tmp_batCell_id,nPts,1) ids_track];
    
    % smooth tracks, remove some tracks and make cell
    idx_remove=[]; % array to fill with track idx to be deleted
    for j=1:size(tmp_batCell1,1)
        [spts{j,1},~,~]=citrack_v2(pts_split_trim{1,j},pts_split_ci_trim{1,j},30,'interp','y');
        tmp_trackNum{j,1}=sprintf('%s%s%s%s_%d',bat_date,bat_site,bat_set,bat_treat,j);
        spts_Rot{j,1}=angleaxisRotation(spts{j,1},repmat([0,0,1],size(spts{j,1},1),1),turb(j).rot_ang);
        spts_transRot{j,1}=spts_Rot{j,1}-turb(j).transBy;
        
        % display progress in waitbar
        wtbar_progress=(i/nBatFile)*(j/numel(pts_split));
        wtbar_mess=sprintf('Bat file %d of %d, Track %d...',i,nBatFile,j);
        waitbar(wtbar_progress,wtbar,wtbar_mess);
        pause(0.1); % pause for 0.1 sec for user to see track progress
        
        % clean tracks
        if sum(isnan(spts{j,1}(:,1))) || size(spts{j,1},1)<=5 % check for all nans after smoothing
            idx_remove=[idx_remove j];
        end
    end
    
    % make bat cell with tracks having nans or <5 frames removed
    tmp_batCell2=[tmp_batCell1 tmp_trackNum  pts_split_trim' pts_split_ci_trim'...
        spts spts_transRot {turb.transRot_turb}'];
    tmp_batCell2(idx_remove,:)=[];
    
    % removed tracks
    tmp_batCell_removed=tmp_batCell1(idx_remove,:);
    
    % make final batCell
    batCell=[batCell;tmp_batCell2];
    batCell_removed=[batCell_removed;tmp_batCell_removed];
    
    %%%
    logFile=sprintf('%s\n\t%d) %s',logFile,i,filePath_pts);
    logFile=sprintf('%s\n\t\t%s%d',logFile,'#bat tracks found - ',numel(pts_split));
    if ~isempty(idx_remove)
        if numel(idx_remove)>1
            logFile=sprintf('%s\n\t\t%s%d,',logFile,'bat track id removed - ',...
                idx_remove(1:end-1));
            logFile=sprintf('%s%d',logFile,idx_remove(end));
        else logFile=sprintf('%s\n\t\t%s%d',logFile,'bat track id removed - ',idx_remove);
        end
    else logFile=sprintf('%s\n\t\t%s',logFile,'No bat tracks removed');
    end
    show_logFile=sprintf('%s\n\n%s',logFile,'To save track import log - press "Save", else press "Cancel" to continue');
end

% define distinct colors for each bat track for plotting
track_colors=distinguishable_colors(size(batCell,1));
batCell=[batCell num2cell(track_colors,2)];
end
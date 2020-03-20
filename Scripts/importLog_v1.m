function [save_importLog] = importLog_v1(show_importLogFile,save_importLogFile)
%
% function importLog_v1(importLogFile)
%
% display the import log for the user. The import log shows all the files
% imported and the tracks removed per data file. The user has the option to
% save the log file or cancel and proceed to the GUI
%
% Input:
%       show_importLogFile - the import log file generated using
%       makeBatCell_v2 and as seen by the user with the save and cancel
%       options
%       save_importLogFile - the import log file saved when the user
%       selects the save option
% Output:
%       user dependent - can save or cancel
%
% 20180727 - Pranav Khandelwal
% 20191101 - William Valentine

% make figure with scrolling capability
save_importLog=figure('menu','none','toolbar','none','NumberTitle','off','Name','File Import Log v3');
ph_importLog=uipanel(save_importLog,'Units','normalized','position',[0 0.1 1 1]);
lbh_importLog=uicontrol(ph_importLog,'style','listbox','Units','normalized','position',[0 0 1 1],'FontSize',9);
% provide save and cancel options
b1_imortLog=uicontrol(save_importLog,'Style','pushbutton','String','Save','Position',[200 15 60 20],'callback',@userSave_importLog);
b2_importLog=uicontrol(save_importLog,'Style','pushbutton','String','Cancel','Position',[300 15 60 20],'callback',@userCancel_importLog);
% display the log file in the window
set(lbh_importLog,'string',show_importLogFile);
set(lbh_importLog,'Value',1);
set(lbh_importLog,'Selected','on');

%% private functions

% define save and cancel callbacks

% function for save callback
function userSave_importLog(source,eventdata)
startingFolder = pwd;
defaultFileName = fullfile(startingFolder, 'batVisv3_importLog_v1.txt');

[logFileName, folder] = uiputfile(defaultFileName, 'Choose folder and specify log file name'); % ask for file name and dir
fullFileName = fullfile(folder,logFileName);
% write import log to file
fid = fopen(fullFileName, 'w');
if fid ~= -1
    % write the data to file
    fprintf(fid,'%s',save_importLogFile);
    fclose(fid);
    disp([fullFileName,' saved successfully!']);
end
% user hits cancel when asked for log file name
if logFileName==0
    quit_importLog=questdlg('By pressing "Ok", log file will not be saved','Are you sure?','Ok','Go back!','Go back!');
    if strcmpi(quit_importLog,'Ok')
        return
    else
        [logFileName, folder] = uiputfile(defaultFileName, 'Choose folder and specify log file name'); % ask for file name and dir
        fullFileName = fullfile(folder,logFileName);
        % write import log to file
        fid = fopen(fullFileName, 'w');
        if fid ~= -1
            % write the data to file
            fprintf(fid,'%s',save_importLogFile);
            fclose(fid);
            disp([fullFileName,' saved successfully!']);
        else
            warningMessage = sprintf('%s\nlog file not saved!', fullFileName);
            uiwait(warndlg(warningMessage));
        end
        
    end
end
end



function userCancel_importLog(source,eventdata)
quit_importLog=questdlg('By pressing "Ok", log file will not be saved','Are you sure?','Ok','Go back!','Go back!');
if strcmpi(quit_importLog,'Ok')
    close(save_importLog);
    disp('Import Log File closed without saving');
else
    startingFolder = pwd;
    defaultFileName = fullfile(startingFolder, 'batVisv3_importLog_v1.txt');
    [logFileName, folder] = uiputfile(defaultFileName, 'Choose folder and specify log file name'); % ask for file name and dir
    fullFileName = fullfile(folder, logFileName);
    % write import log to file
    fid = fopen(fullFileName, 'w');
    if fid ~= -1
        % write the data to file
        fprintf(fid,'%s',save_importLogFile);
        fclose(fid);
        disp([fullFileName,' saved successfully!']);
    else
        warningMessage = sprintf('log file not saved!');
        uiwait(warndlg(warningMessage));
    end
    
end
end

end
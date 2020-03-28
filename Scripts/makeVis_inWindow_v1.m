function [vis] = makeVis_inWindow_v1(dispTracks,summ,axHandle)

% function [Vis] = makeVis_v2(dispTracks)
% Calculates centripetal force for display in Bat Turbine Visualizer
%
% Input:
% dispTracks - cell array containing XYZ points for bat tracks selected in
% GUI
%
% Output:
% Vis - 3D visualization of turbine and bat tracks
% Ortho
%
% 20180506 - J. Rader
% 20180618 - Pranav Khandelwal - each track has a specific color
% 20191031 - William Valentine - modifies original script to make the fig
% stay inside of the UI.


% Load the 3d turbine model
turbine=load('turbineModel_v3');
% delete(findobj(figHandle,'Type','line'));
% vis=figure(figHandle);
% vis.WindowStyle = 'normal';
vis = uiaxes(axhandle);
vis.View(3);
%vis.Interactions = [pan
title(vis, 'Bat Tracks v3', 'Color','Black');
hold on;
axis equal;
grid on;
xlabel('X (m)');ylabel('Y (m)');zlabel('Z (m)');
% plot the turbine using 'patch'
VisT=patch('Faces',turbine.obj.f.v,'Vertices',turbine.obj.vR_trans,'Parent',app.TrackGraphAxes);
VisT.FaceColor=[.45 .55 .6];
VisT.FaceAlpha=.25;
if ~isempty(dispTracks)
    % Plot the selected bat tracks
    pts_cell=dispTracks(:,11); % make cell array of all the tracks
    color_cell=dispTracks(:,13); % get cell array of track colors
    trackName_cell=dispTracks(:,7); % get track names
    % plot tracks in a 3D
    for i=1:numel(pts_cell)
        pts=pts_cell{i};
        color=color_cell{i};
        trackName=trackName_cell{i};
        trackSumm=summ(i);
        h(i)=plot3(pts(:,1),pts(:,2),pts(:,3),'LineWidth',1,'Color',color,'Marker','o',...
            'MarkerSize',3,'MarkerFaceColor','r','MarkerEdgeColor','r','MarkerIndices',1,...
            'Tag',trackName,'DisplayName',sprintf('Track id selected - \n%s',trackName),'UserData',trackSumm);
    end
    
    % make figure interactive
    set(h,'ButtonDownFcn',@makeVis_interactive_v1);
%     axHandle.Pointer='crosshair'; % so that the user knows when track selection is active
end
hold off
% make figure title showing #tracks
if isempty(dispTracks)
    nTracks=0;
else nTracks=size(dispTracks,1);
end
title(['Number of bat tracks = ',num2str(nTracks)]);
legend('off')

%% figure interactivity
    function makeVis_interactive_v1(varargin)
        
        % get the object that produced the call to this function
%         [trackProp,~]=gcbo(); % ~ is for not getting the figure handle
        trackProp = gca(); % gca returns the current axes or chart for the current figure
        if trackProp.LineWidth==1;
            set(trackProp,'LineWidth',1.5);
%             l=legend(trackProp);
%             l.Interpreter='none';
%             l.Location='best';
%             l.Box='off';
%             set(l,'Location','northeastoutside'); % to show the underscore not as a subscript
            % set previous line back to linewidth of 1
            trackProp_idx=cellfun(@(x) strcmpi(trackProp.Tag,x),{h.Tag});
            otherTracks_idx=find(trackProp_idx==0);
            set(h(otherTracks_idx),'LineWidth',1);
            
            % display selected track information
            trackInfo=trackProp.UserData;
%             info=sprintf('Track metrics:');
%             info=sprintf('%s\n=======================',info);
%             info=sprintf('%s\n\tTrack frames = %s',info,num2str(trackInfo.trackFrames));
%             info=sprintf('%s\n\tTrack Time = %.2f s',info,trackInfo.trackTime);
%             info=sprintf('%s\n\tTrack Length = %.2f m',info,trackInfo.trackLen);
%             info=sprintf('%s\n\tMed. Ground Speed = %.2f m/s',info,trackInfo.gs_med);
%             info=sprintf('%s\n\tMin. Ground Speed = %.2f m/s',info,trackInfo.gs_min);
%             info=sprintf('%s\n\tMax. Ground Speed = %.2f m/s',info,trackInfo.gs_max);
%             info=sprintf('%s\n\tMed. Centripetal Force = %.2f m/s2',info,trackInfo.cf_med);
%             info=sprintf('%s\n\tMax. Centripetal Force = %.2f m/s2',info,trackInfo.cf_max);
%             info=sprintf('%s\n\tAvg. Altitude above Hub = %.2f m',info,trackInfo.alt_avg);
%             info=sprintf('%s\n\tMax. Altitude above Hub = %.2f m',info,trackInfo.alt_max);
%             info=sprintf('%s\n\tMin. Distance to Blade plane = %.2f m',info,trackInfo.minBD);
%             info=sprintf('%s\n\tMin. Distance to Hub = %.2f m',info,trackInfo.dist2hub_min);
            if trackInfo.intBlade==0
                int='No';
            else int='Yes';
            end
%             info=sprintf('%s\n\tBlade Interference = %s',info,int);
            % show track info in legend
%             hold on
%             plot_spacer=plot3(nan,nan,nan);
%             plot_spacer.Color='w';
%             plot_spacer.DisplayName='';
%             plot_info=plot3(nan,nan,nan);
%             plot_info.Color='w';
%             plot_info.DisplayName=info;
%             hold off
        else % user clicked line again, so revert back to original line width
            set(trackProp,'LineWidth',1);
            legend('off');
        end
    end
end

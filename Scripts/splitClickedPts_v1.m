function [pts_split]=splitClickedPts_v1(pts,nPts);
%
% function [pts_split]=splitClickedPts_v1(pts,nPts);
% 
% split clicked pts into a cell array where each cell corresponds to one
% set of clicked pts. For example, if there are three sets of clicked pts
% then the cell array generated will have three cells, each each containing
% a set of the clicked pts across all cameras.
%
% Input:
%       pts - array of clicked pts
%       nPts - # of clicked pts
% Output:
%       pts_split - cell array of split pts
%
% example implementation:
%   pts_split=splitClickedPts_v1(pts,3);
%
% 20180320 - Pranav Khandelwal

% split the columns corresponding to pts
nCols=size(pts,2)/nPts; % number of columns per pt clicked
nReps=repmat(nCols,1,nPts);
pts_split=mat2cell(pts,size(pts,1),nReps); % cell array per pt clicked
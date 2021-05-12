function [turbine_pixels, turbine_image] = getTurbineShim(frame,se,seBuffer)
% This function aims to find a wind turbine using an edge-detection
% segmentation approach

% inputs:
% frame: image
% se: strel for eroding the turbine. Typically use strel('disk',1); Passed
% to function for speed
%
% Outputs:
% turbine_pixels: list of pixels that are part of the turbine
% turbine_iamge: image of turbine with turbine==1 and non-turbine==0
%
% Written by Dr. Aaron Corcoran, UC Colorado Springs, acorcora@uccs.edu
% November 26, 2019

%Range of sobel sensitivities to choose frome
sobels = [20,8,5,4,3];      

% Choose starting sensitivity depending on cloudiness
if median(frame(:)) < 30      % Clear
   sobel_idx = 1;
elseif median(frame(:)) < 60  % Moderately cloudy
    sobel_idx = 2;
else
    sobel_idx = 3;            % Very cloudy
end

% Try to find the turbine; increase sensitivity each round if not found
while sobel_idx <=5
    % Find edges
    turbine_img = fcns.getTurbineEdge(frame,sobels(sobel_idx),se);
    
   % Find largest connected component
    CC = bwconncomp(turbine_img,4);
    stats = regionprops(turbine_img,'Area','PixelIdxList');
    area = cat(1,stats.Area);
    idxt = find(area==max(area));
    
    % Check to see if turbine is within expected range of sizes
    % These values allow rather large objects in case of very bright clouds
    % that cannot be distinguished from the turbine
    
    if ~isempty(idxt) & max(area) > 20000 & max(area) < 200000
        %Turbine was found
        turbine_pixels = stats(idxt(1)).PixelIdxList;
        %disp(['Used sobel sensitivity of ' num2str(sobels(sobel_idx))]);
        sobel_idx = 999; %
    else
        %Turbine was not found, try again
        sobel_idx = sobel_idx + 1;
    end
end

if sobel_idx == 6   %Edge segmentation failed; use simple binarization
    bn = imbinarize(frame./max(frame(:)),'global');
    stats = regionprops(bn,'Area','PixelIdxList');
    area = cat(1,stats.Area);
    idxt = find(area==max(area));
    turbine_pixels = stats(idxt(1)).PixelIdxList;
    disp('Didnt find turbine with segmentation; used binarization')
end

turbine_image = zeros(size(frame));
turbine_image(turbine_pixels) = 1;
turbine_image = imdilate(turbine_image,seBuffer);
turbine_pixels = find(turbine_image==1);
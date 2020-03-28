function [turbine_pixels] = getTurbine2(frame)

bright_pixels = frame>80;

if sum(bright_pixels(:) < 100000)   % Clear
    frame(frame>150) = 150; %Set all values greater than 100 to 100 to improve overall contrast
    frame = frame./100;
    bn = imbinarize(frame,'global');
    stats = regionprops(bn,'Area','PixelIdxList');
    area = cat(1,stats.Area);
    
    %Find largest object
    idxt = find(area==max(area));
    turbine_pixels = stats(idxt(1)).PixelIdxList;
else
    turbine_pixels = [];
end
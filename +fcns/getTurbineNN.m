function [turbine_pixels, turbine_image] = getTurbineNN(frame,se,net,seBuffer)
 
frame(513:532,:,:) = 255;
seg_image = semanticseg(frame,net);
seg_image(513:end,:,:) = [];
sky_mask = zeros(512,size(frame,2));

% Dilate blades

blade_mask = seg_image=='blades';
blade_mask = imdilate(blade_mask,strel('disk',seBuffer));
idx = find(blade_mask);
seg_image(idx) = 'blades';

idx = find(seg_image=='sky' | seg_image=='clouds');
sky_mask(idx) = 1;
sky_mask = imfill(sky_mask,'holes');
turbine_mask = ~sky_mask;
turbine_mask = imfill(turbine_mask,'holes');
turbine_image = imdilate(turbine_mask,se);
turbine_pixels = find(turbine_image==1);

end
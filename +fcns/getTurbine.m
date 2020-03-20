function [turbine_pixels, turbine_image] = getTurbine(frame,sensitivity)

bright_bw = frame>80;

if 1 %sum(bright_bw(:)) > 100000  %Cloudy, use edge detection
    if nargin < 2
        sensitivity = 8;
    end
    bw = edge(frame,'Sobel',sensitivity); % Seems to work pretty well
    bw = imdilate(bw,ones(2));

    %Add a white edge of one frame
    bw2 = ones(size(frame,1)+2,size(frame,2)+2);
    bw2(2:end-1,2:end-1) = bw;
    frame2 = ones(size(frame,1)+2,size(frame,2)+2);
    frame2(2:end-1,2:end-1) = frame;
    %Instead of doing this, increase frame size, then shrink later
    %bw(:,1) = 1; bw(:,end) = 1; bw(1,:) = 1; bw(end,:) = 1;

    %Find connected components
    CC = bwconncomp(~bw2,4);

    %Measure average intensity of each component and create new image
    foo = zeros(size(bw2));
    for i = 1:length(CC.PixelIdxList)
        foo(CC.PixelIdxList{i}) = mean(frame2(CC.PixelIdxList{i}));
    end

    foo(foo==0) = max(max(foo));    %Fill in edges
    foo = foo(2:end-1,2:end-1);     %Remove border that was added previously
    foo2 = foo>100;                 %Binarize
else    %Not cloudy, just use bright pixels
    foo2 = bright_bw;
end
%Find largest object
stats = regionprops(foo2,'Area','PixelIdxList');
area = cat(1,stats.Area);
idxt = find(area==max(area))
turbine_pixels = stats(idxt(1)).PixelIdxList;

%For plotting:
turbine_image = zeros(size(frame));
turbine_image(turbine_pixels) = 1;
%imagesc(turbine_image)

%lm = labelmatrix(CC);
%image(label2rgb(lm))
function turbine = getTurbineEdge(frame, sobel_sens, se)

if nargin < 3
     se = strel('disk',3); %Saves processing time to pass the strel
end
bw = edge(frame,'Sobel',sobel_sens);

% Fill gaps between lines
% This takes a long time. Is it necessary?
%bw = filledgegaps(bw,3);    %Sometimes 3 works best, other times 5. May need a better algorithm for identifyig the best number and finding situations when its not working
bw = imdilate(bw,se);
bw = bwareaopen(bw,15);     %Remove small lines

%Add a white edge of one frame
bw2 = ones(size(frame,1)+2,size(frame,2)+2);
bw2(2:end-1,2:end-1) = bw;

frame2 = ones(size(frame,1)+2,size(frame,2)+2);
frame2(2:end-1,2:end-1) = frame;

% bw2 = filledgegaps(bw2,5);  %Connect to edges  %Too slow

%Find connected components
CC = bwconncomp(~bw2,4);

%Measure average intensity of each component and create new image
foo = zeros(size(bw2));
for i = 1:length(CC.PixelIdxList)
    foo(CC.PixelIdxList{i}) = mean(frame2(CC.PixelIdxList{i}));
end

%Fill in edges
foo(foo==0) = max(max(foo));    
foo = foo(2:end-1,2:end-1);     %Remove border that was added previously
 
%turbine = foo>140;                 %Binarize This doesn't work when cloudy
turbine = foo>120;                  % This value is better for NREL re-processed
turbine = imfill(turbine,'holes');
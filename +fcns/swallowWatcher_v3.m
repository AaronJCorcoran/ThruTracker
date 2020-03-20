function [dataBundle] = swallowWatcher_v3(vFile,maskFile)

% function [dataBundle] = swallowWatcher_v3(vFile,maskFile)
%
% Developmental version of swallowWatcher - uses optic flow to recognize
% birds and also gather additional information for flapping frequency ID

% set some constants
display_images = true;         % show what's going on
startFrame = 1;                 % set starting frame
makeMovie=false;               % make an output movie for presentations

% outputs
dataBundle=[]; % big bundle for post-processing
dataOut=[]; % simple output array for birdUVto3D

% name video file
%vFile='/media/hedricklabnas/projects/swallows2013/hwy751_20130513/trial01_001/Red.mrf';

% mask file
%maskFile='/media/hedricklabnas/projects/swallows2013/hwy751_20130513/trial01_001/Red_mask.mat';
if exist('maskFile')==1
  load(maskFile,'fmask');
end

if makeMovie
  myMovie=VideoWriter('~/swallowWatcherMovie.avi','Uncompressed AVI');
  open(myMovie);
end

% get file info
vInfo=mrfInfo(vFile);

% setup optic flow estimation & intialize with first frame
opticFlow = opticalFlowLK('NoiseThreshold',10); % works OK
I = flipud(mrfRead(vFile,1));
%I = uint8(255*(I./max(max(I)))); % stay in 8-bit grayscale range
flow = estimateFlow(opticFlow,I);

% setup display window
if display_images
  h = figure;
  set(h,'position',[66         337        1366         550]);
  ax1=axes(h,'position',[0.02 0.02 0.45 0.92]);
  ax2=axes(h,'position',[0.52 0.02 0.45 0.92]);
end

% detection loop
for i=startFrame:vInfo.NumFrames      %startFrame+#     %vInfo.NumFrames
  
  %Read and crop image if mask provided
  %I = uint8(flipud(mrfRead(vFile,i)));
  I = flipud(mrfRead(vFile,i));
  %I = repmat(I./2^10,[1,1,3]); % fake color image for 10-bit data
  %I = uint8(255*(I./max(max(I)))); % stay in 8-bit grayscale range
  
  
%       % adjust threshold in case of exposure problems in individual frames
%       if mean(mean(double(I))) - mean(mean(double(medianBkg)))<-2
%         disp(['frame ',num2str(i),': bad exposure mode'])
%         %diffThreshold=26;
%       else
%         %diffThreshold=12;
%       end
  
  % get the flow
  flow = estimateFlow(opticFlow,I);
  
  % threshold for big motion
  fg = flow.Magnitude>1;
  
  
  fg = imdilate(fg,strel('disk',2));  %Dilate the image
  if exist('fmask')==1
    fg=fg.*fmask;
  end
  
  if display_images %&& round(i/10)==i/10
    axes(ax1);
    cla;
    imshow(uint8(I));
    hold off
    title(['Original image, frame ',num2str(i)])
    axes(ax2);
    cla
    hold off
    imshow(fg);
    title('Detected foreground')
  end

  
  %Find blobs & other data
  % find birds
  stats = regionprops(fg,'area','majoraxislength','minoraxislength','pixelidxlist','centroid','boundingbox');
  area=cat(1,stats.Area);
  idx=find(area>100); % birds
  centroid=cat(1,stats(idx).Centroid);
  area=cat(1,stats(idx).Area); % overwrite with only the bird areas
  boundingbox=cat(1,stats(idx).BoundingBox); % overwrite with only the bird areas
  majoraxislength=cat(1,stats(idx).MajorAxisLength); 
  minoraxislength=cat(1,stats(idx).MinorAxisLength);
  
  % assemble bundle for databundle, store the big arrays as sparse for
  % space savings
  bundle=[];
  bundle.fMagnitude=sparse(flow.Magnitude.*fg);
  bundle.fOrientation=sparse(flow.Orientation.*fg);
  bundle.fVx=sparse(flow.Vx.*fg);
  bundle.fVy=sparse(flow.Vy.*fg);
  bundle.centroid=centroid;
  bundle.boundingbox=boundingbox;
  bundle.minoraxislength=minoraxislength;
  bundle.majoraxislength=majoraxislength;
  C = struct2cell(stats(idx));
  bundle.PixelIdxList=C(end,:); % assumes that PixelIdxList is the last stat
  dataBundle{i}=bundle;
  
  % display
  if display_images && isempty(centroid)==false %&& round(i/10)==i/10
    hold on;
    plot(centroid(:,1),centroid(:,2),'or','linewidth',2)
    axes(ax1);
    hold on;
    plot(centroid(:,1),centroid(:,2),'or','linewidth',2)
  else
  end
  
  drawnow
  if makeMovie
    writeVideo(myMovie,getframe(gcf))
  end
  
  % collect data for eventual export
  dataOut = [dataOut;[area*0+i-1,centroid,area]];
end

% save the data file
dFile=[vFile(1:end-4),'_detections_v3.csv']; % name
fh=fopen(dFile,'w'); % file handle
fprintf(fh,'frame,u,v,area\n'); % header
fclose(fh); % close after writing header
dlmwrite(dFile,dataOut,'-append'); % add the data
disp('Data saved to:'); % tell the user
disp(dFile);

if display_images
  close(h); % close the figure
end

if makeMovie
  close(myMovie)
  eval('!ffmpeg -y -i ~/swallowWatcherMovie.avi -pix_fmt yuv420p -vcodec libx264 ~/swallowWatcherMovie.mp4');
  eval('!rm -rf ~/swallowWatcherMovie.avi');
end
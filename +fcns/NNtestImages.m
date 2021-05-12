function [] = NNtestImages(Nframes)
% This function applies a neural network segmentation algorithm to select
% frames of a video and outputs images of frames from the video and the
% segmentation into in an output folder
%
% Inputs: Nframes, number of frames to process
% Outputs: Images saved to folders in same directory where video was
% located


%Select Video file
[filename, pathname] = uigetfile({'*.avi';'*.wmv';'*.mp4'}, 'Select a video file');
vid = VideoReader(fullfile(pathname,filename));
frameRate = vid.FrameRate;
vidFrames = round(vid.Duration*vid.FrameRate);
selectFrames = round(1: (vidFrames/Nframes):vidFrames);

% Choose segmentation network
seg_file = uigetfile('*.mat', 'Choose the Matlab file containing the segmentation network (e.g. TurbineNetwork1.mat');
seg = load(seg_file)

% Color Map
%classNames = ["column","blades","sky","nacelle"]; % in the order of the ground truth
classNames = seg.net.Layers(14).Classes;
cmap = jet(numel(classNames));

% Color bar
N = numel(classNames);
ticks = 1/(N*2):1/N:1;

% Make output folder
if exist(fullfile(pathname, 'segimages')) ~= 7
    mkdir(fullfile(pathname, 'segimages'));
    mkdir(fullfile(pathname, 'vidimages'));
end

%Number of characters for frame
numchars = length(num2str(selectFrames(end)));
for i = 1:length(selectFrames)
    vid.CurrentTime = (selectFrames(i)-1)/vid.FrameRate;
    frame = readFrame(vid);
    seg_image = semanticseg(frame,seg.net);
    
    %Overlap original image and classification
    displayedImg = labeloverlay(frame, seg_image,'Colormap',cmap,'transparency',0.25);    % Fig 1
    
    % arrange original/new images side by side for each picture
    fig1 = figure(1); 
    clf;
    montage({frame, displayedImg}); colorbar('TickLabels',cellstr(classNames),'Ticks',ticks,'TickLength',0,'TickLabelInterpreter','none');    % Image 1
    colormap(jet)
    frame_text = num2str(selectFrames(i));
    
    % Add zeros to beginning of frame text if necessary
    if length(frame_text) < numchars
        frame_text = [repmat('0', 1, numchars - length(frame_text)) frame_text];
    end
    saveas(gcf,fullfile(pathname,'segimages',[filename(1:end-4) '_' frame_text '.png']));
    imwrite(frame,fullfile(pathname,'vidimages',[filename(1:end-4) '_' frame_text '.png']));
end
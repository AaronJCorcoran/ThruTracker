inputSize = [32 32 3];
imgLayer = imageInputLayer(inputSize);
filterSize = 8;
numFilters = 16;
conv = convolution2dLayer(filterSize,numFilters,'Padding',1);
relu = reluLayer();
poolSize = 2;
maxPoolDownsample2x = maxPooling2dLayer(poolSize,'Stride',2);

downsamplingLayers = [
    conv
    relu
    maxPoolDownsample2x
    conv
    relu
    maxPoolDownsample2x
    ];

%filterSize = 4;
transposedConvUpsample2x = transposedConv2dLayer(4,numFilters,'Stride',2,'Cropping',1);

upsamplingLayers = [
    transposedConvUpsample2x
    relu
    transposedConvUpsample2x
    relu
    ];

numClasses = 4;
conv1x1 = convolution2dLayer(1,numClasses);

finalLayers = [conv1x1; softmaxLayer(); pixelClassificationLayer()];

net = [imgLayer; downsamplingLayers; upsamplingLayers; finalLayers];

%
numFilters = 64;
filterSize = 3;
layers = [
    imageInputLayer([532 640 3])
    convolution2dLayer(filterSize,numFilters,'Padding',1)
    reluLayer()
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(filterSize,numFilters,'Padding',1)
    reluLayer()
    transposedConv2dLayer(4,numFilters,'Stride',2,'Cropping',1);
    convolution2dLayer(1,numClasses);
    softmaxLayer()
    pixelClassificationLayer()
    ];

%layers(end) = pixelClassificationLayer('Classes',tbl.Name,'ClassWeights',classWeights);

opts = trainingOptions('sgdm', ...
    'InitialLearnRate',1e-2, ...
    'MaxEpochs',200, ...
    'MiniBatchSize',6,...
    'Plots','training-progress');

trainingData = pixelLabelImageDatastore(imds,pxds);

net = trainNetwork(trainingData,layers,opts);
totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
%classWeights = 1./frequency


%%
testImage = imread('A65sc-496_77105-000079-293_23_00_03_438_RR_3_bat_clip001.png');
%imshow(testImage)
tic
C = semanticseg(testImage,net);
toc
B = labeloverlay(testImage,C,'transparency',0.3);
figure; imshow(B)
function [t2] = getTime(header)
% This function extracts the time from a header image
% that has been added to thermal video.

% Inputs:
% header: image of time stamp
% output: t- time in numeric format

% Remove first and last rows which have a different color
header = header(2:end-1,2:end-1);

% Increase resolution of image to improve processing
header = imresize(header,2);

% Remove small objects that are colons
bn = bwareaopen(imbinarize(header),10);

% Extract time characters
t = ocr(bn(:,450:820),'CharacterSet','0123456789/');
t1 = t.Text;  %Get text characters
t1 = t1(~isspace(t1)); %remove spaces

% Convert to date-time Matlab format
t2 = datetime(t1(1:end-3),'InputFormat','MM/dd/yyyyhhmmssSSS');
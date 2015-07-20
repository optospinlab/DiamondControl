clc; close all; clear all;

vid = videoinput('avtmatlabadaptor64_r2009b', 1);
vidRes = vid.VideoResolution; nBands = vid.NumberOfBands;
closepreview;  %close preview if still running
hImage = image( zeros(vidRes(2), vidRes(1), nBands));
%setappdata(hImage,'UpdatePreviewWindowFcn',@mypreview_fcn)
preview(vid, hImage);
vid = videoinput('avtmatlabadaptor64_r2009b', 1);
vidRes = vid.VideoResolution; nBands = vid.NumberOfBands;
closepreview;  %close preview if still running
frame = getsnapshot(vid);

    %sharpen image
    f = fspecial('unsharp', 0.1);
    I1 = imfilter(flipdim(frame,1), f);
    
    %adjust contrast
    %figure 
    Ix = imtophat(I1,strel('disk',33));
    I2 = imadjust(Ix);
    h=image(I2);
    get(h,'CData')
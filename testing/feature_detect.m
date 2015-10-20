close all;
clear all;

 
filter = fspecial('unsharp', .1);

for i=1:3
    I= rgb2gray(imread(['ts' num2str(i) '.png']));
    I= imadjust(I);
    %I=imfilter(I,filter);
    
    BW = im2bw(I);
    subplot(1,3,i)
    imshow(BW)
    %[centersBright, radiiBright] = imfindcircles(I,[12 25], ...
    %'ObjectPolarity','dark','Sensitivity',0.95,'EdgeThreshold',0.7)
    %viscircles(centersBright, radiiBright,'Color','b');
end


 %I11= medfilt2(I1,[15 15]);
 %I2= medfilt2(I2,[15 15]);

%I2 = imguidedfilter(I1,'NeighborhoodSize',[15 15]);
%I2 = imguidedfilter(I2,'NeighborhoodSize',[15 15]);


% tic
% 
% %C1 =    detectMSERFeatures(I1);
% %C2 =    detectMSERFeatures(I2);
% C1=detectSURFFeatures(I1);
% C2=detectSURFFeatures(I2);
% 
% 
% figure
% subplot(1,3,1)
% imshow(I11);
% subplot(1,3,2)
% imshow(I2);
% subplot(1,3,3)
% 
% [features1, valid_points1] = extractFeatures(I1, C1);
% [features2, valid_points2] = extractFeatures(I2, C2);
% 
% indexPairs = matchFeatures(features1, features2);
% 
% matchedPoints1 = valid_points1(indexPairs(:, 1), :)
% matchedPoints2 = valid_points2(indexPairs(:, 2), :)
% 
% %double(matchedPoints1)
% delta=mean(matchedPoints2.Location-matchedPoints1.Location)
% toc
% 
% showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2);
%    
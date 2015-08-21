close all;


I1 = img_enhance(rgb2gray(imread('test_image.png')));
I2 = img_enhance(rgb2gray(imread('test_image_shifted1.png')));

tic
roi1 = I1(20:220,20:300);
C1 = corner(roi1,100);

roi2 = I2(20:220,20:300);
C2 = corner(roi2,100);

[features1, valid_points1] = extractFeatures(roi1, C1);
[features2, valid_points2] = extractFeatures(roi2, C2);

indexPairs = matchFeatures(features1, features2);

matchedPoints1 = valid_points1(indexPairs(:, 1), :);
matchedPoints2 = valid_points2(indexPairs(:, 2), :);

delta=mean(matchedPoints2-matchedPoints1)
toc

figure; showMatchedFeatures(roi1, roi2, matchedPoints1, matchedPoints2);
   
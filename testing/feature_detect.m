close all;
clear all;

I1 = imadjust(rgb2gray(imread('t3.png')));
I2 = imadjust(rgb2gray(imread('t4.png')));

tic
 points1 = detectSURFFeatures(I1, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
 points2 = detectSURFFeatures(I2, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
 
[features1, valid_points1] = extractFeatures(I1,  points1);
[features2, valid_points2] = extractFeatures(I2,  points2);

indexPairs = matchFeatures(features1, features2);

matchedPoints1 = valid_points1(indexPairs(:, 1), :);
matchedPoints2 = valid_points2(indexPairs(:, 2), :);

% Remove Outliers
delta=(matchedPoints2.Location-matchedPoints1.Location);
dist=sqrt(delta(:,1).*delta(:,1) + delta(:,2).*delta(:,2));

mean_dist=mean(dist);
stdev_dist=std(dist);

count=1;
for i=1:length(dist)
    if (dist(i)<mean_dist+stdev_dist) && (dist(i)> mean_dist-stdev_dist)
        filtered_Points1(count,:) = matchedPoints1.Location(i,:);
        filtered_Points2(count,:) = matchedPoints2.Location(i,:);
        count=count+1;
    end
end    

%Debug
% deltaa=(filtered_Points2-filtered_Points1);
%dista=sqrt(deltaa(:,1).*deltaa(:,1) + deltaa(:,2).*deltaa(:,2));
%delta1=round(mean(matchedPoints2.Location-matchedPoints1.Location));

% Calculate the delta
delta=round(mean(filtered_Points2 - filtered_Points1))
toc

figure; showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2);
   

clear all
close all

in_img=rgb2gray(imread('test_chip3.png'));
figure
imshow(in_img)

filter = fspecial('unsharp', 1);
I1 = imfilter(in_img, filter);

%Adjust contrast
I2 = imtophat(I1,strel('disk',25));
out_img = imadjust(I2);   

figure
imshow(out_img)

figure
IBW=im2bw(out_img,0.4); %Convert to BW and Manual Threshold
imshow(IBW)
[circles,radii]=imfindcircles(IBW,[4 10]) %Get Circles


if ~isempty(radii)
viscircles(circles, radii,'EdgeColor','g','LineWidth',1.5);  
end

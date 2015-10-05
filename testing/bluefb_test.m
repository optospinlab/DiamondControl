
in_img=rgb2gray(imread('test_new.png'));
figure
imshow(in_img)

filter = fspecial('unsharp', 1);
I1 = imfilter(in_img, filter);

%Adjust contrast
I2 = imtophat(I1,strel('disk',35));
out_img = imadjust(I2);   

figure
imshow(out_img)

figure
IBW=im2bw(out_img,0.7); %Convert to BW and Manual Threshold
imshow(IBW)
imfindcircles(IBW,[14 26]) %Get Circles


if ~isempty(c.radii)
viscircles(c.circles, c.radii,'EdgeColor','g','LineWidth',1.5);  
end

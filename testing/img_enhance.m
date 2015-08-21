function out_img=img_enhance(in_img)
            %Sharpen 
            filter = fspecial('unsharp', 1);
            I1 = imfilter(in_img, filter);

            %Adjust contrast
            I2 = imtophat(I1,strel('disk',35));
            out_img = imadjust(I2);       
end
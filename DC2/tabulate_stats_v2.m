
clear all; close all; clc;

folder = 'C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_31\Scan @ 18-45-25.141\';

stat_file=fopen([folder 'scan_stats.txt'],'w');
count=1;

c.device = 'd_';
c.set = 's_';

% img = readSPE('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\crosspolarizedbarediamond 7-30-15.SPE');
% plot(img);

img = load(strcat(folder,'normalization_spectrum.mat'));

range=10; % detects within a +- pixel window

% background = 100;
s = 2;
w = 1200/s;
h = 900/s;

final = zeros(20*h, 5*w);
size(final)
warning('off','images:imfindcircles:warnForLargeRadiusRange');

for i=0:3
    for j=0:4
       for k=1:5
            name = [c.device,num2str(k),'_',c.set,'[',num2str(i),',',num2str(j),']'];
                I=imread(strcat(folder,name,'_galvo.png'));
                data = load(strcat(folder,name,'_galvo.mat'));
                img2 = load(strcat(folder,name,'_spectrum.mat'));

%                 p = plot(double(img2.spectrum - min(img2.spectrum))./double(img.spectrumNorm - min(img.spectrumNorm) + 50));
%                 xlim([1 512]);
%                 saveas(p, [folder name '_spectrum.png']);
                
                I2 = imread([folder name '_spectrum.png']);
                
%                 imresize(I2(:,:,1), .25)
                
%                 size(imresize(I2(:,:,1), .25))
%                 size(I2(:,:,1))
%                 
%                 
%                 (k*w) - ((k-1)*w + 1)
%                 
%                 
%                 ((4*j + i + 1)*h) - ((4*j + i)*h + 1)
                
                
%                 spectra(k) = img2.spectrum + spectra(k);
                M(count,k) = (max(max(data.scan)));
%                 I = double(I)/double(max(max(I)));
               
                J=imresize(I,5);
                J=imcrop(J,[length(J)/2-25 length(J)/2-20 55 55]);

                level = graythresh(J);
                IBW=im2bw(J,level);
                [centers, radii] = imfindcircles(IBW,[15 60]);             
               
                if ~isempty(centers)
                    status(count,k)= 'W';
                    %viscircles(centers, radii,'EdgeColor','b')
%                     final(((j + 5*i)*h + 1):((j + 5*i + 1)*h), ((k-1)*w + 1):(k*w)) = imresize(I2(:,:,1), .5);
                else
                    %disp('no detections')
                    status(count,k)= ' ';
%                     final(((j + 5*i)*h + 1):((j + 5*i + 1)*h), ((k-1)*w + 1):(k*w)) = imresize(I2(:,:,1), .5)*(2/3);
                end
                
%                 if (max(max(data.scan))) > 40000
%                     final(((j + 5*i)*h + 1):((j + 5*i + 1)*h), ((k-1)*w + 1):(k*w)) = imresize(I2(:,:,1), .5);
%                 else
%                     final(((j + 5*i)*h + 1):((j + 5*i + 1)*h), ((k-1)*w + 1):(k*w)) = imresize(I2(:,:,1), .5)*(2/3);
%                 end
%             catch err
%                 display(err.message);
%                 display([name ' not there...']);
%             end
        %pause(0.5);
 
        end
        w=strcat('%0',num2str(numel(num2str(max(max(M))))),'i');   
        fprintf(stat_file, strcat(['[' num2str(i) ',' num2str(j) ']' '|'  status(count,1) ' '  num2str(M(count,1),w) '|'  status(count,2) ' '  num2str(M(count,2,:),w) '|' status(count,3) ' '  ...
        num2str(M(count,3,:),w) '|' status(count,4)  ' ' num2str(M(count,4,:),w) '|' status(count,5) ' '  num2str(M(count,5,:),w) '\r\n']));
        count=count+1;    
    end
end

final = final/max(max(final));

imwrite(final, [folder 'final_spectra.png']);

fclose(stat_file);
disp('done writing table');
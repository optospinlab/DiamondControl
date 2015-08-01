
clear all; close all; clc;
stat_file=fopen('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!2015_7_31\Scan @ 11-52-4.638\scan_stats.txt','w');
count=1;

% c.device = 'd_';
% c.set = 's_';
c.device = 'd_';
c.set = 's_';

img = readSPE('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\crosspolarizedbarediamond 7-30-15.SPE');

plot(img);

for i=0:3
    for j=0:4
       for k=1:5
            name = [c.device,num2str(k),'_',c.set,'[',num2str(i),',',num2str(j),']'];
            try
                I=imread(strcat('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\Scan @ 11-52-4.638\',name,'_galvo.png'));
                data = load(strcat('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\Scan @ 11-52-4.638\',name,'_galvo.mat'));
                img2 = load(strcat('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\Scan @ 11-52-4.638\',name,'_spectrum.mat'));


                p = plot(double(img2.image)./double(img));
                xlim([1 512]);
                saveas(p, ['C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_31\Scan @ 11-52-4.638\' name,'_spectrum.png']);

                M(count,k) = (max(max(data.scan)));
                level = graythresh(I);
                IBW=im2bw(I,level);
                [centers, radii] = imfindcircles(IBW,[10 25]);
                if ~isempty(centers)
                   status(count,k)= 'W';
                else
                   status(count,k)= ' ';
                end
            catch err
                display(err.message);
                display([name ' not there...']);
            end
        end
%         w=strcat('%0',num2str(numel(num2str(max(max(M))))),'i');   
%         fprintf(stat_file, strcat('[',num2str(i),',',num2str(j),']','|', status(count,1),'\t', num2str(M(count,1),w),'|', status(count,2),'\t', num2str(M(count,2,:),w),'|',status(count,3),'\t', ...
%         num2str(M(count,3,:),w),'|',status(count,4), '\t',num2str(M(count,4,:),w),'|',status(count,5),'\t', num2str(M(count,5,:),w),'\r\n'));
%         count=count+1;    
    end
end

fclose(stat_file);
disp('done writing table');
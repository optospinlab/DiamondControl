
clear all; close all; clc;
stat_file=fopen('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\scan_stats.txt','w');

for i=0:3
    for j=0:4
        fprintf(stat_file,strcat('Set[',num2str(i),',',num2str(j),']'));
        for k=1:5
            I=imread(strcat('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\device_',num2str(k),'_set_[',num2str(i),',',num2str(j),']_galvo.png'));
            data = load(strcat('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\device_',num2str(k),'_set_[',num2str(i),',',num2str(j),']_galvo.mat'))
            M=max(max(data.scan))
            level = graythresh(I);
            IBW=im2bw(I,level);
            [centers, radii] = imfindcircles(IBW,[10 25]);
            if ~isempty(centers)
                fprintf(stat_file,strcat('|W', num2str(M),'|'));
            else
                fprintf(stat_file,'| |');
            end
        end
       fprintf(stat_file,'\r\n');
    end
end

fclose(stat_file);
disp('done writing device status');
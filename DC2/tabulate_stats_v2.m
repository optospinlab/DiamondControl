
clear all; close all; clc;
stat_file=fopen('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\scan_stats.txt','w');
count=1;

for i=0:3
    for j=0:4
       for k=1:5
            I=imread(strcat('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\device_',num2str(k),'_set_[',num2str(i),',',num2str(j),']_galvo.png'));
            data = load(strcat('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\2015_7_28\Scan @ 19-44-37.94\device_',num2str(k),'_set_[',num2str(i),',',num2str(j),']_galvo.mat'));
            M(count,k) = (max(max(data.scan)));
            level = graythresh(I);
            IBW=im2bw(I,level);
            [centers, radii] = imfindcircles(IBW,[10 25]);
            if ~isempty(centers)
               status(count,k)= 'W';
            else
               status(count,k)= ' ';
            end
       end
    w=strcat('%0',num2str(numel(num2str(max(max(M))))),'i');   
    fprintf(stat_file, strcat('[',num2str(i),',',num2str(j),']','|', status(count,1),'\t', num2str(M(count,1),w),'|', status(count,2),'\t', num2str(M(count,2,:),w),'|',status(count,3),'\t', ...
    num2str(M(count,3,:),w),'|',status(count,4), '\t',num2str(M(count,4,:),w),'|',status(count,5),'\t', num2str(M(count,5,:),w),'\r\n'));
        count=count+1;    
    end
end

fclose(stat_file);
disp('done writing table');
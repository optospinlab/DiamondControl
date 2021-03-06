
% create the trigger file
f = fopen('z:\WinSpec_Scan\matlabfile.txt', 'w');  
if (f == -1) 
    error('oops, file cannot be written'); 
end 
fprintf(f,'Trigger Spectrum\n');
fclose(f);

file = 'null'
image=-1;
disp('Trig spec');

%wait for spectrum and get data
while 1
    try
        disp('waiting')
        d=dir('Z:\WinSpec_Scan\s*.*');
        disp(d);
        file = strcat('Z:\WinSpec_Scan\',d.name)
        image=readSPE(file);
    catch error
        disp(error)
        pause(1)
    end
    if image ~=-1
        tic
        break
    end
end
disp('got the data!');

%plot data -> delete file
figure();
plot(1:512,image)
axis([1 512 min(image) max(image)])
save('C:\Users\Tomasz\Desktop\DiamondControl\spectrum\spectrum.mat','image');
disp('Saved .mat file and cleared folder')
delete(file)
toc

close all;
clear all;

pathData = 'C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_9_26\Scan @ 1-29-6.855\';

device = 'd_';
set = 's_';

x = 1;  xrange = [1 3];
y = 0;  yrange = [0 4];
d = 0;  drange = [4 11];

X=linspace(633.812,640.601,512);
 
BG = readSPE('C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_9_27\Scan @ 19-6-14.096\2015_09_27_Background_5s.spe');
BG = double(BG);
BG(1)=mean(BG);
BG=double(smooth(BG,25))';
figure; plot(X,BG);

Norm_spec=readSPE([ pathData 'normalization_spectrum.spe']);
Norm_spec=double(Norm_spec);
NormBG = (Norm_spec*10./3-BG./5); %OD 1/ Exp 3s
figure; plot(X,NormBG);

A=double(1./(NormBG));

figure
for x = xrange(1):xrange(2)
    for y = yrange(1):yrange(2)
        for d = drange(1):drange(2) 
            name = [device num2str(d) '_' set '['  num2str(x) ','  num2str(y) ']'];
            load([pathData name '_spectrum.mat']);
            trans=((double(spectrum)*100-BG)./5) .*A * 100; %OD 2/ Exp 5 for spectrum data

           
            save([pathData name '_trans.mat'],'trans');
            p = plot(X, trans);

            xlim([X(1) X(end)]);
            title(['device' num2str(d) '- Set '  '['  num2str(x) '  '  num2str(y) ']']);
            grid on;
            saveas(p, [pathData name '_trans.png']);
            
            %plot the mean
%             hold on;
%             plot(X(1:475), repmat(mean(trans),1,475),'g');
%             hold off;

% 
%             k=0;
%             while ~k
%                  k= waitforbuttonpress;
%             end

            
            
        end
     end
end
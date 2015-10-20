function trans_spectrum()
    close all;
    clear all;

    pathData = 'C:\Users\phys\Dropbox\Diamond Room\data\Mike\2015_10_11 OD Measurements\';

    device = 'd__';
    column= 'c_';
    set = 's_';

    xrange = [0 2];
    yrange = [0 5];
    crange = [1 5];
    drange = [1 3];

    OD1 = 9.89;
    9.5684
    OD2 = 74.93;
    74.2578
    OD4 = 8561.92;


    % X=linspace(633.812,640.601,512); % for the high resolution grating
    %The above needs to be changed
%     X=1:512;
    % X=linspace(0,6.79*6,512);

    X = linspace(637.2 - (123/512)*(6.79*6), 637.2 + ((512-123)/512)*(6.79*6), 512);

    BG = readSPE([ pathData 'back.spe']);
    BG = double(BG);
%     BG(1)=mean(BG);
%     BG(end)=mean(BG);
%     BG=(smooth(BG,25))';
    figure; plot(X,BG);

    pause(.5);
    
    l1 = {'spec1.spe', 'spec3.spe'};
    l2 = {'spec2.spe', 'spec4.spe'};
    
    for n = 1:2
        Norm = double(readSPE([ pathData char(l1{n})]));

        trans = Norm./(double(readSPE([ pathData char(l2{n})]))-BG);
        plot(1:512, trans);
        pause(.5)
        display(num2str(mean(trans([1:100 413:512]))));
    end
    
%     for d = {'OD1.spe', 'OD1-2.spe', 'OD2.spe', 'OD2-2.spe', 'OD3.spe'}
%         for n = {'OD0.spe', 'OD0-2.spe'}
%             Norm = double(readSPE([ pathData char(n)]));
%             
%             trans = Norm./(double(readSPE([ pathData char(d)]))-BG);
%             plot(1:200, trans([1:100 413:512]));
%             pause(.5)
% %             display([char(n) '/' char(d)]);
%             display(num2str(mean(trans([1:100 413:512]))));
%         end
%     end
end





















function trans_spectrum()
    close all;
    clear all;

    pathDataUpper = 'C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_10_9\Scan @ 17-57-15.381 - Directional Couplers Upper\';
    pathDataLower = 'C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_10_10\Scan @ 11-14-47.878 - Directional Couplers Lower\';

    device = 'd__';
    column= 'c_';
    set = 's_';

    xrange = [0 2];
    yrange = [0 5];
    crange = [0 1];
    drange = [0 8];

    OD1 = 9.89;
    OD2 = 74.93;
    OD4 = 8561.92;


    % X=linspace(633.812,640.601,512); % for the high resolution grating
    %The above needs to be changed
%     X=1:512;
    % X=linspace(0,6.79*6,512);

    ZPLPixel = 256;
    
    X = linspace(637.2 - (ZPLPixel/512)*(6.79), 637.2 + ((512-ZPLPixel)/512)*(6.79), 512);
    
    % Below is incorrect!
    BG = readSPE(['C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_10_6\Scan @ 17-36-2.051 - Final TE Grating Loops\2015_10_06_Background_1sec.spe']);
    BG = double(BG);
    BG(1)=mean(BG);
    BG(end)=mean(BG);
    BG=(smooth(BG,25))';
    figure; plot(X,BG);
    
    finalCell = cell(1);
    fy = 1;

    for c = crange(1):crange(2)
        if c == 0
            finalCell{fy, 1} = '180nm';
            
            finalCell{fy, 2} =  'Upper SPCM';
            finalCell{fy, 12} = 'Lower SPCM';
            finalCell{fy, 22} = 'Total SPCM';
            finalCell{fy, 32} = 'Coupled SPCM';
            
            finalCell{fy, 42} =  'Coupled Spectrometer';
            finalCell{fy, 52} =  'Coupled Spectrometer ZPL';
        else
            finalCell{fy, 1} = '160nm';
        end
        
        fy = fy + 1;
        
        for x = xrange(1):xrange(2)
            for y = yrange(1):yrange(2)
                finalCell{fy, 1} = ['['  num2str(x) ','  num2str(y) ']'];
                
                for d = drange(1):drange(2)
                    name = [device num2str(d) '_' column num2str(c) '_' set '['  num2str(x) ','  num2str(y) ']'];
                    
                    coupledZPL = 0;
                    coupledAll = 0;

                    try
                        name = [device num2str(d) '_' column num2str(c) '_' set '['  num2str(x) ','  num2str(y) ']'];
                        
                        dataUpper = load([pathDataUpper name '_spectrum.mat']);
                        dataLower = load([pathDataLower name '_spectrum.mat']);
                        
                        dataSPCMUpper = load([pathDataUpper name '_galvo.mat']);
                        dataSPCMLower = load([pathDataLower name '_galvo.mat']);
                        
                        spectrumUpper = (double(dataUpper.spectrum)-BG);
                        spectrumLower = (double(dataLower.spectrum)-BG);
                        
                        SPCMUpper = max(max(dataSPCMUpper.scan));
                        SPCMLower = max(max(dataSPCMLower.scan));
                        
                        coupledZPL = spectrumLower(256)/(spectrumUpper(256) + spectrumLower(256));
                        coupledAll = mean(spectrumLower./(spectrumUpper + spectrumLower));
                    catch err
                        display(err.message);
                    end
                    
                    finalCell{fy, 02 + d} = num2str(SPCMUpper);
                    finalCell{fy, 12 + d} = num2str(SPCMLower);
                    finalCell{fy, 22 + d} = num2str(SPCMUpper + SPCMLower);
                    finalCell{fy, 32 + d} = num2str(SPCMLower/(SPCMUpper + SPCMLower));
                    
                    finalCell{fy, 42 + d} = num2str(coupledAll);
                    finalCell{fy, 52 + d} = num2str(coupledZPL);
                end 
                
                fy = fy + 1;
            end
         end
    end

    xlswrite([pathDataUpper 'final.xlsx'], finalCell);
    
    display('done');


%     for c = crange(1):crange(2)
%         c
%         hold(Axes(c), 'on');
% 
%     %     total(:,c)./num(c)
% % 
% %         p = plot(Axes(c), newX, total(:,c)./num(c), 'b', 'Linewidth', 2);
%         
%         current = all(:,:,c);
%         current( ~any(current,2), : ) = [];
%         
%         q0 = quartile(current,0);
%         q1 = quartile(current,1);
%         q2 = quartile(current,2);
%         q3 = quartile(current,3);
%         q4 = quartile(current,4);
%         m =  mean(current);
%         s =  std(current);
%         mup = m + s;
%         mupup = m + s + s;
%         mdown = m - s;
%         mdowndown = m - s - s;
%         
%         span = 7;
%         
%         q0s = smooth(q0, span);
%         q1s = smooth(q1, span);
%         q2s = smooth(q2, span);
%         q3s = smooth(q3, span);
%         q4s = smooth(q4, span);
%         ms =  smooth(m, span);
%         mups =  smooth(mup, span);
%         mdowns =  smooth(mdown, span);
%         mupups =  smooth(mupup, span);
%         mdowndowns =  smooth(mdowndown, span);
%         
%         xdata = newX;
%                         
%         save([pathData 'finalGrating' num2str(c) '.mat'], 'xdata', 'q0', 'q1', 'q2', 'q3', 'q4', 'm', 'mup', 'mdown', 'mupup', 'mdowndown', 'q0s', 'q1s', 'q2s', 'q3s', 'q4s', 'ms', 'mups', 'mdowns', 'mupups', 'mdowndowns');
% 
%         p = plot(Axes(c), newX, m, 'b', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mup, 'b--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mdown, 'b--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mupup, 'b:', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mdowndown, 'b:', 'Linewidth', 1);
%         
%         p = plot(Axes(c), newX, q0, 'r:', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q1, 'r--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q2, 'r', 'Linewidth', 2);
%         p = plot(Axes(c), newX, q3, 'r--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q4, 'r:', 'Linewidth', 1);
%         
%         xlim(Axes(c), [min(newX) max(newX)]);
%         ylim(Axes(c), [0 35]);
% 
%         saveas(p, [pathData 'finalGrating' num2str(c) '.png']);
%         
%         cla(Axes(c));
% 
%         p = plot(Axes(c), newX, ms, 'b', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mups, 'b--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mdowns, 'b--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mupups, 'b:', 'Linewidth', 1);
%         p = plot(Axes(c), newX, mdowndowns, 'b:', 'Linewidth', 1);
%         
%         p = plot(Axes(c), newX, q0s, 'r:', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q1s, 'r--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q2s, 'r', 'Linewidth', 2);
%         p = plot(Axes(c), newX, q3s, 'r--', 'Linewidth', 1);
%         p = plot(Axes(c), newX, q4s, 'r:', 'Linewidth', 1);
%         
%         xlim(Axes(c), [min(newX) max(newX)]);
%         ylim(Axes(c), [0 35]);
% 
%         saveas(p, [pathData 'finalGrating' num2str(c) 's.png']);
%         
%     end
end
    
function peak = climb(mountains, basecamp) % An Alpine-themed peak-finder...
    direction = 1;
    
    if mountains(basecamp-1) > mountains(basecamp+1)
        direction = -1;
    end
    
    current = basecamp;
    
    while mountains(current + direction) > mountains(current)
        current = current + direction;
    end
    
    peak = mountains(current);
end

function num = quartile(list, q)
    switch(q)
        case 0
            num = min(list);
        case 1
            list = sort(list);
            num = median(list(1:floor(end/2), :));
        case 2
            num = median(list);
        case 3
            list = sort(list);
            num = median(list(ceil(end/2):end, :));
        case 4
            num = max(list);
    end
end





















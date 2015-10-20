function trans_spectrum()
    close all;
    clear all;

    pathData = 'C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_10_6\Scan @ 17-36-2.051 - Final TE Grating Loops\';

    device = 'd__';
    column= 'c_';
    set = 's_';

    xrange = [0 2];
    yrange = [0 5];
    crange = [1 5];
    drange = [1 3];

    OD1 = 9.89;
    OD2 = 74.93;
    OD4 = 8561.92;


    % X=linspace(633.812,640.601,512); % for the high resolution grating
    %The above needs to be changed
%     X=1:512;
    % X=linspace(0,6.79*6,512);

    X = linspace(637.2 - (123/512)*(6.79*6), 637.2 + ((512-123)/512)*(6.79*6), 512);

    BG = readSPE([ pathData '2015_10_06_Background_1sec.spe']);
    BG = double(BG);
    BG(1)=mean(BG);
    BG(end)=mean(BG);
    BG=(smooth(BG,25))';
    figure; plot(X,BG);

    pause(.5);

    %Final Normalization
    Norm_spec(1,:)=double(readSPE([ pathData '2015_10_06_Final_Normalization_OD3_1sec.spe']));
    NormBG(1,:) = (double(Norm_spec(1,:))-BG)*OD1*OD2; %OD 3/ Exp 1s
    % figure; plot(X,NormBG(1,:));

    %Initial Normalization
    Norm_spec(2,:)=double(readSPE([ pathData '2015_10_06_Normalization_OD3_1sec.spe']));
    NormBG(2,:) = (double(Norm_spec(2,:))-BG)*OD1*OD2; %OD 3/ Exp 1s
    % figure; plot(X,double(Norm_spec(2,:)*OD1*OD2));

    [~,~,deviceInfo] = xlsread([pathData 'goodDeviceTransfer.xlsx'])


    deviceInfo{1, 1}

    %Mean
    Norm = mean(NormBG,1);
    figure; plot(X,Norm);

    A = double(1./(Norm));

    % f = figure;

    F = [figure('Name', 'Grating 1') figure('Name', 'Grating 2') figure('Name', 'Grating 3') figure('Name', 'Grating 4') figure('Name', 'Grating 5')];
    Axes = [axes('Parent', F(1)) axes('Parent', F(2)) axes('Parent', F(3)) axes('Parent', F(4)) axes('Parent', F(5))];

    threshhold = 0;

    range = [637.2 - 6, 637.2 + 6];
    Range = (((X < range(2)) + (X > range(1))) == 2)

    newX = X(Range)

    hold on;

    num = [0 0 0 0 0];

    total = zeros(sum(Range), 5);
    

    all = zeros(1,sum(Range), 5);

    for x = xrange(1):xrange(2)
        for y = yrange(1):yrange(2)
            for c = crange(1):crange(2)
                for d = drange(1):drange(2) 
                    infoY = 1 + (d - drange(1)) + (1 + drange(2) - drange(1))*((y - yrange(1)) + (1 + yrange(2) - yrange(1))*(x - xrange(1)));
                    infoX = 1 + (c - crange(1));

                    display([num2str(infoY) ', ' num2str(infoX)]);

                    try
                        name = [device num2str(d) '_' column num2str(c) '_' set '['  num2str(x) ','  num2str(y) ']'];
                        display(num2str(name));
                        data = load([pathData name '_spectrum.mat'])
                        trans= sqrt(((double(data.spectrum)-BG)*OD2) .*A) * 100; %OD 2/ Exp 1 for spectrum data

        %                 1 + (d - drange(1)) + (drange(2) - drange(1))*((x - xrange(1)) + (xrange(2) - xrange(1))*(y - yrange(1)))
        %                 c


                        if deviceInfo{infoY, infoX} == 35
                            display('good!');

                            total(:, c) = total(:, c) + trans(Range)';
                            num(c) = num(c) + 1;
                        
                            all(num(c),:,c) = trans(Range);

                            hold(Axes(c), 'on');

%                             plot(Axes(c), newX, trans(Range)); % , ':');
        %                     xlim(Axes(c), [newX(1) newX(end)]);
                            deviceInfo{infoY, infoX} = climb(trans, 123);
%                             deviceInfo{infoY, infoX} = trans(123);
                        else
                            deviceInfo{infoY, infoX} = ' ';
                        end
        %                 grid on;

        %                 hold off
                        p = plot(newX, trans(Norm > 1e5));
                        xlim([newX(1) newX(end)]);
        %                 title(['device ' num2str(c) ' column ' num2str(d) ' - Set '  '['  num2str(x) '  '  num2str(y) ']']);
        %                 grid on;
        %                 
                        name = [device num2str(c) '_' column num2str(d) '_' set '['  num2str(x) ','  num2str(y) ']'];
                        
                        xdata = newX;
                        ydata = trans;

                        save([pathData name '_transMN.mat'], 'xdata', 'ydata');
                        
                        saveas(p, [pathData name '_trans.png']);
                    catch err
                        display(err.message);
                        deviceInfo{infoY, infoX} = ' ';
                    end


        %             k=0;
        %             while ~k
        %                  k= waitforbuttonpress;
        %             end
                end 
            end
         end
    end

    xlswrite([pathData 'finalPercentages.xlsx'], deviceInfo)


    for c = crange(1):crange(2)
        c
        hold(Axes(c), 'on');

    %     total(:,c)./num(c)
% 
%         p = plot(Axes(c), newX, total(:,c)./num(c), 'b', 'Linewidth', 2);
        
        current = all(:,:,c);
        current( ~any(current,2), : ) = [];
        
        q0 = quartile(current,0);
        q1 = quartile(current,1);
        q2 = quartile(current,2);
        q3 = quartile(current,3);
        q4 = quartile(current,4);
        m =  mean(current);
        s =  std(current);
        mup = m + s;
        mupup = m + s + s;
        mdown = m - s;
        mdowndown = m - s - s;
        
        span = 7;
        
        q0s = smooth(q0, span);
        q1s = smooth(q1, span);
        q2s = smooth(q2, span);
        q3s = smooth(q3, span);
        q4s = smooth(q4, span);
        ms =  smooth(m, span);
        mups =  smooth(mup, span);
        mdowns =  smooth(mdown, span);
        mupups =  smooth(mupup, span);
        mdowndowns =  smooth(mdowndown, span);
        
        xdata = newX;
                        
        save([pathData 'finalGrating' num2str(c) '.mat'], 'xdata', 'q0', 'q1', 'q2', 'q3', 'q4', 'm', 'mup', 'mdown', 'mupup', 'mdowndown', 'q0s', 'q1s', 'q2s', 'q3s', 'q4s', 'ms', 'mups', 'mdowns', 'mupups', 'mdowndowns');

        p = plot(Axes(c), newX, m, 'b', 'Linewidth', 1);
        p = plot(Axes(c), newX, mup, 'b--', 'Linewidth', 1);
        p = plot(Axes(c), newX, mdown, 'b--', 'Linewidth', 1);
        p = plot(Axes(c), newX, mupup, 'b:', 'Linewidth', 1);
        p = plot(Axes(c), newX, mdowndown, 'b:', 'Linewidth', 1);
        
        p = plot(Axes(c), newX, q0, 'r:', 'Linewidth', 1);
        p = plot(Axes(c), newX, q1, 'r--', 'Linewidth', 1);
        p = plot(Axes(c), newX, q2, 'r', 'Linewidth', 2);
        p = plot(Axes(c), newX, q3, 'r--', 'Linewidth', 1);
        p = plot(Axes(c), newX, q4, 'r:', 'Linewidth', 1);
        
        xlim(Axes(c), [min(newX) max(newX)]);
        ylim(Axes(c), [0 35]);

        saveas(p, [pathData 'finalGrating' num2str(c) '.png']);
        
        cla(Axes(c));

        p = plot(Axes(c), newX, ms, 'b', 'Linewidth', 1);
        p = plot(Axes(c), newX, mups, 'b--', 'Linewidth', 1);
        p = plot(Axes(c), newX, mdowns, 'b--', 'Linewidth', 1);
        p = plot(Axes(c), newX, mupups, 'b:', 'Linewidth', 1);
        p = plot(Axes(c), newX, mdowndowns, 'b:', 'Linewidth', 1);
        
        p = plot(Axes(c), newX, q0s, 'r:', 'Linewidth', 1);
        p = plot(Axes(c), newX, q1s, 'r--', 'Linewidth', 1);
        p = plot(Axes(c), newX, q2s, 'r', 'Linewidth', 2);
        p = plot(Axes(c), newX, q3s, 'r--', 'Linewidth', 1);
        p = plot(Axes(c), newX, q4s, 'r:', 'Linewidth', 1);
        
        xlim(Axes(c), [min(newX) max(newX)]);
        ylim(Axes(c), [0 35]);

        saveas(p, [pathData 'finalGrating' num2str(c) 's.png']);
        
    end
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





















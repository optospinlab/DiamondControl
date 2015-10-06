%READPOWERMETER Read power from one channel using GPIB
%
% power = readPowerMeter() gets the power from one channel of the power
% meter. The power meter is a Newport Dual-Channel Power Meter model
% 2832-C. The channel to be read can be changed in the code by making the
% query 'R_A?' or 'R_B?'.
%
% The power is returned in units of Watts, without any conversion. However,
% note that we often have an ND3 in the path.
%
% readPowerMeter('A') reads channel A
% 



function power = readPowerMeter(varargin)

channelsToRead = 'b';
if nargin==1
    channelsToRead = lower(varargin{1});
end

tic
% Initialize communication to the power meter.
obj1 = instrfind('Type', 'visa-gpib', 'RsrcName', 'GPIB0::5::INSTR', 'Tag', '');

% Create the VISA-GPIB object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = visa('NI', 'GPIB0::5::INSTR');
else
%     display('Using instrfind()');
    fclose(obj1);
    obj1 = obj1(1);
end

    fopen(obj1);
    flushinput(obj1);
    flushoutput(obj1);

    
    
%     tic
    % Get power from channel
    
    format long
    
    toc
    
    for j=1:100
%         if strcmp(channelsToRead,'a')
%             fprintf(obj1, 'R_A?');
%             pause(0.0001)
%             power(j) = str2double(fscanf(obj1));
%             pause(0.0001)
%         elseif strcmp(channelsToRead,'b')
            fprintf(obj1, 'R_B?');
            pause(0.005)
            p(j) = str2double(fscanf(obj1));
            pause(0.005)
            
%             power(j) = str2double(query(obj1, 'R_B?'));
%         elseif strcmp(channelsToRead,'ab')
%             fprintf(obj1, 'R_A?');
%             pause(.005);
%             power(1) = str2double(fscanf(obj1));
%             
%             pause(.005);
%             
%             fprintf(obj1, 'R_B?');
%             pause(.005);
%             power(2) = str2double(fscanf(obj1));
%         else
%             error('Channel to read not recognized')
%         end
    end
%     toc
   
    plot(p);
    % Do it again for error received on first read. Sometimes power meter
    % returns previous reading instead of current one.


   % Close communication
    pause(0.005)
   % clrdevice(obj1);
    fclose(obj1);
%     display('finished')
    
    power = mean(p);
% 
% catch err
%     disp(err.message)
%    power = 0;
%    disp('Error reading power meter!') 
% end



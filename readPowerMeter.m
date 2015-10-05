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

channelsToRead = 'a';
if nargin==1
    channelsToRead = lower(varargin{1});
end

% Initialize communication to the power meter.
obj1 = instrfind('Type', 'gpib',...
    'BoardIndex', 0, ...
    'PrimaryAddress', 0, ...
    'Tag', '');
% Create the GPIB object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    display('Using gpib()');
    obj1 = gpib('NI', 0, 0);
else
    display('Using instrfind()');
    fclose(obj1);
    obj1 = obj1(1);
end
% ibsic 
% ibsta
% % ibrsc 1

% try
    fopen(obj1);
    flushinput(obj1);
    flushoutput(obj1);
    % Get power from channel
    
    for j=1:3
        if strcmp(channelsToRead,'a')
            fprintf(obj1, 'R_A?');
            pause(.005);
            power = str2double(fscanf(obj1));
        elseif strcmp(channelsToRead,'b')
            fprintf(obj1, 'R_B?');
            pause(.005);
            power = str2double(fscanf(obj1));
        elseif strcmp(channelsToRead,'ab')
            fprintf(obj1, 'R_A?');
            pause(.005);
            power(1) = str2double(fscanf(obj1));
            pause(.005);
            fprintf(obj1, 'R_B?');
            pause(.005);
            power(2) = str2double(fscanf(obj1));
        else
            error('Channel to read not recognized')
        end
    end
    % Do it again for error received on first read. Sometimes power meter
    % returns previous reading instead of current one.

    
    
    % Close communication
    pause(0.0001)
    % clrdevice(obj1);
    fclose(obj1);
% 
% catch err
%     disp(err.message)
%    power = 0;
%    disp('Error reading power meter!') 
% end



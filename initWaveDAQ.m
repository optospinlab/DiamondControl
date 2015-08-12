%INITWAVEDAQ Initializes communcication to WA-1500 wavemeter
%
% Function opens the serial port on COM1 and puts wavemeter in proper 
% configuration for obtaining single wavelength measurements in nanometers.
%
% The configuration chosen is: 
%
%   Display:    'Wavelength'
%   Medium:     'Air'
%   Resolution: 'Fixed'
%   Averaging:  'Off'
%   Units:      'nm'  
%
% EXAMPLE
% 
% First set up the wavemeter communiation: 
%   >> wa1500 = initWaveDAQ();
%
% Then read the wavelength:
%   >> readWavelength(wa1500)
%
% Use close wave to shut down communication:
%   >> closeWave(wa1500)
%
% See Also: wa1500, commandWave, readWavelength, closeWave
%

% 
%
% 7.10.2012
% pasqual@uw.edu
%
% Modified by Todd Karin
%

function [wa1500] = initWaveDAQ()

% remove all serial instruments from memory to clear any
% open resources conflicts
delete(instrfind) 

% build matlab instrument to serial port COM1
% then open channel, put wavemeter into query mode so it doesn't 
% continue to fill buffer (single reading mode)
% then flush buffer and take a live measurement
wa1500 = serial('COM1', 'Term', 'CR/LF');
query = '@Q';
fopen(wa1500);
fprintf(wa1500, query);
flushinput(wa1500);
info = getReading(wa1500);

% co1mpare statusHex to verify the wavemeter is measuring in 'air' mode
if bitand(hex2dec(info{2}), 256) ~= 256
    pause(.1);
    fprintf(wa1500, '@)');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end

% compare statusHex to verify the wavemeter is reporting 'nm' units
% EDIT: Modified for 'GHz' units
if bitand(hex2dec(info{2}), 18) == 18
    fprintf(wa1500, '@''');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end

if bitand(hex2dec(info{2}), 72) == 72
    fprintf(wa1500, '@''');
    pause(.1);
    fprintf(wa1500, '@''');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end

% compare statusHex to verify the wavemeter is in 'wavelength' mode
if bitand(hex2dec(info{2}), 64) ~= 64
    fprintf(wa1500, '@(');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end

% compare statusHex to verify the wavemeter is in 'fixed' resolution mode
if bitand(hex2dec(info{2}), 1024) ~= 1024
    fprintf(wa1500, '@*');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end
% compare statusHex to verify the wavemeter is not in 'averaging' mode
% make next line:
% if bitand(hex2dec(info{2}), 4096) ~= 4096 For averaging mode.
if bitand(hex2dec(info{2}), 4096)== 4096
    fprintf(wa1500, '@+');
    pause(.1);
    info = getReading(wa1500);
    pause(.1);
end

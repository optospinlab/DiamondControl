%READWAVELENGTH Get a single wavelength measurement
% 
% readWavelength(wa1500) gets a single wavelength reading from the
% wavemeter. Use
%
%   >> wa1500 = initWaveDAQ()
%
% to build the device prior to use.
%
% OUTPUT
%   Function returns a (double) wavelength reading if successful, and
%   returns 0 if there is an error.
%
%
% See also: wa1500, INITWAVEDAQ, CLOSEWAVE



% 7.10.2012
% pasqual@uw.edu
%
% Modified by Todd Karin



function [wavelength] = readWavelength(wa1500)

% Get Reading
try
    fprintf(wa1500, '@Q');
%    pause(.1)
    response = fscanf(wa1500);
    info = textscan(response, '%11c %4c %4c', 'delimiter', ',');
    
    % Catch errors.
catch err
    info = {'0','0','0'};
end

% catch wavemeter thrown errors and return 0 if error found
if strncmp(info{1},'~', 1) | strfind(info{1},'SIG')>0
    wavelength = 0;
else 
    wavelength = str2double(info{1});
end


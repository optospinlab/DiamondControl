%GETREADING get a single reading from the wavemeter.
%
% getReading(wa1500) reads and parses an acquired data string from the
% wavemeter.
%
% If there is an error, function returns the cell array {'0','0','0'}.
% 
% EXAMPLE:
%
%   >> info = getReading(wa1500)
%
% info is a cell array with
%
% info{1} = LED character display on wavemeter.
% info{2} = status led (hexadecimal string) 
% info{3} = system led (hexadecimal string)
% consult the wa1500 manual for hex mask information
%
% See Also: wa1500, initWaveDAQ, readWavelength

%
% 7.10.2012
% pasqual@uw.edu
% Modified by Todd Karin


function [info] = getReading(wa1500)

try
    fprintf(wa1500, '@Q');
%     pause(.1);
    response = fscanf(wa1500);
    info = textscan(response, '%11c %4c %4c', 'delimiter', ',');
    
    % Catch errors.
catch err
    info = {'0','0','0'};
end
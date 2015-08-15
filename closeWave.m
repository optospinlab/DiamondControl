%CLOSEWAVE Shut down communication to wavemeter
%
% Closes the wa1500 serial port object and removes from memory.
%
% Example call:
%
%   >> closeWave(wa1500)
%
% See Also: wa1500, initWaveDAQ

% 7.10.2012
% pasqual@uw.edu


function closeWave(wa1500)
fclose(wa1500);
delete(wa1500);
clear wa1500;
% delete(instrfind);

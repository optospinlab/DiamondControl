%GETSETPOINT Returns the current set point
%
% getSetPoint(wa1500) returns the current set point as a double.
% 
% In order for this function to work, the wavemeter must not be displaying
% the setpoint (i.e. the setpoint LED should not be on).
%
% Example:
%
%   Initialize
%   >> wa1500 = initWaveDAQ()
%   
%   Read the set point:
%   >> setPoint = getSetPoint(wa1500)
%
% See Also: wa1500, initWaveDAQ, commandWave
%

% 
%
% Todd Karin
% 08/30/2012

function setPoint = getSetPoint(wa1500)


% Press set point button.
t=.1;
pause(t)
fprintf(wa1500,'@&');
pause(t)
reading = getReading(wa1500);

pause(t)
% press set point button again
fprintf(wa1500,'@&');

pause(t)
% process

setPoint = str2double(reading{1});
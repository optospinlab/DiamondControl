%RESETDEVIATION Set the setpoint equal to current wavelength
%
% resetDevation(wa1500) sets the wavelength deviation of a WA-1500
% wavemeter to the current reading in nm. wa1500 is an instrument generated
% by calling 
%
%   >> wa1500 = initWaveDAQ();
%
% This function is helpful so that the analog output does not saturate
% either high or low. 
%
% EXAMPLE
%
%   >> resetDeviation(wa1500)
%
%
% See Also: wa1500, initWaveDAQ

% Todd Karin
% 08/22/2012

function setPoint = resetDeviation(wa1500)

% Read the wavelength value to be set.
setPoint = readWavelength(wa1500);
setPointStr = num2str(setPoint);

% Add a set point button press before and an enter button afterwards
commandWave(wa1500, ['S' setPointStr 'E']);



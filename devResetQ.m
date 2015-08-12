%DEVRESETQ does the deviation need to be reset?
%
% For the analog output of the wavemeter to work, the set point must be
% close to the current value. devResetQ(wa1500) reads the set point and the
% current wavelength and determines whether the analog output will saturate
% or not. 
%
% Function returns a 1 if the analog output is saturated (i.e. the current
% wavelength is out of range), and a 0 if the analog output is in range.
%
% See Also: initWaveDAQ, commandWave, getSetPoint, readWavelength

% Todd Karin
% 08/30/2012

function needReset = devResetQ(wa1500)

% Read the set point and the current wavelength.
setPoint = getSetPoint(wa1500);
wavelength = readWavelength(wa1500);

% The DAQ is 11 bits plus a sign bit, the resolution should be set to .0001 
outRange = 2^11*.0001;

% If the set point and the current wavelength are too far apart, then the
% DAQ will not be able to output an analog voltage.
if abs(setPoint-wavelength)<.8*outRange
    needReset = 0;
else
    needReset = 1;
end
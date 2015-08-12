%WAVEMETERV2NM Convert analog out voltage to wavelength
%
% The Burleigh WA-1500 has an analog output that gives a voltage according
% to the formula:
%
% V = .0049*(wavelengthInNm-setPoint)/analogRes+Offset
%
% where analogRes = .0001, and the setPoint must be supplied to the
% function. wavemeterV2nm(analogVoltage,setPoint) converts the analog
% voltage voltage measured at the output to the wavelength in nm, given the
% setPoint. 
%
% The set point can be found by running the function getSetPoint(wa1500).
%
% Note that a small correction may be needed to calibrate the specific
% wavemeter that is used. Go into the source for this code, and change the
% variable 'corr' to calibrate your wavemeter.
%
%
% See Also: wa1500, getSetPoint

% Todd Karin
% 08/30/2012

function wavelength = wavemeterV2nm(analogVoltage,setPoint)

offSet = 0;
analogRes = .0001;
corr = .0003;

wavelength = (analogVoltage-offSet).*analogRes/.0049+setPoint+ corr;

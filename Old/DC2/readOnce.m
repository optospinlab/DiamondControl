%READONCE Gets one wavelength reading from the wavemeter
%
%     This simple function shows how to use this package to get a single
%     wavelength reading from the wavemeter. readOnce() initializes the
%     communication using initWaveDAQ, gets a single wavelength reading
%     using readWavelength(wa1500), and shuts down communication using
%     closeWave(wa1500).
%
%
% See Also: wa1500, initWaveDAQ


% Todd Karin
% 07/11/2012

function wavelength = readOnce()

%Save the instrument type.
wa1500 = initWaveDAQ;

% Get a reading
wavelength = readWavelength(wa1500);

% After you're done,
closeWave(wa1500);

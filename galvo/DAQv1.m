function final = galvoScan(range, upspeed, downspeed)    % range in microns, speed in microns per second (up is upscan; down is downscan)

close all
clear all

%Scan the Galvo +/- 5 deg
%min step of DAQ = 20/2^16 = 3.052e-4V
%min step of Galvo = 8e-4Deg
%for galvo [1V->1Deg], 8e-4V->8e-4Deg

mvConv = .030/5; % Micron to Voltage conversion (this is a guess! this should be changed!)
step = 8e-4;
stepFast = step*(upspeed/downspeed);

maxGalvoRange = 5; % This is a likely-incorrect assumption.

if mvConv*range > maxGalvoRange
    display('Galvo scanrange too large! Reducing to maximum.');
    range = maxGalvoRange/mvConv;
end

up = -(mvConv*range/2):step:(mvConv*range/2);%For testing not using full range
down = -(mvConv*range/2):stepFast:(mvConv*range/2);

final = ones(length(up));
prev = 0;
i = 1;

% Initialize the DAQ
s = daq.createSession('ni');
s.Rate = upspeed*length(up)/range;
s.addAnalogOutputChannel('cDAQ1Mod1', 0:1, 'Voltage');
s.addCounterInputChannel('Dev1', 'ctr1', 'EdgeCount');

queueOutputData(s, [(0:stepFast:-(mvConv*range/2))'     (0:stepFast:-(mvConv*range/2))']);
s.startForeground();    % Goto starting point from 0,0

for y = up  % For y in up. We 
    queueOutputData(s, [up'      y*ones(1,length(up))']);
    [out] = s.startForeground();
    queueOutputData(s, [down'    linspace(y, y + step, length(down))']);
	s.startBackground();
    
    final(i,:) = [(out(1)-prev) diff(out)];
    
    plot(c.axesLower, up, up(1:i), final(1:i,:));   % Display the graph on the backscan
    xlim(c.axesLower, [-mvConv*range/2  mvConv*range/2]);
    ylim(c.axesLower, [-mvConv*range/2  mvConv*range/2]);
    
    i = i + 1;
    
    prev = out(length(up));
    
    s.wait();
end

queueOutputData(s, [(-(mvConv*range/2):stepFast:0)'     ((mvConv*range/2):stepFast:0)']);
s.startForeground();    % Go back to 0,0 from finishing point

s.release();    % release DAQ
end
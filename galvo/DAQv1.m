close all
clear all

%Scan the Galvo +/- 5 deg
%min step of DAQ = 20/2^16 = 3.052e-4V
%min step of Galvo = 8e-4Deg
%for galvo [1V->1Deg], 8e-4V->8e-4Deg
x= -5:8e-4:5;%For testing not using full range
y= -5:8e-4:5;


%Initialize the DAQ
s = daq.createSession('ni');
%s.Rate = 1000;
addAnalogOutputChannel(s,'cDAQ1Mod1', 0:1, 'Voltage');

Galvox_ch0 = 0;
Galvoy_ch1 = 0;


for i=1:length(y)
   for j=1:length(x) 
       Galvox_ch0 = x(j);
       Galvoy_ch1 = y(i);
       %outputSingleScan(s,[Galvox_ch0 Galvoy_ch1]);
       queueOutputData(s,[Galvox_ch0 Galvoy_ch1]);
       s.startForeground();
       pause(0.01); %Allow for settling time
   end
end

s.wait()
s.release;
s = daq.createSession('ni');
s.addAnalogOutputChannel('Dev1', 'ao0', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
s.Rate = 10000;

tic
for x = 1:1000
    s.outputSingleScan(0);
    s.inputSingleScan();
end
toc
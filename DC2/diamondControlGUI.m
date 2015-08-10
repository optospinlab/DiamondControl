function c = diamondControlGUI(varargin)

display('  Making GUI');

if ~isempty(varargin)
    if length(varargin) == 1
        varargin = varargin{1};
    end

    for k = 1:2:length(varargin)
        param = lower(varargin{k});

        if (~ischar(param))
            error('Parameter names must be strings');
        end

        value = varargin{k+1};

        switch (param)
            case 'parent'
                c.parent = value;
%             case 'position'
%                 c.position = value;
            otherwise
                error('Option not understood')
        end
    end
else
    c.parent = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');
end

set(c.parent, 'defaulttextinterpreter', 'latex');

display('  Making Variables');

% 'Global' Variables stored in the GUI object, in the style of Todd
c.running = false;
c.linAct = [0 0];
c.pv = [];
c.pc = [];
c.plottingFigure =  figure('Visible', 'off', 'tag', 'Diamond Control Plotting');
c.plottingAxes =    axes('Parent', c.plottingFigure);

% Helper variables for GUI setup ==========================================
global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
pw = 250;           % Panel Width, the width of the side panel
puh = 180;          % Upper Panel Height
plh = 700;          % Lower Panel Height

bp = 5;             % Button Padding
bw = (pw-4*bp)/2;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object
plhi = plh - 2*bh;  % Inner Lower Panel Height

gp = 25;            % Graph  Padding

% IO ======================================================================
c.vid = 0;              % Empty variable for video input

c.joy = 0;              % Empty variable for the joystick
c.joystickEnabled = 0;

c.focusing = false;

c.joyButtonPrev = [0 0 0 0 0 0 0 0 0 0 0 0];   % Empty lists
c.joyPovPrev = [0 0];

c.joyXDir = 1;
c.joyYDir = -1;
c.joyZDir = 1;

c.joyXYPadding = .15;
c.joyZPadding = .25;

c.outputEnabled = 1;

c.microInitiated = false;
c.microStep = .080; % 80 nm

c.micro =       [0 0];
c.microActual = [0 0];
c.microMin =    [-25000 -25000];
c.microMax =    [25000 25000];

c.microXSerial = 0;     % Empty variable for the X micrometer serial connection
c.microXPort =  'COM5'; % This will be overwritten later (or should we define here?)
c.microXAddr =  '1';

c.microYSerial = 0;     % Empty variable for the Y micrometer serial connection
c.microYPort =  'COM6'; % This will be overwritten later
c.microYAddr =  '1';

% Session for all daq devices
c.s = 0; 
c.daqInitiated = false;

% SPCM DEVice and CHaNnel
c.devSPCM =     'Dev1';         
c.chnSPCM =     'ctr1';

% Galvo DEVice and CHaNnels
c.devGalvo =    'cDAQ1Mod1';	
c.chnGalvoX =   'ao0';
c.chnGalvoY =   'ao1';

c.galvo =       [0 0];
c.galvoBase =   [0 0];
c.galvoMin =    [-5000 -5000];  % mV
c.galvoMax =    [ 5000  5000];  % mV
c.galvoStep =   .05;            % V

% Z Peizo DEVice and CHaNnels
c.devPiezo =    'Dev1';        
c.chnPiezoX =   'ao0';
c.chnPiezoY =   'ao1';
c.chnPiezoZ =   'ao2';

c.piezo =       [0 0 0];
c.piezoBase =   [0 0 0];
c.piezoMin =    [0 0 0];
c.piezoMax =    [10 10 10];
c.piezoStep = .025;

% PLE DEVice and CHaNnels
c.devPleOut =   'cDAQ1Mod1';
c.chnPerotOut = 'ao2';
c.chnGrateOut = 'ao3';

c.devPleDigitOut = 'Dev1';
c.chnPleDigitOut = 'Port0/Line0';

c.devPleIn =   'Dev1';    
c.chnPerotIn = 'ai0';
c.chnSPCMPle =  'ctr1';
c.chnNormIn =  'ai1';

% PLE
c.sPle = 0;
c.sdPle = 0;
c.pleLh = 0;        % Empty variable for listener.

c.FSR = 4.118;    % Change? An old measurement.
c.freqBase = 0;   % From Wavemeter
c.perotBase = 0;  % Original from FP
c.freqPrev = 0;
c.perotPrev = 0;

c.perotMax = 10;  % Maximum Voltage to perot...
c.grateMax = 10;  %  "       "   ...to grating.

c.pleRate = 2^12;
c.pleRateOld = 2^14;
c.perotLength = 2^9;
c.upScans = 30;
c.downScans = 2;

c.interval = perotLength + floor((oldrate - upScans*perotLength)/upScans);
c.leftover = (oldrate - upScans*interval);

c.firstPerotLength = 2^10;
c.fullPerotLength = 1250;

c.up = true;
c.grateCurr = 0;
c.dGrateCurr = 2^-5;

c.intervalCounter = 0;

c.q = 1;
c.qmax = 400;
c.qmaxPle = 50;

c.freqs = [];
c.times = [];
c.rfreqs = [];
c.rtimes = [];

% c.finalGraphX = zeros(1, c.firstPerotLength);       % Frequency
% c.finalGraphY = zeros(1, c.firstPerotLength);       % Intensity
% 
% c.finalColorX = zeros(1,interval*upScans*qmax);
% c.finalColorY = zeros(1,interval*upScans*qmax);
% c.finalColorC = zeros(1,interval*upScans*qmax);
% 
% c.finalPerotColorX = zeros(firstPerotLength, qmax);
% c.finalPerotColorY = zeros(firstPerotLength, qmax);

c.finalGraphX = [];       % Frequency
c.finalGraphY = [];       % Intensity

c.finalColorX = [];
c.finalColorY = [];
c.finalColorC = [];

c.finalPerotColorX = [];
c.finalPerotColorY = [];

c.perotIn = 0;
c.perotInUp = 0;
c.perotInDown = 0;
c.grateIn = 0;
c.grateInUp = 0;
c.grateInDown = 0;
c.pleIn = 0;

% Galvos
c.galvoRange =  8;      % 8 um
c.galvoRangeMax =  50;  % 50 um    
c.galvoSpeed =  25;     % 25 um/sec
c.galvoSpeedMax =  50;  % 50 um/sec    
c.galvoPixels =  40;    % 40 pixels/side

% Piezos
c.piezoRange =  8;      % 8 um
c.piezoRangeMax = 50;  % 50 um    
c.piezoSpeed =  8;     % 25 um/sec
c.piezoSpeedMax =  50;  % 50 um/sec    
c.piezoPixels =  40;    % 40 pixels/side

% File Saving
c.directory = 'C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\';
display('Files will be saved in:');
display(['    ' c.directory]);
c.device = 'd_';
c.set = 's_';

% AXES ====================================================================
display('  Making Axes');
set(gcf,'Renderer','Zbuffer');

c.videoEnabled = 0;
c.hImage = 0;

c.axesMode =    0;     % CURRENT -> 0:Regular, 1:PLE    OLD -> 0:Both, 1:Upper, 2:Lower
c.upperAxes =   axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual');
c.lowerAxes =   axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual');
c.imageAxes =   axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual');
c.counterAxes = axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual');

c.pleAxesAll =  axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'Off');
c.pleAxesOne =  axes('Parent', c.parent, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'Off');

% Add popout figures here.
% c.upperFigure =     figure('Visible', 'Off');
% c.lowerFigure =     figure('Visible', 'Off');
% c.imageFigure =     figure('Visible', 'Off');
% c.counterFigure =   figure('Visible', 'Off');
% 
% c.upperAxes2 =   axes('XLimMode', 'manual', 'YLimMode', 'manual');
% c.lowerAxes2 =   axes('XLimMode', 'manual', 'YLimMode', 'manual');
% c.imageAxes2 =   axes('XLimMode', 'manual', 'YLimMode', 'manual');
% c.counterAxes2 = axes('XLimMode', 'manual', 'YLimMode', 'manual');

% PANELS ==================================================================
display('  Making Panels');
c.ioPanel =         uitabgroup('Parent', c.parent, 'Units', 'pixels');
c.outputTab =       uitab(c.ioPanel, 'Title', 'Outputs');
    c.microText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Micrometers:', 'Position',[bp      puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
    c.microXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp       puh-bp-4*bh bw/2 bh],	'HorizontalAlignment', 'right');
    c.microXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-4*bh bw/2 bh],  'Enable', 'inactive');
    c.microYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [bp       puh-bp-5*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.microYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-5*bh bw/2 bh],  'Enable', 'inactive');
    
    c.piezoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Piezos:', 'Position',    [2*bp+2*bw/2 puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
    c.piezoZLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Z (V): ',   'Position',  [2*bp+2*bw/2 puh-bp-4*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.piezoZZ =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-4*bh bw/2 bh],  'Enable', 'inactive');
    c.piezoXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (V): ',   'Position',  [2*bp+2*bw/2 puh-bp-5*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.piezoXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-5*bh bw/2 bh],  'Enable', 'inactive');
    c.piezoYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (V): ',   'Position',  [2*bp+2*bw/2 puh-bp-6*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.piezoYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-6*bh bw/2 bh],  'Enable', 'inactive');
    
    c.galvoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Galvos:', 'Position',    [bp       puh-bp-7*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
    c.galvoXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (mV): ',   'Position', [bp       puh-bp-8*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.galvoXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-8*bh bw/2 bh],  'Enable', 'inactive');
    c.galvoYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (mV): ',   'Position', [bp       puh-bp-9*bh bw/2 bh],  'HorizontalAlignment', 'right');
    c.galvoYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-9*bh bw/2 bh],  'Enable', 'inactive');

    %     c.microReset =  uicontrol('Parent', c.microTab, 'Style', 'pushbutton', 'String', 'Reset', 'Position', [2*bp+bw puh-bp-5*bh bw bh]);

% c.initiateTab =     uitab(c.ioPanel, 'Title', 'Initiate');
%     c.microInit =   uicontrol('Parent', c.initiateTab, 'Style', 'pushbutton', 'String', 'Initiate!', 'Position', [bp  puh-bp-5*bh bw bh]);

%     c.galvoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Galvometers (nothing to see):', 'Position', [bp puh-bp-5*bh 2*bw bh]);
%     c.piezoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Peizos (nothing to see):', 'Position', [bp puh-bp-6*bh 2*bw bh]);

c.joyTab =          uitab(c.ioPanel, 'Title', 'Joystick!');
    c.joyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Joystick: Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh bw bh]); 
    c.joyAxes =     axes('Parent', c.joyTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [bp+bw bp bw bw-bp]);
    
c.mouseKeyTab =     uitab(c.ioPanel, 'Title', 'Mouse/Key');
    c.mouseEnabled =    uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Mouse: Enable Click on Graph?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh 2*bw bh]); 
    c.keyEnabled =      uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Keyboard: Enable Arrow Keys?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-4*bh 2*bw bh]); 

    
c.automationPanel = uitabgroup('Parent', c.parent, 'Units', 'pixels');
c.gotoTab =         uitab('Parent', c.automationPanel, 'Title', 'Goto');
    c.gotoMLabel  = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Micrometers: ',   'Position', [bp plh-bp-3*bh bw bh],         'HorizontalAlignment', 'left');
    c.gotoMXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp      plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoMX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2 plh-bp-4*bh bw/2 bh]);
    c.gotoMYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [bp      plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoMY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2 plh-bp-5*bh bw/2 bh]);
    c.gotoMReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset','Position', [bp      plh-bp-6*bh bw bh]);
    c.gotoMActual = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Actual','Position', [bp plh-bp-7*bh bw bh]);
    c.gotoMTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [bp plh-bp-8*bh bw bh]);
    c.gotoMButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp      plh-bp-9*bh bw bh]);
  
    c.gotoM = [c.gotoMX c.gotoMY c.gotoMActual c.gotoMTarget c.gotoMButton];
    
    c.gotoPLabel  = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Piezos: ',   'Position', [2*bp+2*bw/2 plh-bp-3*bh bw bh],         'HorizontalAlignment', 'left');
    c.gotoPZLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Z (V): ',   'Position',  [2*bp+2*bw/2 plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoPZ =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2 plh-bp-4*bh bw/2 bh]);
    c.gotoPXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (V): ',   'Position',  [2*bp+2*bw/2 plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoPX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2 plh-bp-5*bh bw/2 bh]);
    c.gotoPYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (V): ',   'Position',  [2*bp+2*bw/2 plh-bp-6*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoPY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2 plh-bp-6*bh bw/2 bh]);
    c.gotoPTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position',    [2*bp+bw    plh-bp-7*bh bw bh]);
    c.gotoPButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position',         [2*bp+bw    plh-bp-8*bh bw bh]);
    c.gotoPMaximize = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Maximize','Position',    [2*bp+bw    plh-bp-9*bh bw bh]);
    c.gotoPReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset XY','Position',      [2*bp+bw    plh-bp-10*bh bw bh]);
    c.gotoPFocus =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Focus','Position',         [2*bp+bw    plh-bp-11*bh bw bh]);
    c.gotoPOptXY =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize XY','Position',   [2*bp+bw    plh-bp-12*bh bw bh]);
    c.gotoPOptZ =   uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize Z','Position',    [2*bp+bw    plh-bp-13*bh bw bh]);
  
    c.gotoP = [c.gotoPX c.gotoPY c.gotoPZ c.gotoPFocus c.gotoPReset c.gotoPMaximize c.gotoPTarget c.gotoPButton];
    
    c.gotoGLabel  = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Galvos: ',   'Position', [bp         plh-bp-11*bh bw bh],         'HorizontalAlignment', 'left');
    c.gotoGXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (mV): ',   'Position', [bp         plh-bp-12*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoGX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-12*bh bw/2 bh]);
    c.gotoGYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (mV): ',   'Position', [bp         plh-bp-13*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoGY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-13*bh bw/2 bh]);
    c.gotoGReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset','Position', [bp	plh-bp-16*bh bw bh]);
    c.gotoGTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [bp	plh-bp-14*bh bw bh]);
    c.gotoGButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp         plh-bp-15*bh bw bh]);
  
    c.gotoM = [c.gotoGX c.gotoGY c.gotoGReset c.gotoGTarget c.gotoGButton];
     
    c.go_mouse_control = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Use Mouse Control: ',   'Position', [bp         plh-bp-22*bh 2*bw bh],         'HorizontalAlignment', 'center');
    c.go_mouse =       uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto MouseClick!','Position', [2*bp	plh-bp-24*bh 2*bw bh]);
    c.go_mouse_fine =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto MouseClick Fine (Piezo)!','Position', [2*bp	plh-bp-26*bh 2*bw bh]);
    
c.scanningTab = uitab('Parent', c.automationPanel, 'Title', 'Scan');
    c.scanningPanel = uitabgroup('Parent', c.scanningTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);

        c.piezoTab =  uitab('Parent', c.scanningPanel, 'Title', 'Piezo');
            c.piezoRLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp        plhi-bp-3*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoR =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoRange,     'Position', [bp+bw   plhi-bp-3*bh bw/2 bh]);
            c.piezoSLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp        plhi-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoS =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoSpeed,     'Position', [bp+bw   plhi-bp-4*bh bw/2 bh]);
            c.piezoPLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Pixels (num/side): ', 'Position', [bp        plhi-bp-5*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoP =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoPixels,     'Position', [bp+bw   plhi-bp-5*bh bw/2 bh]);    
            c.piezoCLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Colormap: ', 'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoC =      uicontrol('Parent', c.piezoTab, 'Style', 'popupmenu', 'String', {'gray', 'jet'},     'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);
            c.piezoButton = uicontrol('Parent', c.piezoTab, 'Style', 'togglebutton', 'String', 'Scan!','Position', [bp        plhi-bp-8*bh bp+2*bw bh]);

            c.piezoOptimize =uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Optimize','Position', [bp        plhi-bp-9*bh bp+2*bw bh]);

            c.piezoScanning = false;
            
        c.galvoTab =  uitab('Parent', c.scanningPanel, 'Title', 'Galvo');
            c.galvoRLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp        plhi-bp-3*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoR =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoRange,     'Position', [bp+bw   plhi-bp-3*bh bw/2 bh]);
            c.galvoSLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp        plhi-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoS =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoSpeed,     'Position', [bp+bw   plhi-bp-4*bh bw/2 bh]);
            c.galvoPLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Pixels (num/side): ', 'Position', [bp        plhi-bp-5*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoP =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoPixels,     'Position', [bp+bw   plhi-bp-5*bh bw/2 bh]);    
            c.galvoCLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Colormap: ', 'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoC =      uicontrol('Parent', c.galvoTab, 'Style', 'popupmenu', 'String', {'gray', 'jet'},     'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);
            c.galvoButton = uicontrol('Parent', c.galvoTab, 'Style', 'togglebutton', 'String', 'Scan!','Position', [bp        plhi-bp-8*bh bp+2*bw bh]);

            c.galvoOptimize =uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Optimize','Position', [bp        plhi-bp-9*bh bp+2*bw bh]);

            c.galvoAlignX = uicontrol('Parent', c.galvoTab, 'Style', 'togglebutton', 'String', 'Sweep X','Position', [bp        plhi-bp-10*bh bw bh]);
            c.galvoAlignY = uicontrol('Parent', c.galvoTab, 'Style', 'togglebutton', 'String', 'Sweep Y','Position', [2*bp+bw   plhi-bp-10*bh bw bh]);

            c.galvoAligning = false;
            c.galvoScanning = false;

        c.counterTab =  uitab('Parent', c.scanningPanel, 'Title', 'Counter');
            c.counterButton = uicontrol('Parent', c.counterTab, 'Style', 'checkbox', 'String', 'Count?', 'Position', [bp plhi-bp-3*bh bp+2*bw bh], 'HorizontalAlignment', 'left');
            c.sC = 0;       % Empty variable for the counter channel;
            c.lhC = 0;      % Empty variable for counter listener;
            c.dataC = [];   % Empty variable for counter data;
            c.rateC = 4;    % rate: scans/sec
            c.lenC = 100;  % len:  scans/graph
            c.iC = 0;
            c.prevCount = 0;
            c.isCounting = 0;

        c.spectraTab =  uitab('Parent', c.scanningPanel, 'Title', 'Spectra');
            c.spectrumButton = uicontrol('Parent', c.spectraTab, 'Style', 'pushbutton', 'String', 'Take Spectrum', 'Position', [bp plhi-bp-3*bh bp+2*bw bh]);

c.automationTab = uitab('Parent', c.automationPanel, 'Title', 'Automation!');
    c.autoPanel = uitabgroup('Parent', c.automationTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);
        c.autoTabC =         uitab('Parent', c.autoPanel, 'Title', 'Controls');
            c.autoPreview =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton','String', 'Preview Path', 'Position', [bp	plhi-bp-3*bh 2*bw+bp bh]);
            c.autoTest =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Test Path', 'Position', [bp	plhi-bp-4*bh 2*bw+bp bh]);
            c.autoButton =  uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Automate!', 'Position', [bp	plhi-bp-5*bh 2*bw+bp bh]);
            c.autoAutoProceed = uicontrol('Parent', c.autoTabC, 'Style', 'checkbox', 'String', 'Auto Proceed', 'Position', [bp	plhi-bp-6*bh bw bh], 'HorizontalAlignment', 'left');
            c.autoProceed = uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Proceed!', 'Position', [2*bp+bw	plhi-bp-6*bh bw bh]);
            c.proceed = false;  % Variable for whether to proceed or not.
            c.autoStop =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Stop', 'Position', [bp	plhi-bp-7*bh 2*bw+bp bh]);
            c.autoScanning = false;
            
        c.autoTab =         uitab('Parent', c.autoPanel, 'Title', 'Grid');
            k = 3;
            c.autoText0 =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Define ranges for N and n: ',   'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;

            c.autoNXRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NX: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoNXRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoNXRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NX: ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoNXRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 3,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;

            c.autoNYRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NY: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoNYRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoNYRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NY: ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoNYRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;

            c.autonRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min nx: ',     'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autonRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,             'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autonRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max nx: ',     'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autonRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 5,             'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;

            c.autonyRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min ny: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autonyRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autonyRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max ny: ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autonyRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+2;

            
            
            c.autoText =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input positions of 3 separate sister devices: ',   'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV123nT =  uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'nx123: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV123n =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 2,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV123nyT =  uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny123: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV123ny =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 2,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;

            c.autoV1T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 1: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            c.autoV1NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV1NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV1NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV1NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV1XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV1X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV1YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV1Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV1ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV1Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV1Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+1;
            

            c.autoV2T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 2: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            c.autoV2NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV2NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV2NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV2NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV2XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV2X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 100,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV2YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV2Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV2ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV2Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV2Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+1;
            
            c.autoV3T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 3: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            c.autoV3NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV3NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 2,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV3XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV3YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', -100,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV3ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV3Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+2;
            
            
            c.autoText2 =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input position of 2 non-sister devices: ',   'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV4T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 4: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV4nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'nx: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4nyT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4ny =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            
            c.autoV4NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV4XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 10,           'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', -2,           'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV4ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+1;
            
            
            c.autoV5T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 5: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV5nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'nx: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5nyT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5ny =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            
            c.autoV5NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV5XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 10,           'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', -2,           'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV5ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
        
        c.autoTabT =         uitab('Parent', c.autoPanel, 'Title', 'Tasks');
            c.autoTaskFocus = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Focus upon arrival?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-3*bh 2*bw bh]); 
%             c.autoTaskReset = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Reset piezos and galvos?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-4*bh 2*bw bh]); 
            
            c.autoTaskBlue = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Take blue image?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-4*bh 2*bw bh]); 
            c.autoTaskGalvo = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Galvo scan?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-5*bh 2*bw bh]); 

            c.autoTaskNumRepeatT = uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Repeat Optimization #: ',   'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.autoTaskNumRepeat  = uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 2,     'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);
            
            c.autoTaskSpectrum = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Take spectrum?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-7*bh 2*bw bh]); 
            
c.pleTab =  uitab(c.automationPanel, 'Title', 'PLE!');
    c.plePanel = uitabgroup('Parent', c.pleTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);
        c.pleScanTab =      uitab('Parent', c.plePanel, 'Title', 'PLE Scan');
            c.pleOnce =       uicontrol('Parent', c.pleScanTab, 'Style', 'pushbutton',   'String', 'Scan Once',       'Position', [2*bp+bw  plhi-bp-3*bh    bw bh], 'Callback', @pleOnceCall); 
            c.pleCont =       uicontrol('Parent', c.pleScanTab, 'Style', 'togglebutton', 'String', 'Scan Continuous', 'Position', [bp       plhi-bp-3*bh    bw bh], 'Callback', @pleCall); 
            c.axesSide =      axes(     'Parent', c.pleScanTab, 'Units', 'pixels', 'Position', [5*bp       plhi-bp-5*bh-bw    2*bw-5*bp bw]);
            set(c.axesSide, 'FontSize', 6);
            c.pleDebug =   uicontrol('Parent', c.perotScanTab, 'Style', 'checkbox',     'String', 'Debug Mode?', 'HorizontalAlignment', 'left', 'Position', [bp plhi-bp-4*bh 2*bw bh]); 
            
        c.perotScanTab =    uitab('Parent', c.plePanel, 'Title', 'Perot Scan');
            c.perotCont =     uicontrol('Parent', c.perotScanTab, 'Style', 'togglebutton', 'String', 'Scan Continuous', 'Position', [bp plhi-bp-3*bh bw bh], 'Callback', @perotCall); 
            c.perotHzOutT =   uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', 'Linewidth:', 'HorizontalAlignment', 'left',  'Position', [bp plhi-bp-4*bh 2*bw bh]); 
            c.perotHzOut =    uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', ' --- ', 'HorizontalAlignment', 'left',  'Position', [bp plhi-bp-8*bh 2*bw 4*bh], 'FontSize', 24); 
            c.perotFsrOut =   uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', 'FSR:  ---', 'HorizontalAlignment', 'left',        'Position', [bp plhi-bp-9*bh 2*bw bh]); 
            c.perotRampOn =   uicontrol('Parent', c.perotScanTab, 'Style', 'checkbox',     'String', 'Ramp?', 'HorizontalAlignment', 'left',            'Position', [bp plhi-bp-10*bh 2*bw bh]); 

% A list of all buttons to disable when a scan/etc is running.
% c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

c.trackTab =           uitab(c.automationPanel, 'Title', 'Tracking');
    c.ratevid = 2;     % vid update rate /sec
    c.ratetrack = 10;  % tracking corrections / sec
    
    c.vid_on=0; c.seldisk=0;
    c.roi='';
    c.roi_pad=10;      %ROI padding of 10 pixels on each side of the disk
    
    c.start_vid =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', ' Start',                   'Position',[2*bp plhi-bp-2*bh bw bh]);  
    c.stop_vid =       uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Stop!',                    'Position',[2*bp+bw plhi-bp-2*bh bw bh]);
    c.track_clear =    uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Clear',                    'Position',[2*bp plhi-bp-18*bh bw bh]);
    c.track_set =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Stabilize Disk',           'Position',[2*bp+bw plhi-bp-18*bh bw bh]);
    c.track_stat =     uicontrol('Parent', c.trackTab, 'Style', 'text',       'String', 'Status: Nothing selected', 'Position',[bp plhi-bp-16*bh 2*bw bh]);  

    c.track_Axes =     axes('Parent', c.trackTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position',[bp plhi-bp-14*bh bp+2*bw 2*bw]);
    c.roi_Axes=        axes('Parent', c.trackTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position',[bp plhi-bp-32*bh bp+2*bw 2*bw]);
  
display('  Finished...');
end





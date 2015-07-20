function c = diamondControlGUI(varargin)

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

% 'Global' Variables stored in the GUI object, in the style of Todd
c.running = false;
c.linAct = [0 0];

% Helper variables for GUI setup ==========================================
global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
pw = 250;           % Panel Width, the width of the side panel
puh = 180;          % Upper Panel Height
plh = 600;          % Lower Panel Height

bp = 5;             % Button Padding
bw = (pw-4*bp)/2;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object

gp = 25;            % Graph  Padding

% IO ======================================================================
c.vid = 0;              % Empty variable for video input

c.joy = 0;              % Empty variable for the joystick

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
c.microXPort = 'COM5'; % This will be overwritten later (or should we define here?)
c.microXAddr = '1';

c.microYSerial = 0;     % Empty variable for the Y micrometer serial connection
c.microYPort = 'COM6'; % This will be overwritten later
c.microYAddr = '1';


c.devSPCM = 'Dev1';         % SPCM DEVice and CHaNnel
c.chnSPCM = 'ctr1';


c.galvoInitiated = false;
c.devGalvo = 'cDAQ1Mod1';	% Galvo DEVice and CHaNnels
c.chnGalvoX = 'ao0';
c.chnGalvoY = 'ao1';

c.galvo = [0 0];
c.galvoBase = [0 0];
c.galvoMin =    [-5 -5];
c.galvoMax =    [ 5  5];
c.sG = 0; % Session for galvos
c.galvoStep = .05;


c.piezoInitiated = false;
c.devPiezo = 'Dev1';        % Z Peizo DEVice and CHaNnels
c.chnPiezoX = 'ao0';
c.chnPiezoY = 'ao1';
c.chnPiezoZ = 'ao2';

c.piezo =       [0 0 0];
c.piezoBase =   [0 0 0];
c.piezoMin =    [0 0 0];
c.piezoMax =    [10 10 10];
c.piezoStep = .05;
c.sP = 0; % Session for piezos


% AXES ====================================================================
c.axesMode =    0;     % 0:Both, 1:Upper, 2:Lower
c.upperAxes =   axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);
c.lowerAxes =   axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);
c.imageAxes =   axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual');

% PANELS ==================================================================
c.ioPanel =         uitabgroup('Units', 'pixels');
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

c.initiateTab =     uitab(c.ioPanel, 'Title', 'Initiate');
    c.microInit =   uicontrol('Parent', c.initiateTab, 'Style', 'pushbutton', 'String', 'Initiate!', 'Position', [bp  puh-bp-5*bh bw bh]);

    
%     c.galvoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Galvometers (nothing to see):', 'Position', [bp puh-bp-5*bh 2*bw bh]);
%     c.piezoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Peizos (nothing to see):', 'Position', [bp puh-bp-6*bh 2*bw bh]);

c.joyTab =          uitab(c.ioPanel, 'Title', 'Joystick!');
    c.joyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Joystick: Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh bw bh]); 
    c.joyAxes =     axes('Parent', c.joyTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [bp+bw bp bw bw-bp]);
    
c.mouseKeyTab =     uitab(c.ioPanel, 'Title', 'Mouse/Key');
    c.mouseEnabled =    uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Mouse: Enable Click on Graph?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh 2*bw bh]); 
    c.keyEnabled =      uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Keyboard: Enable Arrow Keys?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-4*bh 2*bw bh]); 

    
c.automationPanel = uitabgroup('Units', 'pixels');
c.gotoTab =         uitab(c.automationPanel, 'Title', 'Goto');
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
    c.gotoPTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [2*bp+bw plh-bp-7*bh bw bh]);
    c.gotoPButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [2*bp+bw     plh-bp-8*bh bw bh]);
    c.gotoPMaximize = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Maximize','Position', [2*bp+bw plh-bp-9*bh bw bh]);
    c.gotoPReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset XY','Position', [2*bp+bw plh-bp-10*bh bw bh]);
    c.gotoPFocus =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Focus','Position', [2*bp+bw     plh-bp-11*bh bw bh]);
  
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

c.galvoTab =  uitab(c.automationPanel, 'Title', 'Galvo Scan');
    c.galvoRange =  5;      % 5 um
    c.galvoRangeMax =  50;  % 50 um
    c.galvoRLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp        plh-bp-3*bh bw bh],         'HorizontalAlignment', 'right');
    c.galvoR =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoRange,     'Position', [bp+bw   plh-bp-3*bh bw/2 bh]);
    c.galvoSpeed =  5; % 5 um/sec
    c.galvoSpeedMax =  50;  % 50 um/sec
    c.galvoSLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp        plh-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
    c.galvoS =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoSpeed,     'Position', [bp+bw   plh-bp-4*bh bw/2 bh]);
    
    c.galvoPLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Pixels (num/side): ', 'Position', [bp        plh-bp-5*bh bw bh],         'HorizontalAlignment', 'right');
    c.galvoP =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoSpeed,     'Position', [bp+bw   plh-bp-5*bh bw/2 bh]);
    c.galvoButton = uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Scan!','Position', [bp        plh-bp-7*bh bp+2*bw bh]);

c.boxTab =          uitab(c.automationPanel, 'Title', 'Set Box');
    c.boxInfo =     uicontrol('Parent', c.boxTab, 'Style', 'text', 'String', 'This draws a box on the screen, depending upon the given points.', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plh-bp-4*bh 2*bw 2*bh]);
    c.boxLabel =    uicontrol('Parent', c.boxTab, 'Style', 'text', 'String', 'Save Current Position As...', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plh-bp-5*bh 2*bw bh]);
    c.boxTL =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Top Left',     'Position', [bp         plh-bp-6*bh bw bh]);
    c.boxTR =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Top Right',    'Position', [2*bp+bw    plh-bp-6*bh bw bh]);
    c.boxBL =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Bottom Left',  'Position', [bp         plh-bp-7*bh bw bh]);
    c.boxBR =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Bottom Right', 'Position', [2*bp+bw    plh-bp-7*bh bw bh]);
    c.boxPrev = [-1 -1 0];	% [x,y,t] Previous vector [x,y] and type [t] for the box. Types - 0:empty, 1:TL, 2:TR, 3:BR, 4:BL
    c.boxCurr = [-1 -1 0];    % [x,y,t] Current vector [x,y] and type [t] for the box.
    c.boxX = [-1 -1 -1 -1 -1];   % Actual Box for graphing.
    c.boxY = [-1 -1 -1 -1 -1];   % Actual Box for graphing.
    
c.autoTab =         uitab(c.automationPanel, 'Title', 'Automation!');
%     c.autoText0 =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Define ranges for N and n: ',   'Position', [bp         plh-bp-3*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     
%     c.autoNXRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NX: ',   'Position', [bp         plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoNXRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-4*bh bw/2 bh]);
%     c.autoNXRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NX: ',   'Position', [2*bp+bw        plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoNXRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-4*bh bw/2 bh]);
%     
%     c.autoNYRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NY: ',   'Position', [bp         plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoNYRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-5*bh bw/2 bh]);
%     c.autoNYRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NY: ',   'Position', [2*bp+bw        plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoNYRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-5*bh bw/2 bh]);
% 
%     c.autonRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min n: ',     'Position', [bp         plh-bp-6*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autonRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,             'Position', [bp+bw/2    plh-bp-6*bh bw/2 bh]);
%     c.autonRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max n: ',     'Position', [2*bp+bw        plh-bp-6*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autonRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,             'Position', [2*bp+3*bw/2    plh-bp-6*bh bw/2 bh]);
% 
% 
% 
%     c.autoText =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input positions of 3 separate sister devices: ',   'Position', [bp         plh-bp-8*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     
%     c.autoV123nT =  uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'n123: ',   'Position', [bp         plh-bp-9*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV123n =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-9*bh bw/2 bh]);
%     
%     c.autoV1T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 1: ', 'Position', [bp         plh-bp-10*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     c.autoV1NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-11*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV1NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-11*bh bw/2 bh]);
%     c.autoV1NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-11*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV1NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-11*bh bw/2 bh]);
%     c.autoV1XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-12*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV1X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-12*bh bw/2 bh]);
%     c.autoV1YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-12*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV1Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-12*bh bw/2 bh]);
%     c.autoV1ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-13*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV1Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-13*bh bw/2 bh]);
%     c.autoV1Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-13*bh bw bh]);
% 
%     c.autoV2T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 2: ', 'Position', [bp         plh-bp-14*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     c.autoV2NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-15*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV2NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-15*bh bw/2 bh]);
%     c.autoV2NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-15*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV2NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-15*bh bw/2 bh]);
%     c.autoV2XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-16*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV2X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-16*bh bw/2 bh]);
%     c.autoV2YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-16*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV2Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-16*bh bw/2 bh]);
%     c.autoV2ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-17*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV2Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-17*bh bw/2 bh]);
%     c.autoV2Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-17*bh bw bh]);
% 
%     c.autoV3T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 3: ', 'Position', [bp         plh-bp-18*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     c.autoV3NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-19*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV3NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-19*bh bw/2 bh]);
%     c.autoV3NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-19*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV3NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-19*bh bw/2 bh]);
%     c.autoV3XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-20*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV3X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-20*bh bw/2 bh]);
%     c.autoV3YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-20*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV3Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-20*bh bw/2 bh]);
%     c.autoV3ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-21*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV3Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-21*bh bw/2 bh]);
%     c.autoV3Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-21*bh bw bh]);
% 
% 
%     c.autoText2 =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input position of a non-sister device: ',   'Position', [bp         plh-bp-23*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     
%     c.autoV4nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'n4: ',   'Position', [bp         plh-bp-24*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-24*bh bw/2 bh]);
%     
%     c.autoV4T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 4: ', 'Position', [bp         plh-bp-25*bh 2*bw bh],         'HorizontalAlignment', 'left');
%     c.autoV4NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-26*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-26*bh bw/2 bh]);
%     c.autoV4NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-26*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-26*bh bw/2 bh]);
%     c.autoV4XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-27*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-27*bh bw/2 bh]);
%     c.autoV4YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-27*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-27*bh bw/2 bh]);
%     c.autoV4ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-28*bh bw/2 bh],         'HorizontalAlignment', 'right');
%     c.autoV4Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-28*bh bw/2 bh]);
%     c.autoV4Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-28*bh bw bh]);
% 
%     c.autoTest =     uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Preview Path', 'Position', [bp	plh-bp-30*bh 2*bw+bp bh]);
%     c.autoButton =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Automate!', 'Position', [bp	plh-bp-31*bh 2*bw+bp bh]);
    


    c.autoText0 =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Define ranges for N and n: ',   'Position', [bp         plh-bp-3*bh 2*bw bh],         'HorizontalAlignment', 'left');
    
    c.autoNXRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NX: ',   'Position', [bp         plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoNXRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-4*bh bw/2 bh]);
    c.autoNXRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NX: ',   'Position', [2*bp+bw        plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoNXRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 3,            'Position', [2*bp+3*bw/2    plh-bp-4*bh bw/2 bh]);
    
    c.autoNYRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min NY: ',   'Position', [bp         plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoNYRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-5*bh bw/2 bh]);
    c.autoNYRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max NY: ',   'Position', [2*bp+bw        plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoNYRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 3,            'Position', [2*bp+3*bw/2    plh-bp-5*bh bw/2 bh]);

    c.autonRmT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Min n: ',     'Position', [bp         plh-bp-6*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autonRm =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,             'Position', [bp+bw/2    plh-bp-6*bh bw/2 bh]);
    c.autonRMT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Max n: ',     'Position', [2*bp+bw        plh-bp-6*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autonRM =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 6,             'Position', [2*bp+3*bw/2    plh-bp-6*bh bw/2 bh]);



    c.autoText =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input positions of 3 separate sister devices: ',   'Position', [bp         plh-bp-8*bh 2*bw bh],         'HorizontalAlignment', 'left');
    
    c.autoV123nT =  uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'n123: ',   'Position', [bp         plh-bp-9*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV123n =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-9*bh bw/2 bh]);
    
    c.autoV1T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 1: ', 'Position', [bp         plh-bp-10*bh 2*bw bh],         'HorizontalAlignment', 'left');
    c.autoV1NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-11*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV1NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plh-bp-11*bh bw/2 bh]);
    c.autoV1NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-11*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV1NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [2*bp+3*bw/2    plh-bp-11*bh bw/2 bh]);
    c.autoV1XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-12*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV1X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-12*bh bw/2 bh]);
    c.autoV1YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-12*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV1Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-12*bh bw/2 bh]);
    c.autoV1ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-13*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV1Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-13*bh bw/2 bh]);
    c.autoV1Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-13*bh bw bh]);

    c.autoV2T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 2: ', 'Position', [bp         plh-bp-14*bh 2*bw bh],         'HorizontalAlignment', 'left');
    c.autoV2NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-15*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV2NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 2,            'Position', [bp+bw/2    plh-bp-15*bh bw/2 bh]);
    c.autoV2NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-15*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV2NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [2*bp+3*bw/2    plh-bp-15*bh bw/2 bh]);
    c.autoV2XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-16*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV2X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 100,            'Position', [bp+bw/2    plh-bp-16*bh bw/2 bh]);
    c.autoV2YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-16*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV2Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plh-bp-16*bh bw/2 bh]);
    c.autoV2ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-17*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV2Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-17*bh bw/2 bh]);
    c.autoV2Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-17*bh bw bh]);

    c.autoV3T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 3: ', 'Position', [bp         plh-bp-18*bh 2*bw bh],         'HorizontalAlignment', 'left');
    c.autoV3NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-19*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV3NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plh-bp-19*bh bw/2 bh]);
    c.autoV3NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-19*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV3NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 2,            'Position', [2*bp+3*bw/2    plh-bp-19*bh bw/2 bh]);
    c.autoV3XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-20*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV3X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-20*bh bw/2 bh]);
    c.autoV3YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-20*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV3Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', -100,            'Position', [2*bp+3*bw/2    plh-bp-20*bh bw/2 bh]);
    c.autoV3ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-21*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV3Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-21*bh bw/2 bh]);
    c.autoV3Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-21*bh bw bh]);


    c.autoText2 =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input position of a non-sister device: ',   'Position', [bp         plh-bp-23*bh 2*bw bh],         'HorizontalAlignment', 'left');
    
    c.autoV4nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'n4: ',   'Position', [bp         plh-bp-24*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plh-bp-24*bh bw/2 bh]);
    
    c.autoV4T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 4: ', 'Position', [bp         plh-bp-25*bh 2*bw bh],         'HorizontalAlignment', 'left');
    c.autoV4NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plh-bp-26*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plh-bp-26*bh bw/2 bh]);
    c.autoV4NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plh-bp-26*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [2*bp+3*bw/2    plh-bp-26*bh bw/2 bh]);
    c.autoV4XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plh-bp-27*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 10,            'Position', [bp+bw/2    plh-bp-27*bh bw/2 bh]);
    c.autoV4YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plh-bp-27*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', -2,            'Position', [2*bp+3*bw/2    plh-bp-27*bh bw/2 bh]);
    c.autoV4ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (V): ',    'Position', [bp         plh-bp-28*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.autoV4Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-28*bh bw/2 bh]);
    c.autoV4Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plh-bp-28*bh bw bh]);

    c.autoTest =     uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Preview Path', 'Position', [bp	plh-bp-30*bh 2*bw+bp bh]);
    c.autoButton =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Automate!', 'Position', [bp	plh-bp-31*bh 2*bw+bp bh]);

% A list of all buttons to disable when a scan/etc is running.
c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

end





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
c.running = true;
c.xMax = 25000;
c.yMax = 25000;
c.zMax = 10;
c.linAct = [0 0];

% Helper variables for GUI setup ==========================================
global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
pw = 250;           % Panel Width, the width of the side panel
puh = 150;          % Upper Panel Height
pmh = 150;          % Middle Panel Height
plh = 250;          % Lower Panel Height

bp = 5;             % Button Padding
bw = (pw-4*bp)/2;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object

gp = 25;            % Graph  Padding

% IO ======================================================================
c.joy = 0;              % Empty variable for the joystick

c.joyButtonPrev = [0 0 0 0 0 0 0 0 0 0 0 0];   % Empty lists
c.joyPovPrev = [0 0];

c.joyXDir = 1;
c.joyYDir = -1;
c.joyZDir = 1;

c.joyXYPadding = .1;
c.joyZPadding = .25;

c.outputEnabled = 0;

c.microInit = 0;
c.microStep = .080; % 80 nm

c.micro = [0 0];
c.microActual = [0 0];

c.microXSerial = 0;     % Empty variable for the X micrometer serial connection
c.microXPort = 'COM17'; % This will be overwritten later (or should we define here?)
c.microXAddr = '1';

c.microYSerial = 0;     % Empty variable for the Y micrometer serial connection
c.microYPort = 'COM18'; % This will be overwritten later
c.microYAddr = '1';


c.devSPCM = 'Dev1';         % SPCM DEVice and CHaNnel
c.chnSPCM = 'ctr1';

c.devGalvo = 'cDAQ1Mod1';	% Galvo DEVice and CHaNnels
c.chnGalvoX = 'ao0';
c.chnGalvoX = 'ao1';

c.devPiezo = 'Dev1';        % Z Peizo DEVice and CHaNnels
c.chnPiezoZ = 'ao2';

c.piezoZ = 0;
c.piezoStep = .05;


% AXES ====================================================================
c.axesMode = 0;     % 0:Both, 1:Upper, 2:Lower
c.upperAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);
c.lowerAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);

% PANELS ==================================================================
c.ioPanel =         uitabgroup('Units', 'pixels');
c.microTab =       uitab(c.ioPanel, 'Title', 'Micrometers');
    % c.microText =   uicontrol('Parent', c.microTab, 'Style', 'text', 'String', 'Micrometers:', 'Position', [bp puh-bp-3*bh 2*bw bh]);    c.gotoXLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp        plh-bp-3*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.microXLabel = uicontrol('Parent', c.microTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp        puh-bp-3*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.microXX =     uicontrol('Parent', c.microTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2   puh-bp-3*bh bw/2 bh],    'Callback', @limit_Callback);
    c.microYLabel = uicontrol('Parent', c.microTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw     puh-bp-3*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.microYY =     uicontrol('Parent', c.microTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-3*bh bw/2 bh],    'Callback', @limit_Callback);
    c.microInit =   uicontrol('Parent', c.microTab, 'Style', 'pushbutton', 'String', 'Initiate!', 'Position', [bp puh-bp-5*bh bw bh]);
    c.microReset =  uicontrol('Parent', c.microTab, 'Style', 'pushbutton', 'String', 'Reset', 'Position', [2*bp+bw puh-bp-5*bh bw bh]);

    
%     c.galvoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Galvometers (nothing to see):', 'Position', [bp puh-bp-5*bh 2*bw bh]);
%     c.piezoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Peizos (nothing to see):', 'Position', [bp puh-bp-6*bh 2*bw bh]);

c.joyTab =          uitab(c.ioPanel, 'Title', 'Joystick!');
    c.joyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Joystick: Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp pmh-bp-3*bh bw bh]); 
    c.joyAxes =     axes('Parent', c.joyTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [bp+bw bp bw bw-bp]);
    
c.mouseKeyTab =     uitab(c.ioPanel, 'Title', 'Mouse/Key');
    c.mouseEnabled =    uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Mouse: Enable Click on Graph?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp pmh-bp-3*bh 2*bw bh]); 
    c.keyEnabled =      uicontrol('Parent', c.mouseKeyTab, 'Style', 'checkbox', 'String', 'Keyboard: Enable Arrow Keys?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp pmh-bp-4*bh 2*bw bh]); 

    
c.automationPanel = uitabgroup('Units', 'pixels');
c.gotoTab =         uitab(c.automationPanel, 'Title', 'Goto');
    c.gotoXLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp        plh-bp-3*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoX =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2   plh-bp-3*bh bw/2 bh]);
    c.gotoYLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [bp+bw     plh-bp-3*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoY =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+3*bw/2 plh-bp-3*bh bw/2 bh]);
    c.gotoActual =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Actual','Position', [2*bp+bw	plh-bp-5*bh bw bh]);
    c.gotoTarget =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [bp    plh-bp-5*bh bw bh]);
    c.gotoButton =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp        plh-bp-6*bh bp+2*bw bh]);

c.galvoTab =  uitab(c.automationPanel, 'Title', 'Galvo Scan');
    c.galvoRange =  5;      % 5 um
    c.galvoRangeMax =  50;  % 50 um
    c.galvoRLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp        plh-bp-3*bh bw bh],         'HorizontalAlignment', 'right');
    c.galvoR =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoRange,     'Position', [bp+bw   plh-bp-3*bh bw/2 bh]);
    c.galvoSpeed =  5; % 5 um/sec
    c.galvoSpeedMax =  50;  % 50 um/sec
    c.galvoSLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp        plh-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
    c.galvoS =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoSpeed,     'Position', [bp+bw   plh-bp-4*bh bw/2 bh]);
    c.galvoButton = uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Scan!','Position', [bp        plh-bp-6*bh bp+2*bw bh]);

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
    
c.automationTab =   uitab(c.automationPanel, 'Title', 'Automation!');


% A list of all buttons to disable when a scan/etc is running.
c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

end





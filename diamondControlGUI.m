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

% 'Global' Variables stored in the GUI object, in the style of Todd
c.running = true;
c.xMax = 25;
c.yMax = 25;
c.linAct = [0 0];

% Helper variables for GUI setup =====
global pw; global puh; global plh; global bp; global bw; global bh; global gp;
pw = 250;           % Panel Width, the width of the side panel
puh = 150;          % Upper Panel Height
plh = 250;          % Lower Panel Height

bp = 5;             % Button Padding
bw = (pw-4*bp)/2;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object

gp = 25;            % Graph  Padding

% AXES =====
c.axesMode = 0;     % 0:Both, 1:Upper, 2:Lower
c.upperAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);
c.lowerAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual'); %, 'ButtonDownFcn', @graphSwitch_Callback);

% PANEL ====
c.controlPanel =    uitabgroup('Units', 'pixels');
c.gotoTab =         uitab(c.controlPanel, 'Title', 'Goto');
    c.gotoXLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', ['X (0-' num2str(c.xMax) ' mm): '], 'Position', [bp puh-bp-3*bh bw bh], 'HorizontalAlignment', 'right');
    c.gotoX =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0, 'Position', [2*bp+bw puh-bp-3*bh bw bh], 'Callback', @limit_Callback);
    c.gotoYLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', ['Y (0-' num2str(c.xMax) ' mm): '], 'Position', [bp puh-bp-4*bh bw bh], 'HorizontalAlignment', 'right');
    c.gotoY =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0, 'Position', [2*bp+bw puh-bp-4*bh bw bh], 'Callback', @limit_Callback);
    c.gotoButton =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!', 'Position', [bp puh-bp-6*bh bp+2*bw bh]);

c.mouseTab =     uitab(c.controlPanel, 'Title', 'Mouse');
    c.mouseEnabled = uicontrol('Parent', c.mouseTab, 'Style', 'checkbox', 'String', 'Enable Click on Graph?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh 2*bw bh]); 

c.keyTab =     uitab(c.controlPanel, 'Title', 'Keyboard');
    c.keyEnabled = uicontrol('Parent', c.keyTab, 'Style', 'checkbox', 'String', 'Enable Arrow Keys?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh 2*bw bh]); 

c.joystickTab =     uitab(c.controlPanel, 'Title', 'Joystick!');
    c.joystickEnabled = uicontrol('Parent', c.joystickTab, 'Style', 'checkbox', 'String', 'Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh 2*bw bh]); 

c.automationPanel = uitabgroup('Units', 'pixels');
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
    
c.galvoTab =  uitab(c.automationPanel, 'Title', 'Galvo Scan');

c.automationTab =   uitab(c.automationPanel, 'Title', 'Automation!');


% A list of all buttons to disable when a scan/etc is running.
c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

% UI-only functions =====
    function limit_Callback(hObject, ~)
        val = str2double(get(hObject, 'String'));
        
        if isnan(val) % ~isa(val,'double') % If it's NaN, check if it's an equation
            try
                val = eval(get(hObject,'String'));
            catch
                val = 0;
            end
        end
        
        if isnan(val)   % If it's still NaN, set to zero
            val = 0;
        end
        
        if val < 0      % Apply limits
            val = 0;
        else
            if      hObject == c.gotoX && val > c.xMax
                val = c.xMax;
            elseif  hObject == c.gotoY && val > c.yMax
                val = c.yMax;
            end
        end
        
        set(hObject, 'String', val);
    end
end





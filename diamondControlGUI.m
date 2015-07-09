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

% Helper variables for GUI setup =====
pw = 250;           % Panel Width, the width of the side panel
puh = 150;          % Upper Panel Height
plh = 250;          % Lower Panel Height

bp = 5;             % Button Padding
bw = (pw-4*bp)/2;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object

gp = 25;            % Graph  Padding

% We do resizing programatically =====
set(c.parent, 'ResizeFcn', @resizeUI_Callback);

% AXES =====
c.axesMode = 0;     % 0:Both, 1:Upper, 2:Lower
c.upperAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual',      'ButtonDownFcn', @graphSwitch_Callback);
c.lowerAxes = axes('Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual',  'ButtonDownFcn', @graphSwitch_Callback);

% PANEL ====
c.controlPanel =    uitabgroup('Units', 'pixels');
c.gotoTab =         uitab(c.controlPanel, 'Title', 'Goto');
    c.gotoXLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', ['X (0-' num2str(c.xMax) ' mm): '], 'Position', [bp puh-bp-3*bh bw bh], 'HorizontalAlignment', 'right');
    c.gotoX =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0, 'Position', [2*bp+bw puh-bp-3*bh bw bh], 'Callback', @limit_Callback);
    c.gotoYLabel =  uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', ['Y (0-' num2str(c.xMax) ' mm): '], 'Position', [bp puh-bp-4*bh bw bh], 'HorizontalAlignment', 'right');
    c.gotoY =       uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0, 'Position', [2*bp+bw puh-bp-4*bh bw bh], 'Callback', @limit_Callback);
    c.gotoButton =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!', 'Position', [bp puh-bp-6*bh bp+2*bw bh]);

c.keymouseTab =     uitab(c.controlPanel, 'Title', 'Keyboard/Mouse');
    c.keymouseEnabled = uicontrol('Parent', c.keymouseTab, 'Style', 'checkbox', 'String', 'Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh bw bh]); 

c.joystickTab =     uitab(c.controlPanel, 'Title', 'Joystick!');
    c.joystickEnabled = uicontrol('Parent', c.joystickTab, 'Style', 'checkbox', 'String', 'Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh bw bh]); 

c.automationPanel = uitabgroup('Units', 'pixels');
c.boxTab =          uitab(c.automationPanel, 'Title', 'Set Box');
    c.boxInfo =     uicontrol('Parent', c.boxTab, 'Style', 'text', 'String', 'This draws a box on the screen, depending upon the given points.', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plh-bp-4*bh 2*bw 2*bh]);
    c.boxLabel =    uicontrol('Parent', c.boxTab, 'Style', 'text', 'String', 'Save Current Position As...', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plh-bp-5*bh 2*bw bh]);
    c.boxTL =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Top Left',     'Position', [bp         plh-bp-6*bh bw bh]);
    c.boxTR =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Top Right',    'Position', [2*bp+bw    plh-bp-6*bh bw bh]);
    c.boxBL =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Bottom Left',  'Position', [bp         plh-bp-7*bh bw bh]);
    c.boxBR =       uicontrol('Parent', c.boxTab, 'Style', 'pushbutton', 'String', 'Bottom Right', 'Position', [2*bp+bw    plh-bp-7*bh bw bh]);
    c.boxPrev = [0 0 0];	% Previous vector and type for the box. Types - 0:empty, 1:TL, 2:TR, 3:BR, 4:BL
    c.boxCurr = [0 0 0];    % Current vector and type for the box.
    c.boxX = [0 0 0 0 0];
    c.boxY = [0 0 0 0 0];
    
c.galvoTab =  uitab(c.automationPanel, 'Title', 'Galvo Scan');

c.automationTab =   uitab(c.automationPanel, 'Title', 'Automation!');


% A list of all buttons to disable when a scan/etc is running.
c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

% After everything is done, make the figure visible.
set(c.parent, 'Visible', 'on');

% UI-only functions =====
    function limit_Callback(hObject, ~)
        val = str2double(get(hObject,'String'));
        
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

    function graphSwitch_Callback(hObject, ~)
        if c.axesMode == 0
            if hObject == c.upperAxes
                c.axesMode = 1;
                set(c.lowerAxes, 'Visible', 'Off');
            else
                c.axesMode = 2;
                set(c.upperAxes, 'Visible', 'Off');
            end
        else
            c.axesMode = 0;
            set(c.upperAxes, 'Visible', 'On');
            set(c.lowerAxes, 'Visible', 'On');
        end

        resizeUI_Callback();
    end

    function resizeUI_Callback(~, ~)
        p = get(c.parent, 'Position');
        w = p(3); h = p(4);

        % Axes Position =====
        if c.axesMode == 0 % Both
            if (w-pw-2*gp < (h-3*gp)/2) % If Width is limiting
                S = w-pw-2*gp;
                set(c.lowerAxes,    'Position', [gp ((h/4)-(S/2)) S S]);
                set(c.upperAxes,    'Position', [gp ((3*h/4)-(S/2)) S S]);
            else                        % If Height is limiting
                S = (h-3*gp)/2;
                set(c.lowerAxes,    'Position', [(w-pw-S)/2 gp S S]);
                set(c.upperAxes,    'Position', [(w-pw-S)/2 2*gp+S S S]);
            end
        else
            if (w-pw-2*gp < h-2*gp)     % If Width is limiting
                S = w-pw-2*gp;
            else                        % If Height is limiting
                S = h-2*gp;
            end

            if c.axesMode == 1  % Upper only
                set(c.upperAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
            else                % Lower only
                set(c.lowerAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
            end
        end

        % Panel Position =====
        set(c.controlPanel,     'Position', [w-pw h-puh pw puh]);
        set(c.automationPanel,  'Position', [w-pw h-puh-plh pw plh]);
    end
end
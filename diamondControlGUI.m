function c = diamondControlGUI(varargin)

display('  Making GUI');

% Helper variables for GUI setup ==========================================
global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
pw = 250;           % Panel Width, the width of the side panel
puh = 180;          % Upper Panel Height
plh = 700;          % Lower Panel Height

bp = 5;             % Button Padding
bw = pw/2 - 2*bp;   % Button Width, the width of a button/object
bh = 18;            % Button Height, the height of a button/object
plhi = plh - 2*bh;  % Inner Lower Panel Height

psh = 3.5*bh;         % Scale figure height

gp = 25;            % Graph  Padding

c = diamondControlVars();

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
    screensize = get( groot, 'Screensize' );
    c.parent = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none', 'Resize', 'off', 'Position', [screensize(1)-pw, 0, pw, puh+plh+2*bp+bh]);
end

set(c.parent, 'defaulttextinterpreter', 'latex');


% AXES ====================================================================
display('  Making Axes');
set(gcf,'Renderer','Zbuffer');

c.videoEnabled = 0;
c.hImage = 0;

% Add popout figures here.
% c.upperFigure =     0;
% c.lowerFigure =     0;
% c.imageFigure =     0;
% c.pleFigure =       0;
% c.bluefbFigure =    0;

c.upperFigure =     figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'Grid Figure', 'Name', 'Grid Figure', 'Toolbar', 'figure', 'Menubar', 'none');
c.lowerFigure =     figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'Data Figure', 'Name', 'Data Figure', 'Toolbar', 'figure', 'Menubar', 'none');
c.counterFigure =   figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'Counter Figure', 'Name', 'Counter Figure', 'Toolbar', 'figure', 'Menubar', 'none');
c.imageFigure =     figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'Blue Image Figure', 'Name', 'Blue Image Figure', 'Toolbar', 'figure', 'Menubar', 'none');
c.pleFigure =       figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'PLE Figure', 'Name', 'PLE Figure', 'Toolbar', 'figure', 'Menubar', 'none');
c.bluefbFigure =    figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'SizeChangedFcn', @resizeUISmall_Callback, 'tag', 'Blue Disk Detection Figure', 'Name', 'Blue Disk Detection Figure', 'Toolbar', 'figure', 'Menubar', 'none');
% c.scaleFigure =     figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'Resize', 'off', 'tag', 'Scale Figure', 'Name', 'Scale Figure', 'Toolbar', 'figure', 'Menubar', 'none', 'Position', [screensize(1)-pw, 0, pw, puh+plh+2*bp+bh]);
% minfig(c.pleFigure, 1); % ple figure starts minimized

c.scaleFigure =     figure('Visible', 'Off', 'CloseRequestFcn', @closeRequestMinimize, 'Resize', 'off', 'tag', 'Scale Figure', 'Name', 'Scale Figure', 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Position', [100, 100, pw, psh+2*bp+bh]);

c.axesMode =    0;     % CURRENT -> 0:Regular, 1:PLE    OLD -> 0:Both, 1:Upper, 2:Lower 'Units', 'pixels', 
c.upperAxes =   axes('Parent', c.upperFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [0 0 1 1]); %, 'PickableParts', 'all');
c.lowerAxes =   axes('Parent', c.lowerFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [.05 .05 .9 .9]); %, 'PickableParts', 'all');
c.lowerAxes3D = axes('Parent', c.lowerFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [.05 .05 .9 .9], 'Visible', 'Off'); %, 'PickableParts', 'all');
c.globalSaveButton =  uicontrol('Parent', c.lowerFigure, 'Style', 'pushbutton', 'String', 'Save','Position', [bp bp bw bh]);
c.piezoSwitchTo3DButton =  uicontrol('Parent', c.lowerFigure, 'Style', 'pushbutton', 'String', 'View 3D','Position', [2*bp+bw bp bw bh], 'Visible', 'Off');
c.piezo3DMenu =  uicontrol('Parent', c.lowerFigure, 'Style', 'popupmenu', 'String', 'View 3D','Position', [3*bp+2*bw bp bw bh], 'Visible', 'Off');
c.piezo3DPlus =  uicontrol('Parent', c.lowerFigure, 'Style', 'pushbutton', 'String', '+','Position', [4*bp+3*bw bp bh bh], 'Visible', 'Off');
c.piezo3DMinus = uicontrol('Parent', c.lowerFigure, 'Style', 'pushbutton', 'String', '-','Position', [5*bp+3*bw+bh bp bh bh], 'Visible', 'Off');
c.piezo3DEnabled = 0;

% AXES FOR VARIOUS FIGURES ==========
c.imageAxes =   axes('Parent', c.imageFigure,  'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [0 0 1 1]); %, 'PickableParts', 'all');
c.bluefbAxes =  axes('Parent', c.bluefbFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [0 0 1 1]); %, 'PickableParts', 'all');

c.counterAxes = axes('Parent', c.counterFigure,'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [.1 0 .9 .95]); %, 'PickableParts', 'all');
c.counterButton = uicontrol('Parent', c.counterFigure, 'Style', 'pushbutton', 'String', 'Start','Position', [bp bp bw bh]);
c.counterScaleMode = uicontrol('Parent', c.counterFigure, 'Style', 'checkbox', 'String', 'Keep zero in view', 'Value', 1, 'Position', [bp bp+bh bw bh]);
set(c.counterAxes, 'FontSize', 24);
ylabel(c.counterAxes, 'Counts (cts/sec)', 'FontSize', 24);
            
c.pleAxesSum =  axes('Parent', c.pleFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'On', 'Position', [0 0 1 .2]);
c.pleAxesOne =  axes('Parent', c.pleFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'On', 'Position', [0 .2 1 .2]);
c.pleAxesAll =  axes('Parent', c.pleFigure, 'XLimMode', 'manual', 'YLimMode', 'manual', 'Visible', 'On', 'Position', [0 .4 1 .6]);

% SCALE FIGURE ==========
defMin = '2.0e0';   % Default min and max values.
defMax = '2.0e0';

c.scaleMinText =    uicontrol('Parent', c.scaleFigure, 'Style', 'text', 'String', 'Min:', 'Units', 'pixels', 'Position', [bp,psh,bw/4,bh], 'HorizontalAlignment', 'right');
c.scaleMinEdit =    uicontrol('Parent', c.scaleFigure, 'Style', 'edit', 'String', defMin, 'Units', 'pixels', 'Position', [2*bp+bw/4,psh,bw/2,bh]); %, 'Enable', 'Inactive');
c.scaleMinSlid =    uicontrol('Parent', c.scaleFigure, 'Style', 'slider', 'Value', str2double(defMin), 'Min', 0, 'Max', str2double(defMin), 'Units', 'pixels', 'Position', [3*bp+3*bw/4,psh,5*bw/4,bh], 'SliderStep', [2/300, 2/30]); % Instert reasoning for 2/3

c.scaleMaxText =    uicontrol('Parent', c.scaleFigure, 'Style', 'text', 'String', 'Max:', 'Units', 'pixels', 'Position', [bp,psh-bh,bw/4,bh], 'HorizontalAlignment', 'right');
c.scaleMaxEdit =    uicontrol('Parent', c.scaleFigure, 'Style', 'edit', 'String', defMax, 'Units', 'pixels', 'Position', [2*bp+bw/4,psh-bh,bw/2,bh]); %, 'Enable', 'Inactive');
c.scaleMaxSlid =    uicontrol('Parent', c.scaleFigure, 'Style', 'slider', 'Value', str2double(defMax), 'Min', 0, 'Max', str2double(defMax), 'Units', 'pixels', 'Position', [3*bp+3*bw/4,psh-bh,5*bw/4,bh], 'SliderStep', [2/300, 2/30]);
% uicontrol('Parent', c.scaleFigure, 'Style', 'slider', 'Units', 'pixels', 'Position', [bp,psh,bw,bh]);

c.scaleDataMinText = uicontrol('Parent', c.scaleFigure, 'Style', 'text', 'String', 'Data Min:', 'Units', 'pixels', 'Position', [2*bp+bw,psh-2*bh,bw/2,bh], 'HorizontalAlignment', 'right');
c.scaleDataMinEdit = uicontrol('Parent', c.scaleFigure, 'Style', 'edit', 'String', defMin, 'Units', 'pixels', 'Position', [3*bp+3*bw/2,psh-2*bh,bw/2,bh], 'Enable', 'Inactive');

c.scaleDataMaxText = uicontrol('Parent', c.scaleFigure, 'Style', 'text', 'String', 'Data Max:', 'Units', 'pixels', 'Position', [2*bp+bw,psh-3*bh,bw/2,bh], 'HorizontalAlignment', 'right');
c.scaleDataMaxEdit = uicontrol('Parent', c.scaleFigure, 'Style', 'edit', 'String', defMax, 'Units', 'pixels', 'Position', [3*bp+3*bw/2,psh-3*bh,bw/2,bh], 'Enable', 'Inactive');

c.scaleNormAuto =    uicontrol('Parent', c.scaleFigure, 'Value', 1, 'Style', 'checkbox',   'String', 'Auto Normalize', 'Units', 'pixels', 'Position', [bp,psh-2*bh,1.1*bw,bh]);
c.scaleNorm =        uicontrol('Parent', c.scaleFigure, 'Style', 'pushbutton', 'String', 'Normalize', 'Units', 'pixels', 'Position', [bp,psh-3*bh,1.1*bw,bh]);

function closeRequestHide(src, ~)
    set(src, 'Visible', 'Off');
end

function closeRequestMinimize(src, ~)
%     minfig(src, 1);
    
    ratio = [500 500];

    if src == c.imageFigure || src == c.bluefbFigure
        ratio = [640 480];
    end
    if src == c.scaleFigure
        pos = get(src, 'Position');
        ratio = [pos(3) pos(4)];
    end
    
    set(src, 'Position', [100 100 ratio(1) ratio(2)]);
end

function resizeUISmall_Callback(hObject, ~)
    set(0, 'units', 'pixels'); 
    screen = get(0, 'screensize');
    
    p = get(hObject, 'Position');
    w = p(3); h = p(4);

    ratio = [50 50];

    if hObject == c.imageFigure || hObject == c.bluefbFigure
        ratio = [64 48];
    end
    
    % pleFigure does not care at the moment;
    
    if hObject ~= c.pleFigure && hObject ~= c.counterFigure
        if w < h*ratio(1)/ratio(2)  % Make the figure larger to fit the ratio
            w = h*ratio(1)/ratio(2);
        else
            h = w*ratio(2)/ratio(1);
        end
        
        toobig = max([w/screen(3) h/screen(4)]);
        
        if toobig > 1
            w = w/toobig; 
            h = h/toobig;
        end
        
        set(hObject, 'Position', [p(1) p(2) w h]);
    end
end


%c.upperAxes2 =   axes('Parent', c.upperFigure, 'XLimMode', 'manual', 'YLimMode', 'manual');
%c.lowerAxes2 =   axes('Parent', c.lowerFigure, 'XLimMode', 'manual', 'YLimMode', 'manual');
%c.counterAxes2 = axes('Parent', c.counterFigure, 'XLimMode', 'manual', 'YLimMode', 'manual');
% c.imageAxes2 =   axes('XLimMode', 'manual', 'YLimMode', 'manual');

% PANELS ==================================================================
display('  Making Panels');
c.globalStopButton= uicontrol('Parent', c.parent, 'Style', 'pushbutton', 'String', 'Global Stop','Position', [2*bp bp 2*bw+1 bh]);
c.globalStop = false;

c.ioPanel =         uitabgroup('Parent', c.parent, 'Units', 'pixels', 'Position', [0 plh+bh+bp pw puh]);    % This panel contains information about the microscope, and, for the most part, is not directly related to data aquisition.
    c.outputTab =       uitab(c.ioPanel, 'Title', 'Outputs');       % This tab contains the status of our major degrees of freedom: micrometer x,y; piezo x,y,z; and galvo x,y.
    c.joyTab =          uitab(c.ioPanel, 'Title', 'Inputs');        % This tab is called 'joyTab' for legacy reasons.
    c.mouseKeyTab =     uitab(c.ioPanel, 'Title', 'Calibration');   % This naming is obscure for legacy reasons.
    c.saveTab =         uitab(c.ioPanel, 'Title', 'Saving');        % This naming is obscure for legacy reasons.

c.automationPanel = uitabgroup('Parent', c.parent, 'Units', 'pixels', 'Position', [0 2*bp+bh pw plh]);
    c.gotoTab =         uitab('Parent', c.automationPanel, 'Title', 'Goto');
    
    c.scanningTab =     uitab('Parent', c.automationPanel, 'Title', 'Scan');
        c.scanningPanel =   uitabgroup('Parent', c.scanningTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);
            c.piezoTab =    uitab('Parent', c.scanningPanel, 'Title', 'Piezo');
            c.galvoTab =    uitab('Parent', c.scanningPanel, 'Title', 'Galvo');
            c.spectraTab =  uitab('Parent', c.scanningPanel, 'Title', 'Spectra');
            c.powerTab =    uitab('Parent', c.scanningPanel, 'Title', 'Power');
            
    c.automationTab =   uitab('Parent', c.automationPanel, 'Title', 'Automation!');
        c.autoPanel =   uitabgroup('Parent', c.automationTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);
            c.autoTabC =    uitab('Parent', c.autoPanel, 'Title', 'Controls');
            c.autoTab =     uitab('Parent', c.autoPanel, 'Title', 'Grid');
            c.autoTabT =    uitab('Parent', c.autoPanel, 'Title', 'Tasks');
            
    c.pleTab =          uitab(c.automationPanel, 'Title', 'PLE!');
        c.plePanel =    uitabgroup('Parent', c.pleTab, 'Units', 'pixels', 'Position', [0 0 pw plhi]);
            c.pleScanTab =  uitab('Parent', c.plePanel, 'Title', 'PLE Scan');
            c.pleSimpleTab= uitab('Parent', c.plePanel, 'Title', 'PLE Scan Simple');
            c.perotScanTab= uitab('Parent', c.plePanel, 'Title', 'Perot Scan');

            
% The following variables help construct the interface:
c.tabs = [c.outputTab, c.joyTab, c.mouseKeyTab, c.saveTab, ...
          c.piezoTab, c.galvoTab, c.spectraTab, c.powerTab, ...
          c.autoTabC, c.autoTab, c.autoTabT, ...
          c.pleScanTab, c.pleSimpleTab, c.perotScanTab, ...
          c.gotoTab];

leftHeight =    3*ones(1,length(c.tabs));    % Variables containing the number of elements already added to this column...
rghtHeight =    3*ones(1,length(c.tabs));    % ...This prevents overlap.

numUpper =          length(get(c.ioPanel, 'Children'));     % This variable helps the program know what hieght a tab should have. This is neccessary because matlab has a coordinate system from the lower left, yet we want to construct our interface from the upper right.
numLowerInside =    length(get(c.scanningTab, 'Children')) + length(get(c.automationTab, 'Children')) + length(get(c.pleTab, 'Children'));

% The following functions are helper functions to construct the interface.
%  - identifier(tab) assigns a number to each tab object, depending upon
%  the position of the tab in the c.tabs list. 
%  - space(tab, position) returns the proper height for an element to be
%  added to a tab and incriments the stored value of the height for that
%  tab.
%  - makeControl(...) actually makes the button, using space(...) to find
%  the proper hieght so previously-added buttons are not overlapped.
% function identifier = tabIdentifier(tab)
%     if isnumeric(tab)
%         identifier = tab;
%     else
%         identifier = dot((c.tabs == tab)*1, 1:length(c.tabs));
%     end
% end
% 
% function prevHeight = space(tab, position)
%     identifier = tabIdentifier(tab);
%         
%     switch position
%         case 'left'
%             prevHeight = leftHeight(identifier);
%             leftHeight(identifier) =    prevHeight + 1;
%         case 'right'
%             prevHeight = rghtHeight(identifier);
%             rghtHeight(identifier) =    prevHeight + 1;
%         otherwise
%             prevHeight = max(leftHeight(tabIdentifier(tab)), rghtHeight(tabIdentifier(tab)));
%             leftHeight(identifier) =    prevHeight + 1;
%             rghtHeight(identifier) =    prevHeight + 1;
%     end
%     
%     if identifier <= numUpper
%         ph = puh;
%     elseif identifier <= numUpper + numLowerInside
%         ph = plhi;
%     else
%         ph = plh;
%     end
%     
%     prevHeight = ph-bp-prevHeight*bh;
% end
% 
% % Unfinished!
% function control = makeControl(tab, style, position, label, value, active)
%     identifier = tabIdentifier(tab);
%     
%     if identifier <= numUpper
%         ph = puh;
%     elseif identifier <= numUpper + numLowerInside
%         ph = plhi;
%     else
%         ph = plh;
%     end
%     
%     switch style
%         case 'edit'
%             hgt = ph-bp-space(identifier, position)*bh;
%             
%             switch position
%                 case 'left'
%                     positionArray =         [2*bp+bw/2    hgt   bw/2    bh];
%                     positionArrayLabel =    [1*bp         hgt   bw/2    bh];
%                 case 'right'
%                     positionArray =         [4*bp+3*bw/2  hgt   bw/2    bh];
%                     positionArrayLabel =    [3*bp+bw      hgt   bw/2    bh];
%                 otherwise  % centered
%                     positionArray =         [3*bp+bw      hgt   bw/2    bh];
%                     positionArrayLabel =    [2*bp+bw/2    hgt   bw/2    bh];
%             end
% 
%             labelH =  uicontrol('Parent', tab, 'Style', 'text', 'String', label, 'Position', positionArrayLabel,    'HorizontalAlignment', 'right');
%             control = uicontrol('Parent', tab, 'Style', 'edit', 'String', value, 'Position', positionArray,         'Enable', active);
%             
%         case {'text', 'checkbox'}
%             hgt = ph-bp-space(identifier, position)*bh;
%             
%             switch position
%                 case 'left'
%                     positionArray =     [bp         hgt bw bh];
%                 case 'right'
%                     positionArray =     [3*bp+bw    hgt bw bh];
%                 otherwise  % centered
%                     positionArray =     [bp         hgt 2*bw bh];
%             end
%             
%             if strcmp(position, 'center')
%                 control = uicontrol('Parent', tab, 'Style', style, 'String', label, 'Position', positionArray,    'HorizontalAlignment', 'center');
%             else
%                 control = uicontrol('Parent', tab, 'Style', style, 'String', label, 'Position', positionArray,    'HorizontalAlignment', 'left');
%             end
%             
%         case 'button'
%             hgt = ph-bp-space(identifier, position)*bh;
%             
%             switch position
%                 case 'left'
%                     positionArray =     [bp         hgt bw bh];
%                 case 'right'
%                     positionArray =     [3*bp+bw    hgt bw bh];
%                 case 'widecentered'
%                     positionArray =     [bp         hgt 2*bw bh];
%                 otherwise  % centered
%                     positionArray =     [2*bp+bw/2  hgt bw bh];
%             end
% 
%             control = uicontrol('Parent', tab, 'Style', style, 'String', value, 'Position', positionArray,  'Enable', active);     
%     end
% end

% OUTPUT TAB ==========  
     c.microText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Micrometers:', 'Position',[bp      puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
     c.microXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp       puh-bp-4*bh bw/2 bh],	'HorizontalAlignment', 'right');
     c.microXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-4*bh bw/2 bh],  'Enable', 'inactive');
     c.microYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [bp       puh-bp-5*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.microYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-5*bh bw/2 bh],  'Enable', 'inactive');
     
     c.piezoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Piezos:', 'Position',    [2*bp+2*bw/2 puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
     c.piezoZLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Z (um): ',   'Position',  [2*bp+2*bw/2 puh-bp-4*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.piezoZZ =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-4*bh bw/2 bh],  'Enable', 'inactive');
     c.piezoXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (um): ',   'Position',  [2*bp+2*bw/2 puh-bp-5*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.piezoXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-5*bh bw/2 bh],  'Enable', 'inactive');
     c.piezoYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (um): ',   'Position',  [2*bp+2*bw/2 puh-bp-6*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.piezoYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-6*bh bw/2 bh],  'Enable', 'inactive');
     
     c.galvoText =   uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Galvos:', 'Position',    [bp       puh-bp-7*bh bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
     c.galvoXLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'X (mV): ',   'Position', [bp       puh-bp-8*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.galvoXX =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-8*bh bw/2 bh],  'Enable', 'inactive');
     c.galvoYLabel = uicontrol('Parent', c.outputTab, 'Style', 'text', 'String', 'Y (mV): ',   'Position', [bp       puh-bp-9*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.galvoYY =     uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [bp+bw/2  puh-bp-9*bh bw/2 bh],  'Enable', 'inactive');
     
     c.m_zero='';
     c.setText =     uicontrol('Parent', c.outputTab, 'Style', 'text','String', 'Set: ',   'Position',  [2*bp+2*bw/2 puh-bp-8*bh bw/2 bh],  'HorizontalAlignment', 'right');
     c.set_no =      uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-8*bh bw/2 bh],  'Enable', 'inactive');
     c.set_mark =    uicontrol('Parent', c.outputTab, 'Style', 'pushbutton', 'String', 'Mark [0,0]','Position', [2*bp+3*bw/2 puh-bp-9*bh bw/2 bh],'ForegroundColor', 'magenta');
  
% % Right Column ---------
%     c.microText =   makeControl(c.outputTab, 'text', 'left', 'Micrometers:');
%     set(c.microText, 'ForegroundColor', 'red');
%     c.microXX =     makeControl(c.outputTab, 'edit', 'left', 'X (um):', 'N/A', 'inactive');
%     c.microYY =     makeControl(c.outputTab, 'edit', 'left', 'Y (um):', 'N/A', 'inactive');
%     
%     space(c.outputTab, 'left');
%     c.galvoText =   makeControl(c.outputTab, 'text', 'left', 'Galvos:');
%     set(c.microText, 'ForegroundColor', 'red');
%     c.microXX =     makeControl(c.outputTab, 'edit', 'left', 'X (um):', 'N/A', 'inactive');
%     c.microYY =     makeControl(c.outputTab, 'edit', 'left', 'Y (um):', 'N/A', 'inactive');
%      
% % Left Column ---------
%     c.piezoText =   makeControl(c.outputTab, 'text', 'right', 'Piezos:');
%     set(c.piezoText, 'ForegroundColor', 'red');
%     c.piezoXX =     makeControl(c.outputTab, 'edit', 'right', 'X (um):', 'N/A', 'inactive');
%     c.piezoYY =     makeControl(c.outputTab, 'edit', 'right', 'Y (um):', 'N/A', 'inactive');
%     c.piezoZZ =     makeControl(c.outputTab, 'edit', 'right', 'Z (um):', 'N/A', 'inactive');
% 
%     space(c.outputTab, 'right');
%     space(c.outputTab, 'right');
%     space(c.outputTab, 'right');
% %     c.m_zero='';
% %     c.setText =     uicontrol('Parent', c.outputTab, 'Style', 'text','String', 'Set: ',   'Position',  [2*bp+2*bw/2 puh-bp-8*bh bw/2 bh],  'HorizontalAlignment', 'right');
% %     c.set_no =      uicontrol('Parent', c.outputTab, 'Style', 'edit', 'String', 'N/A',        'Position', [2*bp+3*bw/2 puh-bp-8*bh bw/2 bh],  'Enable', 'inactive');
% %     c.set_mark =    uicontrol('Parent', c.outputTab, 'Style', 'pushbutton', 'String', 'Mark [0,0]','Position', [2*bp+3*bw/2 puh-bp-9*bh bw/2 bh],'ForegroundColor', 'magenta');
% 
%     c.set_no =      makeControl(c.outputTab, 'edit', 'right', 'Set:', 'N/A', 'inactive');
%     c.set_mark =    makeControl(c.outputTab, 'button', 'right', 'Mark [0,0]');
%     set(c.set_mark, 'ForegroundColor', 'magenta');

% JOY TAB ===========
    c.joyModeText = uicontrol('Parent', c.joyTab, 'Style', 'text', 'String', 'Mode:', 'Position',[bp puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left');
%     c.joyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Joystick: Enabled?', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-3*bh bw bh]); 
%     c.joyAxes =     axes('Parent', c.joyTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position', [bp+bw bp bw bw-bp]);
    c.joyMode =     uibuttongroup('Parent', c.joyTab, 'Units', 'pixels', 'Position', [bp puh-bp-7*bh bw 4*bh]);
    c.joyMicro =    uicontrol('Parent', c.joyMode, 'Style', 'radiobutton', 'String', 'Micro', 'Position', [bp bp+2.5*bh bw bh]);
    c.joyPiezo =    uicontrol('Parent', c.joyMode, 'Style', 'radiobutton', 'String', 'Piezo', 'Position', [bp bp+1.5*bh bw bh]);
    c.joyGalvo =    uicontrol('Parent', c.joyMode, 'Style', 'radiobutton', 'String', 'Galvo', 'Position', [bp bp+0.5*bh bw bh]);
    
    c.joyModeText2= uicontrol('Parent', c.joyTab, 'Style', 'text', 'String', 'Inputs:', 'Position',[bp+bw+bp puh-bp-3*bh bw bh],	'HorizontalAlignment', 'left');
    c.joyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Joystick',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp+bw+bp puh-bp-4*bh 2*bw bh]); 
    c.keyEnabled =  uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Keyboard',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp+bw+bp puh-bp-5*bh 2*bw bh]); 
    c.mouseEnabled= uicontrol('Parent', c.joyTab, 'Style', 'checkbox', 'String', 'Mouse', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp+bw+bp puh-bp-6*bh 2*bw bh]); 

% MOUSEKEY TAB ===========

% c.saveTab =         uitab(c.ioPanel, 'Title', 'Save');
%     c.saveBlue =    uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp      plh-bp-9*bh bw bh]);
%     c.saveUpper =   uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp      plh-bp-9*bh bw bh]);
%     c.saveLower =   uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp      plh-bp-9*bh bw bh]);

%c.mX = 0.0959868; %default calibration performed on Aug 22 2015
%c.mY = 0.0959868; %default calibration performed on Aug 22 2015

%c.pX = 0.018868;  %default calibration performed on Aug 22 2015
%c.pY = 0.018868;  %default calibration performed on Aug 22 2015

    c.calibText =   uicontrol('Parent', c.mouseKeyTab, 'Style', 'text', 'String', 'Perform Calibration:', 'Position',[bp puh-bp-6*bh 2*bw bh],	'HorizontalAlignment', 'left', 'ForegroundColor', 'red');
    c.microCalib =  uicontrol('Parent', c.mouseKeyTab, 'Style', 'pushbutton', 'String', 'Cal Micro','Position', [bp puh-bp-7*bh 2*bw bh]);
    c.piezoCalib =  uicontrol('Parent', c.mouseKeyTab, 'Style', 'pushbutton', 'String', 'Cal Piezo','Position', [bp puh-bp-8*bh 2*bw bh]);
    c.calibStat =   uicontrol('Parent', c.mouseKeyTab, 'Style', 'text', 'String', 'Staus: Idle', 'Position',[bp puh-bp-9*bh 2*bw bh],	'HorizontalAlignment', 'center');
    
% SAVE TAB ===========
    c.saveBackgroundLabel  =  uicontrol('Parent', c.saveTab, 'Style', 'text', 'String', 'Background Saving Directory: ', 'Position', [bp             puh-bp-3*bh 2*bw bh],    'HorizontalAlignment', 'left');
    c.saveBackgroundDirectory=uicontrol('Parent', c.saveTab, 'Style', 'edit', 'String', c.directoryBackground,           'Position', [bp             puh-bp-4*bh 3*bw/2 bh],  'HorizontalAlignment', 'left');
    c.saveBackgroundChoose =  uicontrol('Parent', c.saveTab, 'Style', 'pushbutton', 'String', 'Choose',       'Position', [2*bp+3*bw/2    puh-bp-4*bh bw/2 bh]);
    
    c.saveLabel  =  uicontrol('Parent', c.saveTab, 'Style', 'text', 'String', 'Manual Saving Directory: ', 'Position', [bp             puh-bp-5*bh 2*bw bh],    'HorizontalAlignment', 'left');
    c.saveDirectory=uicontrol('Parent', c.saveTab, 'Style', 'edit', 'String', c.directory,                 'Position', [bp             puh-bp-6*bh 3*bw/2 bh],  'HorizontalAlignment', 'left');
    c.saveChoose =  uicontrol('Parent', c.saveTab, 'Style', 'pushbutton', 'String', 'Choose',       'Position', [2*bp+3*bw/2    puh-bp-6*bh bw/2 bh]);
    
% GOTO TAB ==========
    c.gotoMLabel  = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Micrometers: ',   'Position', [bp plh-bp-3*bh bw bh],         'HorizontalAlignment', 'left');
    c.gotoMXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp      plh-bp-4*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoMX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2 plh-bp-4*bh bw/2 bh]);
    c.gotoMYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [bp      plh-bp-5*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoMY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2 plh-bp-5*bh bw/2 bh]);
    c.gotoMReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset','Position', [bp      plh-bp-6*bh bw bh]);
    c.gotoMActual = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Actual','Position', [bp plh-bp-7*bh bw bh]);
    c.gotoMTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [bp plh-bp-8*bh bw bh]);
    c.gotoMButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto! (um)','Position', [bp      plh-bp-9*bh bw bh]);
  
    c.gotoM = [c.gotoMX c.gotoMY c.gotoMActual c.gotoMTarget c.gotoMButton];
     
%     c.gotoSet_txt = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Move to Set: (micro)',   'Position', [bp         plh-bp-18*bh bw bh], 'HorizontalAlignment', 'left');
    c.gotoSXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (set): ',   'Position', [bp         plh-bp-10*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoSX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-10*bh bw/2 bh]);
    c.gotoSYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (set): ',   'Position', [bp         plh-bp-11*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoSY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-11*bh bw/2 bh]);
    c.gotoSButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto! (set)','Position', [bp         plh-bp-12*bh bw bh]);

    c.rsttoset0 = uicontrol('Parent', c.gotoTab, 'Style', 'checkbox', 'String', 'Goto [0 0] on Exit','Position', [bp         plh-bp-13*bh 2*bw bh],'Value', 0);
    
    c.gotoGLabel  = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Galvos: ',   'Position', [bp         plh-bp-15*bh bw bh],         'HorizontalAlignment', 'left');
    c.gotoGXLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'X (mV): ',   'Position', [bp         plh-bp-16*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoGX =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-16*bh bw/2 bh]);
    c.gotoGYLabel = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Y (mV): ',   'Position', [bp         plh-bp-17*bh bw/2 bh],         'HorizontalAlignment', 'right');
    c.gotoGY =      uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plh-bp-17*bh bw/2 bh]);
    c.gotoGReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset','Position', [bp	plh-bp-20*bh bw bh]);
    c.gotoGOpt =    uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize','Position', [bp	plh-bp-21*bh bw bh]);
    c.gotoGTarget = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Get Target','Position', [bp	plh-bp-18*bh bw bh]);
    c.gotoGButton = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto!','Position', [bp         plh-bp-19*bh bw bh]);
  
    c.gotoM = [c.gotoGX c.gotoGY c.gotoGReset c.gotoGTarget c.gotoGButton];
    
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
    c.gotoPReset =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Reset XY','Position',      [2*bp+bw    plh-bp-9*bh bw bh]);
    c.gotoPFocus =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Focus','Position',         [2*bp+bw    plh-bp-10*bh bw bh]);
    c.gotoPOptXY =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize XY','Position',   [2*bp+bw    plh-bp-11*bh bw bh]);
    c.gotoPOptZ =   uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize Z','Position',    [2*bp+bw    plh-bp-12*bh bw bh]);
    c.gotoPOptAll = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Optimize All','Position',    [2*bp+bw    plh-bp-13*bh bw bh]);
  
    c.gotoP = [c.gotoPX c.gotoPY c.gotoPZ c.gotoPFocus c.gotoPReset c.gotoPMaximize c.gotoPTarget c.gotoPButton];
           
    c.go_mouse_control_txt = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Use Mouse Control: ',   'Position', [bp plh-bp-23*bh 2*bw bh],'HorizontalAlignment', 'center');
   
    c.laser_offset = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Set Laser Offset','Position', [bp	plh-bp-24*bh bw bh]);
    c.laser_offset_x_disp = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'OX(pix): - ',   'Position',  [bp	plh-bp-25*bh bw bh],         'HorizontalAlignment', 'left');
    c.laser_offset_y_disp = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'OY(pix): - ',   'Position',  [bp+bw	plh-bp-25*bh bw bh],         'HorizontalAlignment', 'left');
    
    c.go_mouse =         uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto MouseClick!','Position', [2*bp	plh-bp-27*bh 2*bw bh]);
    c.go_mouse_fine =    uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Goto MouseClick Fine (Piezo)!','Position', [2*bp	plh-bp-28*bh 2*bw bh]);
    
    %Capture blue image
    c.capture_text = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Capture Blue Image','Position', [bp	plh-bp-30*bh bw bh],  'HorizontalAlignment', 'left');
    c.capture_blue = uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'Start Capture','Position', [2*bp+bw	plh-bp-30*bh bw bh]);
    c.capture_interval_text = uicontrol('Parent', c.gotoTab, 'Style', 'text', 'String', 'Interval(s):','Position', [bp	plh-bp-31*bh bw bh],'HorizontalAlignment', 'left');
    c.capture_interval = uicontrol('Parent', c.gotoTab, 'Style', 'edit', 'String', 10,'Position', [2*bp+bw	plh-bp-31*bh bw bh]);
    
    %Micro abort and reset
    c.micro_rst_txt1 = uicontrol('Parent', c.gotoTab, 'Style', 'text','String', 'Use ONLY if Micrometers stop responding:',   'Position', [2*bp plh-bp-33*bh 2*bw bh],         'HorizontalAlignment', 'center');
    c.micro_rst_txt2 = uicontrol('Parent', c.gotoTab, 'Style', 'text','String', '(Status LED is blinking ORANGE!!)',   'Position', [2*bp plh-bp-34*bh 2*bw bh],         'HorizontalAlignment', 'center');
    c.micro_rst_x =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'RST X','Position', [2*bp plh-bp-35*bh bw bh]);
    c.micro_rst_y =  uicontrol('Parent', c.gotoTab, 'Style', 'pushbutton', 'String', 'RST Y','Position', [2*bp+bw plh-bp-35*bh bw bh]);
    c.micro_rst_txt3 = uicontrol('Parent', c.gotoTab, 'Style', 'text','String', 'Will RST to [22,22] mm',   'Position', [2*bp plh-bp-36*bh 2*bw bh],         'HorizontalAlignment', 'center');
    
    
% SCANNING TAB ===========
        % PIEZO TAB ==========
            c.piezo3DLabel= uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', '2D Confocal:',            'Position', [bp plhi-bp-3*bh bw bh],	'HorizontalAlignment', 'left');
            c.piezoRLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp      plhi-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoR =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoRange,     'Position', [bp+bw   plhi-bp-4*bh bw/2 bh]);
            c.piezoSLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp      plhi-bp-5*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoS =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoSpeed,     'Position', [bp+bw   plhi-bp-5*bh bw/2 bh]);
            c.piezoPLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Pixels (num/side): ', 'Position', [bp plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoP =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', c.piezoPixels,     'Position', [bp+bw  plhi-bp-6*bh bw/2 bh]);
            
            c.piezoZStartLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Z begin (um): ', 'Position', [bp plhi-bp-8*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZStart =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 10,     'Position', [bp+bw        plhi-bp-8*bh bw/2 bh]);
            c.piezoZStopLabel =  uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Z end (um): ', 'Position', [bp   plhi-bp-9*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZStop =       uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 20,     'Position', [bp+bw        plhi-bp-9*bh bw/2 bh]);
            c.piezoZStepLabel =  uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Z steps (num): ', 'Position',[bp plhi-bp-10*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZStep =       uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 1,     'Position', [bp+bw         plhi-bp-10*bh bw/2 bh]);
            
            c.piezoCLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Colormap: ', 'Position', [bp          plhi-bp-12*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoC =      uicontrol('Parent', c.piezoTab, 'Style', 'popupmenu', 'String', {'gray', 'jet'}, 'Position', [bp+bw   plhi-bp-12*bh bw/2 bh]);
            
            c.piezoButton = uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Scan!','Position', [bp        plhi-bp-14*bh bp+2*bw bh]);

            c.piezoOptimize =uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Optimize','Position', [bp        plhi-bp-15*bh bp+2*bw bh]);

            c.piezoScanning = false;
            
            c.piezo1DLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', '1D Linear Optimization:', 'Position', [bp plhi-bp-17*bh bw bh],	'HorizontalAlignment', 'left');
            
            c.piezoXYLabel =  uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'XY Settings:',            'Position', [bp plhi-bp-18*bh bw bh],	'HorizontalAlignment', 'left');
            c.piezoXYRLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp      plhi-bp-19*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoXYR =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', .5,     'Position', [bp+bw   plhi-bp-19*bh bw/2 bh]);
            c.piezoXYSLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Scan Length (s): ', 'Position', [bp      plhi-bp-20*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoXYS =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 1,     'Position', [bp+bw   plhi-bp-20*bh bw/2 bh]);
            c.piezoXYPLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Pixels (num): ', 'Position', [bp plhi-bp-21*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoXYP =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 500,     'Position', [bp+bw  plhi-bp-21*bh bw/2 bh]);
            
            c.piezoZLabel =  uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Z Settings:',        'Position', [bp      plhi-bp-22*bh bw bh],	'HorizontalAlignment', 'left');
            c.piezoZRLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Range (um): ',       'Position', [bp     plhi-bp-23*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZR =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 2,                    'Position', [bp+bw  plhi-bp-23*bh bw/2 bh]);
            c.piezoZSLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String', 'Scan Length (s): ',  'Position', [bp     plhi-bp-24*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZS =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 1,                    'Position', [bp+bw  plhi-bp-24*bh bw/2 bh]);
            c.piezoZPLabel = uicontrol('Parent', c.piezoTab, 'Style', 'text', 'String','Pixels (num): ',      'Position', [bp     plhi-bp-25*bh bw bh],         'HorizontalAlignment', 'right');
            c.piezoZP =      uicontrol('Parent', c.piezoTab, 'Style', 'edit', 'String', 500,                  'Position', [bp+bw  plhi-bp-25*bh bw/2 bh]);
            
            c.piezoOptimizeX = uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Optimize X','Position', [bp plhi-bp-27*bh bp+2*bw bh]);
            c.piezoOptimizeY = uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Optimize Y','Position', [bp plhi-bp-28*bh bp+2*bw bh]);
            c.piezoOptimizeZ = uicontrol('Parent', c.piezoTab, 'Style', 'pushbutton', 'String', 'Optimize Z','Position', [bp plhi-bp-29*bh bp+2*bw bh]);

            
        % GALVO TAB ==========
            c.galvo3DLabel= uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', '2D Confocal:',            'Position', [bp plhi-bp-3*bh bw bh],	'HorizontalAlignment', 'left');
            c.galvoRLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Range (um): ',   'Position', [bp        plhi-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoR =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoRange,     'Position', [bp+bw   plhi-bp-4*bh bw/2 bh]);
            c.galvoSLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Speed (um/s): ', 'Position', [bp        plhi-bp-5*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoS =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoSpeed,     'Position', [bp+bw   plhi-bp-5*bh bw/2 bh]);
            c.galvoPLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Pixels (num/side): ', 'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoP =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', c.galvoPixels,     'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);    
            c.galvoCLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Colormap: ', 'Position', [bp        plhi-bp-7*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoC =      uicontrol('Parent', c.galvoTab, 'Style', 'popupmenu', 'String', {'gray', 'jet'},     'Position', [bp+bw   plhi-bp-7*bh bw/2 bh]);
            c.galvoButton = uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Scan!','Position', [bp        plhi-bp-9*bh bp+2*bw bh]);

            c.galvoOptimize =uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Optimize','Position', [bp        plhi-bp-10*bh bp+2*bw bh]);

            c.galvoAlignX = uicontrol('Parent', c.galvoTab, 'Style', 'togglebutton', 'String', 'Sweep X','Position', [bp        plhi-bp-11*bh bw bh]);
            c.galvoAlignY = uicontrol('Parent', c.galvoTab, 'Style', 'togglebutton', 'String', 'Sweep Y','Position', [2*bp+bw   plhi-bp-11*bh bw bh]);

            c.galvoAligning = false;
            c.galvoScanning = false;
            
            c.galvo1DLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', '1D Linear Optimization:', 'Position', [bp plhi-bp-13*bh bw bh],	'HorizontalAlignment', 'left');
            
            c.galvoXYLabel =  uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'XY Settings:',      'Position', [bp plhi-bp-14*bh bw bh],	'HorizontalAlignment', 'left');
            c.galvoXYRLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Range (mV): ',      'Position', [bp      plhi-bp-15*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoXYR =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', 50,                  'Position', [bp+bw   plhi-bp-15*bh bw/2 bh]);
            c.galvoXYSLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Scan Length (s): ', 'Position', [bp      plhi-bp-16*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoXYS =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', 1,                   'Position', [bp+bw   plhi-bp-16*bh bw/2 bh]);
            c.galvoXYPLabel = uicontrol('Parent', c.galvoTab, 'Style', 'text', 'String', 'Pixels (num): ',    'Position', [bp plhi-bp-17*bh bw bh],         'HorizontalAlignment', 'right');
            c.galvoXYP =      uicontrol('Parent', c.galvoTab, 'Style', 'edit', 'String', 500,                 'Position', [bp+bw  plhi-bp-17*bh bw/2 bh]);
            
            c.galvoOptimizeX = uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Optimize X','Position', [bp plhi-bp-19*bh bp+2*bw bh]);
            c.galvoOptimizeY = uicontrol('Parent', c.galvoTab, 'Style', 'pushbutton', 'String', 'Optimize Y','Position', [bp plhi-bp-20*bh bp+2*bw bh]);

%         c.counterTab =  uitab('Parent', c.scanningPanel, 'Title', 'Counter');
%             c.counterButton = uicontrol('Parent', c.counterTab, 'Style', 'checkbox', 'String', 'Count?', 'Position', [bp plhi-bp-3*bh bp+2*bw bh], 'HorizontalAlignment', 'left', 'Enable', 'off');
%             c.sC = 0;       % Empty variable for the counter channel;
%             c.lhC = 0;      % Empty variable for counter listener;
%             c.dataC = [];   % Empty variable for counter data;
%             c.rateC = 4;    % rate: scans/sec
%             c.lenC = 100;  % len:  scans/graph
%             c.iC = 0;
%             c.prevCount = 0;
%             c.isCounting = 0;

        % SPECTRA TAB ==========
            c.spectrumButton = uicontrol('Parent', c.spectraTab, 'Style', 'pushbutton', 'String', 'Take Spectrum', 'Position', [bp plhi-bp-3*bh bp+2*bw bh]);
        
        % POWER TAB ==========
            c.powerValue = uicontrol('Parent', c.powerTab, 'Style', 'edit', 'String', '0', 'Position', [bp plhi-bp-3*bh bp+2*bw bh]);
            c.powerButton = uicontrol('Parent', c.powerTab, 'Style', 'pushbutton', 'String', 'Get Power', 'Position', [bp plhi-bp-4*bh bp+2*bw bh]);

% AUTOMATION TAB ==========
        % CONTROLS ----------
            c.autoPreview =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton','String', 'Preview Path', 'Position', [bp	plhi-bp-3*bh 2*bw+bp bh]);
            c.autoTest =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Test Path', 'Position', [bp	plhi-bp-4*bh 2*bw+bp bh]);
            c.autoButton =  uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Automate!', 'Position', [bp	plhi-bp-6*bh 2*bw+bp bh]);
            c.autoAutoProceed = uicontrol('Parent', c.autoTabC, 'Style', 'checkbox', 'String', 'Auto Proceed', 'Position', [bp	plhi-bp-8*bh bw bh], 'Value', 1, 'HorizontalAlignment', 'left');
            c.autoProceed = uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Proceed!', 'Position', [2*bp+bw	plhi-bp-8*bh bw bh]);
            c.proceed = false;  % Variable for whether to proceed or not.
            c.autoSkip =    uicontrol('Parent', c.autoTabC, 'Style', 'pushbutton',   'String', 'Skip', 'Position', [bp	plhi-bp-9*bh 2*bw+bp bh]);
            c.autoScanning = false;
            c.autoSkipping = false;
            % c.autoBlueEnable = uicontrol('Parent', c.autoTabC, 'Style', 'checkbox', 'String', 'Blue Feedback Enabled', 'Position', [bp	plhi-bp-12*bh 2*bw bh], 'Value', 1, 'HorizontalAlignment', 'left');

            
        % GRID ----------
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
            c.autoV123n =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV123nyT =  uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny123: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV123ny =   uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
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
            c.autoV1ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (um): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
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
            c.autoV2ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (um): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
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
            c.autoV3ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (um): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV3Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV3Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+2;
            
            
            c.autoText2 =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Input position of 2 non-sister devices: ',   'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV4T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 4: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV4nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'nx: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4nyT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4ny =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
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
            c.autoV4ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (um): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV4Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV4Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+1;
            
            
            c.autoV5T =     uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Device 5: ', 'Position', [bp         plhi-bp-k*bh 2*bw bh],         'HorizontalAlignment', 'left');
            k = k+1;
            
            c.autoV5nT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'nx: ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5n =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5nyT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'ny: ',   'Position', [2*bp+bw         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5ny =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 1,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            
            c.autoV5NXT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NX: ',       'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5NX =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5NYT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'NY: ',       'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5NY =    uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV5XT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'X (um): ',   'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5X =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 10,           'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5YT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Y (um): ',   'Position', [2*bp+bw        plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5Y =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 4,           'Position', [2*bp+3*bw/2    plhi-bp-k*bh bw/2 bh]);
            k = k+1;
            c.autoV5ZT =    uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'Z (um): ',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoV5Z =     uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0,            'Position', [bp+bw/2    plhi-bp-k*bh bw/2 bh]);
            c.autoV5Get =   uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw	plhi-bp-k*bh bw bh]);
            k = k+1;
            c.autoDiskT =   uicontrol('Parent', c.autoTab, 'Style', 'text', 'String', 'T (0-1):',    'Position', [bp         plhi-bp-k*bh bw/2 bh],         'HorizontalAlignment', 'right');
            c.autoDiskThresh = uicontrol('Parent', c.autoTab, 'Style', 'edit', 'String', 0.25,       'Position', [bp+bw/2    plhi-bp-k*bh bw/3 bh]);
            c.autoDiskDet = uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Detect', 'Position', [bp+bw	plhi-bp-k*bh bw/2 bh]);
            c.autoDiskClr = uicontrol('Parent', c.autoTab, 'Style', 'pushbutton', 'String', 'Clear', 'Position', [bp+3*bw/2	plhi-bp-k*bh bw/2 bh]);
            k=k+1;
            c.autoDiskInv = uicontrol('Parent', c.autoTab, 'Style', 'checkbox', 'String', 'Inv', 'Position', [bp	plhi-bp-k*bh bw bh], 'Value', 1, 'HorizontalAlignment', 'left');

        % TASKS ----------
            c.autoTaskOptT =     uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Optimization:', 'Position', [bp        plhi-bp-3*bh 2*bw bh],         'HorizontalAlignment', 'left');
            
            c.autoTaskNumRepeatT = uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Linear Optimization #: ',   'Position', [bp        plhi-bp-4*bh bw bh],         'HorizontalAlignment', 'right');
            c.autoTaskNumRepeat  = uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 2,     'Position', [bp+bw   plhi-bp-4*bh bw/2 bh]);
            
            c.autoTaskGalvoI = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Initial Galvo',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-5*bh bw bh]); 
            c.autoTaskPiezoI = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Initial Piezo',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [2*bp+bw plhi-bp-5*bh bw bh]); 
            c.autoTaskDiskI = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Blue Disk Feedback',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-6*bh bw bh]); 
            c.autoTaskFocus = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Autofocus', 'HorizontalAlignment', 'left', 'Value', 1, 'Position', [2*bp+bw plhi-bp-6*bh bw bh]); 
            
%             c.autoTaskReset = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Reset piezos and galvos?',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp puh-bp-4*bh 2*bw bh]); 
            
            c.autoTaskTaskT =     uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Tasks:', 'Position', [bp        plhi-bp-8*bh 2*bw bh],         'HorizontalAlignment', 'left');
            c.autoTaskBlue = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Blue Image',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-9*bh bw bh]); 
            c.autoTaskGalvo = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Final Galvo',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [2*bp+bw plhi-bp-9*bh bw bh]); 
            c.autoTaskSpectrum = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Spectrum',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-10*bh bw bh]); 
            c.autoTaskPower = uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Record Powers',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [2*bp+bw plhi-bp-10*bh bw bh]); 
                        
            c.autoTaskTaskT =   uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Spectra at Different Galvo Positions:', 'Position', [bp plhi-bp-12*bh 2*bw bh],         'HorizontalAlignment', 'left');
            
            c.autoTaskG2XT =    uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'G2X (mV): ',   'Position', [bp         plhi-bp-13*bh bw/2 bh], 'HorizontalAlignment', 'right');
            c.autoTaskG2X =     uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 0,              'Position', [bp+bw/2    plhi-bp-13*bh bw/2 bh]);
            c.autoTaskG2YT =    uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'G2Y (mV): ',   'Position', [bp         plhi-bp-14*bh bw/2 bh], 'HorizontalAlignment', 'right');
            c.autoTaskG2Y =     uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 0,              'Position', [bp+bw/2    plhi-bp-14*bh bw/2 bh]);
            c.autoTaskG2S =     uicontrol('Parent', c.autoTabT, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [bp plhi-bp-15*bh bw bh]);
            
            c.autoTaskG3XT =    uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'G3X (mV): ',   'Position', [2*bp+bw         plhi-bp-13*bh bw/2 bh], 'HorizontalAlignment', 'right');
            c.autoTaskG3X =     uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 0,              'Position', [2*bp+3*bw/2     plhi-bp-13*bh bw/2 bh]);
            c.autoTaskG3YT =    uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'G3Y (mV): ',   'Position', [2*bp+bw         plhi-bp-14*bh bw/2 bh], 'HorizontalAlignment', 'right');
            c.autoTaskG3Y =     uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', 0,              'Position', [2*bp+3*bw/2     plhi-bp-14*bh bw/2 bh]);
            c.autoTaskG3S =     uicontrol('Parent', c.autoTabT, 'Style', 'pushbutton', 'String', 'Set As Current', 'Position', [2*bp+bw plhi-bp-15*bh bw bh]);
            
            c.autoTaskNameT =   uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Setup:', 'Position', [bp        plhi-bp-17*bh 2*bw bh],         'HorizontalAlignment', 'left');
            c.autoTaskRow =     uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Devices in Rows',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-18*bh bw bh]);
            
            c.autoTaskListT =   uicontrol('Parent', c.autoTabT, 'Style', 'text', 'String', 'Whitelist:',  'HorizontalAlignment', 'left', 'Value', 1, 'Position', [bp plhi-bp-20*bh bw bh]);
            c.autoTaskListBrowse = uicontrol('Parent', c.autoTabT, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [2*bp+bw plhi-bp-21*bh bw bh], 'Callback', @autoTaskListBrowse_Callback);
            c.autoTaskWB =      uicontrol('Parent', c.autoTabT, 'Style', 'checkbox', 'String', 'Enabled?',  'HorizontalAlignment', 'left', 'Value', 0, 'Position', [bp plhi-bp-21*bh bw bh]); 
            c.autoTaskList =    uicontrol('Parent', c.autoTabT, 'Style', 'edit', 'String', '', 'Position', [bp plhi-bp-22*bh 2*bw+bp bh]);
            
    function autoTaskListBrowse_Callback(~,~)
        [filename, pathname, ~] = uigetfile('*.txt;*.xls;*.xlsx', 'Select the White/Black listing file');
        
        if isequal(filename,0)
           disp('User selected Cancel');
        else
           set(c.autoTaskList, 'String', fullfile(pathname, filename));
        end
    end
            
% PLE ==========
        % SCAN ==========
            c.pleCont =       uicontrol('Parent', c.pleScanTab, 'Style', 'togglebutton', 'String', 'Scan Continuous', 'Position', [bp       plhi-bp-3*bh    bw bh], 'Callback', @pleCall); 
            % c.pleOnce =       uicontrol('Parent', c.pleScanTab, 'Style', 'pushbutton',   'String', 'Scan Once',       'Position', [2*bp+bw  plhi-bp-3*bh    bw bh], 'Callback', @pleOnceCall, 'Enable', 'Off'); 
            c.axesSide =      axes(     'Parent', c.pleScanTab, 'Units', 'pixels', 'Position', [5*bp       plhi-bp-9*bh-bw    2*bw-6*bp bw]);
            set(c.axesSide, 'FontSize', 6);
            c.pleDebug =      uicontrol('Parent', c.pleScanTab, 'Style', 'checkbox',     'String', 'Debug Mode?',  'HorizontalAlignment', 'left', 'Position', [bp plhi-bp-4*bh 2*bw bh]); 
            c.pleSave =       uicontrol('Parent', c.pleScanTab, 'Style', 'pushbutton',     'String', 'Save',         'Position', [bp plhi-bp-5*bh 2*bw bh]);
            c.pleSpeedT =     uicontrol('Parent', c.pleScanTab, 'Style', 'text', 'String', 'Length (sec): ', 'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.pleSpeed =      uicontrol('Parent', c.pleScanTab, 'Style', 'edit', 'String', 1,     'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);
            c.pleScansT =     uicontrol('Parent', c.pleScanTab, 'Style', 'text', 'String', 'Scans (num): ', 'Position', [bp        plhi-bp-7*bh bw bh],         'HorizontalAlignment', 'right');
            c.pleScans =      uicontrol('Parent', c.pleScanTab, 'Style', 'edit', 'String', c.perotLength*(c.upScans + c.downScans),     'Position', [bp+bw   plhi-bp-7*bh bw/2 bh]);
            
        % SIMPLE ==========
            c.pleContSimple =       uicontrol('Parent', c.pleSimpleTab, 'Style', 'togglebutton', 'String', 'Scan Continuous', 'Position', [bp       plhi-bp-3*bh   2*bw bh], 'Callback', @pleCall); 
            c.pleSaveSimple =       uicontrol('Parent', c.pleSimpleTab, 'Style', 'pushbutton',     'String', 'Save',            'Position', [bp plhi-bp-4*bh 2*bw bh]);
            c.pleSpeedSimpleT =     uicontrol('Parent', c.pleSimpleTab, 'Style', 'text', 'String', 'Length (sec): ',            'Position', [bp        plhi-bp-6*bh bw bh],         'HorizontalAlignment', 'right');
            c.pleSpeedSimple =      uicontrol('Parent', c.pleSimpleTab, 'Style', 'edit', 'String', 1,                           'Position', [bp+bw   plhi-bp-6*bh bw/2 bh]);
            c.pleBinsSimpleT =      uicontrol('Parent', c.pleSimpleTab, 'Style', 'text', 'String', 'Bins per Length (num): ',   'Position', [bp        plhi-bp-7*bh bw bh],         'HorizontalAlignment', 'right');
            c.pleBinsSimple =       uicontrol('Parent', c.pleSimpleTab, 'Style', 'edit', 'String', 1000,                        'Position', [bp+bw   plhi-bp-7*bh bw/2 bh]);
            c.pleScansSimpleT =     uicontrol('Parent', c.pleSimpleTab, 'Style', 'text', 'String', 'Scans per Bin (num): ',     'Position', [bp        plhi-bp-8*bh bw bh],         'HorizontalAlignment', 'right');
            c.pleScansSimple =      uicontrol('Parent', c.pleSimpleTab, 'Style', 'edit', 'String', 8,                           'Position', [bp+bw   plhi-bp-8*bh bw/2 bh]);
            
        % PEROT =========
            c.perotCont =     uicontrol('Parent', c.perotScanTab, 'Style', 'togglebutton', 'String', 'Scan Continuous', 'Position', [bp plhi-bp-3*bh bw bh], 'Callback', @perotCall); 
            c.perotHzOutT =   uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', 'Linewidth:', 'HorizontalAlignment', 'left',  'Position', [bp plhi-bp-4*bh 2*bw bh]); 
            c.perotHzOut =    uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', ' --- ', 'HorizontalAlignment', 'left',  'Position', [bp plhi-bp-8*bh 2*bw 4*bh], 'FontSize', 24); 
            c.perotFsrOut =   uicontrol('Parent', c.perotScanTab, 'Style', 'text',         'String', 'FSR:  ---', 'HorizontalAlignment', 'left',        'Position', [bp plhi-bp-9*bh 2*bw bh]); 
            c.perotRampOn =   uicontrol('Parent', c.perotScanTab, 'Style', 'checkbox',     'String', 'Ramp?', 'HorizontalAlignment', 'left',            'Position', [bp plhi-bp-10*bh 2*bw bh]); 
            c.perotSpeedT =   uicontrol('Parent', c.perotScanTab, 'Style', 'text', 'String', 'Ramp Speed: ', 'Position', [bp        plhi-bp-11*bh bw bh],         'HorizontalAlignment', 'right');
            c.perotSpeed =    uicontrol('Parent', c.perotScanTab, 'Style', 'edit', 'String', 1,     'Position', [bp+bw   plhi-bp-11*bh bw/2 bh]);
            
% A list of all buttons to disable when a scan/etc is running.
% c.everything = [c.boxTL c.boxTR c.boxBL c.boxBR]; 

c.trackTab =           uitab(c.automationPanel, 'Title', 'Tracking');
 %    c.ratevid = 0.2;     % vid update rate /sec
    % c.trk_min = 2;
%     c.ratetrack = 50;  % tracking corrections / sec
%     c.vid_on=0; c.seldisk=0;
%     c.roi='';
%     c.roi_pad=30;      %ROI padding of 30 pixels on each side of the disk
%     
%     c.start_vid =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', ' Start',                   'Position',[2*bp plhi-bp-2*bh bw bh]);  
%     c.stop_vid =       uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Stop!',                    'Position',[2*bp+bw plhi-bp-2*bh bw bh]);
%     
%     c.trk_gain_txt =   uicontrol('Parent', c.trackTab, 'Style', 'text',       'String', 'Gain:', 'Position',[bp/2 plhi-bp-18*bh bw/2 bh]);  
%     c.trk_gain =       uicontrol('Parent', c.trackTab, 'Style', 'edit', 'String', 0.8,     'Position', [bp/2+bw/2 plhi-bp-18*bh bw/3 bh]);

     c.trk_min_txt =    uicontrol('Parent', c.trackTab, 'Style', 'text', 'String', 'MinAdj (Pix):', 'Position',[bp/2+bw plhi-bp-4*bh 2*bw/3 bh]);  
     c.trk_min =        uicontrol('Parent', c.trackTab, 'Style', 'edit', 'String', 2,               'Position', [bp/2+bw+2*bw/3 plhi-bp-4*bh bw/3 bh]);
     
         
     c.ratevid_txt =    uicontrol('Parent', c.trackTab, 'Style', 'text', 'String', 'Rate(/sec):', 'Position',[bp/2+bw plhi-bp-5*bh 2*bw/3 bh]);  
     c.ratevid =        uicontrol('Parent', c.trackTab, 'Style', 'edit', 'String', 0.2,           'Position', [bp/2+bw+2*bw/3 plhi-bp-5*bh bw/3 bh]);
     
     c.gain_txt =       uicontrol('Parent', c.trackTab, 'Style', 'text', 'String', 'Gain (0-1):', 'Position',[bp/2+bw plhi-bp-6*bh 2*bw/3 bh]);  
     c.trk_gain =       uicontrol('Parent', c.trackTab, 'Style', 'edit', 'String', 0.9,           'Position', [bp/2+bw+2*bw/3 plhi-bp-6*bh bw/3 bh]);
%     
%     c.track_clear =    uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Clear',                    'Position',[2*bp plhi-bp-20*bh bw bh]);
%     c.track_set =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', 'Stabilize Disk',           'Position',[2*bp+bw plhi-bp-20*bh bw bh]);
    
%     c.start_vid =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', ' Start',                   'Position',[2*bp plhi-bp-2*bh bw bh]);  

c.start_newTrack =      uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', ' Start', 'Position',[2*bp plhi-bp-2*bh bw bh]);  
c.stop_newTrack =       uicontrol('Parent', c.trackTab, 'Style', 'pushbutton', 'String', ' Stop',  'Position',[2*bp+bw plhi-bp-2*bh bw bh]);  
%c.track_stat =     uicontrol('Parent', c.trackTab, 'Style', 'text',       'String', 'Status: Nothing selected', 'Position',[bp plhi-bp-4*bh 2*bw bh]);  
     
%     c.track_Axes =     axes('Parent', c.trackTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position',[bp plhi-bp-14*bh bp+2*bw 2*bw]);
%     c.roi_Axes=        axes('Parent', c.trackTab, 'Units', 'pixels', 'XLimMode', 'manual', 'YLimMode', 'manual', 'Position',[bp plhi-bp-34*bh bp+2*bw 2*bw]);

    
display('  Finished...');
end





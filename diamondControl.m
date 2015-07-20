% This is the main fucntion of the DiamondControl program. It provides an
% interface for controlling the automated setup of optospinlab's QIP
% project. This interface includes:
%  - joystick/mouse/keyboard control of linear actuators for X and Y 
%    movement over a sample,
%  - the ability to XY scan the exitiation beam with Galvometers while
%    collecting from the same spot,
%  - control of the peizo stage for precise Z (and soon XY) positioning, and
%  - (soon) basic automation protocols for preforming simple testing.
function varargout = diamondControl(varargin)
    if isempty(varargin)    % If no variables have been given, make the figure
        f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');
        c = diamondControlGUI('Parent', f);
    else                    % Otherwise pass the variables on.
        c = diamondControlGUI(varargin);
    end
    
    % Helper Global variables for UI construction
    global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
    
    
    % CALLBACKS ===========================================================
    set(c.parent, 'WindowKeyPressFcn', @figure_WindowKeyPressFcn);
    set(c.parent, 'CloseRequestFcn', @closeRequest);
    
%     set(c.boxTL, 'Callback', @box_Callback);
%     set(c.boxTR, 'Callback', @box_Callback);
%     set(c.boxBL, 'Callback', @box_Callback);
%     set(c.boxBR, 'Callback', @box_Callback);
    
    % Goto Fields ---------------------------------------------------------
    set(c.gotoMX, 'Callback', @limit_Callback);
    set(c.gotoMY, 'Callback', @limit_Callback);
    set(c.gotoPX, 'Callback', @limit_Callback);
    set(c.gotoPY, 'Callback', @limit_Callback);
    set(c.gotoPZ, 'Callback', @limit_Callback);
    set(c.gotoGX, 'Callback', @limit_Callback);
    set(c.gotoGY, 'Callback', @limit_Callback);
    set(c.galvoS, 'Callback', @limit_Callback);
    set(c.galvoR, 'Callback', @range_Callback);
    
    set(c.gotoMButton, 'Callback', @goto_Callback);
    set(c.gotoMActual, 'Callback', @gotoActual_Callback);
    set(c.gotoMTarget, 'Callback', @gotoTarget_Callback);
    set(c.gotoMReset, 'Callback',  @resetMicro_Callback);
    
    set(c.gotoPButton, 'Callback', @gotoPiezo_Callback);
    set(c.gotoPFocus,  'Callback', @focus_Callback);
    set(c.gotoPReset, 'Callback',  @resetPeizoXY_Callback);
    set(c.gotoPTarget, 'Callback', @gotoTarget_Callback);
    
    set(c.gotoGButton, 'Callback', @gotoGalvo_Callback);
    set(c.gotoGReset, 'Callback',  @resetGalvo_Callback);
    set(c.gotoGTarget, 'Callback', @gotoTarget_Callback);
    
    % Galvo Fields --------------------------------------------------------
    set(c.galvoButton, 'Callback', @galvoScan_Callback);
    
    % Automation Fields ---------------------------------------------------
    set(c.autoV1X, 'Callback', @limit_Callback);
    set(c.autoV2X, 'Callback', @limit_Callback);
    set(c.autoV3X, 'Callback', @limit_Callback);
    set(c.autoV4X, 'Callback', @limit_Callback);
    
    set(c.autoV1Y, 'Callback', @limit_Callback);
    set(c.autoV2Y, 'Callback', @limit_Callback);
    set(c.autoV3Y, 'Callback', @limit_Callback);
    set(c.autoV4Y, 'Callback', @limit_Callback);
    
    set(c.autoV1Z, 'Callback', @limit_Callback);
    set(c.autoV2Z, 'Callback', @limit_Callback);
    set(c.autoV3Z, 'Callback', @limit_Callback);
    set(c.autoV4Z, 'Callback', @limit_Callback);
    
    set(c.autoNXRm, 'Callback', @autoRange_Callback);
    set(c.autoNXRM, 'Callback', @autoRange_Callback);
    set(c.autoNYRm, 'Callback', @autoRange_Callback);
    set(c.autoNYRM, 'Callback', @autoRange_Callback);
    set(c.autonRm,  'Callback', @autoRange_Callback);
    set(c.autonRM,  'Callback', @autoRange_Callback);
    
    set(c.autoV1NX, 'Callback', @makeInteger_Callback);
    set(c.autoV2NX, 'Callback', @makeInteger_Callback);
    set(c.autoV3NX, 'Callback', @makeInteger_Callback);
    set(c.autoV4NX, 'Callback', @makeInteger_Callback);
    
    set(c.autoV1NY, 'Callback', @makeInteger_Callback);
    set(c.autoV2NY, 'Callback', @makeInteger_Callback);
    set(c.autoV3NY, 'Callback', @makeInteger_Callback);
    set(c.autoV4NY, 'Callback', @makeInteger_Callback);
    
    set(c.autoV123n, 'Callback', @makeInteger_Callback);
    set(c.autoV4n,   'Callback', @makeInteger_Callback);
    
    set(c.autoV1Get, 'Callback', @setCurrent_Callback);
    set(c.autoV2Get, 'Callback', @setCurrent_Callback);
    set(c.autoV3Get, 'Callback', @setCurrent_Callback);
    set(c.autoV4Get, 'Callback', @setCurrent_Callback);
    
    set(c.autoTest, 'Callback',  @autoTest_Callback);
    set(c.autoButton, 'Callback',  @automate_Callback);
    
    % UI Fields -----------------------------------------------------------
%     set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
%     set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);

    set(c.imageAxes, 'ButtonDownFcn', @makePopout_Callback);
    
    set(c.mouseEnabled, 'Callback', @mouseEnabled_Callback);
    
%     set(c.microInit, 'Callback', @microInit_Callback);
    
    % Create joystick object =====
    c.joy = vrjoystick(1);
    
    % Initiate Everything...
    
    % We do resizing programatically
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    % Initial rendering
    resizeUI_Callback(0, 0);
    renderUpper();
%     displayImage();
    setGalvoAxesLimits();
    
    set(c.parent, 'Visible', 'On');
    
    initAll();
    
    % Start main loop
    main();
    
    function main()
        while c.running     % c.running is currently unused, but likely will be used.
%             try
            if ~c.focusing
                [outputXY, outputZ] = readJoystick();

                if outputXY % If X or Y have been changed
                    setPos();
                end

                if outputZ  % If Z has been changed
                    piezoOut();
                end

                getCurrent();
            end

%             renderUpper();
                    
            pause(.06); % 60 Hz
                
%                 displayImage();
%             catch           % If something goes wrong (likely the figure is destroyed), deinitialize the Galvos
%                 cmd(c.microXSerial, c.microXAddr, 'RS');
%                 fclose(c.microXSerial); delete(c.microXSerial); clear c.microXSerial;
%                 
%                 cmd(c.microYSerial, c.microYAddr, 'RS');
%                 fclose(c.microYSerial); delete(c.microYSerial); clear c.microYSerial;
%             end
        end
    end

%     function tick()
%         display('here');
%         renderUpper();
%     end

    % INPUTS ==============================================================
    function [outputXY, outputZ] = readJoystick()
        [a, b, p] = read(c.joy);
        % a - axes (vector of values -1 to 1),
        % b - buttons (vector of 0s or 1s)
        % p - povs (vector, but with our joystick there is only one
        %     element, of angles \in { -1, 0, 45, 90, ... } where -1 is 
        %     unset and any other value is the direction the pov is facing.
        
        prevX = c.micro(1); % For comparison later
        prevY = c.micro(2);
        prevZ = c.piezo(3);
        
        % Add the joystick offset to the target vector. The microscope
        % attempts to go to the target vector.
        c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.microStep;
        c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.microStep;
        
        % Same for Z; the third axis is the twisting axis
        if max(abs([joystickAxesFunc(a(1), c.joyXYPadding) joystickAxesFunc(a(2), c.joyXYPadding)])) == 0
            c.piezo(3) = c.piezo(3) + c.piezoStep*c.joyZDir*joystickAxesFunc(a(3), c.joyZPadding);
        end
        
        % Plot the XY offset on the graph in the Joystick tab
        scatter(c.joyAxes, c.joyXDir*a(1), c.joyYDir*a(2));
%         set(c.joyAxes, 'xtick', []);
%         set(c.joyAxes, 'xticklabel', []);
%         set(c.joyAxes, 'ytick', []);
%         set(c.joyAxes, 'yticklabel', []);
        xlim(c.joyAxes, [-1 1]);
        ylim(c.joyAxes, [-1 1]);
        
        % Logic for whether a button has changed since last time and is on.
        buttonDown = (b ~= 0 & b ~= c.joyButtonPrev);
        if buttonDown(1)
            focus_Callback(0,0);
        end
        
        if b(6)
            c.piezo(3) = c.piezo(3) + c.joyZDir*c.piezoStep;
        end
        if b(4)
            c.piezo(3) = c.piezo(3) - c.joyZDir*c.piezoStep;
        end
        
        % From the pov angle, compute the direction of movement in XY
        if p ~= -1
            pov = [dir(sind(p)) (-dir(cosd(p)))];
        else
            pov = [0 0];
        end
        
        % Logic for whether a pov axis has changed since last time and is on.
%         povDown = (pov ~= 0 & pov ~= c.joyPovPrev);
        
        if pov(1) ~= 0
            c.micro(1) = c.micro(1) + c.joyXDir*pov(1)*c.microStep;
        end
        if pov(2) ~= 0
            c.micro(2) = c.micro(2) + c.joyYDir*pov(2)*c.microStep;
        end
        
        % Save for next time
        c.joyButtonPrev = b;
        c.joyPovPrev = pov;
        
        % Limit values
        limit();
        
        % Decide whether things have changed
        outputXY =  (prevX ~= c.micro(1) || prevY ~= c.micro(2));
        outputZ =   (prevZ ~= c.piezo(3));
    end
    function speed = joystickAxesFunc(num, ignore) 
        % Input a number for -1 to 1, get the 'speed' to drive the micrometers/piezo
        if abs(num) < ignore % Ignore small movements of the joystick
            speed = 0;
        else
%             speed = (num - .1*(num/abs(num)))*(num - .1*(num/abs(num))); % Continuous
            speed = num*num*num/(ignore*ignore*ignore*8); % *dir(num);
        end
    end
    function out = dir(num)
        % Returns the DIRection of a NUMber as OUT = 1, 0 ,-1. e.g. dir(3) = 1, dir(-3) = -1
        if num == 0
            out = 0;
        elseif num > 0
            out = 1;
        elseif num < 0
            out = -1;
        end
    end
    function limit()
        if c.micro(1) > c.microMax(1)
            c.micro(1) = c.microMax(1);
        elseif c.micro(1) < c.microMin(1)
            c.micro(1) = c.microMin(1);
        end
        if c.micro(2) > c.microMax(2)
            c.micro(2) = c.microMax(2);
        elseif c.micro(2) < c.microMin(2)
            c.micro(2) = c.microMin(2);
        end

        if c.piezo(1) > c.piezoMax(1)
            c.piezo(1) = c.piezoMax(1);
        elseif c.piezo(1) < c.piezoMin(1)
            c.piezo(1) = c.piezoMin(1);
        end
        if c.piezo(2) > c.piezoMax(2)
            c.piezo(2) = c.piezoMax(2);
        elseif c.piezo(2) < c.piezoMin(2)
            c.piezo(2) = c.piezoMin(2);
        end
        if c.piezo(3) > c.piezoMax(3)
            c.piezo(3) = c.piezoMax(3);
        elseif c.piezo(3) < c.piezoMin(3)
            c.piezo(3) = c.piezoMin(3);
        end

        if c.galvo(1) > c.galvoMax(1)
            c.galvo(1) = c.galvoMax(1);
        elseif c.galvo(1) < c.galvoMin(1)
            c.galvo(1) = c.galvoMin(1);
        end
        if c.galvo(2) > c.galvoMax(2)
            c.galvo(2) = c.galvoMax(2);
        elseif c.galvo(2) < c.galvoMin(2)
            c.galvo(2) = c.galvoMin(2);
        end
    end

    % OUTPUTS =============================================================
    function out = pos(serial_obj, device_addr)
        fprintf(serial_obj, [device_addr 'TP']);	% Get device state
        out = fscanf(serial_obj);
    end
    function out = status(serial_obj, device_addr)
        fprintf(serial_obj, [device_addr 'TS']);    % Get device state
        out = fscanf(serial_obj);
    end
    function cmd(serial_obj, device_addr, c)
        fprintf(serial_obj, [device_addr c]);       % Send a CoMmanD
        % out = fscanf(serial_obj);
        % if ~isempty(out)
        %     disp(['ERR' out])
        % end
    end
    function microInit_Callback(hObject, ~)
        if c.microInitiated == 0
            display('Starting Initialization Sequence');

%             try
                % X-axis actuator =====
                c.microXPort = 'COM5'; % USB Port that X is connected to (we view it as a serial port)
                c.microXAddr = '1';
                
                c.microXSerial = serial(c.microXPort);
                set(c.microXSerial, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                    'FlowControl', 'software', 'Terminator', 'CR/LF');
                fopen(c.microXSerial);
                
                pause(.25);
                
                cmd(c.microXSerial, c.microXAddr, 'OR'); % Go to home state (reset position)

                display('Done Initializing X Axis');
                
                
                % Y-axis actuator =====
                c.microYPort = 'COM6'; % USB Port that Y is connected to (we view it as a serial port)
                c.microYAddr = '1';

                c.microYSerial = serial(c.microYPort);
                set(c.microYSerial,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
                    'FlowControl', 'software','Terminator', 'CR/LF');
                fopen(c.microYSerial);
                
                pause(.25);
                
                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state
                
                display('Done Initializing Y Axis');
                
                pause(.25);
                c.microInitiated = 1;
        
                set(c.microText, 'ForegroundColor', 'black');
%             catch
%                 disp('Controller Disconnected !!!');
%             end   
        end
    end
    function galvoInit_Callback(~, ~)
        if c.galvoInitiated == 0
            c.sG = daq.createSession('ni');
            c.sG.addAnalogOutputChannel(c.devGalvo,   c.chnGalvoX,      'Voltage');
            c.sG.addAnalogOutputChannel(c.devGalvo,   c.chnGalvoY,      'Voltage');

            set(c.galvoText, 'ForegroundColor', 'black');
            
            c.galvoInitiated = 1;
        end
    end
    function piezoInit_Callback(~, ~)
        if c.piezoInitiated == 0
            c.sP = daq.createSession('ni');
            c.sP.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoX,      'Voltage');
            c.sP.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoY,      'Voltage');
            c.sP.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoZ,      'Voltage');

            set(c.piezoText, 'ForegroundColor', 'black');
            
            c.piezoInitiated = 1;
        end
    end
    function videoInit()
        c.vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
        src = getselectedsource(c.vid);

        c.vid.FramesPerTrigger = 1;

        axes(c.imageAxes);

        vidRes = c.vid.VideoResolution;
        nBands = c.vid.NumberOfBands;
        hImage = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(1) 1]);

        preview(c.vid, hImage);

%         set(c.imageAxes, 'ButtonDownFcn', @makePopout_Callback);
%         set(hImage, 'ButtonDownFcn', @makePopout_Callback);
    end
    function initAll()
        piezoInit_Callback(0,0);
        videoInit();
        galvoInit_Callback(0,0);
        microInit_Callback(0,0);
        
        focus_Callback(0,0);
        
        getCurrent();
        
        c.running = true;
    end
    function getCurrent()
        getPos();
        getGalvo();
        getPiezo();
    end
    function getGalvo()
        set(c.galvoXX, 'String', c.galvo(1));
        set(c.galvoYY, 'String', c.galvo(2));
    end
    function getPiezo()
        set(c.piezoXX, 'String', c.piezo(1));
        set(c.piezoYY, 'String', c.piezo(2));
        set(c.piezoZZ, 'String', c.piezo(3));
    end
    function getPos()
        % Gets the current postition from the linear actuators
        if c.outputEnabled && c.microInitiated
            str1 = pos(c.microXSerial, c.microXAddr);
            str2 = pos(c.microYSerial, c.microYAddr);
            
            c.microActual(1) = 1000*str2double(str1(4:end));
            c.microActual(2) = 1000*str2double(str2(4:end));

            set(c.microXX, 'String', c.microActual(1));
            set(c.microYY, 'String', c.microActual(2));
        end
    end
    function setPos()
        % Set the position of the micrometers if the micrometers are
        % initiated and output is enabled.
        if c.outputEnabled && c.microInitiated
            cmd(c.microXSerial, c.microXAddr, ['SE' num2str(c.micro(1)/1000)]); % Remember that c.micro is in um and we must convert to mm
            cmd(c.microYSerial, c.microYAddr, ['SE' num2str(c.micro(2)/1000)]);
            fprintf(c.microXSerial, 'SE'); fprintf(c.microYSerial, 'SE');
        end
    end
    function goto_Callback(hObject, ~)
        % Set the micrometers to the XY values in the goto box
        c.micro = [str2double(get(c.gotoMX, 'String')) str2double(get(c.gotoMY, 'String'))];
        setPos();
        renderUpper();
    end
    function gotoActual_Callback(hObject, ~)
        % Sets the goto box to the current 'actual' position of the
        % micrometers
        set(c.gotoMX, 'String', c.microActual(1));
        set(c.gotoMY, 'String', c.microActual(2));
    end
    function gotoTarget_Callback(hObject, ~)
        % Sets the goto box to the current 'target' position of the
        % micrometers. The target position is changed with joy/mouse/key,
        % and the actual micrometer position should follow close behind
        % this.
        % Update: using this for galvos and piezos also...
        switch hObject
            case c.gotoMTarget
                set(c.gotoMX, 'String', c.micro(1));
                set(c.gotoMY, 'String', c.micro(2));
            case c.gotoPTarget
                set(c.gotoPX, 'String', c.piezo(1));
                set(c.gotoPY, 'String', c.piezo(2));
                set(c.gotoPZ, 'String', c.piezo(3));
            case c.gotoGTarget
                set(c.gotoGX, 'String', c.galvo(1));
                set(c.gotoGY, 'String', c.galvo(2));
        end
    end
    function resetMicro_Callback(hObject, ~)
        c.micro = [0 0];
        setPos();
    end
    function piezoOut()
        if c.outputEnabled && c.piezoInitiated
            c.sP.outputSingleScan(c.piezo);
        end
    end
    function gotoPiezo_Callback(~, ~)
        piezoOutSmooth([str2double(get(c.gotoPX, 'String')) str2double(get(c.gotoPY, 'String')) str2double(get(c.gotoPZ, 'String'))]);
    end
    function resetPeizoXY_Callback(~, ~)
        piezoOutSmooth([0 0 c.piezo(3)]);
    end
    function resetPeizo_Callback(~, ~)
        piezoOutSmooth([0 0 0]);
    end
    function piezoOutSmooth(to)
        if c.outputEnabled && c.piezoInitiated
            prev = c.piezo;
            c.piezo = to;
            
            limit();
            
            steps = round(max(abs(c.piezo - prev))/c.piezoStep);
            
            if steps > 0    % If the piezo isn't already there...
                queueOutputData(c.sP, [linspace(prev(1), c.piezo(1), steps)' linspace(prev(2), c.piezo(2), steps)' linspace(c.piezo(3), c.piezo(3), steps)']);
                c.sP.startForeground();
            end
            
            getPiezo();
        end
    end
    function galvoOut()
        if c.outputEnabled && c.galvoInitiated
            c.sG.outputSingleScan(c.galvo);
        end
    end
    function gotoGalvo_Callback(~, ~)
        galvoOutSmooth([str2double(get(c.gotoGX, 'String')) str2double(get(c.gotoGY, 'String'))]);
    end
    function resetGalvo_Callback(~, ~)
        galvoOutSmooth([0 0]);
    end
    function galvoOutSmooth(to)
        if c.outputEnabled && c.galvoInitiated
            prev = c.galvo;
            c.galvo = to;
            
            limit();
            
            steps = round(max(abs(c.galvo - prev))/c.galvoStep);
            
            if steps > 0    % If the galvo isn't already there...
                queueOutputData(c.sG, [linspace(prev(1), c.galvo(1), steps)' linspace(prev(2), c.galvo(2), steps)']);
                c.sG.startForeground();
            end
            
            getGalvo();
        end
    end
    function focus_Callback(~, ~)
        display('begin focusing');
        
        c.focusing = 1;
        prevContrast = 0;
        direction = 1;
        
        prev10 = [0 0 0 0 0 0 0 0 0 0];
        
        n = 1;
        
        while c.focusing
            start(c.vid);
            data = getdata(c.vid);
            img = data(161:480, 121:360);
%             min(min(img))
%             if (max(max(img)) ~= min(min(img)))
%                 img = img./(max(max(img)) - min(min(img)));  % Normalize inside between [0 1] % 
%             end
%             img = displayImage();
            prev10(1) = sum(sum(diff(img,1,1).^2)) + sum(sum(diff(img,1,2).^2));
            
            if prev10(1) < prev10(2)
                direction = -direction;
                n = n + 1;
            end
            
            prev10 = circshift(prev10, [0 1]);
            
            c.piezo(3) = c.piezo(3) + 20*direction*c.piezoStep/(n*n);
        
            if c.piezo(3) < c.piezoMin(3)
                c.piezo(3) = c.piezoMin(3);
    %             display('Z min');
            end
            if c.piezo(3) > c.piezoMax(3)
                c.piezo(3) = c.piezoMax(3);
    %             display('Z max');
            end
                
            piezoOut();
            
            if (sum(prev10 == 0) == 0) && abs(prev10(1) - prev10(2)) < std(prev10)/4
                c.focusing = 0;
            end
            
            getPiezo();
        end
        
        display('end focusing');
    end
    function figure_WindowKeyPressFcn(hObject, eventdata)
        if c.microInit && c.outputEnabled
            switch eventdata.Key
            case {'uparrow', 'w'}
                c.micro(2) = c.micro(2) + c.microStep;
            case {'downarrow', 's'}
                c.micro(2) = c.micro(2) - c.microStep;
            case {'leftarrow', 'a'}
                c.micro(1) = c.micro(1) - c.microStep;
            case {'rightarrow', 'd'}
                c.micro(1) = c.micro(1) + c.microStep;
            case {'pageup', 'add', 'equal', 'q'}
                c.piezo(3) = c.piezo(3) + c.piezoStep;
            case {'pagedown', 'subtract', 'hyphen', 'e'}
                c.piezo(3) = c.piezo(3) - c.piezoStep;
            end   
            
            limit();
            
            piezoOut();
            setPos();
        end
    end
    function closeRequest(src,callbackdata)
        c.running = false;
        c.outputEnabled = false;
        
        try
            cmd(c.microXSerial, c.microXAddr, 'RS');
            fclose(c.microXSerial); delete(c.microXSerial); clear c.microXSerial;

            cmd(c.microYSerial, c.microYAddr, 'RS');
            fclose(c.microYSerial); delete(c.microYSerial); clear c.microYSerial;
        catch err
            display(err.message);
        end
        
        try
            galvoOutSmooth([0 0]);
            piezoOutSmooth([0 0 0]);
            
            c.sG.release();
            c.sP.release();        
        catch err
            display(err.message);
        end
        
        delete(c.imageAxes);
        delete(c.upperAxes);
        delete(c.lowerAxes);
        
        delete(c.parent);
    end
%     function data = displayImage()
%         start(c.vid);
%         data = getdata(c.vid)
%         
%         axes(c.imageAxes);
%         image(flipdim(data,1));
%     end

    % GALVO ===============================================================
    function galvoScan_Callback(hObject, ~)
        galvoScan()
    end
    function galvoScan()    % range in microns, speed in microns per second (up is upscan; down is downscan)
        %Scan the Galvo +/- mvConv*range/2 deg
        %min step of DAQ = 20/2^16 = 3.052e-4V
        %min step of Galvo = 8e-4Deg
        %for galvo [1V->1Deg], 8e-4V->8e-4Deg
        
        range = str2double(get(c.galvoR, 'String'));
        upspeed = str2double(get(c.galvoR, 'String'));
        downspeed = upspeed/8;

        mvConv = .030/5; % Micron to Voltage conversion (this is a guess! this should be changed!)
        step = 8e-4;
        stepFast = step*(upspeed/downspeed);

        maxGalvoRange = 5; % This is a likely-incorrect assumption.

        if mvConv*range > maxGalvoRange
            display('Galvo scanrange too large! Reducing to maximum.');
            range = maxGalvoRange/mvConv;
        end

        up = -(mvConv*range/2):step:(mvConv*range/2);%For testing not using full range
        down = (mvConv*range/2):-stepFast:-(mvConv*range/2);

        final = ones(length(up));
        prev = 0;
        i = 1;

        % Initialize the DAQ
        sG.Rate = upspeed*length(up)/range;
        
        s2 = daq.createSession('ni');
        s2.Rate = upspeed*length(up)/range;
        
        s2.addCounterInputChannel(c.devSPCM,    c.chnSPCM,      'EdgeCount');
        s2.addAnalogInputChannel(c.devSPCM,     'ai0',      'Voltage');
        
        set(c.galvoXX, 'String', '(scanning)');
        set(c.galvoYY, 'String', '(scanning)');

        queueOutputData(sG, [(0:-stepFast:-(mvConv*range/2))'    (0:-stepFast:-(mvConv*range/2))']);
        sG.startForeground();    % Goto starting point from 0,0

        for y = up  % For y in up. We 
            s2.NumberOfScans = length(up);
        
            queueOutputData(sG, [up'      y*ones(1,length(up))']);
            sG.startBackground();
            [out, ~] = s2.startForeground();
        
            sG.wait();
            
            queueOutputData(sG, [down'    linspace(y, y + step, length(down))']);
            sG.startBackground();

            final(i,:) = [mean(diff(out(:,1)')) diff(out(:,1)')];
    
            if i > 1
                surf(c.lowerAxes, up, up(1:i), final(1:i,:), 'EdgeColor', 'none');   % Display the graph on the backscan
                view(c.lowerAxes,2);
                colormap(c.lowerAxes, 'gray');
                xlim(c.lowerAxes, [-mvConv*range/2  mvConv*range/2]);
                ylim(c.lowerAxes, [-mvConv*range/2  mvConv*range/2]);
%                 zlim(c.lowerAxes, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
            end

            i = i + 1;

            sG.wait();
        end

        queueOutputData(sG, [(-(mvConv*range/2):stepFast:0)'     ((mvConv*range/2):-stepFast:0)']);
        sG.startForeground();    % Go back to 0,0 from finishing point
        
        c.galvo = [0 0];
        getGalvo();
        
        s2.release();    % release DAQ
    end
    function setGalvoAxesLimits()
        xlim(c.lowerAxes, [-c.galvoRange/2, c.galvoRange/2]);
        ylim(c.lowerAxes, [-c.galvoRange/2, c.galvoRange/2]);
    end
    function range_Callback(hObject, ~)
        limit_Callback(hObject,0);
        c.galvoRange = str2double(get(hObject, 'String'));
        setGalvoAxesLimits();
    end

    % AUTOMATION
    function setCurrent_Callback(hObject, ~)
        switch hObject
            case c.autoV1Get
                set(c.autoV1X, 'String', c.microActual(1));
                set(c.autoV1Y, 'String', c.microActual(2));
                set(c.autoV1Z, 'String', c.piezo(3));
            case c.autoV2Get
                set(c.autoV2X, 'String', c.microActual(1));
                set(c.autoV2Y, 'String', c.microActual(2));
                set(c.autoV2Z, 'String', c.piezo(3));
            case c.autoV3Get
                set(c.autoV3X, 'String', c.microActual(1));
                set(c.autoV3Y, 'String', c.microActual(2));
                set(c.autoV3Z, 'String', c.piezo(3));
            case c.autoV4Get
                set(c.autoV4X, 'String', c.microActual(1));
                set(c.autoV4Y, 'String', c.microActual(2));
                set(c.autoV4Z, 'String', c.piezo(3));
        end
    end
    function V = getStoredV(d)
        switch d
            case 1
                V = [str2double(get(c.autoV1X, 'String')) str2double(get(c.autoV1Y, 'String')) str2double(get(c.autoV1Z, 'String'))]';
            case 2
                V = [str2double(get(c.autoV2X, 'String')) str2double(get(c.autoV2Y, 'String')) str2double(get(c.autoV2Z, 'String'))]';
            case 3
                V = [str2double(get(c.autoV3X, 'String')) str2double(get(c.autoV3Y, 'String')) str2double(get(c.autoV3Z, 'String'))]';
            case 4
                V = [str2double(get(c.autoV4X, 'String')) str2double(get(c.autoV4Y, 'String')) str2double(get(c.autoV4Z, 'String'))]';
        end
    end
    function N = getStoredN(d)
        switch d
            case 1
                N = [str2double(get(c.autoV1NX, 'String')) str2double(get(c.autoV1NY, 'String'))]';
            case 2
                N = [str2double(get(c.autoV2NX, 'String')) str2double(get(c.autoV2NY, 'String'))]';
            case 3
                N = [str2double(get(c.autoV3NX, 'String')) str2double(get(c.autoV3NY, 'String'))]';
            case 4
                N = [str2double(get(c.autoV4NX, 'String')) str2double(get(c.autoV4NY, 'String'))]';
        end
    end
    function R = getStoredR(d)
        switch d
            case 'x'
                R = [str2num(get(c.autoNXRm, 'String')) str2num(get(c.autoNXRM, 'String'))]';
            case 'y'
                R = [str2num(get(c.autoNYRm, 'String')) str2num(get(c.autoNYRM, 'String'))]';
            case 'd'
                R = [str2num(get(c.autonRm, 'String'))  str2num(get(c.autonRM, 'String'))]';
        end
    end
    function autoTest_Callback(hObject, ~)
%         try
            generateGrid();
%         catch err
%             display(err.message);
%         end
    end
    function [p, color, name, len] = generateGrid()
        nxrange = getStoredR('x');    % Range of the major grid
        nyrange = getStoredR('y');

        ndrange = getStoredR('d');    % Range of the minor grid

        % These vectors will be used to make our major grid
        V1 = getStoredV(1);    n1 = getStoredN(1);    % [x y z] - the position of the device in um;
        V2 = getStoredV(2);    n2 = getStoredN(2);    % [nx ny] - the position of the device in the major grid.
        V3 = getStoredV(3);    n3 = getStoredN(3);    % Fill in later! All of these coordinates will be loaded from the GUI...

        % This vector will be used to determine our device spacing inside one
        % grid.
        V4 = getStoredV(4);    n4 = getStoredN(4);

        nd123 = str2num(get(c.autoV123n, 'String'));  % The number of the device in the minor grid for 1,2,3
        nd4 =   str2num(get(c.autoV4n, 'String'));      % The number of the device in the minor grid for 4

        if nd123 == nd4
            error('n123 == n4!');
        end

        if abs(dot(V2(1:2) - V1(1:2), V3(1:2) - V1(1:2))) == 1
            error('Position vectors are not linearly independent!');
        end

        if abs(dot(n2 - n1, n3 - n1)) == 1
            error('Grid vectors are not linearly independent!');
        end

        % +++++Broken method with broken logic below:
%         % Find the V0 = [x y] of n0 = [0 0]
%         V0 = V1 - dot(n1, n2-n1)*(V2-V1) - dot(n1, n3-n1)*(V3-V1);
% 
%         % Find the horizontal major grid vector from [0 0] to [1 0] in um
%         Vx = (V1 - dot(n1-[1 0]', n2-n1)*(V2-V1) - dot(n1-[1 0]', n3-n1)*(V3-V1)) - V0;
% 
%         % Find the vertical major grid vector from [0 0] to [0 1] in um
%         Vy = (V1 - dot(n1-[0 1]', n2-n1)*(V2-V1) - dot(n1-[0 1]', n3-n1)*(V3-V1)) - V0;
% 
%         % Structure the major grid in matrix form
%         V = [Vx Vy];

        % +++++Better matrix way:
%         m =    [n1(1)   n1(2)   0       0       1       0;
%                 0       0       n1(1)   n1(2)   0       1;
%                 n2(1)   n2(2)   0       0       1       0;
%                 0       0       n2(1)   n2(2)   0       1;
%                 n3(1)   n3(2)   0       0       1       0;
%                 0       0       n3(1)   n3(2)   0       1]
%             
%         y = [V1(1)  V1(2)  V2(1)  V2(2)  V3(1)  V3(2)]'
%         
%         x = inv(m)*y
%         
%         V =     [x(1) x(2); x(3) x(4); 0 0]
%         V0 =    [x(5) x(6) 0]'
        
        % +++++Even better matrix way:
        m =    [n1(1)   n1(2)   1;
                n2(1)   n2(2)   1;
                n3(1)   n3(2)   1];
        
        x1 = inv(m)*[V1(1) V2(1) V3(1)]';
        x2 = inv(m)*[V1(2) V2(2) V3(2)]';
        x3 = inv(m)*[V1(3) V2(3) V3(3)]';
        
        V =     [x1(1) x1(2); x2(1) x2(2); x3(1) x3(2)];
        V0 =    [x1(3) x2(3) x3(3)]';

        % Check to make sure V1, V2, V3 are recoverable...
        if (sum(abs(V1 - V*n1 + V0)) + sum(abs(V2 - V*n2 + V0)) + sum(abs(V3 - V*n3 + V0)) < 1e-9)  % Within a certain tolerance...
%             display(V1); display(V*n1 + V0);
%             display(V2); display(V*n2 + V0);
%             display(V3); display(V*n3 + V0);
            error('Math is wrong... D:');
        end

        v = (V4 - (V*n4 + V0))/(nd4 - nd123);   % Direction of the linear minor grid. Note that z might be off...

        p = zeros(3, diff(nxrange)*diff(nyrange)*diff(ndrange));
        color = zeros(diff(nxrange)*diff(nyrange)*diff(ndrange), 3);    % (silly matlab)
        name = cell(diff(nxrange)*diff(nyrange)*diff(ndrange),1)
%         l = cell(1, diff(nxrange)*diff(nyrange)*diff(ndrange));

        i = 1;

        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for d = ndrange(1):ndrange(2)
                    p(:,i) = V*([x y]') + V0 + d*v;
                    
                    color(i,:) = [0 0 1];
                    
                    if ((d == nd123) && (sum(n1 == [x y]') == 2 || sum(n2 == [x y]') == 2 || sum(n3 == [x y]') == 2))
                        color(i,:) = [0 1 0];
                    end
                    if (d == nd4 && sum(n4 == [x y]') == 2)
                        color(i,:) = [1 1 0];
                    end
                    if (p(3,i) < c.piezoMin(3))
                        p(3,i) = c.piezoMin(3);
                        color(i,:) = [1 0 0];
                    end
                    if (p(3,i) > c.piezoMax(3))
                        p(3,i) = c.piezoMax(3);
                        color(i,:) = [1 0 0];
                    end
                    
%                     name{i} = ['Device ' num2str(d) 'in set [' num2str(x) ', '  num2str(y) ']'];
                    name{i} = ['device_' num2str(d) '_set_[' num2str(x) ','  num2str(y) ']'];
                    
                    i = i + 1;
                end
            end
        end
        
        len = i-1;

        xlim(c.upperAxes, [min(p(1,:)) max(p(1,:))]);
        ylim(c.upperAxes, [min(p(2,:)) max(p(2,:))]);
        scatter(c.upperAxes, p(1,:), p(2,:), 36, color);
    end
    function automate_Callback(hObject, ~)
        automate();
    end
    function automate()
%         [V, V0, v, nxrange, nyrange, ndrange] = varin;
        [p, color, name, len] = generateGrid();

        clk = clock;

        prefix = [num2str(clk(1)) '_' num2str(clk(2)) '_' num2str(clk(3)) '_'];
        
        original = c.micro;
        
        for i = 1:len
            c.micro = p(1:2,i)';
            
            % Need to set Z also...

            setPos();

            while sum(abs(c.microActual - p(1:2,i)')) > .1
                getPos();
                pause(.1);
            end
            
            piezoOutSmooth([c.piezo(1) c.piezo(2) p(3,i)]);

            pause(.5);

%                     OPTIMIZE();

%                     GALVOSCAN();

%                     OPTIMIZE();

%                     scan = GALVOSCAN();

            display(name{i});

%                     save([prefix name{i} '.mat'], 'scan');

        end
        
        c.micro = original;
        setPos();
    end

    % BOX =================================================================
    function mouseEnabled_Callback(hObject, ~)
        if get(c.mouseEnabled, 'Value')
            set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
        else
            set(c.upperAxes, 'ButtonDownFcn', '');
        end
    end
    function click_Callback(hObject, ~)
        set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
        set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
        
        if strcmp(get(c.parent, 'SelectionType'), 'alt')
            if c.axesMode == 0
                if hObject == c.upperAxes
                    c.axesMode = 1;
                    set(c.lowerAxes, 'Visible', 'Off');
                    set(get(c.lowerAxes,'Children'), 'Visible', 'Off');
                else
                    c.axesMode = 2;
                    set(c.upperAxes, 'Visible', 'Off');
                    set(get(c.upperAxes,'Children'), 'Visible', 'Off');
                end
            else
                c.axesMode = 0;
                set(c.upperAxes, 'Visible', 'On');
                set(c.lowerAxes, 'Visible', 'On');
                set(get(c.upperAxes,'Children'), 'Visible', 'On');
                set(get(c.lowerAxes,'Children'), 'Visible', 'On');
            end

            resizeUI_Callback();
        elseif strcmp(get(c.parent, 'SelectionType'), 'normal') && hObject == c.upperAxes
            x = get(c.upperAxes,'CurrentPoint');
            c.micro = x(1,1:2);
            if c.outputEnabled
                setPos();
            end
            renderUpper();
        end
    end
    function box_Callback(hObject, ~)
        switch hObject
            case c.boxTL
                type = 1;
            case c.boxTR
                type = 2;
            case c.boxBL
                type = 4;
            case c.boxBR
                type = 3;
            otherwise
                type = 0;
        end
        
        c.boxPrev = c.boxCurr;
        c.boxCurr = [c.linAct(1) c.linAct(2) type];
        
        calculateBox();
    end
    function calculateBox()
        if c.boxCurr(3) ~= c.boxPrev(3) && c.boxCurr(3) ~= 0 && c.boxPrev(3) ~= 0
%             c.boxPrev;
%             c.boxCurr;
            
            type = mod(c.boxCurr(3) - c.boxPrev(3), 4);
            
            v1 = c.boxPrev(1:2);
            v2 = c.boxCurr(1:2);
            
            switch type
                case 0      % This should not happen becasue of our first if
                    error('renderBox error; something is terribly wrong!');
                case {1, 3}  % If points are on one side...
                    if type == 3
                        v1 = c.boxCurr(1:2);
                        v2 = c.boxPrev(1:2);
                    end
                    
                    ortho = ([0, 1; -1, 0]*(v2 - v1)')';
                    
                    c.boxX(1) = v1(1);
                    c.boxX(2) = v2(1);
                    c.boxX(3) = v2(1) + ortho(1);
                    c.boxX(4) = v1(1) + ortho(1);
                    c.boxX(5) = v1(1);
                    
                    c.boxY(1) = v1(2);
                    c.boxY(2) = v2(2);
                    c.boxY(3) = v2(2) + ortho(2);
                    c.boxY(4) = v1(2) + ortho(2);
                    c.boxY(5) = v1(2);
                case 2      % If points are across the diagonal...
                    ortho = ([0, 1; -1, 0]*(v2 - v1)')';
                    
                    c.boxX(1) = v1(1);
                    c.boxX(2) = (v1(1) + v2(1) + ortho(1))/2;
                    c.boxX(3) = v2(1);
                    c.boxX(4) = (v1(1) + v2(1) - ortho(1))/2;
                    c.boxX(5) = v1(1);
                    
                    c.boxY(1) = v1(2);
                    c.boxY(2) = (v1(2) + v2(2) + ortho(2))/2;
                    c.boxY(3) = v2(2);
                    c.boxY(4) = (v1(2) + v2(2) - ortho(2))/2;
                    c.boxY(5) = v1(2);
            end
        else
            c.boxX = [-1 -1 -1 -1 -1];
            c.boxY = [-1 -1 -1 -1 -1];
        end
        
        renderUpper();
    end

    % UI ==================================================================
    function renderUpper()
        if c.axesMode ~= 2
%             if sum(c.boxX ~= -1) ~= 0 % If the vals are not all -1...
                plot(c.upperAxes, c.microActual(1), c.microActual(2), 'dr', c.micro(1), c.micro(2), 'dk'); % , c.boxX, c.boxY, ':r', c.boxPrev(1), c.boxPrev(2), 'pr', c.boxCurr(1), c.boxCurr(2), 'hr');
%                 set(c.upperAxes, 'HitTest', 'off');
                if get(c.mouseEnabled, 'Value')
                    set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
                end
                set(get(c.upperAxes,'Children'), 'ButtonDownFcn', '');
                set(get(c.upperAxes,'Children'), 'HitTest', 'off');
                
               
%             else
%                 plot(c.upperAxes, c.linAct(1), c.linAct(2), 'd');
%             end

            xlim(c.upperAxes, [0 25000]);
            ylim(c.upperAxes, [0 25000]);
        end
    end
    function resizeUI_Callback(~, ~)
        p = get(c.parent, 'Position');
        w = p(3); h = p(4);
        
        % 640x480

        % Axes Position =====
        S = w-pw-2*gp;
        set(c.imageAxes,    'Position', [gp (h-gp-S*(480/640)) S S*(480/640)]);
        
        if ((w-pw-2*gp) < (640/480)*(3*h/4)) % If Width is limiting
            S = w-pw-2*gp;
            set(c.imageAxes,    'Position', [gp (h-gp-S*(480/640)) S S*(480/640)]);
        
            if ((w-pw-3*gp)/2 < (h-S*(480/640)-3*gp)) % If Width is limiting
                s = (w-pw-3*gp)/2;
                set(c.lowerAxes,    'Position', [2*gp+w     gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
                set(c.upperAxes,    'Position', [gp         gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
            else                        % If Height is limiting
                s = (h-S*(480/640)-3*gp);
                set(c.lowerAxes,    'Position', [(w-pw)/4 - s/2 gp s s]);
                set(c.upperAxes,    'Position', [3*(w-pw)/4 - s/2 gp s s]);
            end
        else                        % If Height is limiting
            S = (640/480)*3*h/4;
            set(c.imageAxes,    'Position', [gp+(w-pw-S)/2 (h-gp-S*(480/640)) S S*(480/640)]);
        
            if ((w-pw-3*gp)/2 < (h-S*(480/640)-3*gp)) % If Width is limiting
                s = (w-pw-3*gp)/2;
                set(c.lowerAxes,    'Position', [2*gp+w     gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
                set(c.upperAxes,    'Position', [gp         gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
            else                        % If Height is limiting
                s = (h-S*(480/640)-3*gp);
                set(c.lowerAxes,    'Position', [(w-pw)/4 - s/2 gp s s]);
                set(c.upperAxes,    'Position', [3*(w-pw)/4 - s/2 gp s s]);
            end
        end

        % (old) Axes Position =====
%         if c.axesMode == 0 % Both
%             if (w-pw-2*gp < (h-3*gp)/2) % If Width is limiting
%                 S = w-pw-2*gp;
%                 set(c.lowerAxes,    'Position', [gp ((h/4)-(S/2)) S S]);
%                 set(c.upperAxes,    'Position', [gp ((3*h/4)-(S/2)) S S]);
%             else                        % If Height is limiting
%                 S = (h-3*gp)/2;
%                 set(c.lowerAxes,    'Position', [(w-pw-S)/2 gp S S]);
%                 set(c.upperAxes,    'Position', [(w-pw-S)/2 2*gp+S S S]);
%             end
%         else
%             if (w-pw-2*gp < h-2*gp)     % If Width is limiting
%                 S = w-pw-2*gp;
%             else                        % If Height is limiting
%                 S = h-2*gp;
%             end
% 
%             if c.axesMode == 1  % Upper only
%                 set(c.upperAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
%             else                % Lower only
%                 set(c.lowerAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
%             end
%         end

        % Panel Position =====
        set(c.ioPanel,      'Position', [w-pw h-puh pw puh]);
        set(c.automationPanel,  'Position', [w-pw h-puh-plh pw plh]);
    end
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
        
        switch hObject
            case {c.gotoMX, c.autoV1X, c.autoV2X, c.autoV3X, c.autoV4X}
                if val > c.microMax(1)
                    val = c.microMax(1);
                elseif val < c.microMin(1)
                    val = c.microMin(1);
                end
            case {c.gotoMY, c.autoV1Y, c.autoV2Y, c.autoV3Y, c.autoV4Y}
                if val > c.microMax(2)
                    val = c.microMax(2);
                elseif val < c.microMin(2)
                    val = c.microMin(2);
                end
            case c.gotoPX
                if val > c.piezoMax(1)
                    val = c.piezoMax(1);
                elseif val < c.piezoMin(1)
                    val = c.piezoMin(1);
                end
            case c.gotoPY
                if val > c.piezoMax(2)
                    val = c.piezoMax(2);
                elseif val < c.piezoMin(2)
                    val = c.piezoMin(2);
                end
            case {c.gotoPZ, c.autoV1Z, c.autoV2Z, c.autoV3Z, c.autoV4Z}
                if val > c.piezoMax(3)
                    val = c.piezoMax(3);
                elseif val < c.piezoMin(3)
                    val = c.piezoMin(3);
                end
            case c.gotoGX
                if val > c.galvoMax(1)
                    val = c.galvoMax(1);
                elseif val < c.galvoMin(1)
                    val = c.galvoMin(1);
                end
            case c.gotoGY
                if val > c.galvoMax(2)
                    val = c.galvoMax(2);
                elseif val < c.galvoMin(2)
                    val = c.galvoMin(2);
                end
            case c.galvoR
                if val > c.galvoRangeMax
                    val = c.galvoRangeMax;
                elseif val < 0
                    val = 0;
                end
            case c.galvoS
                if val > c.galvoSpeedMax
                    val = c.galvoSpeedMax;
                elseif val < 0
                    val = 0;
                end
        end
        
        set(hObject, 'String', val);
    end
    function makeInteger_Callback(hObject, ~)
        set(hObject, 'String', round(str2double(get(hObject, 'String'))));
    end
    function autoRange_Callback(hObject, ~)
        makeInteger_Callback(hObject, 0);
        
        switch hObject
            case {c.autoNXRm, c.autoNXRM}
                fixRange(c.autoNXRm, c.autoNXRM, hObject);
            case {c.autoNYRm, c.autoNYRM}
                fixRange(c.autoNYRm, c.autoNYRM, hObject);
            case {c.autonRm, c.autonRM}
                fixRange(c.autonRm, c.autonRM, hObject);
        end
    end
    function fixRange(smallObj, largeObj, refObj)
        if str2double(get(smallObj, 'String')) > str2double(get(largeObj, 'String'))
            if smallObj == refObj
                set(largeObj, 'String', get(smallObj, 'String'));
            else
                set(smallObj, 'String', get(largeObj, 'String'));
            end
        end
    end
    function makePopout_Callback(hObject, ~)
        display('here');
        fig = figure();
        copyobj(c.imageAxes, fig);  % Temporary; need to figure out how to make this universal (type issues and parent problems)...
        set(c.imageAxes, 'Position', [.13 .11 .77 .815], 'ButtonDownFcn', []);
    end
    function bool = myIn(num, range)
        bool = (num > range(1)) && (num < range(2));
    end
end





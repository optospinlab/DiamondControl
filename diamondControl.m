% This is the main fucntion of the DiamondControl program. It provides an
% interface for controlling the automated setup of optospinlab's QIP
% project. This interface includes:
%  - joystick/mouse/keyboard control of linear actuators for X and Y 
%    movement over a sample,
%  - the ability to XY scan the exitiation beam with Galvometers while
%    collecting from the same spot,
%  - control of the peizo stage for precise Z (soon XY) positioning, and
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
    set(c.boxTL, 'Callback', @box_Callback);
    set(c.boxTR, 'Callback', @box_Callback);
    set(c.boxBL, 'Callback', @box_Callback);
    set(c.boxBR, 'Callback', @box_Callback);
    
    set(c.gotoX, 'Callback', @limit_Callback);
    set(c.gotoY, 'Callback', @limit_Callback);
    set(c.galvoS, 'Callback', @limit_Callback);
    
    set(c.galvoR, 'Callback', @range_Callback);
    
    set(c.galvoButton, 'Callback', @galvoScan_Callback);
    
    set(c.gotoButton, 'Callback', @goto_Callback);
    set(c.gotoActual, 'Callback', @gotoActual_Callback);
    set(c.gotoTarget, 'Callback', @gotoTarget_Callback);
    
    set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
    set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
    
    set(c.mouseEnabled, 'Callback', @mouseEnabled_Callback);
    
    set(c.microInit, 'Callback', @microInit_Callback);
    
    % Create joystick object =====
    c.joy = vrjoystick(1);
    
    % We do resizing programatically
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    % Initial rendering
    renderUpper();
    setGalvoAxesLimits();
    
    set(c.parent, 'Visible', 'On');
    
    % Start main loop
    main();
    
    function main()
        while c.running     % c.running is currently unused, but likely will be used.
            try
                pause(.12); % 30 Hz
                [outputXY, outputZ] = readJoystick();

                if outputXY % If X or Y have been changed
                    setPos();
                end

                if outputZ  % If Z has been changed
                    piezoZOut();
                end

                getPos();   % Find out where the micrometers actually are
                renderUpper();
            catch           % If something goes wrong (likely the figure is destroyed), deinitialize the Galvos
                cmd(c.microXSerial, c.microXAddr, 'RS');
                fclose(c.microXSerial); delete(c.microXSerial); clear c.microXSerial;
                
                cmd(c.microYSerial, c.microYAddr, 'RS');
                fclose(c.microYSerial); delete(c.microYSerial); clear c.microYSerial;
            end
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
        prevZ = c.piezoZ;
        
        % Add the joystick offset to the target vector. The microscope
        % attempts to go to the target vector.
        joyMult = c.microStep/(c.joyXYPadding*c.joyXYPadding*c.joyXYPadding);
        c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*joyMult;
        c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*joyMult;
        
        % Same for Z; the third axis is the twisting axis
        c.piezoZ = c.piezoZ + c.piezoStep*4*c.joyZDir*joystickAxesFunc(a(3), c.joyZPadding);
        
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
        
        if buttonDown(6)
            c.piezoZ = c.piezoZ + c.joyZDir*c.piezoStep;
        end
        if buttonDown(4)
            c.piezoZ = c.piezoZ - c.joyZDir*c.piezoStep;
        end
        
        % From the pov angle, compute the direction of movement in XY
        if p ~= -1
            pov = [dir(sin(p)) (-dir(cos(p)))];
        else
            pov = [0 0];
        end
        
        % Logic for whether a pov axis has changed since last time and is on.
        povDown = (pov ~= 0 & pov ~= c.joyPovPrev);
        
        if povDown(1)
            c.micro(1) = c.micro(1) + c.joyXDir*pov(1)*c.microStep;
        end
        if povDown(2)
            c.micro(2) = c.micro(2) + c.joyYDir*pov(2)*c.microStep;
        end
        
        % Save for next time
        c.joyButtonPrev = b;
        c.joyPovPrev = pov;
        
        % Limit values
        if c.micro(1) < 0
            c.microX = 0;
%             display('X min');
        end
        if c.micro(1) > c.xMax
            c.microX = c.xMax;
%             display('X max');
        end
        
        if c.micro(2) < 0
            c.microY = 0;
%             display('Y min');
        end
        if c.micro(2) > c.yMax
            c.microY = c.yMax;
%             display('Y max');
        end
        
        if c.piezoZ < 0
            c.piezoZ = 0;
%             display('Z min');
        end
        if c.piezoZ > c.zMax
            c.piezoZ = c.zMax;
%             display('Z max');
        end
        
        % Decide whether things have changed
        outputXY =  (prevX ~= c.micro(1) || prevY ~= c.micro(2));
        outputZ =   (prevZ ~= c.piezoZ);
    end
    function speed = joystickAxesFunc(num, ignore) 
        % Input a number for -1 to 1, get the 'speed' to drive the micrometers/piezo
        if abs(num) < ignore % Ignore small movements of the joystick
            speed = 0;
        else
%             speed = (num - .1*(num/abs(num)))*(num - .1*(num/abs(num))); % Continuous
            speed = num*num*num; % *dir(num);
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
%         clear c.microXSerial
%         clear c.microYSerial
        
        button_state = get(hObject,'Value');
        if button_state == 1 && c.microInitiated == 0
            display('Starting Initialization Sequence');

%             try
                % X-axis actuator =====
                c.microXPort = 'COM5'; % USB Port that X is connected to (we view it as a serial port)
                c.microXAddr = '1';
                
                c.microXSerial = serial(c.microXPort);
                set(c.microXSerial, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                    'FlowControl', 'software', 'Terminator', 'CR/LF');
                fopen(c.microXSerial);
                
                pause(1);
                
                cmd(c.microXSerial, c.microXAddr, 'OR'); % Go to home state (reset position)

                display('Done Initializing X Axis');
                
                
                % Y-axis actuator =====
                c.microYPort = 'COM6'; % USB Port that Y is connected to (we view it as a serial port)
                c.microYAddr = '1';

                c.microYSerial = serial(c.microYPort);
                set(c.microYSerial,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
                    'FlowControl', 'software','Terminator', 'CR/LF');
                fopen(c.microYSerial);
                
                pause(1); 
                
                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state
                
                display('Done Initializing Y Axis');
                
                c.microX = 0;
                c.microY = 0;
                
                pause(1); 
                c.microInitiated = true;
%             catch
%                 disp('Controller Disconnected !!!');
%             end   
        end
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
        c.micro = [str2double(get(c.gotoX, 'String')) str2double(get(c.gotoY, 'String'))];
        setPos();
        renderUpper();
    end
    function gotoActual_Callback(hObject, ~)
        % Sets the goto box to the current 'actual' position of the
        % micrometers
        set(c.gotoX, 'String', c.microActual(1));
        set(c.gotoY, 'String', c.microActual(2));
    end
    function gotoTarget_Callback(hObject, ~)
        % Sets the goto box to the current 'target' position of the
        % micrometers. The target position is changed with joy/mouse/key,
        % and the actual micrometer position should follow close behind
        % this.
        set(c.gotoX, 'String', c.micro(1));
        set(c.gotoY, 'String', c.micro(2));
    end
    function piezoZOut()
        if c.outputEnabled
            s = daq.createSession('ni');    % Currently creates the session each time. This probably should change in the future.
            s.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoZ,      'Voltage');
            s.outputSingleScan(c.piezoZ);
            s.release();
        end
    end

    % GALVO ===============================================================
    function galvoScan_Callback()
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
        down = -(mvConv*range/2):stepFast:(mvConv*range/2);

        final = ones(length(up));
        prev = 0;
        i = 1;

        % Initialize the DAQ
        s = daq.createSession('ni');
        s.Rate = upspeed*length(up)/range;
        
        s.addAnalogOutputChannel(c.devGalvo,    c.chnGalvoX,    'Voltage');
        s.addAnalogOutputChannel(c.devGalvo,    c.chnGalvoY,    'Voltage');
        s.addCounterInputChannel(c.devSPCM,     c.chnSPCM,      'EdgeCount');

        queueOutputData(s, [(0:-stepFast:-(mvConv*range/2))'     (0:-stepFast:-(mvConv*range/2))']);
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

            prev = out(length(out));

            s.wait();
        end

        queueOutputData(s, [(-(mvConv*range/2):stepFast:0)'     ((mvConv*range/2):-stepFast:0)']);
        s.startForeground();    % Go back to 0,0 from finishing point

        s.release();    % release DAQ
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
        display('here');
        p = get(c.parent, 'Position');
        w = p(3); h = p(4);

        % Axes Position =====
        display(c.axesMode);
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
        
        if val < 0      % Apply limits
            val = 0;
        else
            if      hObject == c.gotoX && val > c.xMax
                val = c.xMax;
            elseif  hObject == c.gotoY && val > c.yMax
                val = c.yMax;
            elseif  hObject == c.galvoR && val > c.galvoRangeMax
                val = c.galvoRangeMax;
            elseif  hObject == c.galvoS && val > c.galvoSpeedMax
                val = c.galvoSpeedMax;
            end
        end
        
        set(hObject, 'String', val);
    end
end





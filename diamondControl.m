

function varargout = diamondControl(varargin)
    if ~isempty(varargin)
        c = diamondControlGUI(varargin);
    else
        f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');
        c = diamondControlGUI('Parent', f);
    end
    
    global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
    
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
    
    c.joy = vrjoystick(1);
    
    % We do resizing programatically =====
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    renderUpper();
    setGalvoAxesLimits();
    
    set(c.parent, 'Visible', 'On');
    
    main();
    
    function main()
        while c.running
            pause(.12);
            [outputXY, outputZ] = readJoystick();
            
            if outputXY
                setPos();
            end

            if outputZ
                piezoZOut();
            end
            
            getPos();
            renderUpper();
            
        end
    end

%     function tick()
%         display('here');
%         renderUpper();
%     end

    % INPUTS ==============================================================
    function [outputXY, outputZ] = readJoystick()
        [a, b, p] = read(c.joy);
        
        prevX = c.micro(1);
        prevY = c.micro(2);
        prevZ = c.piezoZ;
        
        c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.microStep/(c.joyXYPadding*c.joyXYPadding*c.joyXYPadding);
        c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.microStep/(c.joyXYPadding*c.joyXYPadding*c.joyXYPadding);
        
        c.piezoZ = c.piezoZ + c.piezoStep*4*c.joyZDir*joystickAxesFunc(a(3), c.joyZPadding);
        
        scatter(c.joyAxes, c.joyXDir*a(1), c.joyYDir*a(2));
        set(c.joyAxes, 'xtick', []);
        set(c.joyAxes, 'xticklabel', []);
        set(c.joyAxes, 'ytick', []);
        set(c.joyAxes, 'yticklabel', []);
        xlim(c.joyAxes, [-1 1]);
        ylim(c.joyAxes, [-1 1]);
        
        
        buttonDown = (b ~= 0 & b ~= c.joyButtonPrev);
        
        if buttonDown(6)
            c.piezoZ = c.piezoZ + c.joyZDir*c.piezoStep;
        end
        if buttonDown(4)
            c.piezoZ = c.piezoZ - c.joyZDir*c.piezoStep;
        end
        
        if p ~= -1
            pov = [-dir(cos(p)) dir(sin(p))];
        else
            pov = [0 0];
        end
        
        povDown = (pov ~= 0 & pov ~= c.joyPovPrev);
        
        if povDown(1)
            c.micro(1) = c.micro(1) + c.joyXDir*pov(1)*c.microStep;
        end
        if povDown(2)
            c.micro(2) = c.micro(2) + c.joyYDir*pov(2)*c.microStep;
        end
        
        
        c.joyButtonPrev = b;
        c.joyPovPrev = pov;
        
        if c.micro(1) < 0
            c.microX = 0;
            display('X min');
        end
        if c.micro(1) > c.xMax
            c.microX = c.xMax;
            display('X max');
        end
        
        if c.micro(2) < 0
            c.microY = 0;
            display('Y min');
        end
        if c.micro(2) > c.yMax
            c.microY = c.yMax;
            display('Y max');
        end
        
        if c.piezoZ < 0
            c.piezoZ = 0;
            display('Z min');
        end
        if c.piezoZ > c.zMax
            c.piezoZ = c.zMax;
            display('Z max');
        end
        
        outputXY =  (prevX ~= c.micro(1) || prevY ~= c.micro(2));
        outputZ =   (prevZ ~= c.piezoZ);
    end
    function speed = joystickAxesFunc(num, ignore)  % Input a number for -1 to 1, get the 'speed' to drive the micrometers/piezo
        if abs(num) < ignore % Ignore small movements of the joystick
            speed = 0;
        else
%             speed = (num - .1*(num/abs(num)))*(num - .1*(num/abs(num))); % Continuous
            speed = num*num*num; % *dir(num);
        end
    end
    function out = dir(num)
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
        fprintf(serial_obj, [device_addr 'TS']); %Get device state
        out = fscanf(serial_obj);
    end
    function cmd(serial_obj, device_addr, c)
        fprintf(serial_obj, [device_addr c]); 
        % out = fscanf(serial_obj);
        % if ~isempty(out)
        %     disp(['ERR' out])
        % end
    end
    function microInit_Callback(hObject, ~)
        button_state = get(hObject,'Value');
        if button_state == 1 && init_done == 0 && init_first == 0
            display('Starting Initialization Sequence');

            try
                % X-axis actuator =====
                c.microXPort = 'COM17'; % USB Port that X is connected to (we view it as a serial port)
                c.microXAddr = '1';
                
                c.microXSerial = serial(c.microXPort);
                set(c.microXSerial, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                    'FlowControl', 'software', 'Terminator', 'CR/LF');
                fopen(c.microXSerial);
                
                pause(1);
                
                cmd(c.microXSerial, c.microXAddr, 'OR'); % Go to home state (reset position)

                display('Done Initializing X Axis');
                
                
                % Y-axis actuator =====
                c.microYPort = 'COM18'; % USB Port that Y is connected to (we view it as a serial port)
                c.microYAddr = '1';

                c.microYSerial = serial(device_port);
                set(c.microYSerial,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
                    'FlowControl', 'software','Terminator', 'CR/LF');
                fopen(c.microYSerial);
                
                pause(1); 
                
                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state
                
                display('Done Initializing Y Axis');
                
                c.microX = 0;
                c.microY = 0;
            catch
                disp('Controller Disconnected !!!');
            end   
        end
    end
    function getPos()
        if c.outputEnabled && c.microInit
            c.microActual(1) = 1000*str2double(pos(c.microXSerial, c.microXAddr));
            c.microActual(2) = 1000*str2double(pos(c.microYSerial, c.microYAddr));

            set(c.microXX, 'String', c.microActual(1));
            set(c.microYY, 'String', c.microActual(2));
        end
    end
    function setPos()
        if c.outputEnabled && c.microInit
            cmd(c.microXSerial, c.microXAddr, ['SE' num2str(c.microActual(1)/1000)]);
            cmd(c.microYSerial, c.microYAddr, ['SE' num2str(c.microActual(2)/1000)]);
        end
    end
    function goto_Callback(hObject, ~)
        c.micro = [str2double(get(c.gotoX, 'String')) str2double(get(c.gotoY, 'String'))];
        setPos();
        renderUpper();
    end
    function gotoActual_Callback(hObject, ~)
        set(c.gotoX, 'String', c.microActual(1));
        set(c.gotoY, 'String', c.microActual(2));
    end
    function gotoTarget_Callback(hObject, ~)
        set(c.gotoX, 'String', c.micro(1));
        set(c.gotoY, 'String', c.micro(2));
    end
    function piezoZOut()
        if c.outputEnabled
            s = daq.createSession('ni');
            s.addAnalogOutputChannel(c.devPiezoZ,   c.chnPiezoZ,      'Voltage');
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





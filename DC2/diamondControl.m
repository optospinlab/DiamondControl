% This is the main fucntion of the DiamondControl program. It provides an
% interface for controlling the automated setup of optospinlab's QIP
% project. This interface includes:
%  - joystick/mouse/keyboard control of linear actuators for X and Y 
%    movement over a sample,
%  - the ability to XY scan the exitiation beam with Galvometers while
%    collecting from the same spot,
%  - control of the peizo stage for precise Z and XY positioning,
%  - poorly-implemented optimization routines, and
%  - (soon [edit: now]) basic automation protocols for performing simple testing.
function varargout = diamondControl(varargin)
    if isempty(varargin)    % If no variables have been given, make the figure
        f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none','Position',get(0,'Screensize'));
        c = diamondControlGUI('Parent', f);
    else                    % Otherwise pass the variables on.
        c = diamondControlGUI(varargin);
    end
    
    % Helper Global variables for UI construction
    global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
    
    
    % CALLBACKS ===========================================================
    set(c.parent, 'WindowKeyPressFcn', @figure_WindowKeyPressFcn);  % Interprects keypresses e.g. up/down arrow.
    set(c.parent, 'CloseRequestFcn', @closeRequest);                % Handles the closing of the figure.
    
%     set(c.boxTL, 'Callback', @box_Callback);
%     set(c.boxTR, 'Callback', @box_Callback);
%     set(c.boxBL, 'Callback', @box_Callback);
%     set(c.boxBR, 'Callback', @box_Callback);
    
    % Goto Fields ---------------------------------------------------------
    set(c.gotoMX, 'Callback', @limit_Callback);                     % Limits the values of these uicontrols to be
    set(c.gotoMY, 'Callback', @limit_Callback);                     % within the safe/allowed limits of the devices
    set(c.gotoPX, 'Callback', @limit_Callback);                     % they control. e.g. piezos are limited 0 -> 10 V.
    set(c.gotoPY, 'Callback', @limit_Callback);
    set(c.gotoPZ, 'Callback', @limit_Callback);
    set(c.gotoGX, 'Callback', @limit_Callback);
    set(c.gotoGY, 'Callback', @limit_Callback);
    
    set(c.gotoMButton, 'Callback', @goto_Callback);                 % MICROMETER GOTO controls - Goto button sends the micros to the current fields
    set(c.gotoMActual, 'Callback', @gotoActual_Callback);           
    set(c.gotoMTarget, 'Callback', @gotoTarget_Callback);           % Actual and Target set the current fields to the actual (where the micros think they are) and target
    set(c.gotoMReset, 'Callback',  @resetMicro_Callback);           % (where the program is going to) values. Reset goes back to [0 0]
    
    set(c.gotoPButton, 'Callback', @gotoPiezo_Callback);            % PIEZO GOTO controls - Goto button sends the piezos (smoothly) to the current fields
    set(c.gotoPFocus,  'Callback', @focus_Callback);                % This uses a contrast-optimization routine to focus using the blue image
    set(c.gotoPOptXY,  'Callback', @optXY_Callback);                % XY and Z opt use filthy count-optimization techniques
    set(c.gotoPOptZ,  'Callback',  @optZ_Callback);
    set(c.gotoPReset, 'Callback',  @resetPiezoXY_Callback);         % Resets the XY to [5 5], approaching from [0 0]
    set(c.gotoPTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    
    set(c.gotoGButton, 'Callback', @gotoGalvo_Callback);            % GALVO GOTO controls - Goto button sends the galvos to the current fields
    set(c.gotoGReset, 'Callback',  @resetGalvo_Callback);           % Resets the XY to [0 0] (should I approach from a direction?)
    set(c.gotoGTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    
    % Galvo Fields --------------------------------------------------------
    set(c.galvoButton, 'Callback', @galvoScan_Callback);            % Starts a Galvo scan. Below are parameters defining that scan.
    set(c.galvoR, 'Callback', @galvoVar_Callback);                  %  - R for Range in um/side (approx) where the side is the side of the scanning square
    set(c.galvoS, 'Callback', @galvoVar_Callback);                  %  - S for Speed in um/sec
    set(c.galvoP, 'Callback', @galvoVar_Callback);                  %  - P for Pixels in pixels/side
    
    set(c.galvoAlignX, 'Callback', @galvoAlign_Callback);
    set(c.galvoAlignY, 'Callback', @galvoAlign_Callback);
    
    set(c.galvoOptimize, 'Callback', @galvoOpt_Callback);
    
    % Automation Fields ---------------------------------------------------
    set(c.autoV1X, 'Callback', @limit_Callback);                    % Same as the limit callbacks above
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
    
    set(c.autoNXRm, 'Callback', @autoRange_Callback);               % This callback makes the field an integer using makeInteger_Callback and also prevents the
    set(c.autoNXRM, 'Callback', @autoRange_Callback);               % m - [m]inimum - field from being greater than the M - [M]aximum - field and visa versa.
    set(c.autoNYRm, 'Callback', @autoRange_Callback);
    set(c.autoNYRM, 'Callback', @autoRange_Callback);
    set(c.autonRm,  'Callback', @autoRange_Callback);
    set(c.autonRM,  'Callback', @autoRange_Callback);
    
    set(c.autoV1NX, 'Callback', @makeInteger_Callback);             % This forces the field to be an integer.
    set(c.autoV2NX, 'Callback', @makeInteger_Callback);
    set(c.autoV3NX, 'Callback', @makeInteger_Callback);
    set(c.autoV4NX, 'Callback', @makeInteger_Callback);
    
    set(c.autoV1NY, 'Callback', @makeInteger_Callback);
    set(c.autoV2NY, 'Callback', @makeInteger_Callback);
    set(c.autoV3NY, 'Callback', @makeInteger_Callback);
    set(c.autoV4NY, 'Callback', @makeInteger_Callback);
    
    set(c.autoV123n, 'Callback', @makeInteger_Callback);
    set(c.autoV4n,   'Callback', @makeInteger_Callback);
    
    set(c.autoV1Get, 'Callback', @setCurrent_Callback);             % These set the fields for vectors 1->4 to be the current position
    set(c.autoV2Get, 'Callback', @setCurrent_Callback);
    set(c.autoV3Get, 'Callback', @setCurrent_Callback);
    set(c.autoV4Get, 'Callback', @setCurrent_Callback);
    
    set(c.autoPreview, 'Callback',  @autoPreview_Callback);               % Displays the devices that will be tested to an axes. Useful for error-correcting
    set(c.autoTest, 'Callback',  @autoTest_Callback);               % Displays the devices that will be tested to an axes. Useful for error-correcting
    set(c.autoButton, 'Callback',  @automate_Callback);             % Starts the automation!
    set(c.autoProceed, 'Callback',  @proceed_Callback);             % Button to proceed to the next device. The use has the option to use this to proceed or 
                                                                    % to autoproceed using a checkbox.
    set(c.autoStop, 'Callback',  @autoStop_Callback);
    % Counter Fields -----------------------------------------
    set(c.counterButton, 'Callback',  @counter_Callback);           
                                       % to autoproceed using a checkbox.
    % Spectra Fields (unfinished) -----------------------------------------
    set(c.spectrumButton, 'Callback',  @takeSpectrum_Callback);           
    
    % Tracking Fields
    set(c.start_vid, 'Callback',  @startvid_Callback);
    set(c.stop_vid, 'Callback',  @stopvid_Callback);
    set(c.track_clear, 'Callback',  @cleartrack_Callback);
    set(c.track_set, 'Callback',  @settrack_Callback);
    
    
    % UI Fields -----------------------------------------------------------
    % set(c.parent, 'ButtonDownFcn', @click_Callback);
    set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
    set(c.counterAxes, 'ButtonDownFcn', @click_Callback);
    set(gcf,'WindowButtonDownFcn', @click_trackCallback);
    
    set(c.mouseEnabled, 'Callback', @mouseEnabled_Callback);
    
%     set(c.microInit, 'Callback', @microInit_Callback);
    
    % Create the joystick object =====
    try
        c.joy = vrjoystick(1);
        c.joystickEnabled = 1;
    catch err
        display(err.message);
        c.joystickEnabled = 0;
    end
    
    % We do resizing programatically
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    % Initial rendering
    resizeUI_Callback(0, 0);
    renderUpper();
%     displayImage();
    setGalvoAxesLimits();
    
    set(c.parent, 'Visible', 'On');
    
    
    % Initiate Everything...
    initAll();
    
    % Start main loop
    main();
    
    function main()
              
        while c.running     % c.running is currently unused, but likely will be used.
            if ~c.focusing
                [outputXY, outputZ] = readJoystick();

                if outputXY && c.microInitiated % If X or Y have been changed
                    setPos();
                end

                if outputZ && c.daqInitiated  % If Z has been changed
                    daqOut();
                end

                getCurrent();
            end

            renderUpper();
                    
            pause(.06); % 60 Hz (should later make this run so we actually delay to 60 Hz)
        end
    end

    % INPUTS ==============================================================
    function [outputXY, outputZ] = readJoystick()
        outputXY = 0;
        outputZ = 0;
        if c.joystickEnabled == 1   % If the joystick is enabled...
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
            c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.microStep*(1+a(4))*5;
            c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.microStep*(1+a(4))*5;
            
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
                pov = [direction(sind(p)) (-direction(cosd(p)))];
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
    function out = direction(num)
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
        % Limits the value of a field to the range acceptable for the
        % device it governs. e.g. piezos are limited 0 -> 10 V.
        % MICROMETERS =====
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

        % PIEZOS =====
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

        % GALVOS =====
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
    function figure_WindowKeyPressFcn(~, eventdata)
        if c.microInitiated && c.daqInitiated && c.outputEnabled && ~c.galvoScanning
            changed = true;
            
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
                otherwise
                    changed = false;
            end   
            
            if changed
                limit();    % Make sure we do not overstep...

                daqOut();   % (piezos, galvos)
                setPos();   % (micrometers)
            end
        end
    end
    function saveState()
        piezoZ = c.piezo(3);
        save('state.mat', 'piezoZ');
    end
    function getState()
        try
            data = load('state.mat');
            piezoZ = data.piezoZ;
        catch err
            dipslay(err.message);
            piezoZ = 0;
        end
        
        piezoOutSmooth([c.piezo(1), c.piezo(2), piezoZ]);
    end
    function closeRequest(~,~)
        display('Starting Deinitialization Sequence');
        c.running = false;
        c.outputEnabled = false;
        
        saveState();
        display('Saved State');
        
        try     % Release the Micrometers
            cmd(c.microXSerial, c.microXAddr, 'RS');
            fclose(c.microXSerial); delete(c.microXSerial); clear c.microXSerial;

            cmd(c.microYSerial, c.microYAddr, 'RS');
            fclose(c.microYSerial); delete(c.microYSerial); clear c.microYSerial;
            display('Released Micrometers...');
        catch err
            display(err.message);
        end
        
        try     % Reset and release the DAQ devices
            daqOutSmooth([0 0 0 0 0]);
            
            c.s.release();   
            display('Released DAQs...');
        catch err
            display(err.message);
        end
        
       %Need to check if the counter is disabled
       try
        if get(c.counterButton, 'Value') == 1
            display('Closing SPCM Counter...')
            stop(c.lhC);
            delete(c.lhC);
        end
        try
            display('Closing Track Counter...')
            stop(c.tktime);
            delete(c.tktime);
        catch err
           display(err.message);
       end       
       catch err
           display(err.message);
       end
        
        % Release the graphics
        delete(c.imageAxes);
        delete(c.upperAxes);
        delete(c.lowerAxes);
%         delete(c.counterAxes);
        
        delete(c.parent);
        display('Released Graphics...');
    end

    % OUTPUTS =============================================================
    % --- INIT ------------------------------------------------------------
    function microInit_Callback(~, ~)
        while c.microInitiated == 0
            display('Starting Initialization Sequence');
            try
                % X-axis actuator =====
                c.microXPort = 'COM5'; % USB Port that X is connected to (we view it as a serial port)
                c.microXAddr = '1';

                c.microXSerial = serial(c.microXPort);
                set(c.microXSerial, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                    'FlowControl', 'software', 'Terminator', 'CR/LF');
                fopen(c.microXSerial);

                pause(.25);

                %cmd(c.microXSerial, c.microXAddr, 'PW1'); 
                cmd(c.microXSerial, c.microXAddr, 'HT1'); 
                cmd(c.microXSerial, c.microXAddr, 'SL-5');     % negative software limit x=-5
                cmd(c.microXSerial, c.microXAddr, 'BA0.003');      % disable backlash compensation
                cmd(c.microXSerial, c.microXAddr, 'FF05');
               
                cmd(c.microXSerial, c.microXAddr, 'PW0');

                pause(.25);

                cmd(c.microXSerial, c.microXAddr, 'OR'); %Get to home state (should retain position)

                pause(.25);

                display('Done Initializing X Axis');


                % Y-axis actuator =====
                c.microYPort = 'COM6'; % USB Port that Y is connected to (we view it as a serial port)
                c.microYAddr = '1';

                c.microYSerial = serial(c.microYPort);
                set(c.microYSerial,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
                    'FlowControl', 'software','Terminator', 'CR/LF');
                fopen(c.microYSerial);

                pause(.25);

               % cmd(c.microYSerial, c.microYAddr, 'PW1'); 
                cmd(c.microYSerial, c.microYAddr, 'HT1'); 
                cmd(c.microYSerial, c.microYAddr, 'SL-5');   % negative software limit y=-5
                cmd(c.microYSerial, c.microYAddr, 'BA0.003');    % disable backlash compensation
                cmd(c.microYSerial, c.microYAddr, 'FF5');
               
                cmd(c.microYSerial, c.microYAddr, 'PW0');

                pause(.25);

                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state

                pause(.25);

                display('Done Initializing Y Axis');

                c.microInitiated = 1;

                set(c.microText, 'ForegroundColor', 'black');
            catch err
                display(err.message);
            end   
        end
    end
    function daqInit_Callback(~, ~)
        if c.daqInitiated == 0
            c.s = daq.createSession('ni');
            
            % Piezos    o 1:3
            c.s.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoX,      'Voltage');
            c.s.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoY,      'Voltage');
            c.s.addAnalogOutputChannel(c.devPiezo,   c.chnPiezoZ,      'Voltage');
            set(c.piezoText, 'ForegroundColor', 'black');
            
            % Galvos    o 4:5
            c.s.addAnalogOutputChannel(c.devGalvo,   c.chnGalvoX,      'Voltage');
            c.s.addAnalogOutputChannel(c.devGalvo,   c.chnGalvoY,      'Voltage');
            set(c.galvoText, 'ForegroundColor', 'black');
            
            % Counter   i 1
            c.s.addCounterInputChannel(c.devSPCM,    c.chnSPCM,      'EdgeCount');

            daqOut();
%             piezoOutSmooth([5 5 0]);
            
            c.daqInitiated = 1;
            
            resetPiezoXY_Callback(0, 0);
        end
    end
    function videoInit()
        % Get video source
        c.vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
%         src = getselectedsource(c.vid);

        c.vid.FramesPerTrigger = 1;
        
        % Send the image from the source to the imageAxes
        axes(c.imageAxes);
        vidRes = c.vid.VideoResolution;
        nBands = c.vid.NumberOfBands;
        hImage = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(1) 1]);
        preview(c.vid, hImage);
        
        axes(c.track_Axes) ;
        frame = getsnapshot(c.vid);
        c.track_img=imshow(frame);
        
%         set(c.imageAxes, 'ButtonDownFcn', @makePopout_Callback);
%         set(hImage, 'ButtonDownFcn', @makePopout_Callback);
    end
 
    function initAll()
        % Self-explainatory
        try
            daqInit_Callback(0,0);
            videoInit();
            microInit_Callback(0,0);
            
            getState();

%             focus_Callback(0,0);
            
            getCurrent();

            c.running = 1;
        catch err
            display(err.message);
        end
    end
    % --- MICROMETER ------------------------------------------------------
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
        % Sets the position of the micrometers if the micrometers are
        % initiated and output is enabled.
        if c.outputEnabled && c.microInitiated
            cmd(c.microXSerial, c.microXAddr, ['SE' num2str(c.micro(1)/1000)]); % Remember that c.micro is in um and we must convert to mm
            cmd(c.microYSerial, c.microYAddr, ['SE' num2str(c.micro(2)/1000)]);
            fprintf(c.microXSerial, 'SE'); fprintf(c.microYSerial, 'SE');
        end
    end
    % --- UI GETTING ------------------------------------------------------
    function getCurrent()
        getPos();
        getGalvo();
        getPiezo();
    end
    function getGalvo()
        set(c.galvoXX, 'String', 1000*c.galvo(1));
        set(c.galvoYY, 'String', 1000*c.galvo(2));
    end
    function getPiezo()
        set(c.piezoXX, 'String', c.piezo(1));
        set(c.piezoYY, 'String', c.piezo(2));
        set(c.piezoZZ, 'String', c.piezo(3));
    end
    % --- GOTO/SMOOTH OUT -------------------------------------------------
    function goto_Callback(~, ~)
        % Set the micrometers to the XY values in the goto box
        c.micro = [str2double(get(c.gotoMX, 'String')) str2double(get(c.gotoMY, 'String'))];
        setPos();
        renderUpper();
    end
    function gotoActual_Callback(~, ~)
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
                set(c.gotoGX, 'String', c.galvo(1)*1000);
                set(c.gotoGY, 'String', c.galvo(2)*1000);
        end
    end
    function gotoPiezo_Callback(~, ~)
        % Sends the piezos to the location currently stored in the fields.
        piezoOutSmooth([str2double(get(c.gotoPX, 'String')) str2double(get(c.gotoPY, 'String')) str2double(get(c.gotoPZ, 'String'))]);
    end
    function gotoGalvo_Callback(~, ~)
        % Sends the galvos to the location currently stored in the fields.
        galvoOutSmooth([str2double(get(c.gotoGX, 'String'))/1000 str2double(get(c.gotoGY, 'String'))/1000]);
    end
    function daqOutSmooth(to)
        % Smoothly sends all the DAQ devices to the location defined by 'to'.
        if c.outputEnabled && c.daqInitiated && ~c.isCounting
            prev = [c.piezo c.galvo];   % Get the previous location.
            c.piezo = to(1:3);          % Set the new location.
            c.galvo = to(4:5);
            curr = [c.piezo c.galvo];
            
            limit();                    % Make sure we aren't going over-bounds.
            
            steplist = [c.piezoStep c.piezoStep c.piezoStep c.galvoStep c.galvoStep];
            
            steps = round(max(abs(curr - prev)./steplist));    % Calculates which device 'furthest away from the target' and uses that device to define the speed.
            prevRate = c.s.Rate;
            c.s.Rate = 1000;
            
            if steps > 0    % If there is something to do...
                queueOutputData(c.s,   [linspace(prev(1), curr(1), steps)'  linspace(prev(2), curr(2), steps)' linspace(prev(3), curr(3), steps)' linspace(prev(4), curr(4), steps)' linspace(prev(5), curr(5), steps)']);
                c.s.startForeground();
            end
            
            c.s.Rate = prevRate;
            
            getCurrent();   % Sets the UI to the current location.
        end
    end
    function piezoOutSmooth(to)
        % Only modifies the piezo.
        daqOutSmooth([to c.galvo]);
    end
    function galvoOutSmooth(to)
        % Only modifies the galvo.
        daqOutSmooth([c.piezo to]);
    end
    function daqOut()
        % Abruptly sends all the DAQ devices to the location defined by 'to'.
        if c.outputEnabled && c.daqInitiated && ~c.isCounting
            c.s.outputSingleScan([c.piezo c.galvo]);
        end
        getCurrent();       % Sets the UI to the current location.
    end
    % --- RESETS ----------------------------------------------------------
    function resetMicro_Callback(~, ~)
        c.micro = [0 0];
        setPos();
    end
    function resetPiezoXY_Callback(~, ~)
        piezoOutSmooth([0 0 c.piezo(3)]);   % Always approach from [0 0]
        piezoOutSmooth([5 5 c.piezo(3)]);
    end
    function resetPiezo_Callback(~, ~)
        piezoOutSmooth([0 0 0]);
        piezoOutSmooth([5 5 0]);
    end
    function resetGalvo_Callback(~, ~)
        galvoOutSmooth([.2 .2]);
        galvoOutSmooth([0 0]);
    end
    % --- OPTIMIZATION ----------------------------------------------------
    function focus_Callback(~, ~)
        display('    begin focusing');
        
        c.focusing = 1;
        prevContrast = 0;
        direction = 1;
        
        prev10 = [0 0 0 0 0 0 0 0 0 0];
        
        n = 1;
        
        while c.focusing
            start(c.vid);
            data = getdata(c.vid);
            img = data(121:360, 161:480);
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
                
           daqOut();
            
            if (sum(prev10 == 0) == 0) && abs(prev10(1) - prev10(2)) <= std(prev10)/4
                c.focusing = 0;
            end
            
            getPiezo();
        end
        
        display('    end focusing');
    end
    function optXY_Callback(~, ~)
        piezoOptimizeXY();
    end
    function piezoOptimizeXY()
%         resetPiezoXY_Callback(0, 0);
        
        % Method 1
        range = .8;
        pixels = 40;
        
        %prev = [5 5];
        
        c.s.Rate = 200;
        
        steps =      round(pixels);
        stepsFast =  round(pixels/8);

        % New method
        up =    linspace(-range + c.piezo(1),  range + c.piezo(1), steps);
        down =  linspace( range + c.piezo(1), -range + c.piezo(1), stepsFast);
        up2 =   linspace(-range + c.piezo(2),  range + c.piezo(2), steps);
        
        if sum(up < 0) ~= 0 || sum(down < 0) ~= 0 || sum(up2 < 0) ~= 0
            error('Piezos might go negative!');
        end
        X = up;
        Y = up2;

        final = ones(steps);
%             prev = 0;
        i = 1;

        otherRows =     [c.piezo(3)*ones(steps,1)       c.galvo(1)*ones(steps,1)        c.galvo(2)*ones(steps,1)];
        otherRowsFast = [c.piezo(3)*ones(stepsFast,1)   c.galvo(1)*ones(stepsFast,1)    c.galvo(2)*ones(stepsFast,1)];

        prev = c.piezo;

%         resetPiezo_Callback(0, 0);
        piezoOutSmooth([0       0       c.piezo(3)]);
        piezoOutSmooth([up(1)   up2(1)  c.piezo(3)]);

        set(c.piezoXX, 'String', '(scanning)');
        set(c.piezoYY, 'String', '(scanning)');

%             queueOutputData(c.s, [piezoRowsFast     linspace(c.galvo(1),  mvConv*range/2, stepsFast)'    linspace(0,  -mvConv*range/2, stepsFast)']);
%             c.s.startForeground();    % Goto starting point from 0,0

        yCopy = 0;
        
%         set(c.lowerAxes, 'Xdir', 'reverse', 'Ydir', 'reverse');

        for y = up2
            yCopy = y;
%             if get(c.galvoButton, 'Value') == 0 && useUI
%                 break;
%             end

%             display(c.s.Rate);

            queueOutputData(c.s, [up'     y*ones(length(up2),1) otherRows]);
            [out, ~] = c.s.startForeground();
            
            queueOutputData(c.s, [down'   linspace(y, y + up2(2) - up2(1), length(down))' otherRowsFast]);
            c.s.startForeground();
            
            final(i,:) = [diff(out(:,1)') mean(diff(out(:,1)'))];
            
%             tic
            if i > 1
%                     up
%                     up(1:i)
%                     final(1:i,:)
                surf(c.lowerAxes, up(1:pixels), up2((1):(i)), final((1):(i),:), 'EdgeColor', 'none');   % Display the graph on the backscan
%                     surf(c.lowerAxes, up./mvConv, up(1:i)./mvConv, final(1:i,:), 'EdgeColor', 'none');   % Display the graph on the backscan
                view(c.lowerAxes,2);
                set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
               
%                 strings = get(c.galvoC, 'string');
%                 curval = get(c.galvoC, 'value');
% %                     strings{curval}
%                 colormap(c.lowerAxes, strings{curval});

                xlim(c.lowerAxes, [up(1)       up(end)]);
                ylim(c.lowerAxes, [up2(1)      up2(end)]);
%                 zlim(c.lowerAxes, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
            end
%             toc

            i = i + 1;

            c.s.wait();
        end
        
        
%         set(c.lowerAxes, 'Xdir', 'normal', 'Ydir', 'normal');
        
        m = min(min(final)); M = max(max(final));
        final = (final - m)/(M - m);
        
        [fx, fy] = myMean(final.*(final > .7), X, Y);
        
        piezoOutSmooth([0      0       c.piezo(3)]);
        piezoOutSmooth([up(1)  up2(1)  c.piezo(3)]);
        piezoOutSmooth([up(1)  fy      c.piezo(3)]);
        piezoOutSmooth([fx     fy      c.piezo(3)]);
        
%         notOptimized = 1;
        
        % Old method
        while false && notOptimized && c.running
            display(range);
            
%             rows = wextend('ar', 'ppd', [c.piezo(3) c.galvo], 10, 'd');
            rows = [c.piezo(3)*ones(pixels+1,1) c.galvo(1)*ones(pixels+1,1) c.galvo(2)*ones(pixels+1,1)];
            
            upx = linspace(c.piezo(1)-range, c.piezo(1)+range, pixels+1);
            upy = linspace(c.piezo(2)-range, c.piezo(2)+range, pixels+1);
            
%             piezoOutSmooth([upx(end)  upy(end) c.piezo(3)]);
            resetPiezoXY_Callback(0, 0);
            piezoOutSmooth([upx(1)  upy(1) c.piezo(3)]);
            
%             queueOutputData(c.s, [upx(1)  upy(1) c.piezo(3) c.galvo]);
            
            for y = upy(1:2:pixels+1)
                
                queueOutputData(c.s, [upx'           y*ones(pixels+1,1)            rows]);
                if y ~= upy(end)
                    queueOutputData(c.s, [upx(pixels+1:-1:1)'  (y+range/pixels)*ones(pixels+1,1)	rows]);
                end
            end
            
            [out, ~] = c.s.startForeground();
            
            c.piezo = [upx(end)  upy(end) c.piezo(3)];
            resetPiezoXY_Callback(0, 0);

%             size(reshape(out(1:end), pixels+1, []))
            
            data = reshape(out, [], pixels+1)';
            data = diff(data, 1, 2);
            data = data(1:2:end, :);
           
%             size(data);
            
            m = min(min(data)); M = max(max(data));
            
            if m ~= M
%                 figure()
%                 surf(data)
%                 pause(5);
                data = (data - m)/(M - m);
%                 data > .7
                [fx, fy] = myMean(data.*(data > .5), upx, upy(1:2:end));
                
                if fx > 10
                    fx = 10;
                end
                if fy > 10
                    fy = 10;
                end
                if fx < 0
                    fx = 0;
                end
                if fy < 0
                    fy = 0;
                end
            
%                 piezoOutSmooth([upx(1)  upy(1) c.piezo(3)]);
                
%                 piezoOutSmooth([x y c.piezo(3)]);
%                 piezoOutSmooth([5 5 c.piezo(3)]);
                
%                 (data > .7)
%                 figure()
%                 surf(data)
%                 pause(5);
%                 figure()
%                 plot(data)
%                 pause(5);
%                 hold(c.lowerAxes, 'on');
                scatter3(c.upperAxes, fx, fy, 0);
                xlim(c.upperAxes, [upx(1) upx(end)]);
                ylim(c.upperAxes, [upy(1) upy(end)]);
                zlim(c.upperAxes, [0 1]);
                dim = size(data);
                upy2 = upy(1:2:end);
                surf(c.lowerAxes, upx(1:dim(2)), upy2(1:dim(1)), data, 'EdgeColor', 'none');
                view(c.lowerAxes,2);
                set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
                xlim(c.lowerAxes, [upx(1) upx(end)]);
                ylim(c.lowerAxes, [upy(1) upy(end)]);
%                 hold(c.lowerAxes, 'off');
%                 pause(10);
                
                
                
%                 piezoOutSmooth([upx(end)  upy(end) c.piezo(3)]);
%                 resetPiezoXY_Callback(0, 0);
                piezoOutSmooth([upx(1)  upy(1)  c.piezo(3)]);
                piezoOutSmooth([upx(1)  fy      c.piezo(3)]);
                piezoOutSmooth([fx      fy      c.piezo(3)]);

                notOptimized = false;

%                 if sum(abs(c.piezo(1:2) - prev)) < c.piezoStep || 8*range < c.piezoStep
%                     notOptimized = false;
%                 end
                
                prev = c.piezo(1:2);
                
%                 range = range/4;
            end
            
%             range = range*2;
        end
%         while notOptimized
        
%         resetPeizoXY_Callback(0, 0);
    end
    function optZ_Callback(~, ~)
        piezoOptimizeZ();
    end
    function piezoOptimizeZ()
        
        % Method 1
        range = 5;
        pixels = 1000;
        
        prev = c.piezo(3);
        
        c.s.Rate = 1000;
        
        u = pixels+1;
        d = round(pixels/8);
            
        up =    [c.piezo(1)*ones(u,1) c.piezo(2)*ones(u,1) linspace(0, range, u)' c.galvo(1)*ones(u,1) c.galvo(2)*ones(u,1)];
        down =  [c.piezo(1)*ones(d,1) c.piezo(2)*ones(d,1) linspace(range, 0, d)' c.galvo(1)*ones(d,1) c.galvo(2)*ones(d,1)];

        piezoOutSmooth([c.piezo(1) c.piezo(2) 0]);
        
        queueOutputData(c.s, up);
        queueOutputData(c.s, down);

        [out, ~] = c.s.startForeground();

        data = diff(out);
        data = data(1:pixels);

        m = min(min(data)); M = max(max(data));

        if m ~= M
            data = (data - m)/(M - m);
            mask = ((up(1:pixels,3) > (prev - .5)) + (up(1:pixels,3) < (prev + .5))) == 2;
            mask = mask(1:length(data));
            data = data.*mask;
            data = data.*(data > .5);
            total = sum(sum(data));
            fz = sum((data').*(up(1:pixels,3)'))/total;

            if fz > 10
                fz = 10;
            end
            if fz < 0
                fz = 0;
            end
            
            if fz > 0
                c.piezo(3) = fz;

                queueOutputData(c.s, up((up(:,3) <= fz), :));

                c.s.startForeground();
            end
        end
    end
    function galvoOpt_Callback(~, ~)
        galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);   % Currently uses GUI values (should change, probably)
    end
    function [final] = galvoOptimize(range, upspeed, pixels)
        [final, X, Y] = galvoScanFull(false, range, upspeed, pixels);
        
        m = min(min(final)); M = max(max(final));
        data = (final - m)/(M - m);
        
        [x, y] = myMean(data.*(data > .7), X, Y);
        
        galvoOutSmooth([.2 .2]);
        galvoOutSmooth([X(1) Y(1)]);
        galvoOutSmooth([X(1) y]);
        galvoOutSmooth([x y]);
    end
    function [x, y] = myMean(data, X, Y)
        % New Method
        dim = size(data);
        
        data = data ~= 0;
    
        data = imdilate(data, strel('diamond', 1));

        [labels, ~] = bwlabel(data, 8);
        measurements = regionprops(labels, 'Area', 'Centroid');
        areas = [measurements.Area];
        [~, indexes] = sort(areas, 'descend');

        centroid = measurements(indexes(1)).Centroid;

        x = linInterp(1, X(1), dim(2), X(dim(2)), centroid(1));
        y = linInterp(1, Y(1), dim(1), Y(dim(1)), centroid(2));
    
        % Old Method
        % Calculates the centroid.
%         total = sum(sum(data));
%         dim = size(data);
%         x = sum(data*((X((length(X)-dim(2)+1):end))'))/total;
%         y = sum((Y((length(Y)-dim(1)+1):end))*data)/total;
    end
    function y = linInterp(x1, y1, x2, y2, x)    % Perhaps make it a spline in the future...
        if x1 < x2
            y = ((y2 - y1)/(x2 - x1))*(x - x1) + y1;
        elseif x1 > x2
            y = ((y1 - y2)/(x1 - x2))*(x - x2) + y2;
        else
            y = (y1 + y2)/2;
        end
    end
%     function data = displayImage()
%         start(c.vid);
%         data = getdata(c.vid)
%         
%         axes(c.imageAxes);
%         image(flipdim(data,1));
%     end

    % GALVOSCAN ===========================================================
    function galvoScan_Callback(~, ~)
        galvoScan(true);
    end
    function [final] = galvoScan(useUI)    
        [final, ~, ~] = galvoScanFull(useUI, c.galvoRange, c.galvoSpeed, c.galvoPixels);
    end
    function [final, X, Y] = galvoScanFull(useUI, range, upspeed, pixels)
        if useUI
            set(c.galvoButton, 'String', 'Stop!');
        end
        
        if get(c.galvoButton, 'Value') == 1 || ~useUI
            % range in microns, speed in microns per second (up is upscan; down is downscan)
            %Scan the Galvo +/- mvConv*range/2 deg
            %min step of DAQ = 20/2^16 = 3.052e-4V
            %min step of Galvo = 8e-4Deg
            %for galvo [1V->1Deg], 8e-4V->8e-4Deg

%             range =     c.galvoRange;
%             upspeed =   c.galvoSpeed;
%             pixels = c.galvoPixels;
            downspeed = c.galvoSpeed*8;

            mvConv =    .030/5;    % Micron to Voltage conversion (this is a guess! this should be changed!)
            steps =      round(pixels);
            stepsFast =  round(pixels*(upspeed/downspeed));

            maxGalvoRange = 5; % This is a likely-incorrect assumption.

            if mvConv*range > maxGalvoRange
                display('Galvo scanrange too large! Reducing to maximum.');
                range = maxGalvoRange/mvConv;
            end

            up =    linspace( (mvConv*range/2) + c.galvo(1), -(mvConv*range/2) + c.galvo(1), steps);
            down =  linspace(-(mvConv*range/2) + c.galvo(1),  (mvConv*range/2) + c.galvo(1), stepsFast);
            up2 =   linspace( (mvConv*range/2) + c.galvo(2), -(mvConv*range/2) + c.galvo(2), steps);
            X = up;
            Y = up2;

            final = ones(steps);
%             prev = 0;
            i = 1;
            
            rate = pixels*(upspeed/range);
            c.s.Rate = rate;

            
            piezoRows = [c.piezo(1)*ones(steps,1) c.piezo(2)*ones(steps,1) c.piezo(3)*ones(steps,1)];
            piezoRowsFast = [c.piezo(1)*ones(stepsFast,1) c.piezo(2)*ones(stepsFast,1) c.piezo(3)*ones(stepsFast,1)];
            
            prev = c.galvo;
            
%             resetGalvo_Callback(0, 0);
            galvoOutSmooth([.2 .2]);
            galvoOutSmooth([up(1) up2(1)]);
            
            set(c.galvoXX, 'String', '(scanning)');
            set(c.galvoYY, 'String', '(scanning)');
            
%             queueOutputData(c.s, [piezoRowsFast     linspace(c.galvo(1),  mvConv*range/2, stepsFast)'    linspace(0,  -mvConv*range/2, stepsFast)']);
%             c.s.startForeground();    % Goto starting point from 0,0
            
            yCopy = 0;
            
%             set(c.lowerAxes, 'Xdir', 'normal', 'Ydir', 'normal');

            for y = up2
                yCopy = y;
                if get(c.galvoButton, 'Value') == 0 && useUI
                    break;
                end
                %display('up');
                queueOutputData(c.s, [piezoRows	up'     y*ones(length(up2),1)]);
                [out, ~] = c.s.startForeground();

                %display('down');
                queueOutputData(c.s, [piezoRowsFast	down'   linspace(y, y + up2(2) - up2(1), length(down))']);
                c.s.startForeground();

                final(i,:) = [mean(diff(out(:,1)')) diff(out(:,1)') ]*rate;

                if i > 1
%                     up
%                     up(1:i)
%                     final(1:i,:)
                    surf(c.lowerAxes, up(1:pixels)./mvConv, up2((pixels):-1:(pixels-i+1))./mvConv, final(1:i,:), 'EdgeColor', 'none');   % Display the graph on the backscan
%                     surf(c.lowerAxes, up./mvConv, up(1:i)./mvConv, final(1:i,:), 'EdgeColor', 'none');   % Display the graph on the backscan
                    view(c.lowerAxes,2);
                    set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
                    
                    strings = get(c.galvoC, 'string');
                    curval = get(c.galvoC, 'value');
%                     strings{curval}
                    colormap(c.lowerAxes, strings{curval});
                    
                    xlim(c.lowerAxes, [up(end)/mvConv       up(1)/mvConv]);
                    ylim(c.lowerAxes, [up2(end)/mvConv      up2(1)/mvConv]);
    %                 zlim(c.lowerAxes, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
                end

                i = i + 1;

                c.s.wait();
            end
            
            c.galvo = [up(1) yCopy];

%             queueOutputData(c.s, [piezoRowsFast	linspace(mvConv*range/2, 0, stepsFast)'     linspace(yCopy, 0, stepsFast)']);
%             c.s.startForeground();    % Go back to start from finishing point

%             resetGalvo_Callback(0, 0);
            galvoOutSmooth([.2 .2]);
            galvoOutSmooth(prev);

%             c.galvo = [0 0];
            getGalvo();
        end
        
        if useUI
            set(c.galvoButton, 'String', 'Scan!');
            set(c.galvoButton, 'Value', 0);
        end    
    end
    function setGalvoAxesLimits()
        xlim(c.lowerAxes, [-c.galvoRange/2, c.galvoRange/2]);
        ylim(c.lowerAxes, [-c.galvoRange/2, c.galvoRange/2]);
    end
    function galvoVar_Callback(hObject, ~)
        limit_Callback(hObject,0);
        switch hObject
            case c.galvoR
                c.galvoRange = str2double(get(hObject, 'String'));
                setGalvoAxesLimits();
            case c.galvoS
                c.galvoSpeed = str2double(get(c.galvoS, 'String'));
            case c.galvoP
                makeInteger_Callback(c.galvoP, 0);
                c.galvoPixels = str2double(get(c.galvoP, 'String'));
        end
    end
    function galvoAlign_Callback(~, ~)
        if ~c.galvoAligning
        
            for i=1:5
               galvoAlignQueue();
            end
                               
            c.s.IsNotifyWhenDataAvailableExceedsAuto = false;
           % c.s.NotifyWhenDataAvailableExceeds = 500;
            c.s.Rate = 10000;
            c.s.IsContinuous = true;
            c.lh = addlistener(c.s, 'DataAvailable', @galvoScansRequired);
            c.galvoAligning = true;
            c.s.startBackground();
        end
    end
    function galvoScansRequired(~,~)
       
        if c.galvoAligning && get(c.galvoAlignX, 'Value') == 0 && get(c.galvoAlignY, 'Value') == 0
            stop(c.s);
            delete(c.lh);
            
            c.galvoAligning = false;
           % c.s.IsContinuous = false;
            
            %reset galvo position
            galvoAlignQueue();
            c.s.startForeground();
            stop(c.s);
            
            c.s.IsNotifyWhenScansQueuedBelowAuto = false;
            c.s.Rate = 1000;
        else
            pause(0.1)
            galvoAlignQueue();
        end
    end
    function galvoAlignQueue()
        m = zeros(1000, 5);
        m(:,1) = ones(1, 1000)*c.piezo(1);
        m(:,2) = ones(1, 1000)*c.piezo(2);
        m(:,3) = ones(1, 1000)*c.piezo(3);
        
        if get(c.galvoAlignX, 'Value') == 1
            m(:,4) = .1*sin(linspace(0, 2*3.141592, 1000));
        else
             m(:,4) = 0*sin(linspace(0, 2*3.141592, 1000));
        end
        
        if get(c.galvoAlignY, 'Value') == 1
            m(:,5) = .1*sin(linspace(0, 2*3.141592, 1000));
        else
            m(:,5) = 0*sin(linspace(0, 2*3.141592, 1000));
        end
        
       % m
        queueOutputData(c.s, m);
    end

    % SPECTROMETER ========================================================
    function sendSpectrumTrigger()
        set(c.spectrumButton, 'Enable', 'off');
        
        % create the trigger file
        fh = fopen('Z:\WinSpec_Scan\matlabfile.txt', 'w');  
        if (fh == -1) 
            error('oops, file cannot be written'); 
        end 
        fprintf(fh, 'Trigger Spectrum\n');
        fclose(fh);
    end
    function spectrum = waitForSpectrum(filename)
        file = '';
        spectrum = -1;
        
        t = now;
        
        i = 0;
        
        while c.running && i < 60
            try
                disp('    waiting')
                d = dir('Z:\WinSpec_Scan\s*.*');
                
                file = strcat('Z:\WinSpec_Scan\', d.name);
                if d.datenum > t % file == 'Z:\WinSpec_Scan\spec.SPE'
                    pause(.5);
                    spectrum = readSPE(file);
                end
            catch error
               % disp(error)
                pause(.5);
            end
            
            if spectrum ~=-1
                break
            end
            i = i + 1;
        end
        
        pause(.5);
        
        if c.running && spectrum ~=-1
            disp('    got the data!');

            %plot data -> delete file
    %         plot(1:512,image)
    %         axis([1 512 min(image) max(image)])

            if filename ~= 0    % If there is a filename, save there.
                save([filename '.mat'],'spectrum');
                disp('    Saved .mat file and cleared folder')
                
                i = 0;
                while i < 20
                    try
                        movefile(file, [filename '.SPE']);
                        break;
                    catch err
                        pause(.5);
                        display(err.message);
                    end
                    i = i + 1;
                end
            else                % Otherwise only delete
                i = 0;
                while i < 20
                    try
                        delete(file);
                        break;
                    catch err
                        pause(.5);
                        display(err.message);
                    end
                    i = i + 1;
                end
            end

            set(c.spectrumButton, 'Enable', 'on');
        elseif spectrum ~=-1
            display('Failed to get data; proceeding');
        end
    end
    function takeSpectrum_Callback(~,~)
        sendSpectrumTrigger();
        image = waitForSpectrum(0);
        
        plot(c.lowerAxes, 1:512, image)
        set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
        xlim(c.lowerAxes, [1 512]);
        ylim(c.lowerAxes, [min(image) max(image)]);
    end

    % AUTOMATION ==========================================================
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
    function autoPreview_Callback(~, ~)
        generateGrid();
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

        % +++++ Broken method with broken logic below:
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

        % +++++ Better matrix way:
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
        
        % +++++ Even better matrix way:
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

        V0 = V0 - nd123*v;
        
        c.p = zeros(3, diff(nxrange)*diff(nyrange)*diff(ndrange));
        color = zeros(diff(nxrange)*diff(nyrange)*diff(ndrange), 3);    % (silly matlab)
        name = cell(diff(nxrange)*diff(nyrange)*diff(ndrange),1);
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
                    name{i} = [c.device num2str(d) '_' c.set '[' num2str(x) ','  num2str(y) ']'];
                    
                    i = i + 1;
                end
            end
        end
        
        len = i-1;
        
        c.pv = p;           % Transportation variables
        c.pc = color;

%         xlim(c.upperAxes, [min(p(1,:)) max(p(1,:))]);
%         ylim(c.upperAxes, [min(p(2,:)) max(p(2,:))]);
%         scatter(c.upperAxes, p(1,:), p(2,:), 36, color);
    end
    function automate_Callback(~, ~)
        automate(false);
    end
    function autoTest_Callback(~, ~)
        automate(true);
    end
    function automate(onlyTest)
        c.autoScanning = true;
%         [V, V0, v, nxrange, nyrange, ndrange] = varin;
        
        nxrange = getStoredR('x');    % Range of the major grid
        nyrange = getStoredR('y');

        ndrange = getStoredR('d');    % Range of the minor grid
        
        [p, color, name, len] = generateGrid();
        
        if ~onlyTest
            clk = clock;

            superDirectory = c.directory;              % Setup the folders
            dateFolder =    [num2str(clk(1)) '_' num2str(clk(2)) '_' num2str(clk(3))];           % Today's folder is formatted in YYYY_MM_DD Form
            scanFolder =    ['Scan @ ' num2str(clk(4)) '-' num2str(clk(5)) '-' num2str(clk(6))]; % This scan's folder is fomatted in @ HH-MM-SS.sss
            directory =     [superDirectory '\' dateFolder];
            subDirectory =  [directory '\' scanFolder];

            [status, message, messageid] = mkdir(superDirectory, dateFolder);                   % Make sure today's folder has been created.
            display(message);

            [status, message, messageid] = mkdir(directory, scanFolder);                        % Create a folder for this scan
            display(message);

            prefix = [subDirectory '\'];
            
            results = true;
            
            try
                fh =  fopen([prefix 'results.txt'],         'w');  
                fhv = fopen([prefix 'results_verbose.txt'], 'w');
                fhb = fopen([prefix 'results_brief.txt'],   'w');

                if (fh == -1 || fhv == -1 || fhb == -1) 
                    error('oops, file cannot be written'); 
                end 
            
                fprintf(fhb, '  Set  |       Works       |\r\n');         % Change this in the future to be compatable with all possibilities.
                fprintf(fhb, ' [x,y] | 1 | 2 | 3 | 4 | 5 |');

                fprintf(fh, '  Set  |                          Counts                           |\r\n');
                fprintf(fh, ' [x,y] |     1     |     2     |     3     |     4     |     5     |');

                fprintf(fhv, 'Welcome to the verbose version of the results summary...\r\n\r\n');
            catch err
                display(err.message);
                results = false;
            end
            
            [fileNorm, pathNorm] = uigetfile('*.SPE','Select the bare-diamond spectrum');

            if isequal(fileNorm, 0)
                spectrumNorm = 0;
            else
                spectrumNorm = readSPE([pathNorm fileNorm]);
                
%                 tempP = plot(1, 'Visible', 'off');
%                 tempA = get(tempP, 'Parent');
%                 png = plot(tempA, 1:512, spectrumNorm);
%                 xlim(tempA, [1 512]);
%                 
% %                 png = plot(c.lowerAxes, 1:512, spectrumNorm);
% %                 xlim(c.lowerAxes, [1 512]);
% %                 
%                 saveas(png, [prefix 'normalization_spectrum.png']);
                save([prefix 'normalization_spectrum.mat'], 'spectrumNorm');
                copyfile([pathNorm fileNorm], [prefix 'normalization_spectrum.SPE']);
            end
            
            if results
                if spectrumNorm == 0
                    fprintf(fhv, 'No bare-diamond normalization was selected.\r\n\r\n');
                else
                    fprintf(fhv, ['Bare diamond normalization was selected from:\r\n  ' pathNorm fileNorm '\r\n\r\n']);
                end
            end
        end
        
        original = c.micro;
        
        i = 1;

        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for d = ndrange(1):ndrange(2)
                    if c.autoScanning
                        try
                            c.micro = p(1:2,i)' - [10 10];
                            setPos();

                            while sum(abs(c.microActual - c.micro)) > .1
                                pause(.1);
                                getPos();
                                renderUpper();
                            end

                            c.micro = p(1:2,i)';
                            setPos();

                            while sum(abs(c.microActual - c.micro)) > .1
                                pause(.1);
                                getPos();
                                renderUpper();
                            end

                            piezoOutSmooth([5 5 p(3,i)]);

                            display(['Arrived at ' name{i}]);

                            if ~onlyTest
                                old = [c.piezo c.galvo];

                                display('  Focusing...');

                                focus_Callback(0, 0);

                                try
                                    start(c.vid);
                                    data = getdata(c.vid);
                                    img = data(360:-1:121, 161:480);    % Fixed flip...
                                catch err
                                    display(err.message)
                                end

                                display('  Optimizing...');

                                piezoOptimizeXY();
                                intitial = galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);

                                if results
                                    fprintf(fhv, ['We moved to DEVICE ' num2str(d) ' of SET [' num2str(x) ',' num2str(y) ']\r\n']);
                                    fprintf(fhv, ['    Z was initially focused to ' num2str(c.piezo(3)) ' V\r\n']);
                                    fprintf(fhv, ['                          from ' num2str(old(3)) ' V.\r\n']);
                                    fprintf(fhv, ['    XY were optimized to ' num2str(c.piezo(1)) ', ' num2str(c.piezo(2))  ' V\r\n']);
                                    fprintf(fhv, ['                    from ' num2str(old(1))   ', ' num2str(old(2))    ' V.\r\n']);
                                    fprintf(fhv, ['    The galvos were optimized to ' num2str(c.galvo(1)*1000) ', ' num2str(c.galvo(2)*1000) ' mV\r\n']);
                                    fprintf(fhv, ['                            from ' num2str(old(4)*1000) ', ' num2str(old(5)*1000) ' mV.\r\n']);
                                    fprintf(fhv, ['    This gave us an inital countrate of ' num2str(round(max(max(intitial)))) ' counts/sec.\r\n']);
                                end

                                old = [c.piezo c.galvo];

                                piezoOptimizeZ();
                                piezoOptimizeXY();

                                if results
                                    fprintf(fhv, ['    Z was optimized to ' num2str(c.piezo(3)) ' V\r\n']);
                                    fprintf(fhv, ['                  from ' num2str(old(3)) ' V.\r\n']);
                                    fprintf(fhv, ['    XY were optimized to ' num2str(c.piezo(1)) ', ' num2str(c.piezo(2))  ' V\r\n']);
                                    fprintf(fhv, ['                    from ' num2str(old(1))   ', ' num2str(old(2))    ' V.\r\n']);
                                end

                                old = [c.piezo c.galvo];

                                piezoOptimizeZ();

                                display('  Scanning...');

                                scan = galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);

                                if results
                                    fprintf(fhv, ['    Z was optimized to ' num2str(c.piezo(3)) ' V\r\n']);
                                    fprintf(fhv, ['                  from ' num2str(old(3)) ' V.\r\n']);
                                    fprintf(fhv, ['    The galvos were optimized to ' num2str(c.galvo(1)*1000) ', ' num2str(c.galvo(2)*1000) ' mV\r\n']);
                                    fprintf(fhv, ['                            from ' num2str(old(4)*1000) ', ' num2str(old(5)*1000) ' mV.\r\n']);
                                    fprintf(fhv, ['    Another scan was taken, with a countrate of ' num2str(round(max(max(scan)))) ' counts/sec.\r\n']);
                                end

                                display('  Taking Spectrum...');

                                try
                                    sendSpectrumTrigger();
                                    spectrum = waitForSpectrum([prefix name{i} '_spectrum']);
                                catch err
                                    display(err.message)
                                end

                                display('  Saving...');
                
%                                 tempP = plot(1, 'Visible', 'off');
%                                 tempA = get(tempP, 'Parent');
%                                 png = plot(tempA, 1:512, spectrumNorm);
%                                 xlim(tempA, [1 512]);
%     %                             png = plot(c.lowerAxes, 1:512, spectrum);
%     %                             xlim(c.lowerAxes, [1 512]);
%                                 saveas(png, [prefix name{i} '_spectrum' '.png']);

                                if spectrumNorm ~= 0
                                    spectrumFinal = double(spectrum - min(spectrum))./double(spectrumNorm - min(spectrumNorm) + 50);
                                    save([prefix name{i} '_spectrumFinal' '.mat'], 'spectrumFinal');

                
%                                     tempP = plot(1, 'Visible', 'off');
%                                     tempA = get(tempP, 'Parent');
%                                     png = plot(tempA, 1:512, spectrumNorm);
%                                     xlim(tempA, [1 512]);
%     %                                 png = plot(c.lowerAxes, 1:512, spectrumFinal);
%     %                                 xlim(c.lowerAxes, [1 512]);
%                                     saveas(png, [prefix name{i} '_spectrumFinal' '.png']);
                                end

                                save([prefix name{i} '_galvo' '.mat'], 'scan');

                                imwrite(rot90(intitial,2)/max(max(intitial)), [prefix name{i} '_galvo_debug' '.png']);  % rotate because the dims are flipped.
                                imwrite(rot90(scan,2)/max(max(scan)), [prefix name{i} '_galvo' '.png']);

                                imwrite(img, [prefix name{i} '_blue' '.png']);

                                if results
                                    display('  Remarking...');

                                    counts = max(max(scan));
    %                                 counts2 = max(max(intitial));

                                    J = imresize(scan, 5);
                                    J = imcrop(J, [length(J)/2-25 length(J)/2-20 55 55]);

                                    level = graythresh(J);
                                    IBW = im2bw(J, level);
                                    [centers, radii] = imfindcircles(IBW, [15 60]);    

    %                                 IBW = im2bw(scan, graythresh(scan));
    %                                 [centers, radii] = imfindcircles(IBW,[5 25]);

                                    if d == ndrange(1)
                                        fprintf(fhb, ['\r\n [' num2str(x) ',' num2str(y) '] |']);
                                        fprintf(fh,  ['\r\n [' num2str(x) ',' num2str(y) '] |']);
                                    end

                                    if ~isempty(centers)
                                        fprintf(fhb, ' W |');
                                        fprintf(fh, [' W ' num2str(round(counts), '%07i') ' |']);
                                        fprintf(fhv, '    Our program detects that this device works.\r\n\r\n');
                                    else
                                        fprintf(fhb, '   |');
                                        fprintf(fh, ['   ' num2str(round(counts), '%07i') ' |']);
                                        fprintf(fhv, '    Our program detects that this device does not work.\r\n\r\n');
                                    end
                                end

                                display('  Finished...');

                                resetGalvo_Callback(0,0);

                                while ~(c.proceed || get(c.autoAutoProceed, 'Value'))
                                    pause(.5);
                                end
                            else
                                pause(.5);
                            end
                        catch err
                            if results
                                try
                                    fprintf(fhb, ' F |');
                                    fprintf(fh, [' F ' num2str(0, '%07i') ' |']);
                                    fprintf(fhv, '    Something went horribly wrong with this device... Skipping to the next one.\r\n\r\n');
                                catch err2
                                    display(['Something went horribly when trying to say that something went horribly wrong with device ' name{i}]);
                                    display(err2.message);
                                end
                            end
                            display(['Something went horribly wrong with device ' name{i} '... Here is the error message:']);
                            display(err.message);
                        end
                        
                        i = i+1;
                    end
                end
            end
        end
        
        if ~onlyTest
            fclose(fhb);
            fclose(fh);
            fclose(fhv);
        end
        
        display('Totally Finished!');
            
        c.micro = original;
        setPos();
        
        c.autoScanning = false;
    end
    function proceed_Callback(~, ~)
        c.proceed = true;
    end
    function autoStop_Callback(~, ~)
        c.autoScanning = false;
    end

    % UI ==================================================================
    function renderUpper()
        if c.axesMode ~= 2
            p =     [c.pv   [c.microActual(1) c.microActual(2) c.piezo(3)]' [c.micro(1) c.micro(2) c.piezo(3)]'];
            color = [c.pc;   [1 0 1];  [0 0 0]];
            
            mx = min(p(1,:));   Mx = max(p(1,:));   Ax = (Mx + mx)/2;   Ox = .55*(Mx - mx) + 25;
            my = min(p(2,:));   My = max(p(2,:));   Ay = (My + my)/2;   Oy = .55*(My - my) + 25;
            
            Of = Ox;
            
            if Ox < Oy
                Of = Oy;
            end
            
            scatter(c.upperAxes, p(1,:), p(2,:), 36, color);
            
            xlim(c.upperAxes, [Ax-Of Ax+Of]);
            ylim(c.upperAxes, [Ay-Of Ay+Of]);
        
%             if sum(c.boxX ~= -1) ~= 0 % If the vals are not all -1...
%                 plot(c.upperAxes, c.microActual(1), c.microActual(2), 'dr', c.micro(1), c.micro(2), 'dk'); % , c.boxX, c.boxY, ':r', c.boxPrev(1), c.boxPrev(2), 'pr', c.boxCurr(1), c.boxCurr(2), 'hr');
%                 set(c.upperAxes, 'HitTest', 'off');
%                 if get(c.mouseEnabled, 'Value')
%                     set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
%                 end
%                 set(get(c.upperAxes,'Children'), 'ButtonDownFcn', '');
%                 set(get(c.upperAxes,'Children'), 'HitTest', 'off');
                
               
%             else
%                 plot(c.upperAxes, c.linAct(1), c.linAct(2), 'd');
%             end
% 
%             xlim(c.upperAxes, [0 25000]);
%             ylim(c.upperAxes, [0 25000]);
        end
    end
    function resizeUI_Callback(~, ~)
        p = get(c.parent, 'Position');
        w = p(3); h = p(4);
        
        % 640x480

        % Axes Position =====
%         S = w-pw-2*gp;
%         set(c.imageAxes,    'Position', [gp (h-gp-S*(480/640)) S S*(480/640)]);
        
        if ((w-pw-2*gp) > (640/480)*(h-2*gp)) % If Width is unlimiting
            S = (640/480)*(h-2*gp);   % Error here is known; too lazy to fix
            set(c.imageAxes,    'Position', [gp (h-gp-S*(480/640)) S S*(480/640)]);
        
%             if ((w-pw-3*gp)/2 < (h-S*(480/640)-3*gp)) % If Width is limiting
                s = (w-pw-3*gp-S);
                set(c.upperAxes,    'Position', [2*gp+S h-gp-s      s s]);
                set(c.lowerAxes,    'Position', [2*gp+S h-2*(gp+s)  s s]);
                set(c.counterAxes,  'Position', [2*gp+S gp          s h-2*(2*gp+s)]);
%             else                        % If Height is limiting
%                 s = (h-S*(480/640)-3*gp);
%                 set(c.lowerAxes,    'Position', [(w-pw)/4 - s/2 gp s s]);
%                 set(c.upperAxes,    'Position', [3*(w-pw)/4 - s/2 gp s s]);
%             end
        elseif ((w-pw-2*gp) < (640/480)*(3*h/4)) % If Width is limiting
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
        
%             if ((w-pw-3*gp)/2 < (h-S*(480/640)-3*gp)) % If Width is limiting
%                 s = (w-pw-3*gp)/2;
%                 set(c.lowerAxes,    'Position', [2*gp+w     gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
%                 set(c.upperAxes,    'Position', [gp         gp + (h - (h-S*(480/640)-3*gp) + s)/2 s s]);
%             else                        % If Height is limiting
                s = (h-S*(480/640)-3*gp);
                set(c.lowerAxes,    'Position', [(w-pw)/4 - s/2 gp s s]);
                set(c.upperAxes,    'Position', [3*(w-pw)/4 - s/2 gp s s]);
%             end
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
            catch err
                display('err');
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
                elseif val < .001
                    val = .001;
                end
            case c.galvoS
                if val > c.galvoSpeedMax
                    val = c.galvoSpeedMax;
                elseif val < .001
                    val = .001;
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
    function makePopout_Callback(~, ~)
        display('POPOUT');
        fig = figure();
        copyobj(c.imageAxes, fig);  % Temporary; need to figure out how to make this universal (type issues and parent problems)...
        set(c.imageAxes, 'Position', [.13 .11 .77 .815], 'ButtonDownFcn', []);
    end
    function bool = myIn(num, range)
        bool = (num > range(1)) && (num < range(2));
    end

    % COUNTER =============================================================
    function counter_Callback(hObject, ~)
        display('Counting started.');
        if hObject ~= 0 && get(hObject, 'Value') == 1
            c.lhC = timer;
            c.lhC.TasksToExecute = Inf;
            c.lhC.Period = 1/c.rateC;
            c.lhC.TimerFcn = @(~,~)counterListener;
            c.lhC.ExecutionMode = 'fixedSpacing';
%             c.lhC.StartDelay = 0;
%             c.lhC.StartFcn = [];
%         	c.lhC.StopFcn = [];
%         	c.lhC.ErrorFcn = [];

            c.dataC = zeros(1, c.lenC);
            c.iC = 0;
            c.isCounting = 1;
            c.prevCount = 0;
            
            start(c.lhC);
        elseif (hObject == 0 && get(c.counterButton, 'Value') == 1) || (hObject ~= 0 && get(hObject, 'Value') == 0)
            stop(c.lhC);
            delete(c.lhC);
            c.isCounting = 0;
        end
    end
    function counterListener(~, ~)
%         display('  Counting...');
%         c.sC.NumberOfScans = 8;
        
        c.dataC = circshift(c.dataC, [0 1]);
        
        try
            out = c.s.inputSingleScan();
        catch err
            out = 0;
            display(err);
            display('counter aquisiton failed');
        end
        
        c.dataC(1) = c.rateC*out - c.prevCount;
        
        c.prevCount = c.rateC*out;
        
        if c.iC < c.lenC
            c.iC = c.iC + 1;
        end
        
        cm = min(c.dataC(1:c.iC)); cM = max(c.dataC(1:c.iC)); cA = (cm + cM)/2; cO = .55*(cM - cm) + 1;
        
        if c.iC > 2
            plot(c.counterAxes, 1:c.iC, c.dataC(1:c.iC));
            set(c.counterAxes, 'ButtonDownFcn', @click_Callback);
            xlim(c.counterAxes, [1 c.lenC]);
            ylim(c.counterAxes, [cA - cO cA + cO]);
            
        end
        
%         c.iC = c.iC + 1;
    
    end

%   Popup Plots ===============================================================
    function mouseEnabled_Callback(~, ~)
        if get(c.mouseEnabled, 'Value')
           set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
           set(c.counterAxes, 'ButtonDownFcn', @click_Callback);
        else
           set(c.lowerAxes, 'ButtonDownFcn', '');
           set(c.counterAxes, 'ButtonDownFcn', '');
        end
    end
    function click_Callback(hObject, ~)
        try
            delete(c.pop);
        end
        c.pop=figure;
        hc = copyobj(hObject, gcf);
        set(hc, 'Units', 'normal','Position', [0.05 0.06 0.9 0.9]);
        uiwait(c.pop);
    end
            
%             
%             if c.axesMode == 0
%                 switch hObject
%                     case c.upperAxes
%                     c.axesMode = 1;
%                     set(c.lowerAxes, 'Visible', 'Off');
%                     set(get(c.lowerAxes,'Children'), 'Visible', 'Off');
%                 else
%                     c.axesMode = 2;
%                     set(c.upperAxes, 'Visible', 'Off');
%                     set(get(c.upperAxes,'Children'), 'Visible', 'Off');
%                 end
%             else
%                 c.axesMode = 0;
%                 set(c.upperAxes, 'Visible', 'On');
%                 set(c.lowerAxes, 'Visible', 'On');
%                 set(get(c.upperAxes,'Children'), 'Visible', 'On');
%                 set(get(c.lowerAxes,'Children'), 'Visible', 'On');
%             end
% 
%             resizeUI_Callback();
%         elseif strcmp(get(c.parent, 'SelectionType'), 'normal') && hObject == c.upperAxes
%             x = get(c.upperAxes,'CurrentPoint');
%             c.micro = x(1,1:2);
%             if c.outputEnabled
%                 setPos();
%             end
%             renderUpper();
%         end
    %end

%     function box_Callback(hObject, ~)
%         switch hObject
%             case c.boxTL
%                 type = 1;
%             case c.boxTR
%                 type = 2;
%             case c.boxBL
%                 type = 4;
%             case c.boxBR
%                 type = 3;
%             otherwise
%                 type = 0;
%         end
%         
%         c.boxPrev = c.boxCurr;
%         c.boxCurr = [c.linAct(1) c.linAct(2) type];
%         
%         calculateBox();
%     end
%     function calculateBox()
%         if c.boxCurr(3) ~= c.boxPrev(3) && c.boxCurr(3) ~= 0 && c.boxPrev(3) ~= 0
% %             c.boxPrev;
% %             c.boxCurr;
%             
%             type = mod(c.boxCurr(3) - c.boxPrev(3), 4);
%             
%             v1 = c.boxPrev(1:2);
%             v2 = c.boxCurr(1:2);
%             
%             switch type
%                 case 0      % This should not happen becasue of our first if
%                     error('renderBox error; something is terribly wrong!');
%                 case {1, 3}  % If points are on one side...
%                     if type == 3
%                         v1 = c.boxCurr(1:2);
%                         v2 = c.boxPrev(1:2);
%                     end
%                     
%                     ortho = ([0, 1; -1, 0]*(v2 - v1)')';
%                     
%                     c.boxX(1) = v1(1);
%                     c.boxX(2) = v2(1);
%                     c.boxX(3) = v2(1) + ortho(1);
%                     c.boxX(4) = v1(1) + ortho(1);
%                     c.boxX(5) = v1(1);
%                     
%                     c.boxY(1) = v1(2);
%                     c.boxY(2) = v2(2);
%                     c.boxY(3) = v2(2) + ortho(2);
%                     c.boxY(4) = v1(2) + ortho(2);
%                     c.boxY(5) = v1(2);
%                 case 2      % If points are across the diagonal...
%                     ortho = ([0, 1; -1, 0]*(v2 - v1)')';
%                     
%                     c.boxX(1) = v1(1);
%                     c.boxX(2) = (v1(1) + v2(1) + ortho(1))/2;
%                     c.boxX(3) = v2(1);
%                     c.boxX(4) = (v1(1) + v2(1) - ortho(1))/2;
%                     c.boxX(5) = v1(1);
%                     
%                     c.boxY(1) = v1(2);
%                     c.boxY(2) = (v1(2) + v2(2) + ortho(2))/2;
%                     c.boxY(3) = v2(2);
%                     c.boxY(4) = (v1(2) + v2(2) - ortho(2))/2;
%                     c.boxY(5) = v1(2);
%             end
%         else
%             c.boxX = [-1 -1 -1 -1 -1];
%             c.boxY = [-1 -1 -1 -1 -1];
%         end
%         
%         renderUpper();
%     end
    function startvid_Callback(hObject,~)
         if hObject ~= 0 && ~c.vid_on
            set(c.track_stat,'String','Status: Started vid');

                c.tktime = timer;
                c.tktime.TasksToExecute = Inf;
                c.tktime.Period = 1/c.ratevid;
                c.tktime.TimerFcn = @(~,~)tkListener;
                c.tktime.ExecutionMode = 'fixedSpacing';
                
                c.vid_on=1;
                c.seldisk=0;
                c.centroid_init=0;
                
                start(c.tktime);
         end
    end
    
    function tkListener(~, ~)
        % frame = getsnapshot(c.vid);
         frame= flipdim(rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\DC2\test_image.png')),1);
         
        if c.vid_on 
            %Sharpen image
            filter = fspecial('unsharp', 1);
            I1 = imfilter(flipdim(frame,1), filter);

            %Adjust contrast
            I2 = imtophat(I1,strel('disk',35));
            I3 = imadjust(I2);
                
            IBW=im2bw(I3,0.7);
            set(c.track_img,'CData',I3); 
 
            if ~isempty(c.roi)  
                c.roi_image = imcrop(IBW,c.roi);
                if c.centroid_init
                    
                    axes(c.roi_Axes); 
                    c.hroi=imshow(c.roi_image);
                    
                    [c.centroidXi,c.centroidYi]=centroid_fun();
                    set(c.track_stat,'String',['Got Initial Centroid']);
                    c.centroid_init=0;
                else
                    [c.centroidX,c.centroidY]=centroid_fun();
                    set(c.track_stat,'String',['Centroid X:' num2str(c.centroidX) 'Y:'  num2str(c.centroidY)]);
                end
    
                k = 0.0144; %calibration constant between pixels and voltage

    %         gain = str2num(get(handles.gain, 'String'));
    %         minAdjustmentpx = str2num(get(handles.minAdjustment, 'String'));
    %         mindelV = minAdjustmentpx*k;
    %         rate=str2num(get(handles.feedbackRate, 'String'));
    %         delay = 1.0/rate
    %         zfocuscounter = 0;
    %         N = round(str2num(get(handles.N, 'String')));
    %         while get(handles.track, 'Value') == 1
    %             global ao1 ao2 nidevice;
    %             frame = getsnapshot(vid);
    %             rot = str2num(get(handles.rot, 'String'));
    %         %     Im=imrotate (frame,rot,'bilinear','crop');
    %         %     [X Y] = centroid_fun(Im,handles);
    %             [X Y] = centroid_fun(frame,handles);
    %             set(handles.xcurrent, 'String', num2str(X));
    %             set(handles.ycurrent, 'String', num2str(Y));
    %             delX = X-X0;
    %             delY = Y-Y0;
    %             Vxold = str2num(get(handles.Vx, 'String'));
    %             Vyold = str2num(get(handles.Vy,'String'));    
    %             delVx = delX*k*gain;
    %             delVy = delY*k*gain;
    %             %only move if greater than 1 pixel which is < 50 nm
    %             if (abs(delVx)>mindelV) | (abs(delVy) > mindelV)
    %             %only move if voltage stays positive
    %             Vxnew = max([0, Vxold - delVx])
    %             Vynew = max([0, Vyold - delVy])
    %             s = daq.createSession('ni');
    %             s.addAnalogOutputChannel(nidevice, [ao1 ao2], 'Voltage');
    %             s.outputSingleScan([Vxnew Vynew]); 
    %             set(handles.Vx, 'String', num2str(Vxnew));
    %             set(handles.Vy, 'String', num2str(Vynew));
    %             end
    %             pause(delay);
    %             zfocuscounter = zfocuscounter + 1;
    %             if zfocuscounter == N
    %                 zfocuscounter = 0;
    %                if get(handles.zFeedback, 'Value') == 2
    %                    figure(2)
    %                    close(2)
    %                    findfocus(handles)
    %                end
    %             end
    %         end
    
            elseif ~c.seldisk
                [c.circles, c.radii] = imfindcircles(IBW,[12 20]);

                     try
                         delete(c.hg1);
                     catch
                     end
                     if ~isempty(c.radii)
                        axes(c.track_Axes);
                        c.hg1=viscircles(c.circles, c.radii,'EdgeColor','g','LineWidth',1.5);  
                     end
            end
        end
    end

    function click_trackCallback(~,~)
        c.trackpt = get (gca, 'CurrentPoint');
        w=strcat('%0','3.1f');   
        if (c.trackpt(1,1) >= 0 && c.trackpt(1,1) <= 640) && (c.trackpt(1,2) >= 0 && c.trackpt(1,2) <= 480) && c.seldisk==0 && c.vid_on
             set(c.track_stat,'String',['Status: clicked' ' ' 'x:' num2str(c.trackpt(1,1),w) ' ' 'y:' num2str(c.trackpt(1,2),w)]);
             axes(c.track_Axes);
             for i=1:length(c.radii)
                if (c.trackpt(1,1)>= (c.circles(i,1)-c.radii(i)) && c.trackpt(1,1)<= (c.circles(i,1)+ c.radii(i))) ...
                        && (c.trackpt(1,2)>= (c.circles(i,2)-c.radii(i)) && c.trackpt(1,2)<= (c.circles(i,2)+ c.radii(i)))
                    c.selcircle(1)=c.circles(i,1); 
                    c.selcircle(2)=c.circles(i,2);
                    c.selradii=c.radii(i);
                    viscircles(c.selcircle ,c.selradii,'EdgeColor','r','LineWidth',1.5); 
                    c.seldisk=1;
                end
             end
        end
    end

    function stopvid_Callback(~,~)
        set(c.track_stat,'String','Status: Stopped vid');
        stop(c.tktime);
        delete(c.tktime);
        c.vid_on = 0;
    end

    function cleartrack_Callback(~,~)
     c.seldisk=0;
     c.centroid_init=0;
     c.roi='';
     axes(c.roi_Axes); cla;
     try
         delete(c.hg1);
     catch
     end
     set(c.track_stat,'String','Status: ROI cleared');
    end

    function settrack_Callback(~,~)
    
      if isempty(c.roi) && c.seldisk 
       %Set the ROI for tracking
       c.roi=[c.selcircle(1)-c.selradii-c.roi_pad c.selcircle(2)-c.selradii-c.roi_pad 2*(c.selradii+c.roi_pad) 2*(c.selradii+c.roi_pad)];   
       set(c.track_stat,'String','Status: New ROI Selected');
       
       %Get Initial Centroid Position 
       c.centroid_init=1;
      end
      
    end

    function [X,Y] = centroid_fun()
                 st = regionprops( c.roi_image, 'Area', 'Centroid','MajorAxisLength','MinorAxisLength');
                 sel = [st.Area] > pi*15*15;
                 st = st(sel);
                 X=st.Centroid(1); Y=st.Centroid(2);
                 diameters = mean([st.MajorAxisLength st.MinorAxisLength],2);
                 radii = diameters/2;
                 set(c.hroi,'CData',c.roi_image);
                 try
                    delete(c.hg2);
                    delete(c.hg3);
                 catch
                end
                 c.hg2=viscircles(st.Centroid ,radii,'EdgeColor','r','LineWidth',1.5); hold on;
                 c.hg3=scatter(st.Centroid(1),st.Centroid(2),50,'g','LineWidth',4);    hold off;     
    end

end
    

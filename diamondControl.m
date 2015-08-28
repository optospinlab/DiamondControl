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
    
    % round2 devices auto set calculation
    set(c.set_mark, 'Callback', @set_mark_Callback);  

    % Calibration
    set(c.microCalib, 'Callback', @microCalib_Callback);  
    set(c.piezoCalib, 'Callback', @piezoCalib_Callback);  
    
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
    set(c.gotoPOptXY,  'Callback', @piezoOpt_Callback);                % XY and Z opt use filthy count-optimization techniques
    set(c.gotoPOptZ,  'Callback',  @optZ_Callback);
    set(c.gotoPReset, 'Callback',  @resetPiezoXY_Callback);         % Resets the XY to [5 5], approaching from [0 0]
    set(c.gotoPTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    
    set(c.gotoGButton, 'Callback', @gotoGalvo_Callback);            % GALVO GOTO controls - Goto button sends the galvos to the current fields
    set(c.gotoGReset, 'Callback',  @resetGalvo_Callback);           % Resets the XY to [0 0] (should I approach from a direction?)
    set(c.gotoGTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    
    set(c.go_mouse, 'Callback', @go_mouse_Callback); 
    set(c.go_mouse_fine, 'Callback', @go_mouse_fine_Callback); 
    set(c.go_mouse_fbk, 'Callback', @go_mouse_fbk_Callback);
    
    set(c.micro_rst_x, 'Callback', @rstx_Callback);
    set(c.micro_rst_y, 'Callback', @rsty_Callback);
    
    set(c.gotoSButton, 'Callback', @gotoSButton_Callback);
    
    % Galvo Fields --------------------------------------------------------
    set(c.galvoButton, 'Callback', @galvoScan_Callback);            % Starts a Galvo scan. Below are parameters defining that scan.
    set(c.galvoR, 'Callback', @galvoVar_Callback);                  %  - R for Range in um/side (approx) where the side is the side of the scanning square
    set(c.galvoS, 'Callback', @galvoVar_Callback);                  %  - S for Speed in um/sec
    set(c.galvoP, 'Callback', @galvoVar_Callback);                  %  - P for Pixels in pixels/side
    
    set(c.galvoAlignX, 'Callback', @galvoAlign_Callback);
    set(c.galvoAlignY, 'Callback', @galvoAlign_Callback);
    
    set(c.galvoOptimize, 'Callback', @galvoOpt_Callback);    
    
    % Piezo Fields --------------------------------------------------------
    set(c.piezoButton, 'Callback', @piezoScan_Callback);            % Starts a Piezo scan. Below are parameters defining that scan.
    set(c.piezoR, 'Callback', @piezoVar_Callback);                  %  - R for Range in um/side (approx) where the side is the side of the scanning square
    set(c.piezoS, 'Callback', @piezoVar_Callback);                  %  - S for Speed in um/sec
    set(c.piezoP, 'Callback', @piezoVar_Callback);                  %  - P for Pixels in pixels/side
    
    set(c.piezoOptimize, 'Callback', @piezoOpt_Callback);
    
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
    
    set(c.autoPreview, 'Callback',  @autoPreview_Callback);         % Displays the devices that will be tested to an axes. Useful for error-correcting
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
    
    % PLE Fields
    set(c.automationPanel, 'SelectionChangedFcn',  @axesMode_Callback);
    set(c.pleOnce, 'Callback',  @pleCall);
    set(c.pleCont, 'Callback',  @pleCall);
    set(c.perotCont, 'Callback',  @perotCall);
    set(c.pleSave, 'Callback',  @pleSave_Callback);
    
    % Tracking Fields
    set(c.start_vid, 'Callback',  @startvid_Callback);
    set(c.stop_vid, 'Callback',  @stopvid_Callback);
    set(c.track_clear, 'Callback',  @cleartrack_Callback);
    set(c.track_set, 'Callback',  @settrack_Callback);
    
    
    % UI Fields -----------------------------------------------------------
    % set(c.parent, 'ButtonDownFcn', @click_Callback);
    % set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
    % set(c.counterAxes, 'ButtonDownFcn', @click_Callback);
    set(c.parent,'WindowButtonDownFcn', @click_trackCallback);
    
    
    set(c.upperAxes, 'ButtonDownFcn', @requestShow);
    set(c.lowerAxes, 'ButtonDownFcn', @requestShow);
    set(c.counterAxes, 'ButtonDownFcn', @requestShow);
    
%     set(c.mouseEnabled, 'Callback', @mouseEnabled_Callback);
    
%     set(c.microInit, 'Callback', @microInit_Callback);
    
    % We do resizing programatically
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    % Create the joystick object =====
    try
        c.joy = vrjoystick(1);
        c.joystickEnabled = 1;
    catch err
        display(err.message);
        c.joystickEnabled = 0;
    end
    
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
            if ~c.pleScanning
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
            end
            
%             takeSpectrum_Callback(0, 0);
                    
            pause(.1); % 60 Hz (should later make this run so we actually delay to 60 Hz)
%             drawnow
        end
    end

    % INPUTS ==============================================================
    function [outputXY, outputZ] = readJoystick()
        outputXY = 0;
        outputZ = 0;
        if c.joystickEnabled == 1 && get(c.joyEnabled, 'Value') == 1   % If the joystick is enabled...
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
            c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.microStep*(1+a(4))*10;
            c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.microStep*(1+a(4))*10;
            
            % Same for Z; the third axis is the twisting axis
            if max(abs([joystickAxesFunc(a(1), c.joyXYPadding) joystickAxesFunc(a(2), c.joyXYPadding)])) == 0
                c.piezo(3) = c.piezo(3) + 4*c.piezoStep*c.joyZDir*joystickAxesFunc(a(3), c.joyZPadding);
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
            speed = num*num/(ignore*ignore*4)*direction(num);
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
        if get(c.keyEnabled, 'Value') == 1 && c.microInitiated && c.daqInitiated && c.outputEnabled && ~c.galvoScanning
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

        if get(c.rsttoset0,'Value')
            
            disp('Going back to Set [0 0]...')
            c.micro=[0 0];
                setPos();
                while sum(abs(c.microActual - c.micro)) > .1
                    pause(.1);
                    getPos();
                    renderUpper();
                end
        end
        
        try     % Release the Micrometers
            cmd(c.microXSerial,c.microXAddr,'RS');
            fclose(c.microXSerial); delete(c.microXSerial); clear c.microXSerial;

            cmd(c.microYSerial,c.microYAddr,'RS');
            fclose(c.microYSerial); delete(c.microYSerial); clear c.microYSerial;
            display('    Released Micrometers...');
        catch err
            display(err.message);
        end

        display('  Goodbye micrometers...');
        c.running = false;
        c.outputEnabled = false;
        
        saveState();
        display('  Saved State');
        
        display('  Goodbye DAQ I/O...');
        try     % Reset and release the DAQ devices
            daqOutSmooth([0 0 0 0 0]);
            ledSet(0);
            
%             stop(c.pleLh);
%             delete(c.pleLh);
            
            stop(c.s); 
            stop(c.sp);  
            stop(c.sd);
            stop(c.sl);
            
            c.s.release(); 
            c.sp.release();  
            c.sd.release();
            c.sl.release();
            
            delete(c.s); 
            delete(c.sp);  
            delete(c.sd);
            delete(c.sl);
            
            display('    Released DAQs...');
        catch err
            display(err.message);
        end
        
        display('  Goodbye Counter...');
        % Need to check if the counter is disabled
        try
            if get(c.counterButton, 'Value') == 1
                display('    Closing SPCM Counter...')
                stop(c.lhC);
                delete(c.lhC);
            end
            
            if c.vid_on
                try
                    display('    Closing Vid Counter...')
                    stop(c.tktime);
                    delete(c.tktime);
                catch err
                    display(err.message);
                end     
                try
                    display('    Closing Track Counter...')
                    stop(c.centroidtime);
                    delete(c.centroidtime);
                catch err
                    display(err.message);
                end     
            end
            
        catch err
            display(err.message);
        end
        
        display('  Goodbye graphics...');
        % Release the graphics
        delete(c.imageAxes);
        delete(c.upperAxes);
        delete(c.lowerAxes);
        delete(c.counterAxes);
        
        delete(c.upperAxes2);
        delete(c.lowerAxes2);
        delete(c.counterAxes2);
        
        delete(c.parent);
    end

    % OUTPUTS =============================================================
    % --- INIT ------------------------------------------------------------
    function microInit_Callback(~, ~)
        while c.microInitiated == 0
            display('Starting Initialization Sequence');
            
            instr = instrfind;
            if ~isempty(instr)
                %disp('fix')
                fclose(instr);
            end
            
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
                cmd(c.microXSerial, c.microXAddr, 'BA0.003');  % change backlash compensation
                cmd(c.microXSerial, c.microXAddr, 'FF05');     % set friction compensation
                cmd(c.microXSerial, c.microXAddr, 'PW0');      % save to controller memory
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

                %cmd(c.microYSerial, c.microYAddr, 'PW1'); 
                cmd(c.microYSerial, c.microYAddr, 'HT1'); 
                cmd(c.microYSerial, c.microYAddr, 'SL-5');      % negative software limit y=-5
                cmd(c.microYSerial, c.microYAddr, 'BA0.003');   % change backlash compensation
                cmd(c.microYSerial, c.microYAddr, 'FF05');       % set friction compensation
                cmd(c.microYSerial, c.microYAddr, 'PW0');       % save to controller memory
                pause(.25);
                
                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state(should retain position)
                 pause(.25);

                display('Done Initializing Y Axis');

                c.microInitiated = 1;

                set(c.microText, 'ForegroundColor', 'black');
            catch err
                display(err.message);
            end   
        end
        set_mark_Callback();
    end
    function daqInit_Callback(~, ~)
        if c.daqInitiated == 0
            c.s = daq.createSession(    'ni');
            
            % Piezos    o 1:3
            c.s.addAnalogOutputChannel( c.devPiezo,   c.chnPiezoX,      'Voltage');
            c.s.addAnalogOutputChannel( c.devPiezo,   c.chnPiezoY,      'Voltage');
            c.s.addAnalogOutputChannel( c.devPiezo,   c.chnPiezoZ,      'Voltage');
            set(c.piezoText, 'ForegroundColor', 'black');
            
            % Galvos    o 4:5
            c.s.addAnalogOutputChannel( c.devGalvo,   c.chnGalvoX,      'Voltage');
            c.s.addAnalogOutputChannel( c.devGalvo,   c.chnGalvoY,      'Voltage');
            set(c.galvoText, 'ForegroundColor', 'black');

            % Counter   i 1
            c.s.addCounterInputChannel( c.devSPCM,    c.chnSPCM,      'EdgeCount');
            
            
            % PLE       o 1:2
            c.sp = daq.createSession(   'ni');
            c.sp.addAnalogOutputChannel(c.devPleOut,  c.chnPerotOut,  'Voltage');     % Perot Out
            c.sp.addAnalogOutputChannel(c.devPleOut,  c.chnGrateOut,  'Voltage');     % Grating Angle Out
            
            % PLE       i 1:3
            c.sp.addCounterInputChannel(c.devPleIn,   c.chnSPCMPle,   'EdgeCount');
            c.sp.addAnalogInputChannel( c.devPleIn,   c.chnPerotIn,   'Voltage');     % Perot In
            c.sp.addAnalogInputChannel( c.devPleIn,   c.chnNormIn,    'Voltage');     % Normalization In

            
            % PLE digital
            c.sd = daq.createSession(   'ni');
            c.sd.addDigitalChannel(     c.devPleDigitOut, c.chnPleDigitOut,  'OutputOnly');  % Modulator (for repumping)
    

            % LED digital
            c.sl = daq.createSession(   'ni');
            c.sl.addDigitalChannel(     c.devLEDDigitOut, c.chnLEDDigitOut,  'OutputOnly');  % LED Warning lights
            
            ledSet(0);
            
            daqOut();
%             piezoOutSmooth([5 5 0]);
            
            c.daqInitiated = 1;
            
            resetPiezoXY_Callback(0, 0);
        end
    end
    function videoInit()
        % Get video source
        try
            c.vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
    %         src = getselectedsource(c.vid);

            c.vid.FramesPerTrigger = 1;

            % Send the image from the source to the imageAxes
            axes(c.imageAxes);
            vidRes = c.vid.VideoResolution;
            nBands = c.vid.NumberOfBands;
            c.hImage = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(2) 1]);
            preview(c.vid, c.hImage);
            c.videoEnabled = 1;
        catch err
            disp(err.message)
        end
        
        axes(c.track_Axes);
        frame = getsnapshot(c.vid);
        
        %Testing image 
        %frame = flipdim(rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png')),1);
        
        c.track_img = imshow(frame);

    end
    function initAll()
        % Self-explainatory
%         try
            initPle();
            daqInit_Callback(0,0);
            videoInit();
            microInit_Callback(0,0);
            
            getState();

%             focus_Callback(0,0);
            
            getCurrent();
            c.running = 1;
%         catch err
%             display(err.message);
%         end
        
        updateScanGraph();
    end
    % --- LED -------------------------------------------------------------
    function ledSet(state)
        if c.ledState ~= state  % If there was a change,
            switch state
                case 0  % Off
                    c.ledBlink = 0;
                    c.sl.outputSingleScan(0);
                case 1  % On
                    c.ledBlink = 0;
                    c.sl.outputSingleScan(1);
                case 2  % Error/blink
                    c.ledBlink = 1;
                    blink();
            end
            
            c.ledState = state;
        end
    end
    function blink()
        while c.ledBlink
            c.sl.outputSingleScan(1);
            pause(.5);
            
            if c.ledBlink
                c.sl.outputSingleScan(0);
                pause(.5);
            end
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
        fprintf(serial_obj, [device_addr c]);       % Send a Command
        % out = fscanf(serial_obj);
        % if ~isempty(out)
        %     disp(['ERR' out])
        % end
    end
    function getPos()
        % Gets the current postition from the linear actuators
        if c.outputEnabled && c.microInitiated
%             c.microXSerial
%             c.microXAddr
            str1 = pos(c.microXSerial, c.microXAddr);
            str2 = pos(c.microYSerial, c.microYAddr);
            
            c.microActual(1) = 1000*str2double(str1(4:end));
            c.microActual(2) = 1000*str2double(str2(4:end));

            set(c.microXX, 'String', c.microActual(1));
            set(c.microYY, 'String', c.microActual(2));
            
            %Assuming initially positioned on [0,0] 01 disk loop
            if ~isempty(c.m_zero)
                c.Sx=floor(abs(c.microActual(1)-c.m_zero(1))/380);
                c.Sy=floor(abs(c.microActual(2)-c.m_zero(2))/260);
                
                if (c.Sx>=0 && c.Sx<4) && (c.Sy>=0 && c.Sy<5)
                    set(c.set_no,'String',['[' num2str(c.Sx) ' ' num2str(c.Sy) ']']);
                else
                    set(c.set_no,'String','N/A');
                end
            end
            
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
    function rstx_Callback(~,~)
        %SEND THE MICROMTR BACK TO MECH-ZERO
        disp('started X-Axis reset sequence...')
        cmd(c.microXSerial,c.microXAddr,'RS'); pause(5);
        cmd(c.microXSerial, c.microXAddr,'PW1'); pause(0.5);
        cmd(c.microXSerial, c.microXAddr,'HT4'); pause(0.5);
        cmd(c.microXSerial, c.microXAddr,'PW0'); pause(5);
        cmd(c.microXSerial, c.microXAddr,'OR'); pause(30);
        
        disp('X-Axis Back to Mech Zero...')
        
        %GET BACK TO chip
        cmd(c.microXSerial,c.microXAddr,'RS'); pause(5);
        cmd(c.microXSerial, c.microXAddr,'PW1'); pause(0.5);
        cmd(c.microXSerial, c.microXAddr,'HT1'); pause(0.5);
        cmd(c.microXSerial, c.microXAddr,'PW0'); pause(5);
        cmd(c.microXSerial, c.microXAddr,'OR'); pause(0.5);
        cmd(c.microXSerial, c.microXAddr, ['PR' num2str(22)]); pause(30);
        
        disp('Finished Reset Sequence')
        disp('X-Axis should be at 22 mm \n')
        disp(['X-Axis at:' num2str(c.microActual(1))])
        
        if(c.microActual(1)~=22000)
            disp('There was an ERROR!!!')
        end
        
    end
    function rsty_Callback(~,~)
        %SEND THE MICROMTR BACK TO MECH-ZERO
        disp('started Y-Axis reset sequence...')
        cmd(c.microYSerial,c.microYAddr,'RS'); pause(5);
        cmd(c.microYSerial, c.microYAddr,'PW1'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'HT4'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'PW0'); pause(5);
        cmd(c.microYSerial, c.microYAddr,'OR'); pause(30);
        
        disp('Y-Axis Back to Mech Zero...')
        
        %GET BACK TO chip
        cmd(c.microYSerial, c.microXAddr,'RS'); pause(5);
        cmd(c.microYSerial, c.microYAddr,'PW1'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'HT1'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'PW0'); pause(5);
        cmd(c.microYSerial, c.microYAddr,'OR'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr, ['PR' num2str(22)]); pause(30);
        
        disp('Finished Reset Sequence')
        disp('Y-Axis should be at 22 mm \n')
        disp(['Y-Axis at:' num2str(c.microActual(2))])
        
        if(c.microActual(2)~=22000)
            disp('There was an ERROR!!!')
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
            prev = [c.piezo c.galvo]; % c.ple];   % Get the previous location.
            c.piezo = to(1:3);          % Set the new location.
            c.galvo = to(4:5);
%             c.ple =   to(6:7);
            
            limit();                    % Make sure we aren't going over-bounds.
            
            steplist = [c.piezoStep c.piezoStep c.piezoStep c.galvoStep c.galvoStep]; %, c.piezoStep, c.piezoStep];
            
            steps = round(max(abs(to - prev)./steplist));    % Calculates which device 'furthest away from the target' and uses that device to define the speed.
            prevRate = c.s.Rate;
            c.s.Rate = 1000;
            
            if steps > 0    % If there is something to do...
                queueOutputData(c.s,   [linspace(prev(1), to(1), steps)'... % There's probably a less-verbose way to do this, but... historical reasons.
                                        linspace(prev(2), to(2), steps)'...
                                        linspace(prev(3), to(3), steps)'...
                                        linspace(prev(4), to(4), steps)'...
                                        linspace(prev(5), to(5), steps)']);
%                                         linspace(prev(6), to(6), steps)'...
%                                         linspace(prev(7), to(7), steps)']);
                c.s.startForeground();
            end
            
            c.s.Rate = prevRate;
            
            getCurrent();   % Sets the UI to the current location.
        end
    end
    function piezoOutSmooth(to)
        % Only modifies the piezo.
        daqOutSmooth([to c.galvo]); % c.ple]);
    end
    function galvoOutSmooth(to)
        % Only modifies the galvo.
        daqOutSmooth([c.piezo to]); % c.ple]);
    end
    function daqOut()
        % Abruptly sends all the DAQ devices to the location defined by c.piezo and c.galvo.
        if c.outputEnabled && c.daqInitiated && ~c.isCounting
            c.s.outputSingleScan([c.piezo c.galvo]); % c.ple]);
        end
        getCurrent();       % Sets the UI to the current location.
    end
    function final = daqOutQueueCleverFull(array, session)
        finalLength = max(cellfun(@length, array));
            
        if session == 1
            curr =  [c.piezo c.galvo];
        else
            curr =  [c.ple];
        end
        final = zeros(finalLength, length(array));
        
%         length(array)
        
        i = 1;

        for y = array
            x = cell2mat(y);
            if sum(isnan(x)) == 1
                final(:,i) = ones(1, finalLength)*curr(i);
            elseif length(x) == 1
                final(:,i) = ones(1, finalLength)*x;
            elseif length(x) > 1 && isvector(x)
                if length(x) == finalLength
                    final(:,i) = x; % Future update? Transpose if neccessary [edit: transpose apparently is automatic]
                elseif length(x) < finalLength
                    final(:,i) = [x ones(1, finalLength - length(x))*x(end)];   % Extend the short list by repeating last element.
                else
                    display('Something broken with the lengths.');
                end
            else
                display('fourth category?');
                display(x);
            end
            
            i = i + 1;
        end
        
%         final
        
        
        if session == 1
            queueOutputData(c.s, final);
            c.piezo = final(end, 1:3);
            c.galvo = final(end, 4:5);
        else
            queueOutputData(c.sp, final);
            c.ple   = final(end, 1:2);
        end
    end
    function final = daqOutQueueClever(array)
        final = daqOutQueueCleverFull(array(1:5), 1);
    end
    function final = daqOutQueueCleverPLE(array)
        final = daqOutQueueCleverFull(array(1:2), 0);
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
    function piezoOpt_Callback(~, ~)
        piezoOptimizeXY(c.piezoRange, c.piezoSpeed, c.piezoPixels);
    end
    function [final] = piezoOptimizeXY(range, upspeed, pixels)
        [final, X, Y] = piezoScanXYFull(range, upspeed, pixels);
        
        [x, y] = myMeanAdvanced(final, X, Y);
        
%         m = min(min(final)); M = max(max(final));
%         data = (final - m)/(M - m);
%         
%         [x, y] = myMean(data.*(data > .7), X, Y);
        
        piezoOutSmooth([0       0       c.piezo(3)]);
        piezoOutSmooth([X(1)    Y(1)    c.piezo(3)]);
        piezoOutSmooth([X(1)    y       c.piezo(3)]);
        piezoOutSmooth([x       y       c.piezo(3)]);
    end
    function optZ_Callback(~, ~)
        piezoOptimizeZ();
    end
    function piezoOptimizeZ()
        
        % Method 1
        range = 10;
        pixels = 1000;
        
        prev = c.piezo(3);
        
        c.s.Rate = 250; 
        
        u = pixels+1;
        d = round(pixels/8);
            
%         up =    [c.piezo(1)*ones(u,1) c.piezo(2)*ones(u,1) linspace(0, range, u)' c.galvo(1)*ones(u,1) c.galvo(2)*ones(u,1)];
%         down =  [c.piezo(1)*ones(d,1) c.piezo(2)*ones(d,1) linspace(range, 0, d)' c.galvo(1)*ones(d,1) c.galvo(2)*ones(d,1)];
        up =    linspace(0, range, u);
        down =  linspace(range, 0, d);

        piezoOutSmooth([c.piezo(1) c.piezo(2) 0]);
        
%         queueOutputData(c.s, up);
%         queueOutputData(c.s, down);

        daqOutQueueClever({NaN, NaN, [up down], NaN, NaN, NaN, NaN});

        [out, ~] = c.s.startForeground();
        out = out(:,1);

        data = diff(out);
        data = data(1:pixels);
        
        plot(c.lowerAxes, up(1:pixels), data);

        m = min(min(data)); M = max(max(data));

        if m ~= M
            data = (data - m)/(M - m);
            data = data.*((((up(1:pixels) > (prev - .5)) + ((up(1:pixels) < (prev + .5)))) == 2)');
            
            m = min(min(data)); M = max(max(data));
            
            if m ~= M
                data = (data - m)/(M - m);
                data = data.*(data > .5);
            end
            
            total = sum(sum(data));
            fz = sum((data).*(up(1:pixels)'))/total;

            if fz > 10 || fz > (prev + .5) || fz < 0 || fz < (prev - .5) || isnan(fz)
                fz = prev;
            end
            
            piezoOutSmooth([c.piezo(1) c.piezo(2) fz]);
        else
            piezoOutSmooth([c.piezo(1) c.piezo(2) prev]);
        end
    end
    function galvoOpt_Callback(~, ~)
        galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);   % Currently uses GUI values (should change, probably)
    end
    function [final] = galvoOptimize(range, upspeed, pixels)
        [final, X, Y] = galvoScanFull(false, range, upspeed, pixels);
        
        [x, y] = myMeanAdvanced(final, X, Y);
        
%         m = min(min(final)); M = max(max(final));
%         data = (final - m)/(M - m);
%         
%         [x, y] = myMean(data.*(data > .7), X, Y);
        
        galvoOutSmooth([.2 .2]);
        galvoOutSmooth([X(1) Y(1)]);
        galvoOutSmooth([X(1) y]);
        galvoOutSmooth([x y]);
    end
    function [x, y] = myMean(data, X, Y)
        % Note that this will yeild an error if data is all zero. This is purposeful.
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
    function [x, y] = myMeanAdvanced(final, X, Y)
        m = min(min(final)); M = max(max(final));
        if m ~= M
            data = (final - m)/(M - m);

            try
                [mx, my] = myMean(data.*(data == 1), X, Y);

    %             data = data*

                dim = size(data);
    %             factor = zeros(dim(1));

                for x1 = 1:dim(1)
                    for y1 = 1:dim(1)
                        data(y1, x1) = data(y1, x1)/(1 + (X(x1) - mx)^2 + (Y(y1) - my)^2);
                    end
                end
                
                m = min(min(data)); M = max(max(data));

                if m ~= M
                    data = (data - m)/(M - m);
                end
            
            catch err
                display(['Attenuation failed: ' err.message]);
            end

            list = .4:.1:.9;

            X0 = []; % zeros(1, length(list));
            Y0 = []; % zeros(1, length(list));

%             i = 1;

            for threshold = list
                try
                    [a, b] = myMean(data.*(data > threshold), X, Y);
                    
                    X0 = [X0 a];
                    Y0 = [Y0 b];
                    
%                     i = i+1;
                catch err
                    display(err.message);
                end
            end
            
            if isempty(X0) || isempty(Y0)
                try
                    [x, y] = myMean(data.*(data == 1), X, Y);
                catch err
                    display(err.message);
                    
                    x = mean(X);
                    y = mean(Y);
                end
            else
                while std(X0) > abs(X(1) - X(2)) || std(Y0) > abs(Y(1) - Y(2))
                    D = (X0.^2) + (Y0.^2);

                    [~, idx] = max(D);

                    X0(idx) = [];
                    Y0(idx) = [];

                    display('      outlier removed');
                end

                x = mean(X0);
                y = mean(Y0);
            end
        else
            x = mean(X);
            y = mean(Y);
        end
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
    function data = displayImage() %Unused
%         start(c.vid);
%         data = getdata(c.vid)
%         
%         axes(c.imageAxes);
%         image(flipdim(data,1));
     end

    % PIEZOSCAN ===========================================================
    function [final, X, Y] = piezoScanXYFull(rangeUM, upspeedUM, pixels)
        % Method 1
%         range = .8;
%         pixels = 40;

        range = rangeUM/5;
        upspeed = upspeedUM/5;
        
        c.s.Rate = pixels*(upspeed/range);
        
        steps =      round(pixels);
        stepsFast =  round(pixels/8);

        % New method
        up =    linspace(-range/2 + c.piezo(1),  range/2 + c.piezo(1), steps);
        down =  linspace( range/2 + c.piezo(1), -range/2 + c.piezo(1), stepsFast);
        up2 =   linspace(-range/2 + c.piezo(2),  range/2 + c.piezo(2), steps);
        
        if sum(up < 0) ~= 0 || sum(down < 0) ~= 0 || sum(up2 < 0) ~= 0
            error('Piezos might go negative!');
        end
        X = up;
        Y = up2;

        final = ones(steps);
%             prev = 0;
        i = 1;

%         otherRows =     [c.piezo(3)*ones(steps,1)       c.galvo(1)*ones(steps,1)        c.galvo(2)*ones(steps,1)];
%         otherRowsFast = [c.piezo(3)*ones(stepsFast,1)   c.galvo(1)*ones(stepsFast,1)    c.galvo(2)*ones(stepsFast,1)];

        prev = c.piezo;

%         resetPiezo_Callback(0, 0);
        piezoOutSmooth([0       0       c.piezo(3)]);
        piezoOutSmooth([up(1)   up2(1)  c.piezo(3)]);

        set(c.piezoXX, 'String', '(scanning)');
        set(c.piezoYY, 'String', '(scanning)');

        yCopy = 0;

        for y = up2
            yCopy = y;

%             queueOutputData(c.s, [up'     y*ones(length(up2),1) otherRows]);

            daqOutQueueClever({up', y*ones(length(up2),1), NaN, NaN, NaN, NaN, NaN});
            [out, times] = c.s.startForeground();
            out = out(:,1);
            
%             queueOutputData(c.s, [down'   linspace(y, y + up2(2) - up2(1), length(down))' otherRowsFast]);

%             down'
%             linspace(y, y + up2(2) - up2(1), length(down))'
            
            if y ~= up2(end)
                daqOutQueueClever({down', linspace(y, y + up2(2) - up2(1), length(down))', NaN, NaN, NaN, NaN, NaN});
                c.s.startForeground();
            end
            
            final(i,:) = [diff(out(:,1)') mean(diff(times'))]./[diff(times') mean(diff(times'))];
            
%             tic
            if i > 1
                strings = get(c.piezoC, 'string');
                curval = get(c.piezoC, 'value');
%                 set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
                
                surf(c.lowerAxes, up(1:pixels), up2((1):(i)), final((1):(i),:), 'EdgeColor', 'none'); %, 'HitTest', 'off');   % Display the graph on the backscan
                view(c.lowerAxes, 2);
                colormap(c.lowerAxes, strings{curval});
                set(c.lowerAxes, 'Xdir', 'reverse', 'Ydir', 'reverse');
                xlim(c.lowerAxes, [up(1)       up(end)]);
                ylim(c.lowerAxes, [up2(1)      up2(end)]);
                
                surf(c.lowerAxes2, up(1:pixels), up2((1):(i)), final((1):(i),:), 'EdgeColor', 'none'); %, 'HitTest', 'off');   % Display the graph on the backscan
                view(c.lowerAxes2, 2);
                colormap(c.lowerAxes2, strings{curval});
                set(c.lowerAxes2, 'Xdir', 'reverse', 'Ydir', 'reverse');
                xlim(c.lowerAxes2, [up(1)       up(end)]);
                ylim(c.lowerAxes2, [up2(1)      up2(end)]);
%                 zlim(c.lowerAxes, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
            end
%             toc

            i = i + 1;

            c.s.wait();
        end
        
%         set(c.lowerAxes, 'Xdir', 'normal', 'Ydir', 'normal');
        
%         notOptimized = 1;
        
%         % Old method
%         while false && notOptimized && c.running
%             display(range);
%             
% %             rows = wextend('ar', 'ppd', [c.piezo(3) c.galvo], 10, 'd');
%             rows = [c.piezo(3)*ones(pixels+1,1) c.galvo(1)*ones(pixels+1,1) c.galvo(2)*ones(pixels+1,1)];
%             
%             upx = linspace(c.piezo(1)-range, c.piezo(1)+range, pixels+1);
%             upy = linspace(c.piezo(2)-range, c.piezo(2)+range, pixels+1);
%             
% %             piezoOutSmooth([upx(end)  upy(end) c.piezo(3)]);
%             resetPiezoXY_Callback(0, 0);
%             piezoOutSmooth([upx(1)  upy(1) c.piezo(3)]);
%             
% %             queueOutputData(c.s, [upx(1)  upy(1) c.piezo(3) c.galvo]);
%             
%             for y = upy(1:2:pixels+1)
%                 
%                 queueOutputData(c.s, [upx'           y*ones(pixels+1,1)            rows]);
%                 if y ~= upy(end)
%                     queueOutputData(c.s, [upx(pixels+1:-1:1)'  (y+range/pixels)*ones(pixels+1,1)	rows]);
%                 end
%             end
%             
%             [out, ~] = c.s.startForeground();
%             
%             c.piezo = [upx(end)  upy(end) c.piezo(3)];
%             resetPiezoXY_Callback(0, 0);
% 
% %             size(reshape(out(1:end), pixels+1, []))
%             
%             data = reshape(out, [], pixels+1)';
%             data = diff(data, 1, 2);
%             data = data(1:2:end, :);
%            
% %             size(data);
%             
%             m = min(min(data)); M = max(max(data));
%             
%             if m ~= M
% %                 figure()
% %                 surf(data)
% %                 pause(5);
%                 data = (data - m)/(M - m);
% %                 data > .7
%                 [fx, fy] = myMean(data.*(data > .5), upx, upy(1:2:end));
%                 
%                 if fx > 10
%                     fx = 10;
%                 end
%                 if fy > 10
%                     fy = 10;
%                 end
%                 if fx < 0
%                     fx = 0;
%                 end
%                 if fy < 0
%                     fy = 0;
%                 end
%             
% %                 piezoOutSmooth([upx(1)  upy(1) c.piezo(3)]);
%                 
% %                 piezoOutSmooth([x y c.piezo(3)]);
% %                 piezoOutSmooth([5 5 c.piezo(3)]);
%                 
% %                 (data > .7)
% %                 figure()
% %                 surf(data)
% %                 pause(5);
% %                 figure()
% %                 plot(data)
% %                 pause(5);
% %                 hold(c.lowerAxes, 'on');
%                 scatter3(c.upperAxes, fx, fy, 0);
%                 xlim(c.upperAxes, [upx(1) upx(end)]);
%                 ylim(c.upperAxes, [upy(1) upy(end)]);
%                 zlim(c.upperAxes, [0 1]);
%                 dim = size(data);
%                 upy2 = upy(1:2:end);
%                 surf(c.lowerAxes, upx(1:dim(2)), upy2(1:dim(1)), data, 'EdgeColor', 'none');
%                 view(c.lowerAxes,2);
%                 set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
%                 xlim(c.lowerAxes, [upx(1) upx(end)]);
%                 ylim(c.lowerAxes, [upy(1) upy(end)]);
% %                 hold(c.lowerAxes, 'off');
% %                 pause(10);
%                 
%                 
%                 
% %                 piezoOutSmooth([upx(end)  upy(end) c.piezo(3)]);
% %                 resetPiezoXY_Callback(0, 0);
%                 piezoOutSmooth([upx(1)  upy(1)  c.piezo(3)]);
%                 piezoOutSmooth([upx(1)  fy      c.piezo(3)]);
%                 piezoOutSmooth([fx      fy      c.piezo(3)]);
% 
%                 notOptimized = false;
% 
% %                 if sum(abs(c.piezo(1:2) - prev)) < c.piezoStep || 8*range < c.piezoStep
% %                     notOptimized = false;
% %                 end
%                 
%                 prev = c.piezo(1:2);
%                 
% %                 range = range/4;
%             end
%             
% %             range = range*2;
%         end
% %         while notOptimized
        
%         resetPeizoXY_Callback(0, 0);
    end
    function piezoVar_Callback(hObject, ~)
        limit_Callback(hObject,0);
        switch hObject
            case c.piezoR
                c.piezoRange = str2double(get(hObject, 'String'));
            case c.piezoS
                c.piezoSpeed = str2double(get(hObject, 'String'));
            case c.piezoP
                makeInteger_Callback(hObject, 0);
                c.piezoPixels = str2double(get(hObject, 'String'));
        end
    end
    function piezoScan_Callback(~, ~)
        display('Beginning 3D Confocal');
        prev = c.piezo;
        ledSet(1);
        
        start = (str2double(get(c.piezoZStart,   'String')) + 25)/5;
        stop =  (str2double(get(c.piezoZStop,    'String')) + 25)/5;
        step =  str2double(get(c.piezoZStep,    'String'));
        
        if start < 0
            start = 0;
        end
        if start > 10
            start = 10;
        end
        if stop < 0
            stop = 0;
        end
        if stop > 10
            stop = 10;
        end
        if step < 0
            step = 1;
        end
        
        
        if step == 1
            final(:,:,1) = piezoScanXYFull(c.piezoRange, c.piezoSpeed, c.piezoPixels);
        else
            final = zeros(c.piezoPixels, c.piezoPixels, step);
            
            i = 1;
            Z = linspace(start, stop, step);
            for z = Z;
                display(['  Z = ' num2str(z)]);
                piezoOutSmooth([prev(1) prev(2) z]);
                [final(:,:,i), X, Y] = piezoScanXYFull(c.piezoRange, c.piezoSpeed, c.piezoPixels);
                i = i + 1;
            end
            
            % 3D GRAPH FINAL HERE!
            % PLOT(final, X, Y, Z) (X Y Z are in volts)
            
            figure;
                [x y z]=meshgrid(X,Y,Z);
                xslice=[]; yslice=[];
                zslice=Z;
             
                h=slice(x,y,z,final,xslice,yslice,zslice);
                set(h,'FaceColor','interp');
                %set(h,'FaceAlpha','0.5');
                set(h,'EdgeColor','none');

                colormap('copper');
                colorbar('vert');
                view([-68 12]);
        end
        
        ledSet(0);
        piezoOutSmooth(prev);
    end

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
            downspeed = upspeed*8;

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

            
%             piezoRows = [c.piezo(1)*ones(steps,1) c.piezo(2)*ones(steps,1) c.piezo(3)*ones(steps,1)];
%             piezoRowsFast = [c.piezo(1)*ones(stepsFast,1) c.piezo(2)*ones(stepsFast,1) c.piezo(3)*ones(stepsFast,1)];
            
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
%                 queueOutputData(c.s, [piezoRows	up'     y*ones(length(up2),1)]);
            
                daqOutQueueClever({NaN, NaN, NaN, up', y*ones(length(up2),1), NaN, NaN});
                [out, time] = c.s.startForeground();

                %display('down');
%                 queueOutputData(c.s, [piezoRowsFast	down'   linspace(y, y + up2(2) - up2(1), length(down))']);
            
                daqOutQueueClever({NaN, NaN, NaN, down', linspace(y, y + up2(2) - up2(1), length(down))', NaN, NaN});
                c.s.startForeground();

                final(i,:) = [mean(diff(out(:,1)')) diff(out(:,1)') ]./[mean(diff(time')) diff(time') ];  % *rate;

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
%                 setGalvoAxesLimits();
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
    function t = sendSpectrumTrigger()
        set(c.spectrumButton, 'Enable', 'off');
        
        t = now;
        
        % create the trigger file
        fh = fopen('Z:\WinSpec_Scan\matlabfile.txt', 'w');  
        if (fh == -1) 
            error('oops, file cannot be written'); 
        end 
        fprintf(fh, 'Trigger Spectrum\n');
        fclose(fh);
    end
    function spectrum = waitForSpectrum(filename, t)
        file = '';
        spectrum = -1;
        
        i = 0;
        
        while c.running && i < 120 && sum(spectrum == -1) == 1
            try
%                 disp(['    waiting ' num2str(i)])
                d = dir('Z:\WinSpec_Scan\spec.SPE');
                
%                 display(['      datenum: ' num2str(d.datenum, 100) ',']);
%                 display(['            t: ' num2str(t, 100)]);
                if d.datenum > t - 4/(24*60*60) % file == 'Z:\WinSpec_Scan\spec.SPE'
                    spectrum = readSPE('Z:\WinSpec_Scan\spec.SPE');
                end
            catch error
%                 disp(error)
            end
            
            pause(.5);
            i = i + 1;
        end
        
        pause(.5);
        
        if spectrum ~=-1
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
                        movefile('Z:\WinSpec_Scan\spec.SPE', [filename '.SPE']);
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
                        delete('Z:\WinSpec_Scan\spec.SPE');
                        break;
                    catch err
                        pause(.5);
                        display(err.message);
                    end
                    i = i + 1;
                end
            end
        elseif spectrum ~=-1
            display('Failed to get data; proceeding');
            k = waitforbuttonpress 
        end
        set(c.spectrumButton, 'Enable', 'on');
    end
    function takeSpectrum_Callback(~,~)
        image = waitForSpectrum(0, sendSpectrumTrigger());
        
        if image ~= -1
            plot(c.lowerAxes, 1:512, image)
            set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
            xlim(c.lowerAxes, [1 512]);
            ylim(c.lowerAxes, [min(image) max(image)]);
        end
        
%         if image ~= -1
%             savePlotPng(1:512, image, 'spectrum.png');
%         end
    end
    function savePlotPng(X, Y, filename)
        p = plot(c.plottingAxes, X, Y);
        xlim(c.plottingAxes, [X(1) X(end)]);
        saveas(p, filename);
    end

    % AUTOMATION! =========================================================
    function setCurrent_Callback(hObject, ~)
        switch hObject
            case c.autoV1Get
                set(c.autoV1X, 'String', c.microActual(1));
                set(c.autoV1Y, 'String', c.microActual(2));
                set(c.autoV1Z, 'String', c.piezo(3));
                set(c.autoV1NX, 'String', c.Sx);
                set(c.autoV1NY, 'String', c.Sy);
            case c.autoV2Get
                set(c.autoV2X, 'String', c.microActual(1));
                set(c.autoV2Y, 'String', c.microActual(2));
                set(c.autoV2Z, 'String', c.piezo(3));
                set(c.autoV2NX, 'String', c.Sx);
                set(c.autoV2NY, 'String', c.Sy);
            case c.autoV3Get
                set(c.autoV3X, 'String', c.microActual(1));
                set(c.autoV3Y, 'String', c.microActual(2));
                set(c.autoV3Z, 'String', c.piezo(3));
                set(c.autoV3NX, 'String', c.Sx);
                set(c.autoV3NY, 'String', c.Sy);
            case c.autoV4Get
                set(c.autoV4X, 'String', c.microActual(1));
                set(c.autoV4Y, 'String', c.microActual(2));
                set(c.autoV4Z, 'String', c.piezo(3));
                set(c.autoV4NX, 'String', c.Sx);
                set(c.autoV4NY, 'String', c.Sy);
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
%         if (sum(abs(V1 - (V*n1 + V0))) + sum(abs(V2 - (V*n2 + V0))) + sum(abs(V3 - (V*n3 + V0))) < 1e-9)  % Within a certain tolerance...
% %             display(V1); display(V*n1 + V0);
% %             display(V2); display(V*n2 + V0);
% %             display(V3); display(V*n3 + V0);
% %             error('Math is wrong... D:');
%         end

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
            ledSet(1);

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
                
                savePlotPng(1:512, spectrumNorm, [prefix 'normalization_spectrum.png']);

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

                                if get(c.autoTaskFocus, 'Value') == 1
                                    focus_Callback(0, 0);
                                end
                                
                                if results
                                    fprintf(fhv, ['We moved to DEVICE ' num2str(d) ' of SET [' num2str(x) ',' num2str(y) ']\r\n']);
                                    fprintf(fhv, ['    Z was initially focused to ' num2str(c.piezo(3)) ' V\r\n']);
                                    fprintf(fhv, ['                          from ' num2str(old(3)) ' V.\r\n']);
                                end
                                
                                old = [c.piezo c.galvo];
                                
                                if get(c.autoTaskBlue, 'Value') == 1
                                    try
                                        start(c.vid);
                                        data = getdata(c.vid);
                                        img = data(360:-1:121, 161:480);    % Fixed flip...
                                    catch err
                                        display(err.message)
                                    end
                                end

                                display('  Optimizing...');
                                display('    XY...');       piezo0 = piezoOptimizeXY(c.piezoRange, c.piezoSpeed, c.piezoPixels);
                                display('    Galvo...');    scan0 = galvoOptimize(c.galvoRange, c.galvoSpeed, round(c.galvoPixels/2));
                                
                                scan = scan0; % in case there is only one repeat tasked.
                                
                                if results
                                    fprintf(fhv, ['    XY were optimized to ' num2str(c.piezo(1)) ', ' num2str(c.piezo(2))  ' V\r\n']);
                                    fprintf(fhv, ['                    from ' num2str(old(1))   ', ' num2str(old(2))    ' V.\r\n']);
                                    fprintf(fhv, ['    The galvos were optimized to ' num2str(c.galvo(1)*1000) ', ' num2str(c.galvo(2)*1000) ' mV\r\n']);
                                    fprintf(fhv, ['                            from ' num2str(old(4)*1000) ', ' num2str(old(5)*1000) ' mV.\r\n']);
                                    fprintf(fhv, ['    This gave us an inital countrate of ' num2str(round(max(max(scan0)))) ' counts/sec.\r\n']);
                                    fprintf(fhv, ['    Z was optimized to ' num2str(c.piezo(3)) ' V\r\n']);
                                    fprintf(fhv, ['                  from ' num2str(old(3)) ' V.\r\n']);
                                end
                                
                                j = 2;
                                
                                while j <= round(str2double(get(c.autoTaskNumRepeat, 'String')))
                                    old = [c.piezo c.galvo];

                                    display('    Z...');    piezoOptimizeZ();
                                    display('    XY...');   piezoOptimizeXY(c.piezoRange/3, c.piezoSpeed, round(c.piezoPixels/3));
                                    
                                    if get(c.autoTaskGalvo, 'Value') == 1
                                        if j == round(str2double(get(c.autoTaskNumRepeat, 'String')));
                                            display('  Scanning...');
                                            scan = galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);
                                        else
                                            display('    Galvo...');
                                            scan = galvoOptimize(c.galvoRange, c.galvoSpeed, round(c.galvoPixels/2));
                                        end

                                    end
                                        
                                    if results
                                        fprintf(fhv, ['    Z was optimized to ' num2str(c.piezo(3)) ' V\r\n']);
                                        fprintf(fhv, ['                  from ' num2str(old(3)) ' V.\r\n']);
                                        fprintf(fhv, ['    XY were optimized to ' num2str(c.piezo(1)) ', ' num2str(c.piezo(2))  ' V\r\n']);
                                        fprintf(fhv, ['                    from ' num2str(old(1))   ', ' num2str(old(2))    ' V.\r\n']);
                                        if get(c.autoTaskGalvo, 'Value') == 1
                                            fprintf(fhv, ['    The galvos were optimized to ' num2str(c.galvo(1)*1000) ', ' num2str(c.galvo(2)*1000) ' mV\r\n']);
                                            fprintf(fhv, ['                            from ' num2str(old(4)*1000) ', ' num2str(old(5)*1000) ' mV.\r\n']);
                                        end
                                        fprintf(fhv, ['    This gives us a countrate of ' num2str(round(max(max(scan)))) ' counts/sec.\r\n']);
                                    end
                                    
                                    j = j + 1;
                                end
                                
                                old = [c.piezo c.galvo];
                                
%                                 display('    Z...');
                                piezoOptimizeZ();
                                
                                if results
                                        fprintf(fhv, ['    Z was optimized a final time to ' num2str(c.piezo(3)) ' V\r\n']);
                                        fprintf(fhv, ['                               from ' num2str(old(3)) ' V.\r\n']);
                                end
                                
                                if get(c.autoTaskSpectrum, 'Value') == 1
                                    display('  Taking Spectrum...');

                                    spectrum = 0;

                                    try
%                                         sendSpectrumTrigger();
%                                         spectrum = waitForSpectrum([prefix name{i} '_spectrum']);
                                        spectrum = waitForSpectrum([prefix name{i} '_spectrum'], sendSpectrumTrigger());
                                    catch err
                                        display(err.message);
                                    end
                                
                                    if spectrum ~= -1
                                        savePlotPng(1:512, spectrum, [prefix name{i} '_spectrum' '.png']);
                                    end

%                                     if spectrumNorm ~= 0 && spectrum ~= 0
%                                         spectrumFinal = double(spectrum - min(spectrum))./double(spectrumNorm - min(spectrumNorm) + 50);
%                                         save([prefix name{i} '_spectrumFinal' '.mat'], 'spectrumFinal');
% 
%                                         savePlotPng(1:512, spectrumFinal, [prefix name{i} '_spectrumFinal' '.png']);
% 
% 
%     %                                     tempP = plot(1, 'Visible', 'off');
%     %                                     tempA = get(tempP, 'Parent');
%     %                                     png = plot(tempA, 1:512, spectrumNorm);
%     %                                     xlim(tempA, [1 512]);
%     %     %                                 png = plot(c.lowerAxes, 1:512, spectrumFinal);
%     %     %                                 xlim(c.lowerAxes, [1 512]);
%     %                                     saveas(png, [prefix name{i} '_spectrumFinal' '.png']);
%                                     end
                                end

                                display('  Saving...');
                
%                                 tempP = plot(1, 'Visible', 'off');
%                                 tempA = get(tempP, 'Parent');
%                                 png = plot(tempA, 1:512, spectrumNorm);
%                                 xlim(tempA, [1 512]);
%     %                             png = plot(c.lowerAxes, 1:512, spectrum);
%     %                             xlim(c.lowerAxes, [1 512]);
%                                 saveas(png, [prefix name{i} '_spectrum' '.png']);

                                if get(c.autoTaskGalvo, 'Value') == 1
%                                     display('here');
                                    save([prefix name{i} '_galvo' '.mat'], 'scan');

                                    imwrite(rot90(scan0,2)/max(max(scan0)),   [prefix name{i} '_galvo_debug'  '.png']);  % rotate because the dims are flipped.
                                    imwrite(rot90(scan,2)/max(max(scan)),           [prefix name{i} '_galvo'        '.png']);
                                end
                                
                                imwrite(piezo0/max(max(piezo0)),   [prefix name{i} '_piezo_debug'  '.png']);

                                imwrite(img, [prefix name{i} '_blue' '.png']);

                                if results
                                    display('  Remarking...');

                                    counts = max(max(scan));
    %                                 counts2 = max(max(intitial));
    
                                    works = true;
                                    
                                    if get(c.autoTaskGalvo, 'Value') == 1
                                        J = imresize(scan, 5);
                                        J = imcrop(J, [length(J)/2-25 length(J)/2-20 55 55]);

                                        level = graythresh(J);
                                        IBW = im2bw(J, level);
                                        [centers, radii] = imfindcircles(IBW, [15 60]);

                                        works = ~isempty(centers);
                                    end

    %                                 IBW = im2bw(scan, graythresh(scan));
    %                                 [centers, radii] = imfindcircles(IBW,[5 25]);

                                    if d == ndrange(1)
                                        fprintf(fhb, ['\r\n [' num2str(x) ',' num2str(y) '] |']);
                                        fprintf(fh,  ['\r\n [' num2str(x) ',' num2str(y) '] |']);
                                    end

                                    if works
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
                            ledSet(2);
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
        ledSet(0);
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
            
%             Of = Ox;
%             
%             if Ox < Oy
%                 Of = Oy;
%             end

            Of = max([Ox Oy]);
            
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
        
        % PLE Axes Position =====
        set(c.pleAxesOne,    'Position', [0      2*gp    w-pw   .3*h-2*gp]);
        set(c.pleAxesAll,    'Position', [0      .3*h    w-pw   .7*h]);

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
%           c.lhC.StartDelay = 0;
%           c.lhC.StartFcn = [];
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

    % Popup Plots =========================================================
%     function mouseEnabled_Callback(~, ~)
%         if get(c.mouseEnabled, 'Value')
%            set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
%            set(c.counterAxes, 'ButtonDownFcn', @click_Callback);
%         else
%            set(c.lowerAxes, 'ButtonDownFcn', '');
%            set(c.counterAxes, 'ButtonDownFcn', '');
%         end
%     end
%     function click_Callback(hObject, ~)
%         try
%             delete(c.pop);
%         end
%         c.pop=figure;
%         hc = copyobj(hObject, gcf);
%         set(hc, 'Units', 'normal','Position', [0.05 0.06 0.9 0.9]);
%         uiwait(c.pop);
%     end
    function requestShow(hObject, ~)
        switch hObject
            case c.upperAxes
                set(c.upperFigure, 'Visible', 'on');
            case c.lowerAxes
                set(c.lowerFigure, 'Visible', 'on');
            case c.counterAxes
                set(c.counterFigure, 'Visible', 'on');
        end
    end

    % PLE! ================================================================
    function initPle()  % Unused
%         if c.pleInitiated == 0
% %             c.sPle = daq.createSession('ni');
%             c.s.addAnalogInputChannel( c.devPleIn,   c.chnPerotIn,   'Voltage');     % Perot In
% %             c.sPle.addCounterInputChannel(c.devPleIn,   c.chnSPCMPle,   'EdgeCount');   % Detector (SPCM) In
%             c.s.addAnalogInputChannel( c.devPleIn,   c.chnNormIn,    'Voltage');     % Normalization In
% % 
%             c.s.addAnalogOutputChannel(c.devPleOut,  c.chnPerotOut,  'Voltage');     % Perot Out
%             c.s.addAnalogOutputChannel(c.devPleOut,  c.chnGrateOut,  'Voltage');     % Grating Angle Out
% 
%             c.sd = daq.createSession('ni');
%             c.sd.addDigitalChannel(    c.devPleDigitOut, c.chnPleDigitOut,  'OutputOnly');  % Modulator (for repumping)
% 
%             c.pleInitiated = 1;
%         end
    end
    function axesMode_Callback(~, eventdata)
        if strcmp(eventdata.NewValue.Title, 'PLE!')
            c.axesMode = 1;
            
%             stoppreview(c.vid);
%             cla(c.imageAxes);
            
            set(c.pleAxesOne, 'Visible', 'On');
            set(c.pleAxesAll, 'Visible', 'On');
            
            set(c.upperAxes, 'Visible', 'Off');
            set(c.lowerAxes, 'Visible', 'Off');
            set(c.imageAxes, 'Visible', 'Off');
            try
                set(c.hImage, 'Visible', 'Off');
            end
            set(c.counterAxes, 'Visible', 'Off');
        elseif strcmp(eventdata.OldValue.Title, 'PLE!')
            c.axesMode = 0;
            
%             preview(c.vid, c.hImage);
            
            cla(c.pleAxesOne, 'reset');
            cla(c.pleAxesAll, 'reset');
            set(c.pleAxesOne, 'Visible', 'Off');
            set(c.pleAxesAll, 'Visible', 'Off');
            
            set(c.upperAxes, 'Visible', 'On');
            set(c.lowerAxes, 'Visible', 'On');
            set(c.imageAxes, 'Visible', 'On');
            try
                set(c.hImage, 'Visible', 'On');
            end
            set(c.counterAxes, 'Visible', 'On');
            
        end
    end
    function updateScanGraph()
        c.interval = c.perotLength + floor((c.pleRateOld - c.upScans*c.perotLength)/c.upScans);
        c.leftover = (c.pleRateOld - c.upScans*c.interval);
        
%  - (c.leftover + 1)*(c.grateMax/c.pleRate)
        c.grateInUp =   linspace(0, c.grateMax, c.upScans*c.interval);
        c.grateInDown = linspace(c.grateMax, 0, c.downScans*c.interval);
        c.grateIn =     [c.grateInUp c.grateInDown];

        c.perotInUp =   linspace(0, c.perotMax - c.perotMax/c.perotLength, c.perotLength);
        c.perotInDown = linspace(c.perotMax - c.perotMax/c.perotLength, 0, c.interval-c.perotLength);
        c.perotIn =     [];

        for scan = 1:(c.upScans+c.downScans)
            c.perotIn = [c.perotIn  c.perotInUp   c.perotInDown];
        end

        %         perotIn = [perotIn  zeros(1, interval)];
        
%         sizeA(c.perotIn)
%         sizeA(c.grateIn)

        if sizeA(c.perotIn) ~= sizeA(c.grateIn)
            error('The perot and grating data are not the same sizeA.');
        end

        X = (1:sizeA(c.grateIn))/c.pleRate;
        plot(c.axesSide, X, c.perotIn, X, c.grateIn, X, 5*(X > c.pleRateOld/c.pleRate));
        xlim(c.axesSide, [0 (c.pleRateOld/c.pleRate)*(c.upScans + c.downScans)/c.upScans]);
    end
    function updateGraph()
%         [x] = find(c.finalColorY, 1, 'last');
        
        c.finalGraphX = linspace(0, 10, c.interval*(c.upScans+c.downScans));
    %     finalColorC((x+1):(x+sizeA(finalGraphX))) = finalGraphY;
        c.finalColorY(:,c.q) = c.finalGraphY;
        c.finalColorP(:,c.q) = c.finalGraphP;

        if (c.q == c.qmaxPle)
            c.finalColorY = circshift(c.finalColorY, [0,-1]);
            c.finalColorP = circshift(c.finalColorP, [0,-1]);
        end
        
        if get(c.pleDebug, 'Value') == 1
            plot(c.pleAxesOne, c.finalGraphX, c.finalGraphP);
        else
            plot(c.pleAxesOne, c.finalGraphX, c.finalGraphY);
        end

%         xmin = min(min(c.finalColorX));
%         xmax = max(max(c.finalColorX));
%         plot(c.pleAxesOne, c.finalGraphX, c.finalGraphY);
%         set(c.pleAxesOne, 'Xlim', [xmin xmax]);
%         xlabel(c.pleAxesOne, 'Frequency (GHz)');

        set(c.pleAxesOne, 'Xlim', [0 10]);
        xlabel(c.pleAxesOne, 'Grating Angle Potential (V)');
        
        if get(c.pleDebug, 'Value') == 1
            surf(c.pleAxesAll, c.finalGraphX, c.qmaxPle:-1:1, transpose(c.finalColorP),'EdgeColor','None');
        else
            surf(c.pleAxesAll, c.finalGraphX, c.qmaxPle:-1:1, transpose(c.finalColorY),'EdgeColor','None');
        end

%         mesh(c.pleAxesAll,[c.finalColorX(c.finalColorY~=0); c.finalColorX(c.finalColorY~=0)], [c.finalColorY(c.finalColorY~=0); c.finalColorY(c.finalColorY~=0)], [c.finalColorC(c.finalColorY~=0); c.finalColorC(c.finalColorY~=0)],'mesh','column','marker','.','markersize',1)
        % surf(axesAll, linspace(xmin, xmax, sizeA(finalColorY)), 100:-1:1, transpose(finalColorY),'EdgeColor','None');
        set(c.pleAxesAll, 'Xlim', [0 10]);
        set(c.pleAxesAll, 'Ylim', [c.qmaxPle-c.q 2*c.qmaxPle-c.q]);
        set(c.pleAxesAll, 'Xtick', []);
        set(c.pleAxesAll, 'Xticklabel', []);
        view(c.pleAxesAll,2); 
    
        c.q = c.q + 1*(c.q ~= c.qmaxPle);
    end
    function updateGraphPerot(xmin, xmax)
        %     finalPerotColorX(:,q) = finalGraphX;
        c.finalPerotColorY(:, c.q) = c.finalGraphY;

        if (c.q == c.qmax)
        %         finalPerotColorX = circshift(finalPerotColorX, [0,-1]);
            c.finalPerotColorY = circshift(c.finalPerotColorY, [0,-1]);
        end

        ymin = min(c.finalGraphY);
        ymax = max(c.finalGraphY);
        dif = (ymax - ymin)/10;

        X = linspace(xmin, xmax, c.firstPerotLength);

        plot(c.pleAxesOne, X, c.finalGraphY);
        set(c.pleAxesOne, 'Xlim', [xmin xmax]);
        set(c.pleAxesOne, 'Ylim', [ymin-dif ymax+dif]);
    %     xlabel(axesOne, 'Frequency (GHz)');

        %     h = surf(axesAll, linspace(xmin, xmax, w), 1:100, finalGraph,'EdgeColor','None');
        surf(c.pleAxesAll, X, c.qmax:-1:1, transpose(c.finalPerotColorY), 'EdgeColor', 'None');
        set(c.pleAxesAll, 'Xlim', [xmin xmax]);
        set(c.pleAxesAll, 'Ylim', [c.qmax+1-c.q     2*c.qmax-c.q]);
        set(c.pleAxesAll, 'Xtick', []);
        set(c.pleAxesAll, 'Xticklabel', []);
        view(c.pleAxesAll, 2);

        c.q = c.q + 1*(c.q ~= c.qmax);
    end
    function perotCall(src,~)
%         once = false;

        %     if src == perotOnce
        %         once = true;
        %         turnEverythingElseOff(perotCont)
        %     else
        
%         if get(c.perotCont, 'Value') == 1
%             turnEverythingElseOff(c.perotCont)
%         end

        if (get(c.perotCont, 'Value') == 1) % || once)
            % Initalize i/o
%             setStatus('Creating Session');
%             s = daq.createSession('ni');
%             s.addAnalogInputChannel( 'Dev1', chanPerotIn, 'Voltage');     % Perot In
%             s.addAnalogOutputChannel('Dev1', chanPerotOut, 'Voltage');     % Perot Out
% 
%             s2 = daq.createSession('ni');
%             s2.addAnalogOutputChannel('Dev1', chanGrateOut, 'Voltage');     % Grating Angle Out

            % wa1500 = initWaveDAQ();
            
            c.pleScanning = 1;

            display('Setting up data');
            c.perotInUp =   linspace(0, c.perotMax - c.perotMax/c.firstPerotLength, c.firstPerotLength);
            c.perotInDown = linspace(c.perotMax - c.perotMax/c.firstPerotLength, 0, c.fullPerotLength - c.firstPerotLength);
            c.perotIn =     [c.perotInDown, c.perotInUp];

            c.grateCurr = 0;
            
            stop(c.sp);
            
            c.sp.IsContinuous = false;
            c.sp.Rate = 5000;
            
%             queueOutputData(c.sPle, [c.perotInUp.' c.gratingCurr*ones(length(c.perotInUp), 1)]);
            
            daqOutQueueCleverPLE({c.perotInUp.', c.grateCurr});

            c.sp.startForeground();
            
            stop(c.sp);
            
            c.finalPerotColorY = zeros(c.firstPerotLength, c.qmax);
%             c.finalPerotColorY = zeros(c.fullPerotLength, c.qmax);

            c.up = true;
            
            c.sp.IsContinuous = true;
            c.sp.Rate = 5000;

            c.sp.IsNotifyWhenDataAvailableExceedsAuto = false;
            c.sp.NotifyWhenDataAvailableExceeds = c.fullPerotLength;

%                 s.IsNotifyWhenScansQueuedBelowAuto = false;
%                 s.NotifyWhenScansQueuedBelow = 3125;

            c.pleLh = c.sp.addlistener('DataAvailable', @intevalCallPerot);

%             for a = 1:2
            output = daqOutQueueCleverPLE({c.perotIn.', c.grateCurr});
%             end
            for a = 1:5
                queueOutputData(c.sp, output);
            end

            c.sp.startBackground();
            display('Scanning');
        end
    end
    function intevalCallPerot(~, event)
        if c.outputEnabled && c.pleScanning
    %         outputSingleScan(s2, grateCurr);

    %         queueOutputData(c.sPle, [c.perotInUp.' c.gratingCurr*ones(length(c.perotInUp), 1)]);
            daqOutQueueCleverPLE({c.perotIn.', c.grateCurr});

            ramp = get(c.perotRampOn, 'Value');
            speed = str2double(get(c.perotSpeed, 'String'));

            if c.up && ramp == 1
                c.grateCurr = c.grateCurr + c.dGrateCurr*speed;
            elseif ramp == 1 && ~c.up
                c.grateCurr = c.grateCurr - c.dGrateCurr*speed;
            elseif ramp == 0 && c.grateCurr ~= 0
                c.grateCurr = c.grateCurr - c.dGrateCurr*speed;
                if c.grateCurr < 0
                    c.grateCurr = 0;
                end
            end

            if c.grateCurr + c.dGrateCurr*speed > c.grateMax
                c.up = false;
            end
            if c.grateCurr - c.dGrateCurr*speed < 0
                c.up = true;
            end

            [perotOut] = event.Data(:, 2);
    %         tic
            offset = 230;
    
            [out, wid] = findPeaks(transpose(perotOut((1 + offset):(c.firstPerotLength + offset))));
    %         toc

            fsrbase = diff(out(out~=0));
            %     std(fsrbase)

            if std(fsrbase) < 30
                c.FSR = mean(fsrbase);  % Take the mean of the differences to find the FSR.
            else
                % display('FSR irregular');
            end

            set(c.perotHzOut, 'String', returnHzString(1000000000*10*(sum(wid)/sum(wid~=0))/c.FSR)); % 
            set(c.perotFsrOut, 'String', ['FSR:  ' num2str((c.perotMax - c.perotMax/c.firstPerotLength)*round(100*c.FSR/c.firstPerotLength)/100) ' V']); % 

%             length(perotOut)
%             length(perotOut((1+c.fullPerotLength-c.firstPerotLength):c.fullPerotLength))
%             c.fullPerotLength
            
%             c.finalGraphY = perotOut((1+c.fullPerotLength-c.firstPerotLength):c.fullPerotLength);
            c.finalGraphY = perotOut((1 + offset):(c.firstPerotLength + offset));
            c.finalGraphX = linspace(0, c.perotMax - c.perotMax/c.firstPerotLength, c.firstPerotLength);

            xmin = 10*((1-out(1))/c.FSR);
            xmax = 10*((c.firstPerotLength-out(1))/c.FSR);

            updateGraphPerot(xmin, xmax);
%             drawnow

            % display('done!');

            if get(c.perotCont, 'Value') ~= 1     % Check if button is still pressed
                display('Stopping');
                c.pleScanning = 0;
                
%                 stop(c.pleLh);
                delete(c.pleLh);
                stop(c.sp);

    %             c.sPle.NotifyWhenDataAvailableExceeds = 50;
                c.sp.IsNotifyWhenScansQueuedBelowAuto = false;
                c.sp.NotifyWhenScansQueuedBelow = 50;

                c.sp.IsContinuous = false;

    %             queueOutputData(c.sPle, [c.perotInDown.' linspace(c.grateCurr, 0, length(c.perotInDown))']);
                daqOutQueueCleverPLE({c.perotInDown.', linspace(c.grateCurr, 0, length(c.perotInDown))'});

                c.sp.startForeground();


    %             while grateCurr - dGrateCurr > 0
    %                 grateCurr = grateCurr - dGrateCurr;
    %                 outputSingleScan(s2, grateCurr);
    %             end
    % 
    %             outputSingleScan(s2, 0);

            %         delete(lh2);
    %             turnEverythingOn();
            %         set(c.perotHzOut, 'String', 'Linewidth:  ---');
            %         set(c.perotFsrOut, 'String', 'FSR:  ---');
    %             setStatus('Ready');
            end
        end
    end
    function pleCall(src,~)
        once = false;

        if src == c.pleOnce
            once = true;
%             turnEverythingElseOff(0);
        elseif get(c.pleCont, 'Value') == 1
%             turnEverythingElseOff(pleCont);
        end

        if (get(c.pleCont, 'Value') == 1 || once)
            ledSet(1);
            
            c.pleScanning = 1;
            
            % Initalize i/o
%             setStatus('Creating Session');
%             s = daq.createSession('ni');
% 
%             s.addAnalogInputChannel( 'Dev1', chanPerotIn,   'Voltage');     % Perot In
%             s.addAnalogInputChannel( 'Dev1', chanNormIn,    'Voltage');     % Normalization In
%             s.addCounterInputChannel('Dev1', chanSPCMIn,    'EdgeCount');   % Detector (SPCM) In
% 
%             s.addAnalogOutputChannel('Dev1', chanPerotOut,  'Voltage');     % Perot Out
%             s.addAnalogOutputChannel('Dev1', chanGrateOut,  'Voltage');     % Grating Angle Out
% 
%             d = daq.createSession('ni');
%             d.addDigitalChannel(     'Dev1', chanDigitOut,  'OutputOnly');  % Modulator (for repumping)

            display('Interfacing with Wavemeter');
            wa1500 = initWaveDAQ();
            c.freqBase = readWavelength(wa1500);
            closeWave(wa1500);

%             display('Aquiring Base Frequency');
%             c.sp.Rate = c.pleRateOld*16;
%             
%             output1 = daqOutQueueCleverPLE({linspace(0, c.perotMax - c.perotMax/c.firstPerotLength, c.firstPerotLength).', 0});
%             output2 = daqOutQueueCleverPLE({linspace(c.perotMax - c.perotMax/c.firstPerotLength, 0, c.fullPerotLength - c.firstPerotLength).', 0});
%             
%             for x = 1:9
%                 queueOutputData(c.sp, output1);
%                 queueOutputData(c.sp, output2);
%             end
%             
% %             for x = 1:10
% % %                 queueOutputData(c.sPle, [linspace(0, c.perotMax - c.perotMax/c.firstPerotLength, c.firstPerotLength).' (0*ones(1, c.firstPerotLength)).']);
% % %                 queueOutputData(c.sPle, [linspace(c.perotMax - c.perotMax/c.firstPerotLength, 0, c.fullPerotLength - c.firstPerotLength).' (0*ones(1, c.fullPerotLength - c.firstPerotLength)).']);
% %             end
% 
%             [perotInit, ~, ~] = c.sp.startForeground();    % This will take 1 second; enough time for the wavemeter to register. [update: this no longer pertains]
%             
% %             pause(1);
% 
%             % Interpret perotInit!
%             [out, ~] = findPeaks(perotInit((c.fullPerotLength*9 + 1):(c.fullPerotLength*9 + 1 + c.firstPerotLength)));
%             fsrbase = diff(out(out~=0));

%             FSR = 4.118; % FIX!!!
%             if std(fsrbase) < 30
%                 FSR = mean(fsrbase);  % Take the mean of the differences to find the FSR.
%             else
%                 display('FSR irregular');
%             end

            c.FSR = 432/2;

            c.perotBase = 0; % out(1);
            c.prevFreq = c.perotBase;
            c.rfreq = [];
            c.rtime = [];
            c.freqs = [];
            c.times = [];
            c.q = 1;
            c.prevCount = 0;

            display('Setting Up Data');

            c.intervalCounter = 0;

            % "Setting up data"
            % finalGraph = 

            c.sp.IsContinuous = true;
            c.sp.Rate = c.pleRate;

            c.sp.IsNotifyWhenDataAvailableExceedsAuto = false;
            c.sp.NotifyWhenDataAvailableExceeds = c.interval;

            c.pleLh = c.sp.addlistener('DataAvailable', @invervalCall);

            updateScanGraph();
            
%             c.pleIn = [c.perotIn.'   c.grateIn.'];  % Generated in updateScanGraph
        
            c.finalGraphX = zeros(1, c.interval*(c.upScans + c.downScans));
            c.finalGraphY = zeros(1, c.interval*(c.upScans + c.downScans));
            c.finalGraphP = zeros(1, c.interval*(c.upScans + c.downScans));

            c.finalColorX = zeros(c.interval*(c.upScans + c.downScans), c.qmaxPle);
            c.finalColorY = zeros(c.interval*(c.upScans + c.downScans), c.qmaxPle);
            c.finalColorP = zeros(c.interval*(c.upScans + c.downScans), c.qmaxPle);

            c.output = daqOutQueueCleverPLE({c.perotIn.', c.grateIn.'});

            queueOutputData(c.sp, c.output);
            queueOutputData(c.sp, c.output);
            
%             queueOutputData(c.sPle, c.pleIn);
%             queueOutputData(c.sPle, c.pleIn);
%             queueOutputData(c.sPle, c.pleIn);
            
            c.sd.outputSingleScan(1);

            c.sp.startBackground();

            display('Scanning Up');
        end
    end
    function invervalCall(src, event)
        if c.outputEnabled && c.pleScanning
            c.intervalCounter = c.intervalCounter + 1;
            
            detectOut = event.Data(:,1);
            perotOut =  event.Data(:,2);
            normOut =   event.Data(:,3);
            time =      event.TimeStamps;

            first = 0;
            if (c.intervalCounter-1) > 0
                first = c.finalGraphY((c.intervalCounter-1)*c.interval);
            end

            c.finalGraphY((1 + (c.intervalCounter-1)*c.interval):(c.intervalCounter*c.interval)) = [first diff(detectOut).'].'; %./normOut; % + (detectOut == 0)
            c.finalGraphP((1 + (c.intervalCounter-1)*c.interval):(c.intervalCounter*c.interval)) = perotOut.*transpose(1:c.interval <= c.perotLength);
            c.finalGraphX((1 + (c.intervalCounter-1)*c.interval):(c.intervalCounter*c.interval)) = time;

            [peaks, ~] = findPeaks(transpose(perotOut(1:c.perotLength)));

            c.rfreq = [c.rfreq	peaks(peaks~=0)];
            c.rtime = [c.rtime	time(floor(peaks(peaks~=0))).'];

            j = 1;
            while peaks(j) ~= 0
                fsrFromPrev = (peaks(j) - c.perotPrev)/c.FSR;

                if ~isnan(fsrFromPrev)
                    fsrFromPrev = fsrFromPrev - round(fsrFromPrev);

                    if (fsrFromPrev < 0)
    %                     display('Warning: Interpreted As Going Backwards!');
                    elseif (fsrFromPrev > 4*1.8/c.upScans)
    %                     display('Warning: Possible Modehop!');
        %             else
                    end

                    c.freqs = [c.freqs	(c.freqPrev + 10*(fsrFromPrev))];    % In GHz
                    c.times = [c.times  time(floor(peaks(j)))];

                    c.perotPrev = peaks(j);
                    c.freqPrev = (c.freqPrev + 10*(fsrFromPrev));

                end

                j = j + 1;
            end

            if c.intervalCounter == c.upScans
                c.sd.outputSingleScan(0);

                display('Scanning Down');
            end
            if c.intervalCounter == c.upScans + c.downScans - 1
                queueOutputData(c.sp, c.output);
            end
            if c.intervalCounter == c.upScans + c.downScans
                c.sd.outputSingleScan(1);

                updateGraph();

                display('Scanning Up');

                if get(c.pleCont, 'Value') ~= 1     % Check if button is still pressed
                    c.sd.outputSingleScan(0);
                    ledSet(0);
                    
                    c.pleScanning = 0;
                    stop(c.sp);  % Not sure if this will flush all of the data; may cause troubles.
                    c.sp.IsContinuous = false;
                    
                    delete(c.pleLh);
    %                 turnEverythingOn();
                    display('Ready');
                end

                c.intervalCounter = 0;
                c.freqPrev = 0; %freqBase;
                c.perotPrev = c.perotBase;
                c.freqs = zeros(1, 3*c.upScans);
                c.times = zeros(1, 3*c.upScans);
                c.rfreq = zeros(1, 3*c.upScans);
                c.rtime = zeros(1, 3*c.upScans);
            end
            % elseif c.intervalCounter <= c.upScans    % Even if intervalCounter is 15...
            %end
        end
    end
    function s = sizeA(array)
        dim = size(array);
        s = dim(2);
    end
    function [out, wid] = findPeaks(array)
        out = zeros(1, 5);
        wid = zeros(1, 5);
        n = 1;

        bin = find((array - max(array)/2) >= 0);

        i = 0;

        xp = 0;

        for x = bin;
            if i == 0
                i = x;
            elseif xp ~= x - 1
                % v = coeffvalues(fit( ((i-5):(x+5)).', array((i-5):(x+5)).', 'gauss1' ));

                out(n) = (xp + i)/2; % v(2);
                wid(n) = xp - i; % v(3);

                n = n + 1;

                if n == 4
    %                 display('More than three peaks detected...');
    %                 break;
                end

        %             if v(1) < m*.75
        %                 error('Peak unusually small...');
        %             end
        %             
        %             if v(3) > 5
        %                 error('Very wide peak detected...');
        %             end

                i = x;
            end
            xp = x;
        end

        out(n) = (xp + i)/2; % v(2);
        wid(n) = xp - i; % v(3);

        out(n+1) = 0;
        wid(n+1) = 0;
    end
    function str = returnHzString(hz)
        str = [num2str(round(hz/10000000)/100) ' GHz'];

        if hz < 1000
            str = [num2str(round(hz)) ' Hz'];
        elseif hz < 1000000
            str = [num2str(round(hz/10)/100) ' kHz'];
        elseif hz < 1000000000
            str = [num2str(round(hz/10000)/100) ' MHz'];
        end
    end
    function pleSave_Callback(~,~)
        freqBase = c.freqBase;
        perotBase = c.perotBase;
        xData = c.finalColorX;
        yData = c.finalColorY;
        pData = c.finalColorP;
        
        save('pleData.mat', 'freqBase', 'perotBase', 'xData', 'yData', 'pData');
    end

    % TRACKING ============================================================
    function out_img=img_enhance(in_img)
            %Sharpen 
            filter = fspecial('unsharp', 1);
            I1 = imfilter(in_img, filter);

            %Adjust contrast
           % I2 = imtophat(I1,strel('disk',32));
            out_img = imadjust(I1);       
    end
    function startvid_Callback(hObject,~)
         if hObject ~= 0 && ~c.vid_on
            set(c.track_stat,'String','Status: Started vid');

                c.tktime = timer;
                c.tktime.TasksToExecute = Inf;
                c.tktime.Period = 1/c.ratevid;
                c.tktime.TimerFcn = @(~,~)tkListener;
                c.tktime.ExecutionMode = 'fixedSpacing';
                
                c.centroidtime = timer;
                c.centroidtime.TasksToExecute = Inf;
                c.centroidtime.Period = 1/c.ratetrack;
                c.centroidtime.TimerFcn = @(~,~)centroidListener;
                c.centroidtime.ExecutionMode = 'fixedSpacing';
                    
                c.vid_on=1;
                c.seldisk=0;
                
                start(c.tktime);
         end
    end
    function tkListener(~, ~)
         frame = flipdim(getsnapshot(c.vid),1);
         %frame= rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png'));
         
        if c.vid_on 
            I3 = img_enhance(frame);          
            set(c.track_img,'CData',I3); 
            
            
            IBW=im2bw(I3,0.7); %Convert to BW and Threshold
            [c.circles, c.radii] = imfindcircles(IBW,[14 26]); %Track Full image
            
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
    function centroidListener(~,~)
       
         frame = flipdim(getsnapshot(c.vid),1);
        %frame= rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png'));

        
        IBW=im2bw(frame,0.6);
        %c.roi_image=imcrop(IBW,c.roi);
        roi = round(c.roi);
        c.roi_image = IBW(roi(2):roi(2)+roi(4),roi(1):roi(1)+roi(3));
        
        
            if c.centroid_init
                axes(c.roi_Axes); 
                c.hroi=imshow(c.roi_image);

                [c.centroidXi,c.centroidYi]=centroid_fun();
                set(c.track_stat,'String',['Got Initial Centroid']);
                c.centroid_init=0;
                
                try
                    c.S=load('piezo_calib.mat');
                catch err
                    disp(err.message)
                end
                
                c.gain = str2double(get(c.trk_gain, 'String'));
                minAdjustmentpx = str2double(get(c.trk_min, 'String'));
                
                c.mindelVx = minAdjustmentpx*c.S.pX;
                c.mindelVy = minAdjustmentpx*c.S.pY;
                %zfocuscounter = 0;
                
            else 

                 [c.centroidX,c.centroidY, R]=centroid_fun();
                 %set(c.track_stat,'String',['Centroid X:' num2str(c.centroidX) 'Y:'  num2str(c.centroidY)]);
                 set(c.hroi,'CData',c.roi_image);
                 try
                    delete(c.hg2);
                    delete(c.hg3);
                 catch
                 end

                try
                 c.hg2=viscircles([c.centroidX c.centroidY] ,R,'EdgeColor','r','LineWidth',1.5); hold on;
                 c.hg3=scatter(c.centroidX, c.centroidY,50,'g','LineWidth',4);    hold off;    
                catch err
                    disp(err.message)
                end

                delX = c.centroidX-c.centroidXi;
                delY = c.centroidY-c.centroidYi;

                delVx = delX*c.S.pX*c.gain;
                delVy = delY*c.S.pY*c.gain;
                
                %only move if voltage stays positive
                %Vxnew = max([0, Vxold - delVx])
                %Vynew = max([0, Vyold - delVy])

                
                if (abs(delVx)>c.mindelVx) && (abs(delVy) > c.mindelVy)
                    %disp('corrected')
                     c.s.outputSingleScan([(c.piezo + [-delVx delVy 0]) c.galvo]);
                elseif (abs(delVx)>c.mindelVx)
                   % disp('corrected')
                     c.s.outputSingleScan([(c.piezo + [-delVx 0 0]) c.galvo]);
                elseif (abs(delVy) > c.mindelVy)
                   % disp('corrected')
                     c.s.outputSingleScan([(c.piezo + [0 delVy 0]) c.galvo]);
                end
                
                %getPiezo();
                
            end
           
    end
    function click_trackCallback(~,~)
        %disp('click')
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
                    c.hg2=viscircles(c.selcircle ,c.selradii,'EdgeColor','r','LineWidth',1.5); 
                    c.seldisk=1;
                    stop(c.tktime);
                end
             end
        end
    end
    function stopvid_Callback(~,~)
        if c.vid_on
            set(c.track_stat,'String','Status: Stopped Everything');

            try
            stop(c.tktime);
            delete(c.tktime);
            catch err
                disp(err.message)
            end

            try
                stop(c.centroidtime);
                delete(c.centroidtime);
            catch err
                disp(err.message)
            end

            c.vid_on = 0;
        end
    end
    function cleartrack_Callback(~,~)
        if c.vid_on && c.seldisk
            c.seldisk=0;
            start(c.tktime);
            
            try
                stop(c.centroidtime);
            catch err
                disp(err.message)
            end
             
             c.roi='';
             axes(c.roi_Axes); cla;
             try
                 delete(c.hg1);
             catch
             end
             try
                    delete(c.hg2);
                    delete(c.hg3);
             catch
             end
             set(c.track_stat,'String','Status: ROI cleared');
        end
    end
    function settrack_Callback(~,~)
      if isempty(c.roi) && c.seldisk 
       %Set the ROI for tracking
       c.roi=[c.selcircle(1)-c.selradii-c.roi_pad c.selcircle(2)-c.selradii-c.roi_pad 2*(c.selradii+c.roi_pad) 2*(c.selradii+c.roi_pad)];   
       set(c.track_stat,'String','Status: New ROI Selected');
       
       %Get Initial Centroid Position  
       c.centroid_init=1;   
       start(c.centroidtime);
      end
    end
    function [X,Y,R] = centroid_fun()
         st = regionprops( c.roi_image, 'Area', 'Centroid','MajorAxisLength','MinorAxisLength');
         sel = [st.Area] > pi*15*15;
         st = st(sel);
         X=st.Centroid(1); Y=st.Centroid(2);
         diameters = mean([st.MajorAxisLength st.MinorAxisLength],2);
         R = diameters/2;
    end

    % Mouse Control =======================================================
    function go_mouse_Callback(~,~)
        pt=impoint(c.imageAxes);
        setColor(pt,'r');
        
        pos=getPosition(pt);
        X=pos(1); Y=pos(2);
        
       deltaX = X - 640/2;
       deltaY = -(Y - 480/2);

       %Always approach from same direction (from bottom left)
       offset=5; % in um
       try
        S=load('micro_calib.mat');
       catch err
           disp(err.message)
       end
       
      % disp([num2str(S.mX) num2str(S.mY)])
       
       deltaXm = deltaX*S.mX;
       deltaYm = deltaY*S.mY;
       deltaXmo= deltaXm - offset;
       deltaYmo= deltaYm - offset;

       c.micro = c.micro + [deltaXmo deltaYmo];
       setPos();

       while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end

       %Approach from bottom left
       c.micro = c.micro + [offset offset];
       setPos(); 
       renderUpper();

       while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end

       setPosition(pt,[640/2 480/2]);
       setColor(pt,'g');
       pause(1);
       delete(pt);
    end
    function go_mouse_fine_Callback(~,~)
        %Allow only small change
        axes(c.imageAxes);
        mask=rectangle('Position',[640/2-50,480/2-50,100,100],'EdgeColor','r');

        pt=impoint(c.imageAxes);
        setColor(pt,'m');
        
        pos=getPosition(pt);
        X=pos(1); Y=pos(2);
        if (X>640/2-50 && X<640/2+50) && (Y>480/2-50 && Y<480/2+50)
           
            disp('inside mask')
            deltaX = -(X - 640/2);
            deltaY = (Y - 480/2);
            
            %calibration constant between pixels and voltage
            try
                S=load('piezo_calib.mat');
            catch err
                disp(err.message)
            end
            
           % disp([num2str(S.pX) num2str(S.pY)])
            %Always approach from same direction (from bottom left)
            offset = 0.2; % in V

            deltaXm = deltaX*S.pX;
            deltaYm = deltaY*S.pY;
            deltaXmo= deltaXm + offset;
            deltaYmo= deltaYm + offset;

            piezoOutSmooth(c.piezo + [deltaXmo deltaYmo 0]);
            pause(0.2);
            %disp('m1')
            
            %Approach from bottom left
            piezoOutSmooth(c.piezo + [-offset -offset 0]);
            pause(0.2);
            renderUpper();
            %disp('m2')
            
            setPosition(pt,[640/2 480/2]);
            setColor(pt,'g');
            pause(1);
        else
            disp('click outside mask!!')
        end
        delete(pt);
        delete(mask);
    end
    function go_mouse_fbk_Callback(~,~)  %Unused For Now
%         axes(c.imageAxes);
%         mask=rectangle('Position',[640/2-200,480/2-150,400,300],'EdgeColor','r');
%         
%         pt=impoint(c.imageAxes);
%         setColor(pt,'r');
%         
%         pos=getPosition(pt);
%         X=pos(1); Y=pos(2);
%         if (X>640/2-200 && X<640/2+200) && (Y>480/2-150 && Y<480/2+150)
%             
%             disp('inside mask')
%             
%            
%            
%            deltaX = X - 640/2;
%            deltaY = -(Y - 480/2);
% 
%            % Feedback for backlash and hysteresis compensation
%            
%            % Parameters
%            min_delta=5;  % Threshold deviation (Pix)
%            max_tries=5;  % Maximum Iterations
%            %Always approach from same direction (from bottom left)
%            offset=5; % in um
%            min_offset=1;  % in um
% 
%            count=1;
%            while (deltaX>min_delta || deltaY>min_delta) && count<max_tries+1
% 
%                deltaXm = deltaX*78/640;
%                deltaYm = deltaY*62/480;
%                deltaXmo= deltaXm - offset;
%                deltaYmo= deltaYm - offset;
% 
%                %img_before=flipdim(getsnapshot(c.vid),1);
%                old = c.microActual;
%                c.micro = c.micro + [deltaXmo deltaYmo];
%                setPos();
% 
%                %Wait to complete the initial move
%                while sum(abs(c.microActual - c.micro)) > .1
%                     pause(.1);
%                     getPos();
%                     renderUpper();
%                 end
% 
%                %Approach from bottom left
%                c.micro = c.micro + [offset offset];
%                setPos(); 
%                renderUpper();
% 
%                while sum(abs(c.microActual - c.micro)) > .1
%                     pause(.1);
%                     getPos();
%                     renderUpper();
%                end
%                
%                new=c.microActual;
%                %img_after=flipdim(getsnapshot(c.vid),1);
% 
%                %calculate actual distance moved
%                
%                %a_delta=actual_delta(img_before,img_after);
%                a_delta=new-old;
%                
%                %get new delta
%                deltaX=deltaX-a_delta(1);
%                deltaY=deltaY-a_delta(2);
% 
%                %reduce offset for next iteration
%                offset=offset-count;
%                offset=max(min_offset,offset); % has to be >=min_ofset
% 
%                count=count+1;
%            end
%            
%            setPosition(pt,[640/2 480/2]);
%            setColor(pt,'g');
%            pause(1);
%         else
%             disp('click outside mask!!')
%         end
%         delete(pt);
%         delete(mask);
    end
    function a_delta=actual_delta(img_before,img_after)%Need to have a working computer vision toolbox!!
%         I1 = img_before;
%         I2 = img_after;
%         
%         %remove the image borders and detect 100 corner features
%         roi1 = I1(20:460,20:620);
%         C1 = corner(roi1,100);
% 
%         %remove the image borders and detect 100 corner features
%         roi2 = I2(20:460,20:620);
%         C2 = corner(roi2,100);
% 
%         [features1, valid_points1] = extractFeatures(roi1, C1);
%         [features2, valid_points2] = extractFeatures(roi2, C2);
% 
%         indexPairs = matchFeatures(features1, features2);
% 
%         matchedPoints1 = valid_points1(indexPairs(:, 1), :);
%         matchedPoints2 = valid_points2(indexPairs(:, 2), :);
% 
%         a_delta=mean(matchedPoints2-matchedPoints1);
    end

    % Calibration =========================================================
    function microCalib_Callback(~,~)
        set(c.calibStat,'String','Status: select a refrence pt');
        offset=5; %in um
        
        %Performing X-Axis calibration
        pt1=impoint(c.imageAxes);
        setColor(pt1,'r');
        pos1=getPosition(pt1); X1=pos1(1);
        
        set(c.calibStat,'String','Status: moving micrometers by 10um in X');
        c.micro = c.micro + [10-offset -offset];
        setPos(); 
        renderUpper();
        while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end
        
        c.micro = c.micro + [offset offset];
        setPos(); 
        renderUpper();
        while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end
        
        set(c.calibStat,'String','Status: Please re-select the same reference pt');
        pt2=impoint(c.imageAxes);
        setColor(pt2,'b');
        
        pos2=getPosition(pt2); X2=pos2(1);
        
        mX = 10/(X1-X2)
        set(c.calibStat,'String',['Status: XFactor: ' num2str(mX)]);
        pause(1);
        
        delete(pt1); delete(pt2);
        
        %Performing Y-Axis calibration
        set(c.calibStat,'String','Status: Now for Y Axis, select a refrence pt');
        pt1=impoint(c.imageAxes);
        setColor(pt1,'r');
        pos1=getPosition(pt1); Y1=pos1(2);
        
        set(c.calibStat,'String','Status: moving micrometers by 10um in Y');
        c.micro = c.micro + [-offset 10-offset];
        setPos(); 
        renderUpper();
        while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end
        
        c.micro = c.micro + [offset offset];
        setPos(); 
        renderUpper();
        while sum(abs(c.microActual - c.micro)) > .1
            pause(.1);
            getPos();
            renderUpper();
        end
        
        set(c.calibStat,'String','Status: Please re-select the same reference pt');
        pt2=impoint(c.imageAxes);
        setColor(pt2,'b');
        
        pos2=getPosition(pt2); Y2=pos2(2);
        
        mY = 10/(Y2-Y1)
        set(c.calibStat,'String',['Status: YFactor:\t' num2str(mY)]);
        pause(1);
        
        delete(pt1); delete(pt2);
        
        set(c.calibStat,'String','Done','ForegroundColor', 'green');
        
        save('micro_calib.mat','mX','mY');
    end
    function piezoCalib_Callback(~,~)
        set(c.calibStat,'String','Status: select a refrence pt');
        offset=0.2; % in V
        
        %Performing X-Axis calibration
        pt1=impoint(c.imageAxes);
        setColor(pt1,'r');
        pos1=getPosition(pt1); X1=pos1(1);
        
        set(c.calibStat,'String','Status: moving piezo by 1V in X');
        piezoOutSmooth(c.piezo + [1+offset +offset 0]);
        pause(0.2);renderUpper();
        
        piezoOutSmooth(c.piezo + [-offset -offset 0]);
        pause(0.2);
        renderUpper();
  
        set(c.calibStat,'String','Status: Please re-select the same reference pt');
        pt2=impoint(c.imageAxes);
        setColor(pt2,'b');
        
        pos2=getPosition(pt2); X2=pos2(1);
        
        pX = 1/(X2-X1)
        set(c.calibStat,'String',['Status: XFactor: ' num2str(pX)]);
        pause(1);
        
        delete(pt1); delete(pt2);
        
        %Performing Y-Axis calibration
        set(c.calibStat,'String','Status: Now for Y Axis, select a refrence pt');
        pt1=impoint(c.imageAxes);
        setColor(pt1,'r');
        pos1=getPosition(pt1); Y1=pos1(2);
        
        set(c.calibStat,'String','Status: moving piezo by -1V in Y');
         piezoOutSmooth(c.piezo + [+offset -1+offset 0]);
        pause(0.2);renderUpper();
        
        piezoOutSmooth(c.piezo + [-offset -offset 0]);
        pause(0.2);renderUpper();
        
        set(c.calibStat,'String','Status: Please re-select the same reference pt');
        pt2=impoint(c.imageAxes);
        setColor(pt2,'b');
        
        pos2=getPosition(pt2); Y2=pos2(2);
        
        pY = 1/(Y2-Y1)
        set(c.calibStat,'String',['Status: YFactor:\t' num2str(pY)]);
        pause(1);
        
        delete(pt1); delete(pt2);
        
        set(c.calibStat,'String','Done','ForegroundColor', 'green');
        
        save('piezo_calib.mat','pX','pY');
    end

    % Set counting
    function set_mark_Callback(~,~)
        set(c.set_no,'String','[0 0]');
        c.m_zero=c.microActual;
    end
    function gotoSButton_Callback(~,~)
        if ~isempty(c.m_zero)
            
            X=str2double(get(c.gotoSX, 'String'));
            Y=str2double(get(c.gotoSY, 'String'));
            
            if X>3 || Y>4
                disp('Given value out of range')
            else
            
            dX= X-c.Sx;
            dY= -(Y-c.Sy);
            
            c.micro=c.micro + [dX*400.05 dY*262.507];
            setPos(); 
            renderUpper();

               while sum(abs(c.microActual - c.micro)) > .1
                    pause(.1);
                    getPos();
                    renderUpper();
               end
            end
        else
            disp('Set zero not marked!!!')
        end
            
    end
end
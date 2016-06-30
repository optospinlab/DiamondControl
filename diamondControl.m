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
%     if isempty(varargin)    % If no variables have been given, make the figure
%         f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none','Position',get(0,'Screensize'));
%         c = diamondControlGUI('Parent', f);
%     else                    % Otherwise pass the variables on.
%         c = diamondControlGUI(varargin);
%     end

    c = diamondControlGUI();
    
    javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel');
    
    % Helper Global variables for UI construction
    global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
    
    % UI CALLBACKS ========================================================
%     set(c.parent, 'WindowKeyPressFcn', @figure_WindowKeyPressFcn);  % Interprets keypresses e.g. up/down arrow.
%     set(c.parent, 'WindowKeyReleaseFcn', @figure_WindowKeyReleaseFcn);
    
    set(c.parent, 'CloseRequestFcn', @closeRequest);                % Handles the closing of the figure.
    
    set(c.joyMode, 'SelectionChangedFcn', @joyModeColor);
    
%     set(c.boxTL, 'Callback', @box_Callback);
%     set(c.boxTR, 'Callback', @box_Callback);
%     set(c.boxBL, 'Callback', @box_Callback);
%     set(c.boxBR, 'Callback', @box_Callback);
    
    % round2 devices auto set calculation
    set(c.set_mark, 'Callback', @set_mark_Callback);  

    % Calibration ---------------------------------------------------------
    set(c.microCalib, 'Callback', @microCalib_Callback);  
    set(c.piezoCalib, 'Callback', @piezoCalib_Callback);  
    
    % Saving --------------------------------------------------------------
    set(c.saveChoose,           'Callback', @save_Callback);  
    set(c.saveBackgroundChoose, 'Callback', @saveBackground_Callback);  
    set(c.saveDirectory,           'Callback', @saveEdit_Callback);  
    set(c.saveBackgroundDirectory, 'Callback', @saveEditBackground_Callback);  
    
    % Goto Fields ---------------------------------------------------------
    set(c.gotoMX, 'Callback', @limit_Callback);                     % Limits the values of these uicontrols to be
    set(c.gotoMY, 'Callback', @limit_Callback);                     % within the safe/allowed limits of the devices
    set(c.gotoPX, 'Callback', @limit_Callback);                     % they control. e.g. piezos are limited 0 -> 50 um.
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
    set(c.gotoPOptXY,  'Callback', @optXY_Callback);                % XY and Z opt use count-optimization techniques
    set(c.gotoPOptZ,  'Callback',  @optZ_Callback);
    set(c.gotoPOptAll,  'Callback',@optAll_Callback);
    set(c.gotoPReset, 'Callback',  @resetPiezoXY_Callback);         % Resets the XY to [0 0], approaching from [-25 -25]
    set(c.gotoPTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    
    set(c.gotoGButton, 'Callback', @gotoGalvo_Callback);            % GALVO GOTO controls - Goto button sends the galvos to the current fields
    set(c.gotoGReset, 'Callback',  @resetGalvo_Callback);           % Resets the XY to [0 0] (should I approach from a direction?)
    set(c.gotoGTarget, 'Callback', @gotoTarget_Callback);           % Sets the fields to the current target
    set(c.gotoGOpt, 'Callback', @optGalvo_Callback);
    
    set(c.go_mouse, 'Callback', @go_mouse_Callback); 
    set(c.go_mouse_fine, 'Callback', @go_mouse_fine_Callback); 
    set(c.laser_offset, 'Callback', @laser_offset_Callback);
    
    set(c.capture_blue, 'Callback', @capture_blue_Callback);
    
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
    
    set(c.galvoOptimizeX,  'Callback', @optGalvoX_Callback);
    set(c.galvoOptimizeY,  'Callback', @optGalvoY_Callback);
    
    % Piezo Fields --------------------------------------------------------
    set(c.piezoButton, 'Callback', @piezoScan_Callback);            % Starts a Piezo scan. Below are parameters defining that scan.
    set(c.piezoR, 'Callback', @piezoVar_Callback);                  %  - R for Range in um/side (approx) where the side is the side of the scanning square
    set(c.piezoS, 'Callback', @piezoVar_Callback);                  %  - S for Speed in um/sec
    set(c.piezoP, 'Callback', @piezoVar_Callback);                  %  - P for Pixels in pixels/side
    
    set(c.piezoOptimize, 'Callback', @piezoOpt_Callback);
    
    set(c.piezoOptimizeX,  'Callback', @optX_Callback);
    set(c.piezoOptimizeY,  'Callback', @optY_Callback);
    set(c.piezoOptimizeZ,  'Callback', @optZ_Callback);
    
    set(c.piezoSwitchTo3DButton, 'Callback', @piezoSwitch3D_Callback);
    set(c.piezo3DMenu, 'Callback', @piezoChange3DMenu_Callback);
    set(c.piezo3DPlus, 'Callback', @piezo3DPlus_Callback);
    set(c.piezo3DMinus,'Callback', @piezo3DPlus_Callback);
    
    function piezo3DPlus_Callback(src,~)
        if src == c.piezo3DPlus
            v = get(c.piezo3DMenu, 'Value') + 1;
        else
            v = get(c.piezo3DMenu, 'Value') - 1;
        end

        if v < 1
            v = length(get(c.piezo3DMenu, 'String'));
        end
        if v > length(get(c.piezo3DMenu, 'String'))
            v = 1;
        end

        set(c.piezo3DMenu, 'Value', v);
        
        renderData(1);
    end
    
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
    set(c.autoV5Get, 'Callback', @setCurrent_Callback);
    
    set(c.autoTaskG2S, 'Callback', @setCurrent_Callback);
    set(c.autoTaskG3S, 'Callback', @setCurrent_Callback);
    
    set(c.autoDiskDet, 'Callback', @diskdetect_Callback);
    set(c.autoDiskClr, 'Callback', @diskclear_Callback);
    
    set(c.autoPreview, 'Callback',  @autoPreview_Callback);         % Displays the devices that will be tested to an axes. Useful for error-correcting
    set(c.autoTest, 'Callback',  @autoTest_Callback);               % Displays the devices that will be tested to an axes. Useful for error-correcting
    set(c.autoButton, 'Callback',  @automate_Callback);             % Starts the automation!
    set(c.autoProceed, 'Callback',  @proceed_Callback);             % Button to proceed to the next device. The use has the option to use this to proceed or 
                                                                    % to autoproceed using a checkbox.
    set(c.autoSkip, 'Callback',  @autoSkip_Callback);
    
    % Counter Fields ------------------------------------------------------
    set(c.counterButton, 'Callback',  @counterToggle);           
    
    % Spectra Fields (unfinished) -----------------------------------------
    set(c.spectrumButton, 'Callback',  @takeSpectrum_Callback);      
    
    set(c.globalStopButton, 'Callback', @globalStop_Callback);
    set(c.globalSaveButton, 'Callback', @globalSave_Callback);
    set(c.powerButton, 'Callback', @power_Callback);
    
    % PLE Fields ----------------------------------------------------------
    % set(c.automationPanel, 'SelectionChangedFcn',  @axesMode_Callback);
    % set(c.pleOnce, 'Callback',  @pleCall);
    set(c.pleCont, 'Callback',  @pleCall);
    set(c.pleContSimple, 'Callback',  @pleSimpleCall);
    set(c.perotCont, 'Callback',  @perotCall);
    set(c.pleSave, 'Callback',  @pleSave_Callback);
    set(c.pleSpeed, 'Callback',  @updateScanGraph_Callback);
    set(c.pleScans, 'Callback',  @updateScanGraph_Callback);
    
    % Tracking Fields -----------------------------------------------------
    set(c.start_newTrack,'Callback', @newTrack_Callback);
    set(c.stop_newTrack,'Callback', @stopnewTrack_Callback);
    
    % Scaling Fields ------------------------------------------------------
    set(c.scaleNorm, 'Callback', @scaleNormalize_Callback);
    
    set(c.scaleMinSlid, 'Callback', @scaleSlider_Callback);
    set(c.scaleMaxSlid, 'Callback', @scaleSlider_Callback);
    
    set(c.scaleMinEdit, 'Callback', @scaleEdit_Callback);
    set(c.scaleMaxEdit, 'Callback', @scaleEdit_Callback);
    
    scaleSlider_Callback(c.scaleMinSlid, 0);
    scaleSlider_Callback(c.scaleMaxSlid, 0);

    
    % Create the joystick object ==========================================
    try
        c.joy = vrjoystick(1);
        c.joystickInitiated = 1;
    catch err
        display(err.message);
        c.joystickInitiated = 0;
    end
    
    % Initial rendering
%     resizeUI_Callback(0, 0);
    renderUpper();
%     displayImage();
    setGalvoAxesLimits();
    
    % set(c.parent, 'Visible', 'On');
    
    % Initiate all external devices. e.g. piezos, micrometers.
    initAll();
    
    % Start the main loop
    main();
    
    function main()
              
        while c.running     % c.running is currently unused, but likely will be used.
            if ~c.pleScanning
                if ~c.focusing && ~c.autoScanning && ~c.doing
                    [microChanged, daqChanged] = readKeyJoy();

                    if microChanged && c.microInitiated % If X or Y have been changed
                        setPos();   % Change position of micrometers
                    end

%                     c.piezo
                    
                    if daqChanged && c.daqInitiated  % e.g. if Z has been changed
                        daqOut();   % Change position of DAQ devices
                    end

                    getCurrent();   % Get the current position of the micrometers.
                end

                renderUpper();      % Updates the grid figure.
            end
            
%             takeSpectrum_Callback(0, 0);
                    
            pause(.1); % (should later make this run so we actually delay to 60 Hz)
%             drawnow
        end
    end

    function str = returnPrefixString(num)
        neg = sign(num);

        pow = floor(log10(neg*num));
        pow3 = round(pow/3);

        switch pow3
            case -4
                prefix = 'p';
            case -3
                prefix = 'n';
            case -2
                prefix = 'u';
            case -1
                prefix = 'm';
            case 0
                prefix = '';
            case 1
                prefix = 'k';
            case 2
                prefix = 'M';
            case 3
                prefix = 'G';
            case 4
                prefix = 'T';
            case 5
                prefix = 'Y';
            otherwise
                prefix = [' x 10^' num2str(round(pow))];
        end

        if pow3 == 0
            str = [num2str(num, '%03.2f') ' '];
        else
            str = [num2str(num*(10^(-3*round(pow/3)) ), '%03.2f') ' ' prefix];
        end
    end
    function str = returnHzString(hz)
        str = [returnPrefixString(hz) 'Hz'];
    end

    % INPUTS ==============================================================
    function [outputXY, outputZ] = readKeyJoy()
        % Reads the joystick. Outputs are true if the corresponding axes were changed.
        outputXY = 0;
        outputZ = 0;

        prevMicro = c.micro;
        prevPiezo = c.piezo;
        prevGalvo = c.galvo;
        
        if get(c.keyEnabled, 'Value') == 1
            mode = get(c.joyMode, 'SelectedObject');
            
            switch mode
                case c.joyMicro
                    % Add the joystick offset to the target vector. The microscope attempts to go to the target vector.
                    c.micro(1) = c.micro(1) + (c.keyRgt - c.keyLft)*c.joyXDir*c.microStep;
                    c.micro(2) = c.micro(2) + (c.keyFwd - c.keyBck)*c.joyYDir*c.microStep;
                case c.joyPiezo
                    c.piezo(1) = c.piezo(1) - (c.keyRgt - c.keyLft)*c.joyXDir*c.piezoStep;
                    c.piezo(2) = c.piezo(2) - (c.keyFwd - c.keyBck)*c.joyYDir*c.piezoStep;
                case c.joyGalvo
                    c.galvo(1) = c.galvo(1) + (c.keyRgt - c.keyLft)*c.joyXDir*c.galvoStep;
                    c.galvo(2) = c.galvo(2) + (c.keyFwd - c.keyBck)*c.joyYDir*c.galvoStep;
            end
            
            c.piezo(3) = c.piezo(3) + (c.keyUpp - c.keyDwn)*c.piezoStep;
        end
        if (c.joystickInitiated == 1 && get(c.joyEnabled, 'Value') == 1) % && get(c.joyEnabled, 'Value') == 1   % If the joystick is enabled...
            [a, b, p] = read(c.joy);
            % a - axes (vector of values -1 to 1),
            % b - buttons (vector of 0s or 1s)
            % p - povs (vector, but with our joystick there is only one
            %     element, of angles \in { -1, 0, 45, 90, ... } where -1 is 
            %     unset and any other value is the direction the pov is facing.

%             prevX = c.micro(1); % For comparison later
%             prevY = c.micro(2);
%             prevZ = c.piezo(3);

            % Logic for whether a button has changed since last time and is on.
            buttonDown = (b ~= 0 & b ~= c.joyButtonPrev);
            if buttonDown(1)
                focus_Callback(0,0);
            end
            
            if b(11)
                set(c.joyMode, 'SelectedObject', c.joyGalvo);
            elseif b(9)
                set(c.joyMode, 'SelectedObject', c.joyPiezo);
            elseif b(7)
                set(c.joyMode, 'SelectedObject', c.joyMicro);
            end
            
            if b(7) || b(9) || b(11)
                joyModeColor(0,0);
            end
            
            mode = get(c.joyMode, 'SelectedObject');
            
            switch mode
                case c.joyMicro
                    % Add the joystick offset to the target vector. The microscope attempts to go to the target vector.
                    c.micro(1) = c.micro(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.microStep*(1+a(4))*10;
                    c.micro(2) = c.micro(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.microStep*(1+a(4))*10;
                case c.joyPiezo
                    c.piezo(1) = c.piezo(1) - c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.piezoStep*(1+a(4))*10;
                    c.piezo(2) = c.piezo(2) - c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.piezoStep*(1+a(4))*10;
                case c.joyGalvo
                    c.galvo(1) = c.galvo(1) + c.joyXDir*joystickAxesFunc(a(1), c.joyXYPadding)*c.galvoStep*(1+a(4))*10;
                    c.galvo(2) = c.galvo(2) + c.joyYDir*joystickAxesFunc(a(2), c.joyXYPadding)*c.galvoStep*(1+a(4))*10;
            end
            
            % Same for Z; the third axis is the twisting axis
            if max(abs([joystickAxesFunc(a(1), c.joyXYPadding) joystickAxesFunc(a(2), c.joyXYPadding)])) == 0
                c.piezo(3) = c.piezo(3) + 4*c.piezoStep*c.joyZDir*joystickAxesFunc(a(3), c.joyZPadding);
            end

            % Plot the XY offset on the graph in the Joystick tab
%             scatter(c.joyAxes, c.joyXDir*a(1), c.joyYDir*a(2));
%     %         set(c.joyAxes, 'xtick', []);
%     %         set(c.joyAxes, 'xticklabel', []);
%     %         set(c.joyAxes, 'ytick', []);
%     %         set(c.joyAxes, 'yticklabel', []);
%             xlim(c.joyAxes, [-1 1]);
%             ylim(c.joyAxes, [-1 1]);

            if b(6) % Up next to the pov
                c.piezo(3) = c.piezo(3) + c.joyZDir*c.piezoStep;
            end
            if b(4) % Down next to the pov
                c.piezo(3) = c.piezo(3) - c.joyZDir*c.piezoStep;
            end

            % From the pov angle, compute the direction of movement in XY
            if p ~= -1
                pov = [direction(sind(p)) (-direction(cosd(p)))];
            else
                pov = [0 0];
            end
            
            switch mode
                case c.joyMicro
                    c.micro(1) = c.micro(1) + c.joyXDir*pov(1)*c.microStep;
                    c.micro(2) = c.micro(2) + c.joyYDir*pov(2)*c.microStep;
                case c.joyPiezo
                    c.piezo(1) = c.piezo(1) + c.joyXDir*pov(1)*c.piezoStep;
                    c.piezo(2) = c.piezo(2) + c.joyYDir*pov(2)*c.piezoStep;
                case c.joyGalvo
                    c.galvo(1) = c.galvo(1) + c.joyXDir*pov(1)*c.galvoStep;
                    c.galvo(2) = c.galvo(2) + c.joyYDir*pov(2)*c.galvoStep;
            end

            % Save for next time
            c.joyButtonPrev = b;
            c.joyPovPrev = pov;
        end

        if (c.joystickInitiated == 1 && get(c.joyEnabled, 'Value') == 1) || get(c.keyEnabled, 'Value') == 1
            % Limit values
            limit();

            % Decide whether things have changed
            outputXY = sum(prevMicro ~= c.micro) ~= 0;
            outputZ = (sum(prevPiezo ~= c.piezo) + sum(prevGalvo ~= c.galvo))  ~= 0;
        end
        
        if outputZ && c.counting
            c.piezo = prevPiezo;
            c.galvo = prevGalvo;
            outputZ = false;
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
    function joyModeColor(~,~)
        mode = get(c.joyMode, 'SelectedObject');

        switch mode
            case c.joyMicro
                display('Micro mode...');
                set(c.microText, 'ForegroundColor', 'green');
                set(c.piezoText, 'ForegroundColor', 'black');
                set(c.galvoText, 'ForegroundColor', 'black');
            case c.joyPiezo
                display('Piezo mode...');
                set(c.microText, 'ForegroundColor', 'black');
                set(c.piezoText, 'ForegroundColor', 'green');
                set(c.galvoText, 'ForegroundColor', 'black');
            case c.joyGalvo
                display('Galvo mode...');
                set(c.microText, 'ForegroundColor', 'black');
                set(c.piezoText, 'ForegroundColor', 'black');
                set(c.galvoText, 'ForegroundColor', 'green');
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
%         if get(c.keyEnabled, 'Value') == 1 && c.microInitiated && c.daqInitiated && c.outputEnabled && ~c.galvoScanning && false
%             changed = true;
%             
%             switch eventdata.Key
%                 case {'uparrow', 'w'}
%                     c.micro(2) = c.micro(2) + c.microStep;
%                 case {'downarrow', 's'}
%                     c.micro(2) = c.micro(2) - c.microStep;
%                 case {'leftarrow', 'a'}
%                     c.micro(1) = c.micro(1) - c.microStep;
%                 case {'rightarrow', 'd'}
%                     c.micro(1) = c.micro(1) + c.microStep;
%                 case {'pageup', 'add', 'equal', 'q'}
%                     c.piezo(3) = c.piezo(3) + c.piezoStep;
%                 case {'pagedown', 'subtract', 'hyphen', 'e'}
%                     c.piezo(3) = c.piezo(3) - c.piezoStep;
%                 otherwise
%                     changed = false;
%             end   
%             
%             if changed
%                 limit();    % Make sure we do not overstep...
% 
%                 daqOut();   % (piezos, galvos)
%                 setPos();   % (micrometers)
%             end
%         end
%         if get(c.keyEnabled, 'Value') == 1 && c.microInitiated && c.daqInitiated && c.outputEnabled && ~c.galvoScanning
%             changed = true;
            
            switch eventdata.Key
                case {'uparrow', 'w'}
                    c.keyFwd = c.keyFwd + 1;
                case {'downarrow', 's'}
                    c.keyBck = c.keyBck + 1;
                case {'leftarrow', 'a'}
                    c.keyLft = c.keyLft + 1;
                case {'rightarrow', 'd'}
                    c.keyRgt = c.keyRgt + 1;
                case {'pageup', 'add', 'equal', 'q'}
                    c.keyUpp = c.keyUpp + 1;
                case {'pagedown', 'subtract', 'hyphen', 'e'}
                    c.keyDwn = c.keyDwn + 1;
%                 otherwise
%                     changed = false;
            end   
            
%             if changed
%                 limit();    % Make sure we do not overstep...
% 
%                 daqOut();   % (piezos, galvos)
%                 setPos();   % (micrometers)
%             end
%         end
    end
    function figure_WindowKeyReleaseFcn(~, eventdata)
        switch eventdata.Key
            case {'uparrow', 'w'}
                c.keyFwd = c.keyFwd - 1;
            case {'downarrow', 's'}
                c.keyBck = c.keyBck - 1;
            case {'leftarrow', 'a'}
                c.keyLft = c.keyLft - 1;
            case {'rightarrow', 'd'}
                c.keyRgt = c.keyRgt - 1;
            case {'pageup', 'add', 'equal', 'q'}
                c.keyUpp = c.keyUpp - 1;
            case {'pagedown', 'subtract', 'hyphen', 'e'}
                c.keyDwn = c.keyDwn - 1;
        end
    end
    function saveState()
        try
            piezoZ =    c.piezo(3);

            parentP =   get(c.parent, 'Position');
            upperP =    get(c.upperFigure, 'Position');
            lowerP =    get(c.lowerFigure, 'Position');
            imageP =    get(c.imageFigure, 'Position');
            pleP =      get(c.pleFigure, 'Position');
            blueP =     get(c.bluefbFigure, 'Position');

            parentM =   figstate(c.parent);
            upperM =    figstate(c.upperFigure);
            lowerM =    figstate(c.lowerFigure);
            imageM =    figstate(c.imageFigure);
            pleM =      figstate(c.pleFigure);
            blueM =     figstate(c.bluefbFigure);

            save([c.directory 'state.mat'], 'piezoZ',... 
                'parentP', 'upperP', 'lowerP', 'imageP', 'pleP', 'blueP',...
                'parentM', 'upperM', 'lowerM', 'imageM', 'pleM', 'blueM');
        catch err
            display(err.message);
        end
    end
    function getState()
        piezoZ = 0;
        try
            data = load([c.directory 'state.mat']);
            piezoZ = data.piezoZ;
            prev = get(c.parent, 'Position');
            
            screenSize = get(0,'screensize');
            
            if data.parentP(1) < 0 || data.parentP(1) > screenSize(3)
                data.parentP(1) = 100;
            end
            if data.parentP(2) < 0 || data.parentP(2) > screenSize(4)
                data.parentP(2) = 100;
            end
            
            set(c.parent,       'Position', [data.parentP(1) data.parentP(2) prev(3) prev(4)]);
            set(c.upperFigure,  'Position', data.upperP);
            set(c.lowerFigure,  'Position', data.lowerP);
            set(c.imageFigure,  'Position', data.imageP);
            set(c.pleFigure,    'Position', data.pleP);
            
%             if strcmp(data.parentM, 'Minimized') == 0
%                 minfig(c.parent, 1);
%             end
%             if strcmp(data.upperM, 'Minimized') == 0
%                 minfig(c.upperFigure, 1);
%             end
%             if strcmp(data.lowerM, 'Minimized') == 0
%                 minfig(c.lowerFigure, 1);
%             end
%             if strcmp(data.imageM, 'Minimized') == 0
%                 minfig(c.imageFigure, 1);
%             end
%             if strcmp(data.pleM, 'Minimized') == 0
%                 minfig(c.pleFigure, 1);
%             end
%             if strcmp(data.blueM, 'Minimized') == 0
%                 minfig(c.bluefbFigure, 1);
%             end
        catch err
            display('Error with setting the previous UI state:');
            display(err.message);
        end
            % set(c.parent, 'Position', [100 100 pw puh+plh]);
        
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
            % daqOutSmooth([0 0 0 0 0]);
            
            ledSet(0);
            pause(.25);
            
            c.sd.outputSingleScan(1);
            
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
            
            fclose(c.norm);
            
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
            
            try
                stop(c.tktime);
                delete(c.tktime);
                clear c.tktime
            catch err
                disp(err.message)
            end
    
    c.newtrack_on=0;
            
        catch err
            display(err.message);
        end
        
        display('  Goodbye graphics...');
        % Release the graphics
        delete(c.imageAxes);
        delete(c.upperAxes);
        delete(c.lowerAxes);
        delete(c.bluefbAxes);
        delete(c.counterAxes);
        %delete(c.upperAxes2);
        %delete(c.lowerAxes2);
        %delete(c.counterAxes2);
        
        delete(c.upperFigure);
        delete(c.lowerFigure);
        delete(c.imageFigure);
        delete(c.pleFigure);
        delete(c.bluefbFigure);
        delete(c.counterFigure);
        delete(c.parent);
        delete(c.scaleFigure);
    end
    function globalStop_Callback(~,~)
%         set(c.globalStopButton, 'Enable', 'off');
        display('Stopping');
        
        c.globalStop = true;
        c.autoScanning = false;
%         pause(3);
%         if c.globalStop
%             display('Nothing was stopped...');
%             c.globalStop = false;
%         end
        
%         set(c.globalStopButton, 'Enable', 'on');
    end
    function globalSave_Callback(~,~)
        globalSave(c.directory);
    end
    function globalSave(directory)
        clk = clock;
        timestamp = [num2str(clk(1)) '_' num2str(clk(2)) '_' num2str(clk(3)) ' ' num2str(clk(4)) '-' num2str(clk(5)) '-' num2str(clk(6))];
        
        data.micrometerLocation = c.micro;
        
        switch c.saveMode
            case 'piezo3D'
                saveas(c.lowerAxes3D, [directory timestamp '_' c.saveMode '_AxesTest' '.png']);
            otherwise
                saveas(c.lowerAxes, [directory timestamp '_' c.saveMode '_AxesTest' '.png']);
        end
        
        switch c.saveMode
            case {'piezo', 'galvo'} % Need to fix the image flipping!
                data.type =   c.saveMode;
                data.xrange = c.saveX;
                data.yrange = c.saveY;
                data.data =   c.saveD;
                data.center = [mean(data.xrange) mean(data.yrange)];
                if strcmp(c.saveMode, 'piezo')
                    data.range =  c.piezoRange;
                    data.speed =  c.piezoSpeed;
                    data.pixels = c.piezoPixels;
                else
                    data.range =  c.galvoRange;
                    data.speed =  c.galvoSpeed;
                    data.pixels = c.galvoPixels;
                end
                
                m = min(min(data.data));
                M = max(max(data.data));
                
                save(   [directory timestamp '_' c.saveMode '.mat'], 'data');
                
                fname = [directory timestamp '_' c.saveMode '.png'];
                if M-m ~= 0
                    imwrite((data.data-m)./(M-m), fname);
                else
                    imwrite((data.data-m),        fname);
                end
            case {'piezo3D'}
                data.type = c.saveMode;
                data.xrange = c.saveX;
                data.yrange = c.saveY;
                data.zrange = c.saveZ;
                data.data = c.saveD3D;
                data.center = [mean(data.xrange) mean(data.yrange)];
                
                save(   [directory timestamp '_' c.saveMode '.mat'], 'data');
                
                i = 1;
                
                for z = data.zrange
                    data2D = c.saveD3D(:,:,i);
                    
                    m = min(min(data2D));
                    M = max(max(data2D));
                    
                    fname = [directory timestamp '_' c.saveMode '_Layer_' num2str(i) '_of_' num2str(length(data.zrange)) '.png'];
                    if M-m ~= 0
                        imwrite((data2D-m)./(M-m), fname);
                    else
                        imwrite((data2D-m),        fname);
                    end
                    
                    i = i+1;
                end
            case {'spectrum', 'optscan'}
                data.type = c.saveMode;
                data.xrange = c.saveX;
                data.data = c.saveY;
                
                if  strcmp(c.saveMode, 'optscan')
%                     data.range =  c.piezoRange;
%                     data.speed =  c.piezoSpeed;
%                     data.pixels = c.piezoPixels;
                    data.before = c.saveBA(1);
                    data.after = c.saveBA(2);
                end
                
                save([directory timestamp '_' c.saveMode '.mat'], 'data');
                savePlotPng(data.xrange, data.data, [directory timestamp '_' c.saveMode '.png']);
            otherwise
                display('Nothing to save...');
        end
    end
    function open_Callback(~,~)
        if ~c.doing
            fname = open();
        end
    end
    function power_Callback(~,~)
        set(c.powerButton, 'Enable', 'off');
        
        [power, ~] = getPower();
        set(c.powerValue, 'String', power2str(power));
        
        set(c.powerButton, 'Enable', 'on');
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
                c.microXPort = 'COM5'; % USB Port that X is connected to (we view it as a serial port)
                c.microXAddr = '1';

                c.microXSerial = serial(c.microXPort);
                set(c.microXSerial, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                    'FlowControl', 'software', 'Terminator', 'CR/LF');
                fopen(c.microXSerial);
                
                
                c.microYPort = 'COM6'; % USB Port that Y is connected to (we view it as a serial port)
                c.microYAddr = '1';

                c.microYSerial = serial(c.microYPort);
                set(c.microYSerial,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
                    'FlowControl', 'software','Terminator', 'CR/LF');
                fopen(c.microYSerial);

                pause(.25);

                
                %cmd(c.microXSerial, c.microXAddr, 'PW1'); 
                cmd(c.microXSerial, c.microXAddr, 'HT1'); 
                cmd(c.microXSerial, c.microXAddr, 'SL-5');     % negative software limit x=-5
                cmd(c.microXSerial, c.microXAddr, 'BA0.003');  % change backlash compensation
                cmd(c.microXSerial, c.microXAddr, 'FF05');     % set friction compensation
                cmd(c.microXSerial, c.microXAddr, 'PW0');      % save to controller memory

                
                %cmd(c.microYSerial, c.microYAddr, 'PW1'); 
                cmd(c.microYSerial, c.microYAddr, 'HT1'); 
                cmd(c.microYSerial, c.microYAddr, 'SL-5');      % negative software limit y=-5
                cmd(c.microYSerial, c.microYAddr, 'BA0.003');   % change backlash compensation
                cmd(c.microYSerial, c.microYAddr, 'FF05');       % set friction compensation
                cmd(c.microYSerial, c.microYAddr, 'PW0');       % save to controller memory
                pause(.25);

                
                cmd(c.microXSerial, c.microXAddr, 'OR'); %Get to home state (should retain position)
                cmd(c.microYSerial, c.microYAddr, 'OR'); % Go to home state(should retain position)
                pause(.25);

                display('Done Initializing Micrometers');

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
            c.s.addCounterInputChannel( c.devSPCM,    c.chnSPCM,      'EdgeCount')
%             c.s.Channels(6)
            
            % PLE       o 1:2
            c.sp = daq.createSession(   'ni');
            c.sp.addAnalogOutputChannel(c.devPleOut,  c.chnPerotOut,  'Voltage');     % Perot Out
            c.sp.addAnalogOutputChannel(c.devPleOut,  c.chnGrateOut,  'Voltage');     % Grating Angle Out
            
            % PLE       i 1:3
            c.sp.addCounterInputChannel(c.devPleIn,   c.chnSPCMPle,   'EdgeCount')
            c.sp.Channels(3)
            c.sp.addAnalogInputChannel( c.devPleIn,   c.chnPerotIn,   'Voltage');     % Perot In
            c.sp.addAnalogInputChannel( c.devPleIn,   c.chnNormIn,    'Voltage');     % Normalization In
            
            
%             % Counter       i 1
%             c.sc.addCounterInputChannel(c.devPleIn,   c.chnSPCMPle,   'EdgeCount');

            
            % PLE digital
            c.sd = daq.createSession(   'ni');
            c.sd.addDigitalChannel(     c.devPleDigitOut, c.chnPleDigitOut,  'OutputOnly');  % Modulator (for repumping)
            c.sd.outputSingleScan(1);
    

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
        
%         axes(c.track_Axes);
%         frame = getsnapshot(c.vid);
%         imshow(frame);
        %Testing image 
        %frame = flipdim(rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png')),1);
        
    end
    function normInit()
        try
            c.norm = instrfind('Type', 'visa-gpib', 'RsrcName', 'GPIB0::5::INSTR', 'Tag', '');

            if isempty(c.norm)    % Create the VISA-GPIB object if it does not exist
                c.norm = visa('NI', 'GPIB0::5::INSTR');
            else                % otherwise use the object that was found.
                fclose(c.norm);
                c.norm = c.norm(1);
            end

            fopen(c.norm);
            flushinput(c.norm);
            flushoutput(c.norm);
            
            c.normInit = 1;
        catch err
            display(err.message);
        end
    end
    function initAll()
        % Self-explainatory
%         try
            % initPle();
            daqInit_Callback(0,0);
            
%             initNormalization(true)
            
            getState();
            set(c.upperFigure, 'Visible', 'On');
            set(c.lowerFigure, 'Visible', 'On');
            set(c.imageFigure, 'Visible', 'On');
            set(c.pleFigure, 'Visible', 'On');
            set(c.bluefbFigure,'Visible', 'On');
            set(c.counterFigure, 'Visible', 'On');
            set(c.parent, 'Visible', 'On');
            set(c.scaleFigure, 'Visible', 'On');
            
            videoInit();
            microInit_Callback(0,0);
            normInit();
            
            joyModeColor(0,0);

%             focus_Callback(0,0);
            
            getCurrent();
            c.running = 1;
            c.newtrack_on = 0;
            
%             choice = questdlg('You have restarted. Do you want to mechanically reset the micrometers? This involves returning to mechanical [0, 0].', 'Reset?', 'Yes', 'No', 'Yes');
%             
%             switch choice
%                 case 'Yes'
%                     resetMicro_Callback(0,0);
%                 case 'No'
%                     display('No reset chosen. You can reset manually in the Goto menu.');
%             end
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
%                     blink();
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
%         display('setting to: ');
%         display(c.micro);
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
        cmd(c.microXSerial, c.microXAddr,'OR'); %pause(30);
        
        disp('X Going to zero...');
        while c.running && c.microActual(1) ~= 0 % Not sure if this is the best choice; one could move away within a second of reaching zero.
            pause(1)
        end
        
        disp('X-Axis Back to Mech Zero...')
        
        %GET BACK TO chip (disabled 6/24/16 - it doesnt' make sense to go
        %to an arbitrary posiiton)
%         cmd(c.microXSerial,c.microXAddr,'RS'); pause(5);
%         cmd(c.microXSerial, c.microXAddr,'PW1'); pause(0.5);
%         cmd(c.microXSerial, c.microXAddr,'HT1'); pause(0.5);
%         cmd(c.microXSerial, c.microXAddr,'PW0'); pause(5);
%         cmd(c.microXSerial, c.microXAddr,'OR'); pause(0.5);
%         cmd(c.microXSerial, c.microXAddr, ['PR' num2str(22)]); pause(30);
%         
%         disp('Finished Reset Sequence')
%         disp('X-Axis should be at 22 mm \n')
%         disp(['X-Axis at:' num2str(c.microActual(1))])
%         
%         if(c.microActual(1)~=22000)
%             disp('There was an ERROR!!!')
%         end
        
    end
    function rsty_Callback(~,~)
        %SEND THE MICROMTR BACK TO MECH-ZERO
        disp('started Y-Axis reset sequence...')
        cmd(c.microYSerial,c.microYAddr,'RS'); pause(.5);
        cmd(c.microYSerial, c.microYAddr,'PW1'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'HT4'); pause(0.5);
        cmd(c.microYSerial, c.microYAddr,'PW0'); pause(.5);
        cmd(c.microYSerial, c.microYAddr,'OR'); %pause(30);
        
        disp('Y Going to zero...');
        while c.running && c.microActual(2) ~= 0 % Not sure if this is the best choice; one could move away within a second of reaching zero.
            pause(1)
        end
        
        disp('Y-Axis Back to Mech Zero...')
        
        %GET BACK TO chip (disabled 6/24/16 - it doesnt' make sense to go
        %to an arbitrary posiiton)
%         cmd(c.microYSerial, c.microXAddr,'RS'); pause(5);
%         cmd(c.microYSerial, c.microYAddr,'PW1'); pause(0.5);
%         cmd(c.microYSerial, c.microYAddr,'HT1'); pause(0.5);
%         cmd(c.microYSerial, c.microYAddr,'PW0'); pause(5);
%         cmd(c.microYSerial, c.microYAddr,'OR'); pause(0.5);
%         cmd(c.microYSerial, c.microYAddr, ['PR' num2str(22)]); pause(30);
%         
%         disp('Finished Reset Sequence')
%         disp('Y-Axis should be at 22 mm \n')
%         disp(['Y-Axis at:' num2str(c.microActual(2))])
%         
%         if(c.microActual(2)~=22000)
%             disp('There was an ERROR!!!')
%         end
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
        set(c.piezoXX, 'String', piezoVtoUM(c.piezo(1)));
        set(c.piezoYY, 'String', piezoVtoUM(c.piezo(2)));
        set(c.piezoZZ, 'String', piezoVtoUM(c.piezo(3)));
    end
    % --- GOTO/SMOOTH OUT -------------------------------------------------
    function um = piezoVtoUM(v)
        um = 5*v - 25;
    end
    function v = piezoUMtoV(um)
        v = (um + 25)/5;
    end
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
                set(c.gotoPX, 'String', piezoVtoUM(c.piezo(1)));
                set(c.gotoPY, 'String', piezoVtoUM(c.piezo(2)));
                set(c.gotoPZ, 'String', piezoVtoUM(c.piezo(3)));
            case c.gotoGTarget
                set(c.gotoGX, 'String', c.galvo(1)*1000);
                set(c.gotoGY, 'String', c.galvo(2)*1000);
        end
    end
    function gotoPiezo_Callback(~, ~)
        % Sends the piezos to the location currently stored in the fields.
        piezoOutSmooth([piezoUMtoV(str2double(get(c.gotoPX, 'String')))...
                        piezoUMtoV(str2double(get(c.gotoPY, 'String')))...
                        piezoUMtoV(str2double(get(c.gotoPZ, 'String')))]);
    end
    function gotoGalvo_Callback(~, ~)
        % Sends the galvos to the location currently stored in the fields.
        galvoOutSmooth([str2double(get(c.gotoGX, 'String'))/1000 str2double(get(c.gotoGY, 'String'))/1000]);
    end
    function daqOutSmooth(to)
        % Smoothly sends all the DAQ devices to the location defined by 'to'.
        if c.outputEnabled && c.daqInitiated && ~c.counting
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
        if c.outputEnabled && c.daqInitiated && ~c.counting
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
    function gotoMicro(pos)
        if ~c.globalStop
            c.micro = pos;
            setPos();

            j = 0;

            while norm(c.microActual - c.micro) > .2 && j < 600 && ~c.globalStop
                pause(.1);
                getPos();
                renderUpper();
                j = j + 1;
            end
        end
    end
    % --- RESETS ----------------------------------------------------------
    function resetMicro_Callback(~, ~)
         % Old way - does not actually reset.
%         c.micro = [0 0];
%         setPos();

        % New way - adapted from the x and y reset functions.
        disp('Started micrometer reset sequence...')
        
        cmd(c.microXSerial, c.microXAddr,'RS');
        cmd(c.microYSerial, c.microYAddr,'RS');  pause(.5);
        
        cmd(c.microXSerial, c.microXAddr,'PW1');
        cmd(c.microYSerial, c.microYAddr,'PW1'); pause(0.1);
        
        cmd(c.microXSerial, c.microXAddr,'HT4');
        cmd(c.microYSerial, c.microYAddr,'HT4'); pause(0.1);
        
        cmd(c.microXSerial, c.microXAddr,'PW0');
        cmd(c.microYSerial, c.microYAddr,'PW0'); pause(.5);
        
        cmd(c.microXSerial, c.microXAddr,'OR');
        cmd(c.microYSerial, c.microYAddr,'OR'); %pause(30);
        
        disp('Sequence finished; wait for return to zero...')
        
%         while c.running && c.microActual(1) ~= 0 && c.microActual(2) ~= 0 % Not sure if this is the best choice; one could move away within a second of reaching zero.
%             pause(1)
%         end
        
%         disp('...Axes are back to mechanical zero.')
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
    function focus_Callback(~, ~)   % Needs to be improved!
        display('    begin focusing');
        
        c.focusing = 1;
%         prevContrast = 0;
        direction = 1;
        
        prev10 = [0 0 0 0 0 0 0 0 0 0];
        
        n = 1;
        
        while c.focusing && ~c.globalStop
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
        
        c.globalStop = false;
        
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
        r = str2double(get(c.piezoZR, 'String'))/5;
        s = str2double(get(c.piezoZP, 'String'))/str2double(get(c.piezoZS, 'String'));
        p = str2double(get(c.piezoZP, 'String'));
        
        optimizeAxis(3, r, p, s);
    end
    function optX_Callback(~, ~)
        r = str2double(get(c.piezoXYR, 'String'))/5;
        s = str2double(get(c.piezoXYP, 'String'))/str2double(get(c.piezoXYS, 'String'));
        p = str2double(get(c.piezoXYP, 'String'));
        
        optimizeAxis(1, r, p, s);
    end
    function optY_Callback(~, ~)
        r = str2double(get(c.piezoXYR, 'String'))/5;
        s = str2double(get(c.piezoXYP, 'String'))/str2double(get(c.piezoXYS, 'String'));
        p = str2double(get(c.piezoXYP, 'String'));
        
        optimizeAxis(2, r, p, s);
    end
    function optXY_Callback(~, ~)
        optX_Callback(0, 0)
        optY_Callback(0, 0)
    end
    function optAll_Callback(~, ~)
%         piezoOptimizeAxis(1);
%         piezoOptimizeAxis(2);
%         piezoOptimizeAxis(3);
        optXY_Callback(0, 0);
        optZ_Callback(0, 0);
    end
    function optGalvoX_Callback(~, ~)
        r = str2double(get(c.galvoXYR, 'String'))/1000;
        s = str2double(get(c.galvoXYP, 'String'))/str2double(get(c.galvoXYS, 'String'));
        p = str2double(get(c.galvoXYP, 'String'));
        
        optimizeAxis(4, r, p, s);
    end
    function optGalvoY_Callback(~, ~)
        r = str2double(get(c.galvoXYR, 'String'))/1000;
        s = str2double(get(c.galvoXYP, 'String'))/str2double(get(c.galvoXYS, 'String'));
        p = str2double(get(c.galvoXYP, 'String'));
        
        optimizeAxis(5, r, p, s);
    end
    function optGalvo_Callback(~, ~)
        optGalvoX_Callback(0, 0);
        optGalvoY_Callback(0, 0);
    end
    function final = optimizeAxis(axis, range, pixels, rate)     % 1,2,3,4,5 = piezo x,y,z, galvo x,y... Range in Volts.
        if ~c.doing
            c.doing = true;
            
            center = -1;

            prevRate = c.s.Rate;
            c.s.Rate = rate;

            if axis >= 1 && axis <= 3
                center = c.piezo(axis);
            elseif axis >= 4 && axis <= 5
                center = c.galvo(axis-3);
            else
                display('    Axis for optimization not understood');
            end

            if center ~= -1
                up = -1;

                if axis >= 1 && axis <= 3
                    up = linspace(center-range/2, center+range/2, pixels+1);
                    if up(end) > 10
                        up = linspace(center-range/2, 10, pixels+1);
                    end

                    if up(1) < 0
                        up = linspace(0, center+range/2, pixels+1);

                        if up(end) > 10
                            up = linspace(0, 10, pixels+1);
                        end
                    end
                elseif axis == 4
                    up = linspace(center+range/2, center-range/2, pixels+1);
                elseif axis == 5
                    up = linspace(center-range/2, center+range/2, pixels+1);
                end

                prev = [c.piezo c.galvo];

                prev2 = prev;

                if axis >= 1 && axis <= 3
                    prev2(axis) = 0;
                elseif axis == 4
                    prev2(axis) = .2;
                elseif axis == 5
                    prev2(axis) = -.2;
                end
                daqOutSmooth(prev2);

                prev2(axis) = up(1);
                daqOutSmooth(prev2);

                switch axis
                    case 1
                        daqOutQueueClever({up, NaN, NaN, NaN, NaN, NaN, NaN});
                    case 2
                        daqOutQueueClever({NaN, up, NaN, NaN, NaN, NaN, NaN});
                    case 3
                        daqOutQueueClever({NaN, NaN, up, NaN, NaN, NaN, NaN});
                    case 4
                        daqOutQueueClever({NaN, NaN, NaN, up, NaN, NaN, NaN});
                    case 5
                        daqOutQueueClever({NaN, NaN, NaN, NaN, up, NaN, NaN});
                end

                [out, times] = c.s.startForeground();
                out = out(:,1);

                data = diff(double(out))./diff(double(times));
                final = data;


                [fz, ~] = myMeanAdvanced(data, up(1:pixels), 0);

%                 display('      plot');

%                 if axis >= 1 && axis <= 3
%                     up = piezoVtoUM(up);
%                 end

%                 mx = min(up(1:pixels));
%                 Mx = max(up(1:pixels));
% 
%                 my = min(data);
%                 My = max(data);
%                 dy = My - my + 1;
                
                c.saveMode = 'optscan';
                c.saveX = piezoVtoUM(up(1:pixels));
                c.saveY = data;
                c.saveBA = [ piezoVtoUM(center),  piezoVtoUM(fz)];

                
%                 plot(c.lowerAxes, up(1:pixels), data, 'b', [fz, fz], [my - dy/10, My + dy/10], 'r', [center, center], [my - dy/10, My + dy/10], 'r:');
%                 xlim(c.lowerAxes, [mx Mx]);
%                 ylim(c.lowerAxes, [my - dy/10, My + dy/10]);
                
                switch axis
                    case 1
                        c.saveAxis = 'Piezo X';
                    case 2
                        c.saveAxis = 'Piezo Y';
                    case 3
                        c.saveAxis = 'Piezo Z';
                    case 4
                        c.saveAxis = 'Galvo X';
                    case 5
                        c.saveAxis = 'Galvo Y';
                end
                
                renderData(1)
                
%                 title(c.lowerAxes, name);

    %             m = min(min(data)); M = max(max(data));
    % 
    %             if m ~= M
    %                 data = (data - m)/(M - m);
    %                 data = data.*(data > .5);
    % 
    %                 total = sum(sum(data));
    %                 fz = sum((data).*(up(1:pixels)'))/total;
    % 
    %                 if axis >= 1 && axis <= 3
    %                     if (fz > 10 || fz < 0 || isnan(fz))
    %                         fz = center;
    %                         display(['    ' num2str(axis) '-axis optimization failed']);
    %                     end
    %                 elseif axis >= 4 && axis <= 5
    %                     if isnan(fz)
    %                         fz = center;
    %                         display(['    ' num2str(axis) '-axis optimization failed']);
    %                     end
    %                 end
    %             end

                if axis >= 1 && axis <= 3
                    prev2(axis) = 0;
                elseif axis == 4
                    prev2(axis) = .2;
                elseif axis == 5
                    prev2(axis) = -.2;
                end

                daqOutSmooth(prev2);

                prev2(axis) = fz;
                daqOutSmooth(prev2);

                c.s.Rate = prevRate;
            end
            
            globalSave(c.directoryBackground)
            
            c.doing = false;
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
        % Note that this will yield an error if data is all zero. This is purposeful.
        % New Method
        dim = size(data);
        
        data = data ~= 0;
    
        data = imdilate(data, strel('diamond', 1));

        [labels, ~] = bwlabel(data, 8);
        measurements = regionprops(labels, 'Area', 'Centroid');
        areas = [measurements.Area];
        [~, indexes] = sort(areas, 'descend');

        centroid = measurements(indexes(1)).Centroid;
        
        if dim(2) == 1
            x = linInterp(1, X(1), dim(1), X(dim(1)), max(centroid));
            y = 0;
        else
            x = linInterp(1, X(1), dim(2), X(dim(2)), centroid(1));
            y = linInterp(1, Y(1), dim(1), Y(dim(1)), centroid(2));
        end
    
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

%             try
%                 [mx, my] = myMean(data.*(data == 1), X, Y);
% 
%     %             data = data*
% 
%                 dim = size(data);
%     %             factor = zeros(dim(1));
% 
%                 for x1 = 1:dim(1)
%                     for y1 = 1:dim(1)
%                         data(y1, x1) = data(y1, x1)/(1 + (X(x1) - mx)^2 + (Y(y1) - my)^2);
%                     end
%                 end
%                 
%                 m = min(min(data)); M = max(max(data));
% 
%                 if m ~= M
%                     data = (data - m)/(M - m);
%                 end
%             
%             catch err
%                 display(['Attenuation failed: ' err.message]);
%             end

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
                dim = size(data);
                if dim(2) == 1
                    while std(X0) > abs(X(1) - X(2))
                        D = ((X0 - mean(X0)).^2);

                        [~, idx] = max(D);

                        X0(idx) = [];

%                         display('      outlier removed');
                    end
                else
                    while std(X0) > abs(X(1) - X(2)) || std(Y0) > abs(Y(1) - Y(2))
                        D = ((X0 - mean(X0)).^2) + ((Y0 - mean(Y0)).^2);

                        [~, idx] = max(D);

                        X0(idx) = [];
                        Y0(idx) = [];

                        display('      outlier removed');
                    end
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

    % NORMALIZATION =======================================================
    function initNormalization(useAnalog) % Unused
        if useAnalog && c.normInit == 0
            % Norm Analog
            c.sn = daq.createSession(   'ni');
            c.sn.addAnalogInputChannel( c.devNorm,   c.chnNorm,    'Voltage');
            
            c.normInit = 1;
        end
    end
    function [power, dpower] = getPower()
        if  c.normInit == 1
%             c.sn.Rate = 10000;
%             c.sn.DurationInSeconds = 1; % 10000 samples
% 
%             data = startForeground(c.sn);
            len = 30;
            data = zeros(1,len);
            
            for jj = 1:len
                fprintf(c.norm, 'R_B?');
                pause(0.005);
                data(jj) = str2double(fscanf(c.norm));
                pause(0.005);
            end

            power =     mean(data);
            dpower =    std(data);
        end
    end
    function str = power2str(power)
        [char, magn] = getMagn(power);
        
        str = [num2str(power/magn) ' ' char 'W'];
    end
    function [char, magn] = getMagn(num)
        chars = 'TZEPTGMkm unpfazy';
        
        m = floor(log10(num)/3);
        
        char = chars(9-m);
        if char == ' '
            char = '';
        end
        
        magn = 1000^m;
    end

    % DATA FIGURE =========================================================
    function renderData(normalize)
        cla(c.lowerAxes);
        cla(c.lowerAxes3D);
        
        switch c.saveMode
            case {'piezo', 'piezo3D', 'galvo'} % Need to fix the image flipping!
                switch c.saveMode
                    case 'galvo'
                        strings = get(c.galvoC, 'string');
                        curval = get(c.galvoC, 'value');
                    case {'piezo', 'piezo3D'}
                        strings = get(c.piezoC, 'string');
                        curval = get(c.piezoC, 'value');
                end
                
                switch c.saveMode
                    case 'piezo3D'
                        m = min(min(min(c.saveD3D(c.saveD3D ~= 0 & c.saveD3D ~= 1))));
                        M = max(max(max(c.saveD3D)));
                    otherwise
%                         c.saveD(c.saveD ~= 0)
                        m = min(min(c.saveD(c.saveD ~= 0 & c.saveD ~= 1)));
                        M = max(max(c.saveD));
                end
                
                if isempty(m)
                    m = 0;
                end

                if m <= 0
                    str = '0';
                else
                    magn = floor(log10(m));
                    str = [num2str(m/(10^magn), '%1.1f') 'e' num2str(magn)];
                end

                if M <= 0
                    STR = '0';
                else
                    magn = floor(log10(M));
                    STR = [num2str(M/(10^magn), '%1.1f') 'e' num2str(magn)];
                end
                
                set(c.scaleDataMinEdit, 'String', str);
                set(c.scaleDataMaxEdit, 'String', STR);
        
                if get(c.scaleNormAuto, 'Value') && normalize
                	scaleNormalize_Callback(0,0);
                end
                
                cscale = [c.scaleMinSlid.Value, max(c.scaleMinSlid.Value, c.scaleMaxSlid.Value) + .01];

                if c.piezo3DEnabled
                    if strcmp(lower(get(c.lowerAxes3D, 'Visible')),  'on')
                        [x, y, z] = meshgrid(c.saveX,c.saveY,c.saveZ);

                        xslice=[]; 
                        yslice=[];
                        zslice=c.saveZ;

                        h = slice(c.lowerAxes3D, x, y, z, c.saveD3D, xslice, yslice, zslice);
                        set(h, 'FaceColor','interp');
                        %set(h,'FaceAlpha','0.5');
                        set(h, 'EdgeColor','none');

                        title(c.lowerAxes3D, 'Piezo Scan - 3D');

                        set(c.lowerAxes3D, 'Ydir', 'reverse');
                        xlim(c.lowerAxes3D, [c.saveX(1)      c.saveX(end)]);
                        ylim(c.lowerAxes3D, [c.saveY(1)      c.saveY(end)]);
                        caxis(c.lowerAxes3D, cscale);

                        colormap(c.lowerAxes3D, strings{curval});
%                     view([-68 12]);
                    else
                        piezoPlot2D();
                    end
                else

                    surf(c.lowerAxes, c.saveX, c.saveY, c.saveD, 'EdgeColor', 'none'); %, 'HitTest', 'off');   % Display the graph on the backscan
                    view(c.lowerAxes, 2);
                    colormap(c.lowerAxes, strings{curval});
%                         set(c.lowerAxes, 'Xdir', 'reverse', 'Ydir', 'reverse');
                    set(c.lowerAxes, 'Ydir', 'reverse');
                    xlim(c.lowerAxes, [c.saveX(1)      c.saveX(end)]);
                    ylim(c.lowerAxes, [c.saveY(1)      c.saveY(end)]);
                    caxis(c.lowerAxes, cscale); 
                    
                    switch c.saveMode
                        case 'piezo'
                            title(c.lowerAxes3D, 'Piezo Scan');
                        case 'galvo'
                            title(c.lowerAxes3D, 'Galvo Scan');
                    end
                end
            case {'spectrum', 'optscan'}
                data.type = c.saveMode;
                data.xrange = c.saveX;
                data.data = c.saveY;
                
                m = min(min(c.saveY(c.saveY ~= 0 & c.saveY ~= 1)));
                M = max(max(c.saveY));
                
                if isempty(m)
                    m = 0;
                end

                if isempty(m)
                    str = '0';
                else
                    magn = floor(log10(m));
                    str = [num2str(m/(10^magn), '%1.1f') 'e' num2str(magn)];
                end

                if M <= 0
                    STR = '0';
                else
                    magn = floor(log10(M));
                    STR = [num2str(M/(10^magn), '%1.1f') 'e' num2str(magn)];
                end
                
                set(c.scaleDataMinEdit, 'String', str);
                set(c.scaleDataMaxEdit, 'String', STR);
        
                if get(c.scaleNormAuto, 'Value') && normalize
                	scaleNormalize_Callback(0,0);
                end
                
                cscale = [c.scaleMinSlid.Value, max(c.scaleMinSlid.Value, c.scaleMaxSlid.Value) + .01];
                
                switch c.saveMode
                    case 'optscan'
                        plot(c.lowerAxes, c.saveX, c.saveY, 'b', [c.saveBA(2), c.saveBA(2)], cscale, 'r', [c.saveBA(1), c.saveBA(1)], cscale, 'r:');
                    case 'spectrum'
                        plot(c.lowerAxes, c.saveX, c.saveY, 'b');
                end
                
                mx = min(c.saveX);
                Mx = max(c.saveX);

                my = min(c.saveY);
                My = max(c.saveY);
                dy = My - my + 1;

                xlim(c.lowerAxes, [mx Mx]);
%                 ylim(c.lowerAxes, [my - dy/10, My + dy/10]);
                ylim(c.lowerAxes, cscale);
                
                switch c.saveMode
                    case 'spectrum'
                        title(c.lowerAxes, 'Spectrum');
                    case 'optscan'
                        title(c.lowerAxes, ['Optimize - ' c.saveAxis]);
                end
            otherwise
                display(['Nothing to plot... ' c.saveMode]);
        end
    end

    % PIEZOSCAN ===========================================================
    function [final, X, Y] = piezoScanXYFull(rangeUM, upspeedUM, pixels)
        if ~c.doing
            % Method 1
    %         range = .8;
    %         pixels = 40;

%             c.globalStop = false;

            if c.globalStop
                display('Stopped');
                c.globalStop = false;
                return;
            end
            
            c.doing = true;

            range = rangeUM/5;
            upspeed = upspeedUM/5;

            c.s.Rate = pixels*(upspeed/range);

            steps =      round(pixels);
            stepsFast =  round(pixels/8);

            % New method
            up =    linspace(-range/2 + c.piezo(1),  range/2 + c.piezo(1), steps);
            down =  linspace( range/2 + c.piezo(1), -range/2 + c.piezo(1), stepsFast);
            up2 =   linspace(-range/2 + c.piezo(2),  range/2 + c.piezo(2), steps);

            if sum(up < 0) ~= 0 || sum(down < 0) ~= 0 || sum(up2 < 0) ~= 0 || sum(up > 10) ~= 0 || sum(down > 10) ~= 0 || sum(up2 > 10) ~= 0
                display('Error: Piezos might go out of range!');

                final = zeros(steps);
            else
                X = up;
                Y = up2;

                final = zeros(steps);
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

                for y = up2
                    daqOutQueueClever({up', y*ones(length(up2),1), NaN, NaN, NaN, NaN, NaN});
                    [out, times] = c.s.startForeground();
                    out = out(:,1);

                    if y ~= up2(end)
                        daqOutQueueClever({down', linspace(y, y + up2(2) - up2(1), length(down))', NaN, NaN, NaN, NaN, NaN});
                        c.s.startForeground();
                    end

                    final(i,:) = [diff(out(:,1)') mean(diff(times'))]./[diff(times') mean(diff(times'))];

                    if i >= 1   % Equal needs testing
                        strings = get(c.piezoC, 'string');
                        curval = get(c.piezoC, 'value');
                        
                        c.saveX = piezoVtoUM(up);
                        c.saveY = piezoVtoUM(up2);

                        if c.piezo3DEnabled %&& strcmp(get(c.lowerAxes3D, 'Visible'),  'Off')
                            j = get(c.piezo3DMenu, 'value');
        
                            c.saveD3D(:,:,c.level3D) = final;
                            c.saveD = c.saveD3D(:,:,j);
                            c.saveMode = 'piezo3D';
                
%                             [x, y, z] = meshgrid(X,Y,Z);
% 
%                             xslice=[]; 
%                             yslice=[];
%                             zslice=Z;
% 
%                             h = slice(c.lowerAxes3D, x, y, z, c.saveD3D, xslice, yslice, zslice);
%                             set(h, 'FaceColor','interp');
%                             %set(h,'FaceAlpha','0.5');
%                             set(h, 'EdgeColor','none');
%                             
%                             title(c.lowerAxes3D, 'Piezo Scan 3D');
%                             
%                             set(c.lowerAxes3D, 'Ydir', 'reverse');
%                             xlim(c.lowerAxes3D, [up(1)       up(end)]);
%                             ylim(c.lowerAxes3D, [up2(1)      up2(end)]);
%                             
%                             colormap(c.lowerAxes3D, strings{curval});
%                             view([-68 12]);
%                             
%                             piezoPlot2D()
                        else
                            c.saveD = final;
                            c.saveZ = c.piezo(3);
                            c.saveMode = 'piezo';
                            
%                             surf(c.lowerAxes, up(1:pixels), up2((1):(i)), final((1):(i),:), 'EdgeColor', 'none'); %, 'HitTest', 'off');   % Display the graph on the backscan
%                             view(c.lowerAxes, 2);
%                             colormap(c.lowerAxes, strings{curval});
%     %                         set(c.lowerAxes, 'Xdir', 'reverse', 'Ydir', 'reverse');
%                             set(c.lowerAxes, 'Ydir', 'reverse');
%                             xlim(c.lowerAxes, [up(1)       up(end)]);
%                             ylim(c.lowerAxes, [up2(1)      up2(end)]);
                        end
                    end
                
                    renderData(1)

                    i = i + 1;

                    if c.globalStop && ~c.piezo3DEnabled
                        display('Stopped');
                        c.globalStop = false;
                        break;
                    end

                    c.s.wait();
                end
            end

            c.doing = false;
        end
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
    function piezoEnable3D(is3D)
        c.piezo3DEnabled = is3D;
        c.level3D = 1;
        
        if c.piezo3DEnabled
%             piezoSwitch3D_Callback(0,0)
            set(c.piezoSwitchTo3DButton,    'Visible',  'On');
            set(c.piezo3DMenu,    'Visible',  'On');
            set(c.piezo3DPlus,    'Visible',  'On');
            set(c.piezo3DMinus,   'Visible',  'On');
            piezoFillMenu(c.saveZ)
        else
            set(c.lowerAxes3D,              'Visible',  'Off');
            set(c.lowerAxes,                'Visible',  'On');
            set(c.globalSaveButton,         'String',   'Save');
            set(c.piezoSwitchTo3DButton,    'Visible',  'Off');
            set(c.piezo3DMenu,    'Visible',  'Off');
            set(c.piezo3DPlus,    'Visible',  'Off');
            set(c.piezo3DMinus,   'Visible',  'Off');
        end
    end
    function piezoSwitch3D_Callback(~,~)
        disp('Switching between 2D and 3D');
        if strcmp(lower(get(c.lowerAxes3D, 'Visible')),  'off') && c.piezo3DEnabled
            c.saveMode = 'piezo3D';
            set(c.lowerAxes,                'Visible',  'Off');
            set(c.lowerAxes3D,              'Visible',  'On');
            set(c.globalSaveButton,         'String',   'Save 3D');
            set(c.piezoSwitchTo3DButton,    'String',  'View 2D');
            set(c.piezo3DMenu,    'Visible',  'Off');
            set(c.piezo3DPlus,    'Visible',  'Off');
            set(c.piezo3DMinus,   'Visible',  'Off');
        else
            c.saveMode = 'piezo';
            set(c.lowerAxes3D,              'Visible',  'Off');
            set(c.lowerAxes,                'Visible',  'On');
            set(c.globalSaveButton,         'String',   'Save');
            set(c.piezoSwitchTo3DButton,    'String',  'View 3D');
            if c.piezo3DEnabled
                set(c.piezo3DMenu,    'Visible',  'On');
                set(c.piezo3DPlus,    'Visible',  'On');
                set(c.piezo3DMinus,   'Visible',  'On');
            end
        end
        
        renderData(1);
    end
    function piezoChange3DMenu_Callback(~,~)
        renderData(1);
    end
    function piezoFillMenu(zlist)
        array = cell(size(zlist));
        
        i = 1;
        
        for z = zlist
            array{i} = [num2str(z) ' um'];
            i = i + 1;
        end
        
        set(c.piezo3DMenu, 'String', array);
    end
    function piezoPlot2D()
        strings = get(c.piezoC, 'string');
        curval = get(c.piezoC, 'value');

        layers = get(c.piezo3DMenu, 'string');
        i = get(c.piezo3DMenu, 'value');
        
        surf(c.lowerAxes, c.saveX, c.saveY, c.saveD3D(:,:,i), 'EdgeColor', 'none'); %, 'HitTest', 'off');   % Display the graph on the backscan
        view(c.lowerAxes, 2);
        colormap(c.lowerAxes, strings{curval});
%         set(c.lowerAxes, 'Xdir', 'reverse', 'Ydir', 'reverse');
        set(c.lowerAxes, 'Ydir', 'reverse');
        xlim(c.lowerAxes, [c.saveX(1)       c.saveX(end)]);
        ylim(c.lowerAxes, [c.saveY(1)      c.saveY(end)]);
        caxis(c.lowerAxes, [c.scaleMinSlid.Value, c.scaleMaxSlid.Value + 1e-9]);
        
        title(c.lowerAxes, ['Piezo Scan - Layer ' num2str(i) ': ' layers{i}]);
    end
    function piezoScan_Callback(~, ~)
        if ~c.globalStop
            display('Beginning 3D Confocal');
            prev = c.piezo;
            ledSet(1);

            start = piezoUMtoV(str2double(get(c.piezoZStart,   'String')));
            stop =  piezoUMtoV(str2double(get(c.piezoZStop,    'String')));
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

%             piezoEnable3D

            if step == 1
                piezoEnable3D(0);
                
%                 try
                    final(:,:,1) = piezoScanXYFull(c.piezoRange, c.piezoSpeed, c.piezoPixels);
%                 catch err
%                     display(err.message)
%                 end
            else
                Z = linspace(start, stop, step);
                c.saveZ = piezoVtoUM(Z);
                piezoEnable3D(1);
                
                final = zeros(c.piezoPixels, c.piezoPixels, step);
                c.saveD3D = final;

                i = 1;
                for z = Z;
                    if ~c.globalStop
                        c.level3D = i;
    %                     display(['  Z = ' num2str(z)]);
                        piezoOutSmooth([prev(1) prev(2) z]);
                        [final(:,:,i), X, Y] = piezoScanXYFull(c.piezoRange, c.piezoSpeed, c.piezoPixels);
                        i = i + 1;
                    else
                        break;
                    end
                end

                c.saveMode = 'piezo3D';
                c.saveD3D = final;
                c.saveX = piezoVtoUM(X);
                c.saveY = piezoVtoUM(Y);

                % 3D GRAPH FINAL HERE!
                % PLOT(final, X, Y, Z) (X Y Z are in volts)

%                 figure;
                
%                 [x, y, z] = meshgrid(X,Y,Z);
%                 
%                 xslice=[]; 
%                 yslice=[];
%                 zslice=Z;
% 
%                 h = slice(x, y, z, final, xslice, yslice, zslice);
%                 set(h,'FaceColor','interp');
%                 %set(h,'FaceAlpha','0.5');
%                 set(h,'EdgeColor','none');
% 
%                 strings = get(c.piezoC, 'string');
%                 curval = get(c.piezoC, 'value');
%                 colormap(c.lowerAxes, strings{curval});
%                 view([-68 12]);
            end
            
            globalSave(c.directoryBackground)
            
            if c.globalStop
                display('Stopped');
                c.globalStop = false;
            end

%             save('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\piezoScan.mat', 'final');

            ledSet(0);
            piezoOutSmooth(prev);
        end
    end

    % GALVOSCAN ===========================================================
    function galvoScan_Callback(~, ~)
        final = galvoScan(true);
        
        save('scan.mat', 'final');
    end
    function [final] = galvoScan(useUI)    
        [final, ~, ~] = galvoScanFull(useUI, c.galvoRange, c.galvoSpeed, c.galvoPixels);
    end
    function [final, X, Y] = galvoScanFull(useUI, range, upspeed, pixels)
        c.globalStop = false;
        
        if ~c.doing
            
            if c.globalStop
                display('Stopped');
                c.globalStop = false;
                return;
            end
            
            c.doing = true;
            
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
                display('Error: Galvo scanrange too large! Reducing to maximum.');
                range = maxGalvoRange/mvConv;

                final = zeros(steps);
            end

            up =    linspace( (mvConv*range/2) + c.galvo(1), -(mvConv*range/2) + c.galvo(1), steps);
            down =  linspace(-(mvConv*range/2) + c.galvo(1),  (mvConv*range/2) + c.galvo(1), stepsFast);
            up2 =   linspace( (mvConv*range/2) + c.galvo(2), -(mvConv*range/2) + c.galvo(2), steps);
            X = up;
            Y = up2;

            final = zeros(steps);
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
                    title(c.lowerAxes, ['Galvo Scan (' num2str(up(end)/mvConv) ':' num2str(up(1)/mvConv) ',' num2str(up2(end)/mvConv) ':' num2str(up2(1)/mvConv) ')']);
    %                 zlim(c.lowerAxes, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
    
                    c.saveD = final;
                    c.saveX = up;
                    c.saveY = up2;
                    c.saveMode = 'galvo';
                end

                i = i + 1;
            
                if c.globalStop
                    display('Stopped');
                    c.globalStop = false;
                    break;
                end

                c.s.wait();
            end
            
            %c.galvo = [up(1) yCopy];
%             c.galvo = [prev(end,4) prev(end,5)];

%             queueOutputData(c.s, [piezoRowsFast	linspace(mvConv*range/2, 0, stepsFast)'     linspace(yCopy, 0, stepsFast)']);
%             c.s.startForeground();    % Go back to start from finishing point

%             resetGalvo_Callback(0, 0);
            galvoOutSmooth([.2 .2]);
            galvoOutSmooth(prev);

%             c.galvo = [0 0];
            getGalvo();
            
            globalSave(c.directoryBackground)
            
            c.doing = false;
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
        if ~c.doing
            c.doing = true;
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
    end
    function spectrum = waitForSpectrum(filename, t)
%         file = '';
        spectrum = -1;
        
        i = 0;
        
        disp(c.running)
        disp(i < 120)
        disp(sum(spectrum == -1) == 1)
        disp(~c.globalStop)
        disp(~c.autoSkipping)
        
        while c.running && i < 120 && sum(spectrum == -1) == 1 && ~c.globalStop && ~c.autoSkipping
            try
                disp(['    waiting ' num2str(i)])
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
            k = waitforbuttonpress;
        end
        set(c.spectrumButton, 'Enable', 'on');
        
        c.doing = false;
    end
    function takeSpectrum_Callback(~,~)
        image = waitForSpectrum(0, sendSpectrumTrigger());
        
        if image ~= -1
            plot(c.lowerAxes, 1:512, image)
            set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
            xlim(c.lowerAxes, [1 512]);
            ylim(c.lowerAxes, [min(image) max(image)]);
            
            c.saveX = 1:512;
            c.saveY = image;
            c.saveMode = 'spectrum';
            
            globalSave(c.directoryBackground)
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
    function [white, black] = loadWhitelist()
        % Loads the file pointed at by the path in the Automation Task settings and returns whitelist
        % and blacklist cell arrays populated by lists of the form [dx, dy, x, y]. e.g. the list
        % [NaN, NaN, 1, 1] would mean Set 1 1. The NaNs denote that those values are not specified.
        % As another example, [1, NaN, NaN, NaN] would mean device or column 1, depending upon one's
        % choice of how the devices are arranged (i.e. in rows or columns)
        
%         path = 'C:\Users\phys\Desktop\whitelist.txt'
        path = get(c.autoTaskList, 'String');
        
        if exist(path) ~= 0     % If the whitelist path exists
            switch path(end-3:end)
                case '.txt'
                    file = fopen(path);
                    array = textscan(file, '%s', 'Delimiter', '\n');
                case {'.xls', 'xlsx'}
                    display('Excel whitelist files currently disabled');
%                     array = xlsread(path, 'A:A');
            end
            
            white = cell(1);    w = 1;
            black = cell(1);    b = 1;
            
            isBlack = false;    % Variable used to determine whether a line is part of the white or black list.
            
            for x = 1:max(size(array{1}))   % Scan through the lines in the file
%                 array{1}{x}
%                 array{1}{x}(1)
                if ~isempty(array{1}{x})    % If the line isn't empty:
                    switch array{1}{x}(1)
                        case {'#', '%', '\', '/', '!'}  % If line is commented out
                            % Nothing.
                        case {'w', 'W'}                 % Interprets subsequent lines as part of the whitelist
                            isBlack = false;
                        case {'b', 'B'}                 % Interprets subsequent lines as part of the blacklist
                            isBlack = true;
                        otherwise                       % Interpret line
    %                         array{1}{x}
                            list = interpretWhiteString([array{1}{x}, ' ']);    % Returns line in the form: [dx, dy, x, y]

                            if length(list) ~= 1    % If the list is nonempty (i.e. if the line made sense)
                                if isBlack          % Add line to the blacklist if it should be.
                                    black{b,1} = list; b = b + 1;
                                else
                                    white{w,1} = list;
                                    w = w + 1;
                                end
                            end
                    end
                end
            end
        else 
            white = {0};
            black = {0};
            return;
        end
        
        if w == 1   % If nothing was added...
            white = {0};
        end
        if b == 1
            black = {0};
        end
    end
    function list = interpretWhiteString(str)
        list = [NaN, NaN, NaN, NaN];

        ii = 1;
        
%         str
        
        while ii <= length(str)
%             list
            switch str(ii)
                case {'x'}
                    [list(1), ii] = getNum(str, list(1), ii);
                case {'y'}
                    [list(2), ii] = getNum(str, list(2), ii);
                case {'d', 'c', 'r', 'D', 'C', 'R'}
                    if (get(c.autoTaskRow, 'Value') == 1)
                        if str(ii) == 'd' || str(ii) == 'D'
                            [list(1), ii] = getNum(str, list(1), ii);
                        elseif str(ii) == 'r' || str(ii) == 'R'
                            [list(2), ii] = getNum(str, list(2), ii);
                        else
                            disp([str ' not understood - expected rows, not columns']);
                        end
                    else
                        if str(ii) == 'c' || str(ii) == 'C'
                            [list(1), ii] = getNum(str, list(1), ii);
                        elseif str(ii) == 'd' || str(ii) == 'D'
                            [list(2), ii] = getNum(str, list(2), ii);
                        else
                            disp([str ' not understood - expected columns, not rows']);
                        end
                    end
                case {'X'}
                    [list(3), ii] = getNum(str, list(3), ii);
                case {'Y'}
                    [list(4), ii] = getNum(str, list(4), ii);
                case {'s', 'S'}
                    if ii+1 <= length(str)
                        if str(ii+1) == 'x' || str(ii+1) == 'X'
                            [list(3), ii] = getNum(str, list(3), ii);
                        elseif str(ii+1) == 'y' || str(ii+1) == 'Y'
                            [list(4), ii] = getNum(str, list(4), ii);
                        else
                            [list(3), ii] = getNum(str, list(3), ii);
                            [list(4), ii] = getNum(str, list(4), ii);
                        end
                    else
                        [list(3), ii] = getNum(str, list(3), ii);
                        [list(4), ii] = getNum(str, list(4), ii);
                    end
            end
            
            if isnan(ii) == 1
                break;
            end
            
            ii = ii + 1;
        end
        
        if sum(isnan(list)) == 4
            list = 0;
        end
    end
    function [num, ii] = getNum(str, default, ii)
        jj = 0;
        
        while ii <= length(str);
            switch str(ii)
                case {'0','1','2','3','4','5','6','7','8','9'}
                    jj = ii;
                    break;
            end
            
            ii = ii + 1;
        end
        
        if jj == 0
            num = default;
            ii = NaN;
            return;
        end
        
        while jj <= length(str)
            switch str(jj)
                case {'0','1','2','3','4','5','6','7','8','9'}
                    jj = jj + 1;
                otherwise
%                     str(ii:(jj-1))
                    num = eval(str(ii:(jj-1)));
                    ii = jj;
                    return;
            end
        end
    end
    function setCurrent_Callback(hObject, ~)
        disableWarning = false;
                
        switch hObject
            case c.autoV1Get
                set(c.autoV1X, 'String', c.microActual(1));
                set(c.autoV1Y, 'String', c.microActual(2));
                set(c.autoV1Z, 'String', c.piezo(3));
                set(c.autoV1NX, 'String', c.Sx);
                set(c.autoV1NY, 'String', c.Sy);
                % c.autoV1DX = c.selcircle(1);
                % c.autoV1DY = c.selcircle(2);
            case c.autoV2Get
                set(c.autoV2X, 'String', c.microActual(1));
                set(c.autoV2Y, 'String', c.microActual(2));
                set(c.autoV2Z, 'String', c.piezo(3));
                set(c.autoV2NX, 'String', c.Sx);
                set(c.autoV2NY, 'String', c.Sy);
               % c.autoV2DX = c.selcircle(1);
               % c.autoV2DY = c.selcircle(2);
            case c.autoV3Get
                set(c.autoV3X, 'String', c.microActual(1));
                set(c.autoV3Y, 'String', c.microActual(2));
                set(c.autoV3Z, 'String', c.piezo(3));
                set(c.autoV3NX, 'String', c.Sx);
                set(c.autoV3NY, 'String', c.Sy);
                % c.autoV3DX = c.selcircle(1);
                % c.autoV3DY = c.selcircle(2);
                 disp('Disk Centroid ...')
%                 c.selcircle(1)
%                  c.selcircle(2)
                diskclear_Callback();
            case c.autoV4Get
                set(c.autoV4X, 'String', c.microActual(1));
                set(c.autoV4Y, 'String', c.microActual(2));
                set(c.autoV4Z, 'String', c.piezo(3));
                set(c.autoV4NX, 'String', c.Sx);
                set(c.autoV4NY, 'String', c.Sy);
                % c.autoV4DX = c.selcircle(1);
                % c.autoV4DY = c.selcircle(2);
            case c.autoV5Get
                set(c.autoV5X, 'String', c.microActual(1));
                set(c.autoV5Y, 'String', c.microActual(2));
                set(c.autoV5Z, 'String', c.piezo(3));
                set(c.autoV5NX, 'String', c.Sx);
                set(c.autoV5NY, 'String', c.Sy);
                % c.autoV4DX = c.selcircle(1);
                % c.autoV4DY = c.selcircle(2);
            case c.autoTaskG2S
                set(c.autoTaskG2X, 'String', c.galvo(1)*1000);
                set(c.autoTaskG2Y, 'String', c.galvo(2)*1000);
                
                disableWarning = true;
            case c.autoTaskG3S
                set(c.autoTaskG3X, 'String', c.galvo(1)*1000);
                set(c.autoTaskG3Y, 'String', c.galvo(2)*1000);
                
                disableWarning = true;
        end
        
        if ~disableWarning
            if (c.piezo(1) ~= 5 || c.piezo(2) ~= 5) && (c.galvo(1) ~= 0 || c.galvo(2) ~= 0)
                questdlg('The piezos are not set to [5,5] and the galvos are not set to [0,0]!', 'Warning!', 'Okay');
            elseif (c.piezo(1) ~= 5 || c.piezo(2) ~= 5)
                questdlg('The piezos are not set to [5,5]!', 'Warning!', 'Okay');
            elseif (c.galvo(1) ~= 0 || c.galvo(2) ~= 0)
                questdlg('The galvos are not set to [0,0]!', 'Warning!', 'Okay');
            end
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
            case 5
                V = [str2double(get(c.autoV5X, 'String')) str2double(get(c.autoV5Y, 'String')) str2double(get(c.autoV5Z, 'String'))]';
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
            case 5
                N = [str2double(get(c.autoV5NX, 'String')) str2double(get(c.autoV5NY, 'String'))]';
        end
    end
    function R = getStoredR(d)
        switch d
            case 'x'
                R = [str2double(get(c.autoNXRm, 'String')) str2double(get(c.autoNXRM, 'String'))]';
            case 'y'
                R = [str2double(get(c.autoNYRm, 'String')) str2double(get(c.autoNYRM, 'String'))]';
            case 'dx'
                R = [str2double(get(c.autonRm, 'String'))  str2double(get(c.autonRM, 'String'))]';
            case 'dy'
                R = [str2double(get(c.autonyRm, 'String')) str2double(get(c.autonyRM, 'String'))]';
        end
    end
    function autoPreview_Callback(~, ~)
%         if (get(c.autoTaskWB, 'Value') == 1)
%             generateGrid(true); 
%         else
            generateGrid(false);
%         end
    end
    function [p, color, name, len] = generateGrid(onlyGoodListed)
        nxrange = getStoredR('x');    % Range of the major grid
        nyrange = getStoredR('y');

        ndxrange = getStoredR('dx');    % Range of the minor grid
        ndyrange = getStoredR('dy');

        % These vectors will be used to make our major grid
        V1 = getStoredV(1);    n1 = getStoredN(1);    % [x y z] - the position of the device in um;
        V2 = getStoredV(2);    n2 = getStoredN(2);    % [nx ny] - the position of the device in the major grid.
        V3 = getStoredV(3);    n3 = getStoredN(3);    % Fill in later! All of these coordinates will be loaded from the GUI...

        % This vector will be used to determine our device spacing inside one
        % grid.
        V4 = getStoredV(4);    n4 = getStoredN(4);
        V5 = getStoredV(5);    n5 = getStoredN(5);

        nd123 = [str2double(get(c.autoV123n, 'String')) str2double(get(c.autoV123ny, 'String'))]';  % The number of the device in the minor grid for 1,2,3
        nd4 =   [str2double(get(c.autoV4n, 'String'))   str2double(get(c.autoV4ny, 'String'))]';    % The number of the device in the minor grid for 4
        nd5 =   [str2double(get(c.autoV5n, 'String'))   str2double(get(c.autoV5ny, 'String'))]';    % The number of the device in the minor grid for 4

        % Major Grid
        m =    [n1(1)   n1(2)   1;
                n2(1)   n2(2)   1;
                n3(1)   n3(2)   1];
            
        if max(max(inv(m))) == Inf
            error('Major grid has a non-orthoganal basis');
        end
        
        x1 = inv(m)*[V1(1) V2(1) V3(1)]';
        x2 = inv(m)*[V1(2) V2(2) V3(2)]';
        x3 = inv(m)*[V1(3) V2(3) V3(3)]';
        
        V =     [x1(1) x1(2); x2(1) x2(2); x3(1) x3(2)];
        V0 =    [x1(3) x2(3) x3(3)]';

        % Minor Grid
        m =    [nd123(1) nd123(2) 1;
                nd4(1)   nd4(2)   1;
                nd5(1)   nd5(2)   1];
        
        if max(max(inv(m))) == Inf
            error('Minor grid has a non-orthoganal basis');
        end
        
        V123 = [0 0 0]';
        V4m = V4 - V*n4 - V0; %;
        V5m = V5 - V*n5 - V0; %;
        
        x1 = inv(m)*[V123(1) V4m(1) V5m(1)]';
        x2 = inv(m)*[V123(2) V4m(2) V5m(2)]';
        x3 = inv(m)*[V123(3) V4m(3) V5m(3)]';
        
        v =     [x1(1) x1(2); x2(1) x2(2); x3(1) x3(2)];
        v0 =    [x1(3) x2(3) x3(3)]';
        
        V0 = V0 + v0;
        
%         v = (V4 - (V*n4 + V0))/(nd4 - nd123);   % Direction of the linear minor grid. Note that z might be off...
        
        [white, black] = loadWhitelist();

        if(get(c.autoTaskWB, 'Value') ~= 1)
            
            c.p = zeros(3, diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange));
            color = zeros(diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange), 3);    % (silly matlab)
            name = cell(diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange),1);
        else
            
            c.p = zeros(3, length(white));
            color = zeros(length(white), 3);    % (silly matlab)
            name = cell(length(white),1);
        end
%         l = cell(1, diff(nxrange)*diff(nyrange)*diff(ndrange));

        i = 1;
        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for dx = ndxrange(1):ndxrange(2)
                    for dy = ndyrange(1):ndyrange(2)
                        isWhite = -1;    % -1 = no list; 0 = not on list; 1 = on list; 2 = specific;
                        isBlack = -1;    % -1 = no list; 0 = not on list; 1 = on list; 2 = specific;
                        isGood = true;
                        
                        if ~(length(white{1}) == 1)
                            for w = 1:length(white)
                                match = (white{w} == [dx, dy, x, y]) & ~isnan(white{w});
                                
                                if sum(match) == 4
                                    isWhite = 2;
                                elseif sum(match) == sum(~isnan(white{w})) && isWhite ~= 2
                                    isWhite = 1;
                                elseif isWhite == -1
                                    isWhite = 0;
                                end
                            end
                        end
                        if ~(length(black{1}) == 1)
                            for b = 1:length(black)
                                match = (black{b} == [dx, dy, x, y]) & ~isnan(black{b});
                                
                                if sum(match) == 4
                                    isBlack = 2;
                                elseif sum(match) == sum(~isnan(black{b})) && isBlack ~= 2
                                    isBlack = 1;
                                elseif isBlack == -1
                                    isBlack = 0;
                                end
                            end
                        end
                            
                        %disp((get(c.autoTaskWB, 'Value') == 1))
%                         disp('B, W:')
%                         disp(isBlack)
%                         disp(isWhite)
%                         disp([dx, dy, x, y])
                        
                        if (get(c.autoTaskWB, 'Value') == 1) && ((isWhite == 0) || (isBlack > 0 && isWhite ~= 2))   % Disable device if it is not whitelisted, or if it is blacklisted and not specifically enabled by the whitelist.
                            isGood = false;
%                         else
%                             disp('True:')
%                             disp(isBlack)
%                             disp(isWhite)
%                             [dx, dy, x, y]
                        end
                        
                        if ~onlyGoodListed || (onlyGoodListed && isGood)
%                             [dx, dy, x, y]
                            c.p(:,i) = V*([x y]') + v*([dx dy]') + V0;

                            color(i,:) = [0 0 1];

                            if ((dx == nd123(1) && dy == nd123(2)) && (sum(n1 == [x y]') == 2 || sum(n2 == [x y]') == 2 || sum(n3 == [x y]') == 2))
                                color(i,:) = [0 1 0];
                            end
                            if ((dx == nd4(1) && dy == nd4(2)) && sum(n4 == [x y]') == 2)
                                color(i,:) = [1 .5 0];
                            end
                            if ((dx == nd5(1) && dy == nd5(2)) && sum(n5 == [x y]') == 2)
                                color(i,:) = [1 .5 0];
                            end
                            if (c.p(3,i) < c.piezoMin(3))
                                p(3,i) = c.piezoMin(3);
                                color(i,:) = [1 0 0];
                            end
                            if (c.p(3,i) > c.piezoMax(3))
                                p(3,i) = c.piezoMax(3);
                                color(i,:) = [1 0 0];
                            end
                            if ~isGood
                                color(i,:) = [.7 0 0];
                            end

        %                     name{i} = ['Device ' num2str(d) ' in set [' num2str(x) ', '  num2str(y) ']'];
                            name{i} = '';

                            if diff(ndyrange) == 0 && diff(ndxrange) ~= 0
                                name{i} = ['d_[' num2str(dx) ']_s_[' num2str(x) ','  num2str(y) ']'];
                            elseif diff(ndxrange) == 0 && diff(ndyrange) ~= 0
                                name{i} = ['d_[' num2str(dy) ']_s_[' num2str(x) ','  num2str(y) ']'];
                            elseif diff(ndyrange) == 0 && diff(ndxrange) == 0
                                name{i} = ['s_[' num2str(x) ','  num2str(y) ']'];
                            else
                                if (get(c.autoTaskRow, 'Value') == 1)
                                    name{i} = ['d_[' num2str(dx) ']_r_['  num2str(dy) ']_s_[' num2str(x) ','  num2str(y) ']'];
                                else
                                    name{i} = ['d_[' num2str(dy) ']_c_['  num2str(dx) ']_s_[' num2str(x) ','  num2str(y) ']'];
                                end
                            end

                            i = i + 1;
                        end
                    end
                end
            end
        end
        
        len = i-1;
        
        c.pv = c.p;           % Transportation variables
        p = c.p;
        c.pc = color;
        c.len = len;

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
    function enabled = checkTask(ui)
        enabled = (get(ui, 'Value') == 1)  && ~c.globalStop && c.autoScanning;
    end
    function sayResult(string)
        if c.results
            for char = string
                switch char
                    case 'X'
                        fprintf(c.fhv, ['\tX:\t' num2str(c.old(1)) '\t==>\t'  num2str(c.piezo(1)) '\tV\r\n']);
                    case 'Y'
                        fprintf(c.fhv, ['\tY:\t' num2str(c.old(2)) '\t==>\t'  num2str(c.piezo(2)) '\tV\r\n']);
                    case 'Z'
                        fprintf(c.fhv, ['\tZ:\t' num2str(c.old(3)) '\t==>\t'  num2str(c.piezo(3)) '\tV\r\n']);
                    case 'x'
                        fprintf(c.fhv, ['\tGX:\t' num2str(c.old(4)*1000) '\t==>\t'  num2str(c.galvo(1)*1000) '\tmV\r\n']);
                    case 'y'
                        fprintf(c.fhv, ['\tGY:\t' num2str(c.old(5)*1000) '\t==>\t'  num2str(c.galvo(2)*1000) '\tmV\r\n']);
                end
            end
        end
    end
    function automate(onlyTest)
        c.autoScanning = true;          % 'Running' variable
        
        nxrange =   getStoredR('x');    % Range of the major grid
        nyrange =   getStoredR('y');

        ndrange =   getStoredR('dx');   % Range of the minor grid
        ndyrange =  getStoredR('dy');
        
        % Get the grid...
        [p, color, name, len] = generateGrid(true);
        
        c.results = false;
        
        if ~onlyTest    % Generate directory...
            clk = clock;
            ledSet(1);

            superDirectory = [c.directory '\' c.autoFolder];                                    % Setup the folders
            dateFolder =    [num2str(clk(1)) '_' num2str(clk(2)) '_' num2str(clk(3))];          % Today's folder is formatted in YYYY_MM_DD Form
            scanFolder =    ['Scan @ ' num2str(clk(4)) '-' num2str(clk(5)) '-' num2str(clk(6))];% This scan's folder is fomatted in @ HH-MM-SS.sss
            directory =     [superDirectory '\' dateFolder];
            subDirectory =  [directory '\' scanFolder];

            [status, message, messageid] = mkdir(superDirectory, dateFolder);                   % Make sure today's folder has been created.
            display(message);

            [status, message, messageid] = mkdir(directory, scanFolder);                        % Create a folder for this scan
            display(message);

            prefix = [subDirectory '\'];
            
            c.results = true;     % Record results?
            
            %Get mean centroid
%             disp('Mean Centroid ...')
%          
%             if exist('c.autoV4DX','var')
%                 Xi=mean([c.autoV1DX c.autoV2DX c.autoV3DX c.autoV4DX])
%                 Yi=mean([c.autoV1DY c.autoV2DY c.autoV3DY c.autoV4DY])
%             else
%                 Xi=mean([c.autoV1DX c.autoV2DX c.autoV3DX])
%                 Yi=mean([c.autoV1DY c.autoV2DY c.autoV3DY])
%             end
            if get(c.autoAutoProceed,'Value') == 1 && checkTask(c.autoTaskDiskI) && exist('c.autoV3DX') && exist('c.autoV3DY')
                c.autoDX=c.autoV3DX;
                c.autoDY=c.autoV3DY;

                Xi= c.autoV3DX;
                Yi= c.autoV3DY;

                %Load Piezo Calibration Data
                try
                    c.calib=load('piezo_calib.mat');
                catch err
                    disp(err.message)
                end

                %debug
                pX=c.calib.pX
                pY=c.calib.pY
            end
                
            try     % Try to setup the results files...
                fh =  fopen([prefix 'results.txt'],         'w');  c.fh = fh;
                fhv = fopen([prefix 'results_verbose.txt'], 'w');  c.fhv = fhv;
                fhb = fopen([prefix 'results_brief.txt'],   'w');  c.fhb = fhb;
                fhp = fopen([prefix 'results_power.txt'],   'w');  c.fhp = fhp;

                if (fh == -1 || fhv == -1 || fhb == -1) 
                    error('oops, file cannot be written'); 
                end 
            
                fprintf(fh,  '  Set  \t Info \r\n');
                fprintf(fh, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);
                % The above is incomplete, as it does not include dy

                fprintf(fhb,  '  Set  \t Counts \r\n');
                fprintf(fhb, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);

                fprintf(fhp,  '  Set  \t Powers \r\n');
                fprintf(fhp, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);

                fprintf(fhv, 'Welcome to the verbose version of the results summary...\r\n\r\n');
            catch err
                display('Failed to create results files...');
                display(err.message);
                c.results = false;    % Don't record results if the above fails.
            end
            
%             [fileNorm, pathNorm] = uigetfile('*.SPE','Select the bare-diamond spectrum');     % Normalization setup
% 
%             if isequal(fileNorm, 0)
%                 spectrumNorm = 0;
%             else
%                 spectrumNorm = readSPE([pathNorm fileNorm]);
%                 
%                 savePlotPng(1:512, spectrumNorm, [prefix 'normalization_spectrum.png']);
% 
%                 save([prefix 'normalization_spectrum.mat'], 'spectrumNorm');
%                 copyfile([pathNorm fileNorm], [prefix 'normalization_spectrum.SPE']);
%             end
%             
%             if results
%                 if spectrumNorm == 0
%                     fprintf(fhv, 'No bare-diamond normalization was selected.\r\n\r\n');
%                 else
%                     fprintf(fhv, ['Bare diamond normalization was selected from:\r\n  ' pathNorm fileNorm '\r\n\r\n']);
%                 end
%             end
        end
        
        original = c.micro; % Record the original position of the micrometers so we can return to it later...
        
        i = 1;
        resetGalvo_Callback(0,0);      
        dZ = 0;     % Variable to account for significant drift in Z.

        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for d = ndrange(1):ndrange(2)
                    for dy = ndyrange(1):ndyrange(2)
                        if c.autoScanning && c.running && ~c.globalStop && (i <= size(p,2))
                            try
                                gotoMicro(p(1:2,i)' - [10 10]);     % Goto the current device, approaching from the lower left.
                                gotoMicro(p(1:2,i)');
                                
%                                 pause(.5);
                                
                                if ~onlyTest
                                    piezoOutSmooth([0 0 0]);
                                end
                                piezoOutSmooth([5 5 p(3,i) + dZ]);       % Reset the piezos and goto the proper height

                                display(['Arrived at ' name{i}]);

                                if ~onlyTest && ~c.globalStop && c.autoScanning
                                    c.old = [c.piezo c.galvo];        % Save the previous state of the galvos and piezos.

                                    if checkTask(c.autoTaskFocus)
                                        display('  Focusing...');
                                        focus_Callback(0, 0);
                                        
%                                         dZ = dZ + (c.piezo(3)- c.old(3))/2;     % Add any discrepentcy to dZ (over 2 to help prevent mistakes).
                                        % Disabled the above feature on 10/6 until autofocus is improved.
                                    end

                                    if c.results
                                        fprintf(fhv, ['We moved to ' name{i} '\r\n']);
                                        sayResult('Z');
                                    end

                                    c.old = [c.piezo c.galvo];

                                    if checkTask(c.autoTaskBlue)
                                        try
                                            start(c.vid);
                                            data = getdata(c.vid);
                                            img = data(360:-1:121, 161:480);    % Fixed flip...
                                        catch err
                                            display(err.message)
                                        end
                                    end

                                    display('  Optimizing...');
                                    
                                    if checkTask(c.autoTaskDiskI)
                                        %Running Blue Feedback
                                        
                                        
%                                         for ii = 1:4
%                                             [c.Xf,c.Yf] = diskcheck(1); % Check Centroid for inverted image 
%                                         end
                                        
                                        for ii = 1:4
                                            [c.Xf,c.Yf] = diskcheck(); % Check Centroid for positive image
                                        end
                                        
                                    end

                                    scan0 = 0;
                                    scan = 0;
                                    piezo0 = 0;
                                    
                                    if checkTask(c.autoTaskPiezoI)
                                        display('    XY...');       piezo0 = piezoOptimizeXY(c.piezoRange, c.piezoSpeed, c.piezoPixels);
                                    end

                                    if checkTask(c.autoTaskGalvoI)
                                        display('    Galvo...');    scan0 = galvoOptimize(c.galvoRange, c.galvoSpeed, round(c.galvoPixels/2));
                                        scan = scan0; % In case there is only one repeat tasked.
                                    end

                                    if c.results
                                        sayResult('XYxy');
                                        fprintf(fhv, ['    This gave us an inital countrate of ' num2str(round(max(max(scan0)))) ' counts/sec.\r\n']);
                                    end

                                    j = 1;

                                    while j <= round(str2double(get(c.autoTaskNumRepeat, 'String'))) && ~c.globalStop && c.autoScanning
                                        c.old = [c.piezo c.galvo];
                                        
                                        display('    XYZ...');   optAll_Callback(0,0);
                                        
                                        display('    Galvo...'); optimizeAxis(4, .025, 200, 50);  scan = optimizeAxis(5, .025, 200, 50);

                                        sayResult('XYZxy');
                                        
                                        if c.results
                                            fprintf(fhv, ['    This gives us a countrate of ' num2str(round(max(max(scan)))) ' counts/sec.\r\n']);
                                        end

                                        j = j + 1;
                                    end

                                    c.old = [c.piezo c.galvo];
                                    
                                    if checkTask(c.autoTaskGalvo)
                                            display('  Scanning...');
                                            scan = galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);
                                    end

                                    sayResult('xy');

                                    if checkTask(c.autoTaskSpectrum)
                                        display('  Taking Spectrum...');
                                        
                                        G = {[0, 0],...
                                             [str2double(get(c.autoTaskG2X, 'String')), str2double(get(c.autoTaskG2Y, 'String'))],...
                                             [str2double(get(c.autoTaskG3X, 'String')), str2double(get(c.autoTaskG3Y, 'String'))]};
                                         
                                         numG = 1 + (sum(G{1} == 0) ~= 2) + (sum(G{2} == 0) ~= 2);
                                        
                                        for g = 1:3
                                            if g == 1 || sum(G{g} == 0) ~= 2
                                                if numG > 1
                                                    galvoOutSmooth([.2 .2]);
                                                    galvoOutSmooth(G{g}/1000);
                                                end
                                                
                                                spectrum = -1;

                                                k = 0;
                                                
                                                if g == 1 && numG == 1
                                                    fname = [prefix name{i} '_spectrum'];
                                                else
                                                    fname = [prefix name{i} '_g_[' num2str(g) ']_spectrum'];
                                                end

                                                while sum(size(spectrum)) == 2 && k < 3 && ~c.globalStop && c.autoScanning
                                                    try
                                                        trig = sendSpectrumTrigger();

                                                        if g == 1 && checkTask(c.autoTaskPower)
                                                            try
                                                                fprintf(fh, ['\t' num2str(getPower())]);
                                                            catch err
                                                                display(['Power aquisition failed with message: ' err.message]);
                                                            end
                                                        end

                                                        spectrum = waitForSpectrum(fname, trig);
                                                    catch err
                                                        display(err.message);
                                                    end
                                                    k = k + 1;
                                                end

                                                if sum(size(spectrum)) ~= 2 && ~c.globalStop && c.autoScanning
                                                    try
                                                        savePlotPng(1:512, spectrum, [fname '.png']);
                                                        savePlotPng(1:512, spectrum, [fname '.png']);
                                                    catch err
                                                        display(err.message);
                                                    end
                                                else
                                                    fprintf(fhv, ['    Unfortunately, spectrum acquisition failed for this device (g=' num2str(g) ').\r\n']);
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
                                        end
                                        
                                        if numG > 1
                                            resetGalvo_Callback(0,0)
                                        end
                                    end

                                    display('  Saving...');

    %                                 tempP = plot(1, 'Visible', 'off');
    %                                 tempA = get(tempP, 'Parent');
    %                                 png = plot(tempA, 1:512, spectrumNorm);
    %                                 xlim(tempA, [1 512]);
    %     %                             png = plot(c.lowerAxes, 1:512, spectrum);
    %     %                             xlim(c.lowerAxes, [1 512]);
    %                                 saveas(png, [prefix name{i} '_spectrum' '.png']);

                                    if scan0  ~= 0
                                        imwrite(rot90(scan0,2)/max(max(scan0)),   [prefix name{i} '_galvo_debug'  '.png']);  % rotate because the dims are flipped.
                                    end
                                    if scan   ~= 0
                                        save([prefix name{i} '_galvo' '.mat'], 'scan');
                                        imwrite(rot90(scan,2)/max(max(scan)),     [prefix name{i} '_galvo'        '.png']);
                                    end
                                    if piezo0 ~= 0
                                        imwrite(piezo0/max(max(piezo0)),   [prefix name{i} '_piezo_debug'  '.png']);
                                    end

                                    if checkTask(c.autoTaskBlue)
                                        imwrite(img, [prefix name{i} '_blue' '.png']);
                                        
                                        try
                                            start(c.vid);
                                            data = flipdim(getdata(c.vid),1);
                                            
                                            pos   = [c.autoDX c.autoDY; c.Xf c.Yf];
                                            color = {'red', 'green'};
                                            img = insertMarker(data, pos, 'x', 'color', color, 'size', 5); 

                                            img = imcrop(img,[161 121 320 240]);    % Crop...
                                        catch err
                                            display(err.message)
                                        end
                                        
                                        imwrite(img, [prefix name{i} '_blue_after' '.png']);
                                    end


                                    if c.results
                                        display('  Remarking...');

                                        counts = max(max(scan));
        %                                 counts2 = max(max(intitial));

%                                         works = true;
% 
%                                         if get(c.autoTaskGalvo, 'Value') == 1
%                                             J = imresize(scan, 5);
%                                             J = imcrop(J, [length(J)/2-25 length(J)/2-20 55 55]);
% 
%                                             level = graythresh(J);
%                                             IBW = im2bw(J, level);
%                                             [centers, radii] = imfindcircles(IBW, [15 60]);
% 
%                                             works = ~isempty(centers);
%                                         end

        %                                 IBW = im2bw(scan, graythresh(scan));
        %                                 [centers, radii] = imfindcircles(IBW,[5 25]);

                                        if d == ndrange(1)
                                            fprintf(fhb, ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                            fprintf(fh,  ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                            fprintf(fhp, ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                        end

%                                         if works
%                                             fprintf(fhb, ' W |');
%                                             fprintf(fh, [' W ' num2str(round(counts), '%07i') ' |']);
%                                             fprintf(fhv, '    Our program detects that this device works.\r\n\r\n');
%                                         else
%                                             fprintf(fhb, '   |');
%                                             fprintf(fh, ['   ' num2str(round(counts), '%07i') ' |']);
%                                             fprintf(fhv, '    Our program detects that this device does not work.\r\n\r\n');
%                                         end

                                        if c.autoSkipping
                                            fprintf(fhb, '\tS');
                                            fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
                                            fprintf(fhv, '    This device was skipped.\r\n\r\n');
                                        else
                                            fprintf(fhb, '\t');
                                            fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
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
                                if c.results
                                    try
                                        fprintf(fhb, '\tF');
                                        fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
                                        fprintf(fhv, '    Our program failed durign this device...\r\n\r\n');
                                    catch err2
                                        display(['Something went horribly when trying to say that something went horribly wrong with device ' name{i}]);
                                        display(err2.message);
                                    end
                                end
                                display([name{i} ' failed... Here is the error message:']);
                                display(err.message);
                            end

                            i = i+1;

                            if c.autoSkipping
                                c.autoScanning = true;
                                c.globalStop = false;
                                c.autoSkipping = false;
                            end
                        end
                    end
                end
            end
        end
        
        if ~onlyTest && c.results
            fclose(fhb);
            fclose(fh);
            fclose(fhv);
            fclose(fhp);
        end
        
        if c.running
            display('Totally Finished!');

            c.micro = original;
            setPos();

            c.autoScanning = false;
            c.globalStop = false;
            ledSet(0);
        end
    end
    function proceed_Callback(~, ~)
        c.proceed = true;
    end
    function autoSkip_Callback(~, ~)
        c.autoScanning = false;
        c.autoSkipping = true;
        c.globalStop = true;
    end

    % UI ==================================================================
    function renderUpper()
        if c.axesMode ~= 2
            p =     [c.pv   [c.microActual(1) c.microActual(2) c.piezo(3)]' [c.micro(1) c.micro(2) c.piezo(3)]'];
            color = [c.pc;   [0 0 0];  [1 0 1]];
            % shape = [repmat('c', 1, c.len) 'd' 'd'];
            
            mx = min(p(1,:));   Mx = max(p(1,:));   Ax = (Mx + mx)/2;   Ox = .55*(Mx - mx) + 25;
            my = min(p(2,:));   My = max(p(2,:));   Ay = (My + my)/2;   Oy = .55*(My - my) + 25;
            
%             Of = Ox;
%             
%             if Ox < Oy
%                 Of = Oy;
%             end

            Of = max([Ox Oy]);
            
            scatter(c.upperAxes, p(1,:), p(2,:), 36, color);
            
%             hold off
%             hold on
%              
%             scatter(c.upperAxes, p(1,(1):(end-2)), p(2,(1):(end-2)), 36, c.pc);
%             scatter(c.upperAxes, p(1,(end-1):(end)), p(2,(end-1):(end)), 36, [1 0 1; 0 0 0], 'd');
%             
%             hold off
            
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
    function limit_Callback(hObject, ~)
        val = str2double(get(hObject, 'String'));
        
        if isnan(val) % ~isa(val,'double') % If it's NaN, check if it's an equation
            try
                val = eval(get(hObject,'String'));
            catch err
                display(err.message);
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
    function scaleEdit_Callback(src,~)
        val = str2double(src.String);

        if isnan(val)   % If it's NaN (if str2double didn't work), check if it's an equation
            try
                val = eval(src.String);
            catch err
                display(err.message);
                val = 0;
            end
        end

        if isnan(val)   % If it's still NaN, set to zero
            val = 0;
        end

        switch src
            case c.scaleMinEdit
                c.scaleMinSlid.Value = val;
                scaleSlider_Callback(c.scaleMinSlid, 0)
            case c.scaleMaxEdit
                c.scaleMaxSlid.Value = val;
                scaleSlider_Callback(c.scaleMaxSlid, 0)
        end
    end
    function scaleNormalize_Callback(src, ~)
        c.scaleMinSlid.Max = str2double(c.scaleDataMinEdit.String);
        c.scaleMinSlid.Value = c.scaleMinSlid.Max;

        c.scaleMaxSlid.Max = str2double(c.scaleDataMaxEdit.String);
        c.scaleMaxSlid.Value = c.scaleMaxSlid.Max;

        scaleSlider_Callback(c.scaleMinSlid, -1);
        scaleSlider_Callback(c.scaleMaxSlid, -1);
    end
    function scaleSlider_Callback(src, data)
        maxMagn = floor(log10(src.Max));

        if src.Value <= 0
            src.Value = 0;
            src.Max = 1e4;

            switch src
                case c.scaleMinSlid
                    c.scaleMinEdit.String = 0;
                case c.scaleMaxSlid
                    c.scaleMaxEdit.String = 0;
            end
        else
            magn = floor(log10(src.Value));

    %         if magn ~= log10(src.Value)
    %             magn = magn-1;
    %         end

            str = [num2str(src.Value/(10^magn), '%1.1f') 'e' num2str(magn)];

            switch src
                case c.scaleMinSlid
                    c.scaleMinEdit.String = str;
                case c.scaleMaxSlid
                    c.scaleMaxEdit.String = str;
            end

            if magn+1 > maxMagn
                switch src
                    case c.scaleMinSlid
                        c.scaleMinSlid.Max = 1.5*10^(magn+1);
                    case c.scaleMaxSlid
                        c.scaleMaxSlid.Max = 1.5*10^(magn+1);
                end
            end

            if magn+1 < maxMagn
                switch src
                    case c.scaleMinSlid
                        c.scaleMinSlid.Max = 1.5*10^(magn+1);
                    case c.scaleMaxSlid
                        c.scaleMaxSlid.Max = 1.5*10^(magn+1);
                end
            end
        end
        
        if c.scaleMinSlid.Value > c.scaleMaxSlid.Value
            switch src
                case c.scaleMinSlid
                    c.scaleMaxSlid.Value = c.scaleMinSlid.Value;
                    if c.scaleMaxSlid.Max < c.scaleMinSlid.Value
                        c.scaleMaxSlid.Max = c.scaleMinSlid.Value;
                    end
                    if c.scaleMaxSlid.Min > c.scaleMinSlid.Value
                        c.scaleMaxSlid.Min = c.scaleMinSlid.Value;
                    end
                    scaleSlider_Callback(c.scaleMaxSlid, 0);      % Possible recursion if careless?
                case c.scaleMaxSlid
                    c.scaleMinSlid.Value = c.scaleMaxSlid.Value;
                    if c.scaleMinSlid.Max < c.scaleMaxSlid.Value
                        c.scaleMinSlid.Max = c.scaleMaxSlid.Value;
                    end
                    if c.scaleMinSlid.Min > c.scaleMaxSlid.Value
                        c.scaleMinSlid.Min = c.scaleMaxSlid.Value;
                    end
                    scaleSlider_Callback(c.scaleMinSlid, 0);
            end
        else
            if data ~= -1
                renderData(0);
            end
        end
    end
    function save_Callback(~, ~)
        [~, pathNorm] = uigetfile('*', 'Select the location for files to be saved via the Save button');
        if pathNorm
            c.directory = pathNorm;
            set(c.saveDirectory, 'String', c.directory);
        end
    end
    function saveEdit_Callback(~, ~)
        c.directory = get(c.saveDirectory, 'String');
    end
    function saveBackground_Callback(~, ~)
        [~, pathNorm] = uigetfile('*', 'Select the location for files to be saved in the background');
        if pathNorm
            c.directoryBackground = pathNorm;
            set(c.saveBackgroundDirectory, 'String', c.directoryBackground);
        end
    end
    function saveEditBackground_Callback(~, ~)
        c.directory = get(c.saveBackgroundDirectory, 'String');
    end

    % COUNTER =============================================================
    function counterToggle(src,~)
        if ~c.counting
            set(src, 'String', 'Stop');
            c.counting = true;
            
            c.counterLength = 10;
    %         c.sp.DurationInSeconds = 1;
            c.sp.Rate = 10;
            c.sp.IsContinuous = true;

            c.sp.resetCounters();

            c.sp.IsNotifyWhenScansQueuedBelowAuto = false;
            c.sp.NotifyWhenScansQueuedBelow = 5;

            c.lhCA = c.sp.addlistener('DataAvailable', @counterPlot);
            c.lhCR = c.sp.addlistener('DataRequired', @counterSustain);

            c.sp.queueOutputData([linspace(0,0,10)' linspace(0,0,10)']);
            
            cla(c.counterAxes);
            hold(c.counterAxes, 'on');
            set(c.counterAxes, 'FontSize', 24);
            ylabel(c.counterAxes, 'Counts (cts/sec)', 'FontSize', 24);
            set(c.counterFigure, 'GraphicsSmoothing', 'on');

            c.counterTime = linspace(0, 1, c.counterLength*c.sp.Rate);

            c.counterData = linspace(-1, -1, c.counterLength*c.sp.Rate);
            c.counterMean = linspace(-1, -1, c.counterLength*c.sp.Rate);
            c.counterStdP = linspace(-1, -1, c.counterLength*c.sp.Rate);
            c.counterStdM = linspace(-1, -1, c.counterLength*c.sp.Rate);

            c.counterMeanH = plot(c.counterTime, c.counterMean, 'r-', 'LineWidth', 2);
            c.counterStdPH = plot(c.counterTime, c.counterStdP, 'r:', 'LineWidth', 2);
            c.counterStdMH = plot(c.counterTime, c.counterStdM, 'r:', 'LineWidth', 2);
            c.counterDataH = plot(c.counterTime, c.counterData, 'b-', 'LineWidth', 2);

            plot([0 1], [1e6 1e6], 'r-', 'LineWidth', 2);
            plot([0 1], [1e7 1e7], 'r-', 'LineWidth', 4);
            plot([0 1], [1e8 1e8], 'r-', 'LineWidth', 8);

            set(c.counterAxes, 'Xlim', [0, 1]);

            c.countPrev = -1;

            c.sp.startBackground();
        else
            pause(1)
%             c.sp.wait();
            c.sp.stop();
            delete(c.lhCA);
            delete(c.lhCR);
            
            c.counting = false;
            set(src, 'String', 'Start');
        end
    end
    function counterPlot(~,event)
        if c.countPrev == -1;
            c.countPrev = event.Data(1);
            c.countPrevTime = event.TimeStamps(1);
        else
            c.counterData(1) = (event.Data(1) - c.countPrev)/(event.TimeStamps(1) - c.countPrevTime);
%             (event.Data(1) - c.countPrev)/(event.TimeStamps(1) - c.countPrevTime)
            c.countPrev = event.Data(1);
            c.countPrevTime = event.TimeStamps(1);
            
            c.counterMean(1) = mean(c.counterData(c.counterData(1:20) ~= -1));

            s = std( c.counterData(c.counterData(1:20) ~= -1));
            c.counterStdP(1) = c.counterMean(1) + s;
            c.counterStdM(1) = c.counterMean(1) - s;

            set(c.counterDataH, 'YData', c.counterData);
            set(c.counterMeanH, 'YData', c.counterMean);
            set(c.counterStdPH, 'YData', c.counterStdP);
            set(c.counterStdMH, 'YData', c.counterStdM);
            
            c.counterData = circshift(c.counterData, [0,1]);
            c.counterMean = circshift(c.counterMean, [0,1]);
            c.counterStdP = circshift(c.counterStdP, [0,1]);
            c.counterStdM = circshift(c.counterStdM, [0,1]);
            
            m = min(c.counterStdM(c.counterStdM ~= -1));
            M = max(c.counterStdP);
            d = .5*(M - m + 1);
            
            m = m - d;
            M = M + d;
            
            if m < 0 || get(c.counterScaleMode, 'Value') == 1
                m = 0;
            end
            
            set(c.counterAxes, 'Ylim', [m, M]);
        end
    end
    function counterSustain(~,~)
%         display('here');
        if c.counting
            c.sp.queueOutputData([linspace(0,0,10)' linspace(0,0,10)']);
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
    function updateScanGraph_Callback(~,~)
        updateScanGraph();
    end
    function updateScanGraph()
        c.pleRate =     floor(((2^11) / str2num(get(c.pleSpeed, 'String'))) * (str2num(get(c.pleScans, 'String'))/(2^6)) );
        c.pleRateOld =  floor( (2^11) * (str2num(get(c.pleScans, 'String'))/(2^6)) );
        c.perotLength = floor(str2num(get(c.pleScans, 'String'))/(c.upScans + c.downScans));
        
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
        
%         c.finalGraphX = linspace(0, 10*(9/8), );
    %     finalColorC((x+1):(x+sizeA(finalGraphX))) = finalGraphY;
        c.finalColorY(:,c.q) = c.finalGraphY;
        c.finalColorP(:,c.q) = c.finalGraphP;
        c.finalGraphS = c.finalGraphS + c.finalGraphY;

        if (c.q == c.qmaxPle)
            c.finalColorY = circshift(c.finalColorY, [0,-1]);
            c.finalColorP = circshift(c.finalColorP, [0,-1]);
        end
        
        if get(c.pleDebug, 'Value') == 1
            plot(c.pleAxesOne, c.finalGraphX, c.finalGraphP);
        else
            plot(c.pleAxesOne, c.finalGraphX, c.finalGraphY);
            plot(c.pleAxesSum, c.finalGraphX, c.finalGraphS);
        end

%         xmin = min(min(c.finalColorX));
%         xmax = max(max(c.finalColorX));
%         plot(c.pleAxesOne, c.finalGraphX, c.finalGraphY);
%         set(c.pleAxesOne, 'Xlim', [xmin xmax]);
%         xlabel(c.pleAxesOne, 'Frequency (GHz)');

        set(c.pleAxesOne, 'Xlim', [0 12.5]);
        set(c.pleAxesSum, 'Xlim', [0 12.5]);
%         xlabel(c.pleAxesOne, 'Grating Angle Potential (V)');
        
        if get(c.pleDebug, 'Value') == 1
            surf(c.pleAxesAll, c.finalGraphX, c.qmaxPle:-1:1, transpose(c.finalColorP),'EdgeColor','None');
        else
            surf(c.pleAxesAll, c.finalGraphX, c.qmaxPle:-1:1, transpose(c.finalColorY),'EdgeColor','None');
        end

%         mesh(c.pleAxesAll,[c.finalColorX(c.finalColorY~=0); c.finalColorX(c.finalColorY~=0)], [c.finalColorY(c.finalColorY~=0); c.finalColorY(c.finalColorY~=0)], [c.finalColorC(c.finalColorY~=0); c.finalColorC(c.finalColorY~=0)],'mesh','column','marker','.','markersize',1)
        % surf(axesAll, linspace(xmin, xmax, sizeA(finalColorY)), 100:-1:1, transpose(finalColorY),'EdgeColor','None');
        set(c.pleAxesAll, 'Xlim', [0 12.5]);
        set(c.pleAxesAll, 'Ylim', [c.qmaxPle-c.q  2*c.qmaxPle-c.q]);
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
                c.grateCurr = c.grateCurr - c.dGrateCurr*speed*8;
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
    function pleSimpleCall(src,~)
        if get(c.pleContSimple, 'Value') == 1
            c.pleScanning = 1;
            
            ledSet(1);
            c.q = 1;
            c.sd.outputSingleScan(0);
            % Setup
            length = str2double(get(c.pleSpeedSimple, 'String'))
            bins =  floor(str2double(get(c.pleBinsSimple, 'String')))
            c.scans = floor(str2double(get(c.pleScansSimple, 'String')))
            
            uplens = bins;
            downlens = floor(bins/4);  % Down scan is 1/4th of the length of the upscan.
            
            c.uplen = uplens*c.scans; % + 1;
            c.downlen = downlens*c.scans + 1;  % Down scan is 1/8th of the length of the upscan.
            
            fulllens = uplens + downlens;
            
            rate = c.uplen/length;
            c.sp.Rate = rate;
        
%             c.finalGraphX = zeros(1, fulllens);
            c.finalGraphX = linspace(0, (1 + downlens/uplens)*10, fulllens).';
            c.finalGraphY = zeros(1, fulllens);
            c.finalGraphS = zeros(1, fulllens).';
            c.finalGraphP = zeros(1, fulllens);

            c.finalColorX = zeros(fulllens, c.qmaxPle);
            c.finalColorY = zeros(fulllens, c.qmaxPle);
            c.finalColorP = zeros(fulllens, c.qmaxPle);
            
            up =    linspace(0, 10, c.uplen);
            down =  linspace(10, 0, c.downlen);
            
            c.sp.IsContinuous = true;

            c.sp.IsNotifyWhenDataAvailableExceedsAuto = false;
            c.sp.NotifyWhenDataAvailableExceeds = c.uplen + c.downlen;
            
            c.sp.IsNotifyWhenScansQueuedBelowAuto = false;
            c.sp.NotifyWhenScansQueuedBelow = c.downlen;

            c.pleLh = c.sp.addlistener('DataAvailable', @intervalCallSimpleA);
            c.pleLh2 = c.sp.addlistener('DataRequired', @intervalCallSimpleR);
            c.dataNeeded = true;

            c.out = daqOutQueueCleverPLE({NaN, [up down].'});
            c.sp.startBackground();
%             c.upOut = daqOutQueueCleverPLE({NaN, up.'});
%             [cts, times] = c.sp.startForeground();
% %             size(cts)
% %             size(cts(:,1))
%             out1 = [diff(cts(:,1))./diff(times)].';
%             
% %             finX = times(2:end);
% %             if scans > 1
% %                 finY = out(:,1:scans:end)
% %                 for x = 2:scans
% %                     finY = finY + out(:,x:scans:end);
% %                 end
% %             else
% %                 finY = out;
% %             end
%             
%             c.sd.outputSingleScan(1);
            
%             c.downOut = daqOutQueueCleverPLE({NaN, down.'});
%             [cts, times] = c.sp.startForeground();
            
%             queueOutputData(c.sp, c.upOut);
%             c.sp.startBackground();
%             out2 = [diff(cts(:,1))./diff(times)].';
%             
% %             finX2 = times(2:end);
%             out = [out1 out2];
%             if scans > 1
%                 finY = out(:,1:scans:end);
%                 for x = 2:scans
%                     finY = finY + out(:,x:scans:end);
%                 end
%             else
%                 finY = out;
%             end
%         
% %             display('finGraph');
%             %c.finalGraphX = [linspace(0, 10, uplens) linspace(10, 0, downlens)].';
% %             size(c.finalGraphX)
%             c.finalGraphY = finY.';
% %             size(c.finalGraphY)
%             
% %             display('fin');
% %             size(finY)
% %             size(finY2)
%             
%             c.sd.outputSingleScan(0);
%             
%             updateGraph();
%             
            % While
%             while get(c.pleContSimple, 'Value') == 1
%                 display('here');
%                 queueOutputData(c.sp, upOut);
%                 tic
%                 [cts, times] = c.sp.startForeground();
%                 toc
%                 out1 = [diff(cts(:,1))./diff(times)].';
% 
% %                 finX = times(2:end);
% %                 if scans > 1
% %                     finY = out(:,1:scans:end);
% %                     for x = 2:scans
% %                         finY = finY + out(:,x:scans:end);
% %                     end
% %                 else
% %                     finY = out;
% %                 end
% 
%                 c.sd.outputSingleScan(1);
%                 
%                 queueOutputData(c.sp, downOut);
%                 tic
%                 [cts, times] = c.sp.startForeground();
%                 toc
%                 out2 = [diff(cts(:,1))./diff(times)].';
% 
%                 c.sd.outputSingleScan(0);
%                 
%                 tic
%                 
%                 out = [out1 out2];
%                 if scans > 1
%                     finY = out(:,1:scans:end);
%                     for x = 2:scans
%                         finY = finY + out(:,x:scans:end);
%                     end
%                 else
%                     finY = out;
%                 end
%                 
% %                 c.finalGraphX = [finX finX2];
%                 c.finalGraphY = finY.';
%                 toc
%                 
%                 tic
%                 updateGraph();
%                 toc
%             end
%             
%             c.sd.outputSingleScan(1);
        end
    end
    function intervalCallSimpleR(src, event)
        if c.dataNeeded
            c.sd.outputSingleScan(1);
%             display('on')
            queueOutputData(c.sp, c.out);
            c.dataNeeded = false;
        end
    end
    function intervalCallSimpleA(src, event)
        if get(c.pleContSimple, 'Value') == 1
            c.dataNeeded = true;
%             display('off')
            c.sd.outputSingleScan(0);
            out = [diff(event.Data(:,1))./diff(event.TimeStamps)].';

            if c.scans > 1
                finY = out(:,1:c.scans:end);
                for x = 2:c.scans
                    finY = finY + out(:,x:c.scans:end);
                end
            else
                finY = out;
            end
            
            c.finalGraphY = finY.';

            updateGraph();
        else
            c.sd.outputSingleScan(1);
            ledSet(0);

            c.pleScanning = 0;

            delete(c.pleLh);
            delete(c.pleLh2);
            
            stop(c.sp);  % Not sure if this will flush all of the data; may cause troubles.

            c.sp.IsNotifyWhenDataAvailableExceedsAuto = true;
            c.sp.NotifyWhenDataAvailableExceeds = 50;
            
            c.sp.IsNotifyWhenScansQueuedBelowAuto = true;
            c.sp.NotifyWhenScansQueuedBelow = 50;
            
            c.sp.IsContinuous = false;
            
            c.sp.startForeground();
        end
    end
    function intervalCallSimple(src, event)
        if get(c.pleContSimple, 'Value') == 1
            switch sum(size(event.Data(:,1)))-1
                case c.uplen
                    c.sp.NotifyWhenDataAvailableExceeds = c.downlen;
                    c.sd.outputSingleScan(1);
                    queueOutputData(c.sp, c.upOut);
                    c.prev = [diff(event.Data(:,1))./diff(event.TimeStamps)].';
                case c.downlen
                    c.sp.NotifyWhenDataAvailableExceeds = c.uplen;
                    c.sd.outputSingleScan(0);
                    queueOutputData(c.sp, c.downOut);
                    out = [c.prev [diff(event.Data(:,1))./diff(event.TimeStamps)].'];
                    
                    if c.scans > 1
                        finY = out(:,1:c.scans:end);
                        for x = 2:scans
                            finY = finY + out(:,x:c.scans:end);
                        end
                    else
                        finY = out;
                    end

    %                 c.finalGraphX = [finX finX2];
                    c.finalGraphY = finY.';
                
                    updateGraph();
                otherwise
                    display('Something is wrong');
            end
        else
            c.sd.outputSingleScan(1);
            ledSet(0);

            c.pleScanning = 0;
            stop(c.sp);  % Not sure if this will flush all of the data; may cause troubles.
            c.sp.IsContinuous = false;

            delete(c.pleLh);
        end
    end
    function pleCall(src,~)
        once = false;

%         if src == c.pleOnce
%             once = true;
% %             turnEverythingElseOff(0);
%         elseif get(c.pleCont, 'Value') == 1
% %             turnEverythingElseOff(pleCont);
%         end

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

            c.sp.Rate = c.pleRate;
            c.sp.IsContinuous = true;

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
            
            c.sd.outputSingleScan(0);

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
                c.sd.outputSingleScan(1);

                display('Scanning Down');
            end
            if c.intervalCounter == c.upScans + c.downScans - 1
                queueOutputData(c.sp, c.output);
            end
            if c.intervalCounter == c.upScans + c.downScans
                c.sd.outputSingleScan(0);

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
    function pleSave_Callback(~,~)
%         freqBase = c.freqBase;
%         perotBase = c.perotBase;
%         xData = c.finalColorX;
        yData = c.finalColorY;
%         pData = c.finalColorP;
        
        save('C:\Users\Tomasz\Dropbox\Diamond Room\Automation!\pleData.mat', 'yData'); %'freqBase', 'perotBase', 'xData', 'yData', 'pData');
    end

    %Blue F/B for grid=====================================================
    function out_img=img_enhance(in_img)
            %Sharpen 
            filter = fspecial('unsharp', 1);
            I1 = imfilter(in_img, filter);

           % Clean up background and Adjust contrast
           % I2 = imtophat(I1,strel('disk',32));
           % out_img = imadjust(I2); 
           % Not reuired for round 3 devices
           
            out_img = I1;
    end
    function diskdetect_Callback(~,~) %Detects disks and plots them
         frame = flipdim(getsnapshot(c.vid),1);
         %frame= rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png'));
    
        I3 = img_enhance(frame);          
        %set(c.bluefbAxes,'CData',I3); 
        axes(c.bluefbAxes);
        
        thresh=str2double(get(c.autoDiskThresh, 'String'));
        
        
        % the ~ inverts the greyscale image 
        % inversion requiired for round 3 devices
        if (get(c.autoDiskInv,'Value')==1)
            IBW=~im2bw(I3,thresh); %Convert to BW and Manual Threshold
        else    
            IBW=im2bw(I3,thresh); %Convert to BW and Manual Threshold
        end
        
            imshow(IBW);
            [c.circles, c.radii] = imfindcircles(IBW,[4 10]); %Get Circles

        %Delete any old detections   
         try
             delete(c.hg1);
             delete(c.hg2);
         catch
         end
             
         %Plot Detected Disks
         if ~isempty(c.radii)
            axes(c.bluefbAxes);
            c.hg1=viscircles(c.circles, c.radii,'EdgeColor','g','LineWidth',1.5);  
         end
    end
    function diskclick_Callback(~,~) % Mark selected disk and get position 
        %disp('click')
        c.trackpt = get (c.bluefbAxes, 'CurrentPoint');
        if (c.trackpt(1,1) >= 0 && c.trackpt(1,1) <= 640) && (c.trackpt(1,2) >= 0 && c.trackpt(1,2) <= 480) && c.seldisk==0
             axes(c.bluefbAxes);
             for i=1:length(c.radii)
                if (c.trackpt(1,1)>= (c.circles(i,1)-c.radii(i)) && c.trackpt(1,1)<= (c.circles(i,1)+ c.radii(i))) ...
                        && (c.trackpt(1,2)>= (c.circles(i,2)-c.radii(i)) && c.trackpt(1,2)<= (c.circles(i,2)+ c.radii(i)))
                    c.selcircle(1)=c.circles(i,1); 
                    c.selcircle(2)=c.circles(i,2);
                    c.selradii=c.radii(i);
                    c.hg2=viscircles(c.selcircle ,c.selradii,'EdgeColor','r','LineWidth',1.5); 
                    c.seldisk=1;
                end
             end
        end
    end
    function [Xf, Yf] = diskcheck() 

        %Get device Image

        frame = flipdim(getsnapshot(c.vid), 1);
        I3 = img_enhance(frame);     

        %thresh=str2double(get(c.autoDiskThresh, 'String'));

        %Find the centroid of the required disk
        thresh = linspace(0.2, 0.9, 20);
        for ii = 1:length(thresh)
            
%             if(inv==1)
%                 IBW = ~im2bw(I3, thresh(ii));  
%                 circles = imfindcircles(~IBW, [10 23]); %Get Inverted Circles
%             else
                IBW = im2bw(I3, thresh(ii));  
                circles = imfindcircles(IBW, [4 10]); %Get Circles
%             end
            
            if size(circles, 1)
                for kk = 1:size(circles, 1)
                    a(kk) = (circles(kk, 1)-c.autoDX)^2 + (circles(kk,2)-c.autoDY)^2;
                end

                [min_v(ii), min_i(ii)] = min(a);
                clear a;

                pcirc(ii,:) = [circles(min_i(ii),1) circles(min_i(ii),2)];

            else
                min_v(ii) = 1000;
                pcirc(ii,:) = [0 0];
            end
        end

        [min_V, min_i] = min(min_v);

        if min_V == 1000
             disp('WARNING!!! No disks detected!!!')
             Xf=640/2;
             Yf=480/2;
             
        else
            XX = pcirc(min_i, 1);
            YY = pcirc(min_i, 2);

            %[X,Y,R] = centroid_fun()
            delX = XX-c.autoDX;
            delY = YY-c.autoDY;                                

            if abs(delX)>50 || abs(delY)>50
                disp('WARNING!!! Large drift or Broken Device!!!')
                Xf = XX;
                Yf = YY;
            else
                Xf = XX-delX;
                Yf = YY-delY;
                minAdjustmentpx = str2double(get(c.trk_min, 'String'));
                c.mindelVx = minAdjustmentpx*c.calib.pX;
                c.mindelVy = minAdjustmentpx*c.calib.pY;

                delVx = delX*c.calib.pX;
                delVy = delY*c.calib.pY;

                if (abs(delVx) > c.mindelVx) && (abs(delVy) > c.mindelVy)
                    disp('corrected')
                    piezoOutSmooth(c.piezo + [-delVx delVy 0]);
                elseif (abs(delVx) > c.mindelVx)
                    disp('corrected')
                    piezoOutSmooth(c.piezo + [-delVx 0 0]);
                elseif (abs(delVy) > c.mindelVy)
                    disp('corrected')
                    piezoOutSmooth(c.piezo + [0 delVy 0]);
                end
            end
        end
    end
    function diskclear_Callback(~,~)
         c.seldisk=0;
         try
             delete(c.hg1);
             delete(c.hg2);
         catch
         end
    end
 
    %New code using MSER Features
    function newTrack_Callback(hObject,~)
         if hObject ~= 0
             if c.newtrack_on==1
                 disp('Already running')
             else
                %set(c.track_stat,'String','Status: Started tracking');

                c.tktime = timer;
                c.tktime.TasksToExecute = Inf;
                rate=str2num(get(c.ratevid,'String'));
                
                %debug
                rate
                
                c.tktime.Period = 1/rate;
                c.tktime.TimerFcn = @(~,~)newtkListener;
                c.tktime.ExecutionMode = 'fixedSpacing';
                
                c.newtrack_on=1;
                
                %Grab the Initial Image
                c.frame_init = imadjust(flipdim(getsnapshot(c.vid),1));  
                c.points1 = detectSURFFeatures(c.frame_init, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
                [c.features1, c.valid_points1] = extractFeatures(c.frame_init,  c.points1);
                
                try
                    c.calib=load('piezo_calib.mat');
                catch err
                    disp(err.message)
                end
            
                start(c.tktime);
             end
         end
    end
    function newtkListener(~,~)
        %Grab image
         frame = imadjust(flipdim(getsnapshot(c.vid),1));
 %a=1       
        if c.newtrack_on            
                 points2 = detectSURFFeatures(frame, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
                [features2, valid_points2] = extractFeatures(frame,  points2);

                indexPairs = matchFeatures(c.features1, features2);

                matchedPoints1 = c.valid_points1(indexPairs(:, 1), :);
                matchedPoints2 = valid_points2(indexPairs(:, 2), :);
%a=2
                % Remove Outliers
                delta=(matchedPoints2.Location-matchedPoints1.Location);
                dist=sqrt(delta(:,1).*delta(:,1) + delta(:,2).*delta(:,2));

                mean_dist=mean(dist);
                stdev_dist=std(dist);

                count=1;
                for i=1:length(dist)
                    if (dist(i)<mean_dist+stdev_dist) && (dist(i)> mean_dist-stdev_dist)
                        filtered_Points1(count,:) = matchedPoints1.Location(i,:);
                        filtered_Points2(count,:) = matchedPoints2.Location(i,:);
                        count=count+1;
                    end
                end    
                %count
 %a=2.5              
                %Debug
                % deltaa=(filtered_Points2-filtered_Points1);
                %dista=sqrt(deltaa(:,1).*deltaa(:,1) + deltaa(:,2).*deltaa(:,2));
                %delta1=round(mean(matchedPoints2.Location-matchedPoints1.Location));
                if exist('filtered_Points1', 'var')
                    % Calculate the delta
                    del=mean(filtered_Points2 - filtered_Points1)
%a=3
                    trk_min=str2num(get(c.trk_min,'String'));
                    gain=str2num(get(c.trk_gain,'String'));
                    %Debug
                    trk_min
                    gain
                    
                    minAdjustmentpx = trk_min;
                    c.mindelVx = minAdjustmentpx*c.calib.pX;
                    c.mindelVy = minAdjustmentpx*c.calib.pY;
%a=4
                    delVx = gain*del(1)*c.calib.pX;
                    delVy = gain*del(2)*c.calib.pY;

                    if (abs(delVx) > c.mindelVx) && (abs(delVy) > c.mindelVy)
                        disp('corrected')
                        piezoOutSmooth(c.piezo + [-delVx delVy 0]);
                    elseif (abs(delVx) > c.mindelVx)
                        disp('corrected')
                        piezoOutSmooth(c.piezo + [-delVx 0 0]);
                    elseif (abs(delVy) > c.mindelVy)
                        disp('corrected')
                        piezoOutSmooth(c.piezo + [0 delVy 0]);
                    end
%a=5
                    
                end
        end
    end
    function stopnewTrack_Callback(hObject,~)
    try
        stop(c.tktime);
        delete(c.tktime);
        clear c.tktime
    catch err
        disp(err.message)
    end
    
    c.newtrack_on=0;
end

    % Mouse Control =======================================================
    function laser_offset_Callback(~,~)
        if isfield(c, 'LO_pt')
            disp('Setting new Laser offset!!')
            delete(c.LO_pt);
        end
        c.LO_pt=impoint(c.imageAxes);
        setColor(c.LO_pt,'m');
        pos=getPosition(c.LO_pt);
        c.laser_offset_x=pos(1); c.laser_offset_y=pos(2);
        set(c.laser_offset_x_disp,'String',['OX(pix):' num2str(c.laser_offset_x)]);
        set(c.laser_offset_y_disp,'String',['OY(pix):' num2str(c.laser_offset_y)]);
        disp(['LOX(pix):' num2str(c.laser_offset_x)]);
        disp(['LOY(pix):' num2str(c.laser_offset_y)]);
    end     
    function go_mouse_Callback(~,~)
        if isfield(c, 'LO_pt')==0
            disp('Laser offset not specified!!')
        else
            pt=impoint(c.imageAxes);
            setColor(pt,'r');

            pos=getPosition(pt);
            X=pos(1); Y=pos(2);

           deltaX = X - c.laser_offset_x;
           deltaY = -(Y - c.laser_offset_y);

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

           setPosition(pt,[(c.laser_offset_x) (c.laser_offset_y)]);
           setColor(pt,'g');
           pause(2);
           delete(pt);
        end
    end
    function go_mouse_fine_Callback(~,~)
        %Allow only small change
        if isfield(c, 'LO_pt')==0
            disp('Laser offset not specified!!')
        else    
            axes(c.imageAxes);
            mask=rectangle('Position',[c.laser_offset_x-50,c.laser_offset_y-50,100,100],'EdgeColor','r');

            pt=impoint(c.imageAxes);
            setColor(pt,'m');

            pos=getPosition(pt);
            X=pos(1); Y=pos(2);




            if (X>(c.laser_offset_x-50) && X<(c.laser_offset_x+50)) && (Y>(c.laser_offset_y-50) && Y<(c.laser_offset_y+50))


                disp('inside mask')
                deltaX = -(X - c.laser_offset_x);
                deltaY =  (Y - c.laser_offset_y);

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

                setPosition(pt,[(c.laser_offset_x) (c.laser_offset_y)]);
                setColor(pt,'g');
                pause(1);
            else
                disp('click outside mask!!')
            end
            delete(pt);
            delete(mask);
        end
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
            
            
            c.micro=c.micro + [dX*400 dY*262.507];
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

    % Blue Image Capture
    function capture_blue_Callback(~,~)
        if strcmp(get(c.capture_blue,'String'),'Start Capture')
            c.cap_blue = timer;
            c.cap_blue.TasksToExecute = Inf;

            c.cap_blue.Period = str2num(get(c.capture_interval,'String'));
            c.cap_blue.TimerFcn = @(~,~)cap_blue_Listener;
            c.cap_blue.ExecutionMode = 'fixedSpacing';

            set(c.capture_blue,'String','Stop Capture');
            format shortg; % Set clock format

            start(c.cap_blue);
        else 
            try
                stop(c.cap_blue);
                delete(c.cap_blue);
                clear c.cap_blue
                set(c.capture_blue,'String','Start Capture');
            catch err
                disp(err.message)
            end

        end
    end
    function cap_blue_Listener(~,~)
        time=fix(clock);
        folder='C:\Users\Tomasz\Desktop\DiamondControl\blue_capture\';
        filename = [num2str(time(end-3)) '__' num2str(time(end-2)) '_' num2str(time(end-1)) '_' num2str(time(end)) '.png'];
        frame = imadjust(flipdim(getsnapshot(c.vid),1));    %Capture Frame
        imwrite(frame, [folder filename]);
    end
end
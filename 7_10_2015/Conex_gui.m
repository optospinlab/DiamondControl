%Notes:
%Set Not Interruptable tags on all the functions (Except on move btn!)

%--------------------------------------------------------------------------
function varargout = Conex_gui(varargin)
global sx; global sy;global device_xaddr; global device_yaddr;
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Conex_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @Conex_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Conex_gui is made visible.
function Conex_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for Conex_gui
global active; active=0;
handles.output = hObject;
guidata(hObject, handles);
%--------------------------------------------------------------------------

%%% Edited 7/10/2015 Srivatsa
% --- Outputs from this function are returned to the command line.
function varargout = Conex_gui_OutputFcn(hObject, eventdata, handles) 

%Global variables
global sx; global sy; global device_xaddr; global device_yaddr;
global init_first;global init_done;global kb_enable; global set_m;
global coord_in; global popout1; global popout2; global zstep;
global z_obj; global upspeed; global range;


init_first=0; init_done=0; z_obj='Null';
stx='Not Connected'; sty='Not Connected';
xpos='Null'; ypos='Null';
kb_enable=1;
set_m=5; coord_in=[NaN NaN, NaN NaN, NaN NaN, NaN NaN];
popout1=0;popout2=0;
zstep=0;
upspeed =0; range=0;
%Refresh Device Status
while ~0 
    try
        if init_first==1 
            stx=status(sx,device_xaddr);
            xpos=pos(sx,device_xaddr);
            
            sty=status(sy,device_yaddr);
            ypos=pos(sy,device_yaddr);
        end
        
        set(handles.status_x,'String',stx);
        set(handles.xpos,'String',xpos);
        
        set(handles.status_y,'String',sty);
        set(handles.ypos,'String',ypos);
        
        guidata(hObject, handles);
        
    catch
        disp('GUI CLOSED');
        % Should I move to zero position before shutdown??
        try %to stop error when we close gui without initialization
            cmd(sx,device_xaddr,'RS'); %Reset X-Axis
            fclose(sx); delete(sx); clear sx;

            cmd(sy,device_yaddr,'RS'); %Reset Y-Axis
            fclose(sy); delete(sy); clear sy;
            disp('Serial connections closed')
            
            z_obj.release();
            disp('Released Z-Piezo')
        catch
            disp('No serial connections were made')
            try
                z_obj.release();
                disp('Released Z-Piezo')
            catch
                disp('Z-Piezo connection not made')
            end
        end
        break;
    end  
    pause(2); % run every 2sec
end
varargout{1} = handles.output;

% --- Executes on button press in move_btn.
function move_btn_Callback(hObject, eventdata, handles)
global sx; global sy;global device_xaddr; global device_yaddr;
global xin; global yin;global active; global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
	cmd(sx,device_xaddr,['SE' xin]); %Queue X-Axis
    cmd(sy,device_yaddr,['SE' yin]); %Queue Y-Axis
    %start simultaneous move
    fprintf(sx,'SE'); fprintf(sy,'SE');
    %stx=status(sx,device_xaddr);
   % sty=status(sy,device_yaddr);
    disp('Started move'); %Debug
    %Only one move command should be passed to the device
   % while ~strcmp([stx(end-1) stx(end)],'33') && ~strcmp([sty(end-1) sty(end)],'33')
     %   active=1;
     %   stx=status(sx,device_xaddr);
     %   sty=status(sy,device_yaddr);
   % end    
    disp('Finished move'); %Debug
    active=0;  
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in config_btn.
function config_btn_Callback(hObject, eventdata, handles)
global sx; global sy;global device_xaddr; global device_yaddr;
global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
%do something
set(hObject,'Value',0); %Reset the button state
end

% --- Executes on button press in reset_btn.
function reset_btn_Callback(hObject, eventdata, handles)
global sx; global sy;global device_xaddr; global device_yaddr;
global init_done; global active;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
    active=0;
    init_done = 0;
    cmd(sx,device_xaddr,'RS'); %Reset X-Axis
    cmd(sy,device_yaddr,'RS'); %Reset Y-Axis
    pause(5);
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in init_btn.
function init_btn_Callback(hObject, eventdata, handles)
global sx; global sy;global device_xaddr; global device_yaddr;
global init_done;global init_first;
button_state = get(hObject,'Value');
if button_state==1 && init_done==0 && init_first==0
	display('Starting Initialization Sequence');
    
        %X-axis actuator
        device_port='COM5';
        device_xaddr='1';
    try
        sx = serial(device_port); 
        set(sx,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
            'FlowControl', 'software','Terminator', 'CR/LF');
        fopen(sx);
        pause(1); 
        
        %Save previous Xposition
        cmd(sx,device_xaddr,'PW1'); 
        cmd(sx,device_xaddr,'HT1'); 
        cmd(sx,device_xaddr,'SL-5');  % negative software limit x=-5
        cmd(sx,device_xaddr,'BA0.005');% backlash compensation
        cmd(sx,device_xaddr,'PW0');
        pause(2);
        
        cmd(sx,device_xaddr,'OR'); %Get to home state (should retain position)

        display('Done Initializing X Axis');

        %Y-axis actuator
        device_port='COM6';
        device_yaddr='1';
        
        sy = serial(device_port);
        set(sy,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
            'FlowControl', 'software','Terminator', 'CR/LF');
        fopen(sy);
        pause(1); 
        
        %Save previous Yposition
        cmd(sy,device_yaddr,'PW1'); 
        cmd(sy,device_yaddr,'HT1'); 
        cmd(sy,device_yaddr,'SL-5');   % negative software limit y=-5
        cmd(sy,device_yaddr,'BA0.005'); % backlash compensation
        cmd(sy,device_yaddr,'PW0');
        pause(2);
        
        cmd(sy,device_yaddr,'OR'); %Go to home state
        display('Done Initializing Y Axis');
        
        z_init();
        display('Done Initializing Z-Piezo');
        
    init_done = 1; init_first=1;
    guidata(hObject,handles);
    
    catch
        disp('Controller Disconnected !!!');
    end   
end

if button_state==1 && init_done==0 && init_first==1
    display('Starting Re-Initialization Sequence');
    %X-axis actuator
    cmd(sx,device_xaddr,'OR'); %Get to home state (reset position)
    display('Done Initializing X Axis');
    %Y-axis actuator
    cmd(sy,device_yaddr,'OR'); %Get to home state (reset position)
    display('Done Initializing Y Axis');
end
set(hObject,'Value',0); %Reset the button state

%-------------------------------------------------------------------------
%%Take X Y input
function edit3_Callback(hObject, eventdata, handles)
global xin;
xin=get(hObject,'String');

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit4_Callback(hObject, eventdata, handles)
global yin;
yin=get(hObject,'String');

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stop_btn.
function stop_btn_Callback(hObject, eventdata, handles)
global sx; global sy; global active; global init_done;
button_state = get(hObject,'Value');
if button_state==1 && active==1 && init_done==1
    fprintf(sx,'ST'); %stop X axis motion
    fprintf(sy,'ST'); %stop Y axis motion
    active=0;
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in inc_x.
function inc_x_Callback(hObject, eventdata, handles)
global sx; global device_xaddr; global step; global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
    cmd(sx,device_xaddr,['PR' step]);
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in dec_x.
function dec_x_Callback(hObject, eventdata, handles)
global sx; global device_xaddr; global step; global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
    cmd(sx,device_xaddr,['PR' '-' step]);
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in inc_y.
function inc_y_Callback(hObject, eventdata, handles)
global sy; global device_yaddr; global step; global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
    cmd(sy,device_yaddr,['PR' step]);
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in dec_y.
function dec_y_Callback(hObject, eventdata, handles)
global sy; global device_yaddr; global step;global init_done;
button_state = get(hObject,'Value');
if button_state==1 && init_done==1
    cmd(sy,device_yaddr,['PR' '-' step]);
end
set(hObject,'Value',0); %Reset the button state

%Keyboard controls for manual fine tuning
% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
global sx; global device_xaddr; global sy; global device_yaddr;global step;
global init_done; global kb_enable; global z_obj; global zstep; global zout;
if init_done==1 && kb_enable==1
    switch eventdata.Key
    case 'uparrow'
        %disp('up')
        cmd(sy,device_yaddr,['PR' step]);
    case 'downarrow'
        %disp('down')
        cmd(sy,device_yaddr,['PR' '-' step]);
    case 'leftarrow'
        %disp('left')
        cmd(sx,device_xaddr,['PR' step]);
    case 'rightarrow'
        %disp('right')
        cmd(sx,device_xaddr,['PR' '-' step]);
    case 'pageup'
        if strcmp(z_obj,'Null')
            disp('not init')
        end
        zout=zout+zstep;
        z_obj.outputSingleScan(zout);
    case 'pagedown'
        zout=zout-zstep;
        z_obj.outputSingleScan(zout);
    end    
end


function step_Callback(hObject, eventdata, handles)
global step;
step=get(hObject,'String');

% --- Executes during object creation, after setting all properties.
function step_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function status_x_CreateFcn(hObject, eventdata, handles)
% hObject    handle to status_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


%----From Ian's GUI design------------------------------------------------
%--------------------------------------------------------------------------

% --- Executes on button press in enable_kb.
function enable_kb_Callback(hObject, eventdata, handles)
global kb_enable;
kb_en=get(hObject,'Value');
if kb_en==0 && kb_enable==1
    disp('Keyboard input disabled');
    kb_enable=kb_en;
end   
if kb_en==1 && kb_enable==0
    disp('Keyboard input enabled');
    kb_enable=kb_en;
end   

% --- Executes on button press in enable_jstick.
function enable_jstick_Callback(hObject, eventdata, handles)
% hObject    handle to enable_jstick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enable_jstick


% --- Executes on button press in setbox.
function setbox_Callback(hObject, eventdata, handles)
global set_m;
button_state = get(hObject,'Value');
if button_state==1
    cla(handles.axes1); %not sure if this works
    set_m=1;
end
set(hObject,'Value',0); %Reset the button state


% --- Executes on mouse press over axes1 background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
global coord_in; global set_m; global popout1;
if strcmp(get(ancestor(hObject, 'figure'), 'SelectionType'), 'normal') && set_m<5
    x = get(hObject, 'CurrentPoint');
    coord_in(set_m,1) = x(1,1); coord_in(set_m,2) = x(1,2);
    plot(coord_in(set_m,1),coord_in(set_m,2),'.','color','r','MarkerSize', 15);
   set_m=set_m+1;
end
if set_m==5
    fill(coord_in(:,1)',coord_in(:,2)','r')
    set_m=set_m+1;
end
if strcmp(get(ancestor(hObject, 'figure'), 'SelectionType'), 'alt') && popout1==0
    disp('creating new figure')
    popout1=1;
    pop1=figure;
    h=handles.axes1; 
    hc = copyobj(h, gcf);
    set(hc, 'Units', 'normal','Position', [0.05 0.06 0.9 0.9]);
    uiwait(pop1);
    popout1=0;
end
    

% --- Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
global popout2;
if strcmp(get(ancestor(hObject, 'figure'), 'SelectionType'), 'alt') && popout2==0
    disp('creating new figure')
    popout2=1;
    pop2=figure;
    h=handles.axes2; 
    hc = copyobj(h, gcf);
    set(hc, 'Units', 'normal','Position', [0.05 0.06 0.9 0.9]);
    uiwait(pop2);
    popout2=0;
end


%Z-axis control
function Zstep_Callback(hObject, eventdata, handles)
global zstep;
zstep = str2num(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function Zstep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    set(hObject,'String','0');
end


% --- Executes on button press in Zminus.
function Zminus_Callback(hObject, eventdata, handles)
global zout; global zstep;global z_obj;
button_state = get(hObject,'Value');
if button_state==1
    if strcmp(z_obj,'Null')
        z_init();
    end
    zout = zout - zstep;
    if zout < -10
        zout = -10;
    end
    z_obj.outputSingleScan(zout);
end
set(hObject,'Value',0); %Reset the button state


% --- Executes on button press in Zplus.
function Zplus_Callback(hObject, eventdata, handles)
global zout; global zstep; global zinit;global z_obj;
button_state = get(hObject,'Value');
if button_state==1
    if strcmp(z_obj,'Null')
        z_init();
    end
    zout = zout + zstep;
    if zout > 10
        zout = 10;
    end
    z_obj.outputSingleScan(zout);
end
set(hObject,'Value',0); %Reset the button state

% --- Executes on button press in Zmove.
function Zmove_Callback(hObject, eventdata, handles)
global zm; global zout; global zstep; global zinit;global z_obj;
button_state = get(hObject,'Value');
if button_state==1
    if strcmp(z_obj,'Null')
        z_init();
    end
    zout=zm;
    z_obj.outputSingleScan(zout);
end
set(hObject,'Value',0); %Reset the button state


function Zedit_Callback(hObject, eventdata, handles)
global zm;
zm = str2double(get(hObject,'String'));
if zm > 10
    zm = 10;
end
if zm < -10
    zm = -10;
end

function z_init()
global z_obj;
z_obj = daq.createSession('ni');
z_obj.addAnalogOutputChannel('Dev1', 'ao2', 'Voltage');
disp('Initialized Z-Axis Piezo')


% --- Executes during object creation, after setting all properties.
function Zedit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%Galvo Stuff
% --- Executes on button press in startScan.
function startScan_Callback(hObject, eventdata, handles)
global range;global upspeed;

% xlim(handles.axes1, [-range/2, range/2]);
% ylim(handles.axes1, [-range/2, range/2]);
%   
% range in microns, speed in microns per second (up is upscan; down is downscan)
%Scan the Galvo +/- mvConv*range/2 deg
%min step of DAQ = 20/2^16 = 3.052e-4V
%min step of Galvo = 8e-4Deg
%for galvo [1V->1Deg], 8e-4V->8e-4Deg
button_state = get(hObject,'Value');
if button_state==1
    upspeed = double(upspeed);
    range = double(range);
    
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
    s = daq.createSession('ni');
    s.Rate = upspeed*length(up)/range;

    s2 = daq.createSession('ni');
    s2.Rate = upspeed*length(up)/range;

    s.addAnalogOutputChannel('cDAQ1Mod1',   'ao0',    'Voltage');
    s.addAnalogOutputChannel('cDAQ1Mod1',   'ao1',    'Voltage');

    s2.addCounterInputChannel('Dev1',    'ctr1',      'EdgeCount');
    s2.addAnalogInputChannel('Dev1',     'ai0',      'Voltage');

    queueOutputData(s, [(0:-stepFast:-(mvConv*range/2))'    (0:-stepFast:-(mvConv*range/2))']);
    s.startForeground();    % Goto starting point from 0,0

    for y = up  % For y in up. We 
        s2.NumberOfScans = length(up);
        
        queueOutputData(s, [up'      y*ones(1,length(up))']);
        s.startBackground();
        [out, ~] = s2.startForeground();
        
        s.wait();

        queueOutputData(s, [down'    linspace(y, y + step, length(down))']);
        s.startBackground();

        final(i,:) = [mean(diff(out(:,1)')) diff(out(:,1)')];

    %             display('up');
    %             up
    %             display('up(1:i)');
    %             up(1:i)
    %             display('final(1:i,:)');
    %             final(1:i,:)

        if i > 1
            surf(handles.axes1, up, up(1:i), final(1:i,:));   % Display the graph on the backscan
            view(handles.axes1,2);
            colormap('gray');
            xlim(handles.axes1, [-mvConv*range/2  mvConv*range/2]);
            ylim(handles.axes1, [-mvConv*range/2  mvConv*range/2]);
    %                 zlim(handles.axes1, [min(min(final(2:i, 2:end))) max(max(final(2:i, 2:end)))]);
        end

        i = i + 1;

        prev = out(end);

        s.wait();
    end

    queueOutputData(s, [(-(mvConv*range/2):stepFast:0)'     ((mvConv*range/2):-stepFast:0)']);
    s.startForeground();    % Go back to 0,0 from finishing point

    s.release();    % release DAQ
end
set(hObject,'Value',0); %Reset the button state
    

function galvoScanRange_Callback(hObject, eventdata, handles)
global range;
range = str2double(get(hObject,'String'))

% --- Executes during object creation, after setting all properties.
function galvoScanRange_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function galvoScanSpeed_Callback(hObject, eventdata, handles)
global upspeed;
upspeed = str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function galvoScanSpeed_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

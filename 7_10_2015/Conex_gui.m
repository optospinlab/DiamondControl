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
global coord_in; 

init_first=0; init_done=0;
stx='Not Connected'; sty='Not Connected';
xpos='Null'; ypos='Null';
kb_enable=1;
set_m=5; coord_in=[NaN NaN, NaN NaN, NaN NaN, NaN NaN];

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
        catch
            disp('No serial connections were made')
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
if button_state==1 && active==0 && init_done==1
	cmd(sx,device_xaddr,['SE' xin]); %Queue X-Axis
    cmd(sy,device_yaddr,['SE' yin]); %Queue Y-Axis
    %start simultaneous move
    fprintf(sx,'SE'); fprintf(sy,'SE');
    stx=status(sx,device_xaddr);
    sty=status(sy,device_yaddr);
    disp('Started move'); %Debug
    %Only one move command should be passed to the device
    while ~strcmp([stx(last-1) stx(last)],'33') && ~strcmp([sty(last-1) sty(last)],'33')
        active=1;
        stx=status(sx,device_xaddr);
        sty=status(sy,device_yaddr);
    end    
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
        device_port='COM17';
        device_xaddr='1';
    try
        sx = serial(device_port); 
        set(sx,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
            'FlowControl', 'software','Terminator', 'CR/LF');
        fopen(sx);
        pause(1); 
        cmd(sx,device_xaddr,'OR'); %Get to home state (reset position)

        display('Done Initializing X Axis');

        %Y-axis actuator
        device_port='COM18';
        device_yaddr='1';
        
        sy = serial(device_port);
        set(sy,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1, ...
            'FlowControl', 'software','Terminator', 'CR/LF');
        fopen(sy);
        pause(1); cmd(sy,device_yaddr,'OR'); %Go to home state
        display('Done Initializing Y Axis');
        
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
global init_done; global kb_enable;
if init_done==1 && kb_enable==1
    switch eventdata.Key
    case 'uparrow'
        disp('up')
        cmd(sy,device_yaddr,['PR' step]);
    case 'downarrow'
        disp('down')
        cmd(sy,device_yaddr,['PR' '-' step]);
    case 'leftarrow'
        disp('left')
        cmd(sx,device_xaddr,['PR' '-' step]);
    case 'rightarrow'
        disp('right')
        cmd(sx,device_xaddr,['PR' step]);
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


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
global coord_in; global set_m; 
if strcmp(get(ancestor(hObject, 'figure'), 'SelectionType'), 'normal') && set_m<5
    x = get(hObject, 'CurrentPoint');
    coord_in(set_m,1) = x(1,1); coord_in(set_m,2) = x(1,2);
    plot(coord_in(set_m,1),coord_in(set_m,2),'.','color','r','MarkerSize', 15);
   set_m=set_m+1;
end
if set_m==5
    fill(coord_in(:,1)',coord_in(:,2)','r')
end
    

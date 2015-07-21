function varargout = test(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test_OpeningFcn, ...
                   'gui_OutputFcn',  @test_OutputFcn, ...
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


% --- Executes just before test is made visible.
function test_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
global alpha; alpha=0;
global run; run=1;


% --- Outputs from this function are returned to the command line.
function varargout = test_OutputFcn(hObject, eventdata, handles) 
global alpha; global run;

vid = videoinput('avtmatlabadaptor64_r2009b', 1);
vidRes = vid.VideoResolution; nBands = vid.NumberOfBands;
closepreview;  %close preview if still running

while run
    frame = getsnapshot(vid);
    
    axes(handles.axes1);
    imagesc(frame); colormap('Gray');
    
    f = fspecial('unsharp', alpha); % Create mask
    out = imfilter(frame, f); % Filter the image
    
    BW = im2bw(frame,0.99);
    
    axes(handles.axes2);
    imshow(BW);
    
   [centers, radii] = imfindcircles(BW,[12 20])
   viscircles(centers, radii,'EdgeColor','b')
    
    pause(0.5)
end
close all;
varargout{1} = handles.output;



function in_alpha_Callback(hObject, eventdata, handles)
global alpha;
alpha=str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function in_alpha_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exit_btn.
function exit_btn_Callback(hObject, eventdata, handles)
global run;
button_state = get(hObject,'Value');
if button_state==1 
    run=0;
end

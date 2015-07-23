function varargout = imagefeedbackGUI(varargin)
% IMAGEFEEDBACKGUI MATLAB code for imagefeedbackGUI.fig
%      IMAGEFEEDBACKGUI, by itself, creates a new IMAGEFEEDBACKGUI or raises the existing
%      singleton*.
%
%      H = IMAGEFEEDBACKGUI returns the handle to a new IMAGEFEEDBACKGUI or the handle to
%      the existing singleton*.
%
%      IMAGEFEEDBACKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGEFEEDBACKGUI.M with the given input arguments.
%
%      IMAGEFEEDBACKGUI('Property','Value',...) creates a new IMAGEFEEDBACKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imagefeedbackGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imagefeedbackGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imagefeedbackGUI

% Last Modified by GUIDE v2.5 23-May-2014 11:27:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imagefeedbackGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @imagefeedbackGUI_OutputFcn, ...
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


% --- Executes just before imagefeedbackGUI is made visible.
function imagefeedbackGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imagefeedbackGUI (see VARARGIN)

% Choose default command line output for imagefeedbackGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imagefeedbackGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = imagefeedbackGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%here we read in the configuration file for the piezo voltage ao channels
%these global variables will need to be accessed from other functions
fid = fopen('image_config.txt');
fgetl(fid);
global ao1 ao2 ao3 ctrclock ctr nidevice;
nidevice = fgetl(fid)
fgetl(fid);
ao1 = round(str2num(fgetl(fid)))
fgetl(fid);
ao2 = round(str2num(fgetl(fid)))
fgetl(fid);
ao3 = round(str2num(fgetl(fid)));
fgetl(fid);
ctr = fgetl(fid);
fgetl(fid);
ctrclock = fgetl(fid);
%next we drive the stage to the default values
Vx = str2num(get(handles.Vx, 'String'));
Vy = str2num(get(handles.Vy, 'String'));
s = daq.createSession('ni');
s.addAnalogOutputChannel(nidevice, [ao1 ao2], 'Voltage');
s.outputSingleScan([Vx Vy]); 
pause(0.05);
s.release();

% --- Executes on button press in previewbutton.
function previewbutton_Callback(hObject, eventdata, handles)
% hObject    handle to previewbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'Value') == 1
    vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
    src = getselectedsource(vid);
%     vid.FramesPerTrigger = 1;
    src.ExtendedShutter = str2num(get(handles.shuttertime, 'String')); 
    %find out whether to use full chip or ROI (Region Of Interest)
    if get(handles.FullChipOrROI, 'Value')==2
        %[xoff, yoff] is position of upper left corner of image
        xoff = str2num(get(handles.xcen, 'String')) 
        yoff = str2num(get(handles.ycen, 'String'))
        width = str2num(get(handles.width, 'String'))
        height = str2num(get(handles.height, 'String'))
        vid.ROIPosition = [xoff yoff width height];
    end
        
    %axes(handles.axes1) %suppose to make plot in gui but it does not work
    preview(vid);  
else
%     get(hObject, 'Value')
%     vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
    closepreview;
end

% --- Executes on button press in snapshot.
function snapshot_Callback(hObject, eventdata, handles)
% hObject    handle to snapshot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closepreview;
vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
src = getselectedsource(vid);
 src.ExtendedShutter = str2num(get(handles.shuttertime, 'String'));  
%find out whether to use full chip or ROI (Region Of Interest)
    if get(handles.FullChipOrROI, 'Value')==2
        %[xoff, yoff] is position of upper left corner of image
        xoff = str2num(get(handles.xcen, 'String')) 
        yoff = str2num(get(handles.ycen, 'String'))
        width = str2num(get(handles.width, 'String'))
        height = str2num(get(handles.height, 'String'))
        vid.ROIPosition = [xoff yoff width height];
    end    
frame = getsnapshot(vid);
axes(handles.axes1)
rot = str2num(get(handles.rot, 'String'));
% Im=imrotate (frame,rot,'bilinear','crop');
% imagesc(Im)
imagesc(frame);
colormap('Gray');
set(handles.figureTitle, 'String', 'Snapshot');

% --- Executes on button press in track.
function track_Callback(~, eventdata, handles)
% hObject    handle to track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closepreview;  %close preview if still running
vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
src = getselectedsource(vid);
 src.ExtendedShutter = str2num(get(handles.shuttertime, 'String'));   
%find out whether to use full chip or ROI (Region Of Interest)
    if get(handles.FullChipOrROI, 'Value')==2
        %[xoff, yoff] is position of upper left corner of image
        xoff = str2num(get(handles.xcen, 'String')) 
        yoff = str2num(get(handles.ycen, 'String'))
        width = str2num(get(handles.width, 'String'))
        height = str2num(get(handles.height, 'String'))
        vid.ROIPosition = [xoff yoff width height];
    end  

frame = getsnapshot(vid);

axes(handles.axes1)
rot = str2num(get(handles.rot, 'String'));
% Im=imrotate (frame,rot,'bilinear','crop');
% centroid_fun(Im,handles)
centroid_fun(frame,handles)
% colormap('Gray');

pause(0.1)
% [X0 Y0] = centroid_fun(Im,handles);
[X0 Y0] = centroid_fun(frame,handles);
set(handles.x0, 'String', num2str(X0));
set(handles.y0, 'String', num2str(Y0));
%start tracking
%here I record approximate calibration from Dec. 5 2012
%full x range on camera corresponds to ~46 um, 1 pixel = 0.072 um
%for y range on camera corresponds to ~35 um
%next need to know voltage/per pixel 10V = 50 microns -> 1 px = 0.0144 V
k = 0.0144; %calibration constant between pixels and voltage
%check calibration a different way- look at image as voltage is changed on
%piezos,it is about 9V across which agrees well with 46microns

gain = str2num(get(handles.gain, 'String'));
minAdjustmentpx = str2num(get(handles.minAdjustment, 'String'));
mindelV = minAdjustmentpx*k;
rate=str2num(get(handles.feedbackRate, 'String'));
delay = 1.0/rate
zfocuscounter = 0;
N = round(str2num(get(handles.N, 'String')));
while get(handles.track, 'Value') == 1
    global ao1 ao2 nidevice;
    frame = getsnapshot(vid);
    rot = str2num(get(handles.rot, 'String'));
%     Im=imrotate (frame,rot,'bilinear','crop');
%     [X Y] = centroid_fun(Im,handles);
    [X Y] = centroid_fun(frame,handles);
    set(handles.xcurrent, 'String', num2str(X));
    set(handles.ycurrent, 'String', num2str(Y));
    delX = X-X0;
    delY = Y-Y0;
    Vxold = str2num(get(handles.Vx, 'String'));
    Vyold = str2num(get(handles.Vy,'String'));    
    delVx = delX*k*gain;
    delVy = delY*k*gain;
    %only move if greater than 1 pixel which is < 50 nm
    if (abs(delVx)>mindelV) | (abs(delVy) > mindelV)
    %only move if voltage stays positive
    Vxnew = max([0, Vxold - delVx])
    Vynew = max([0, Vyold - delVy])
    s = daq.createSession('ni');
    s.addAnalogOutputChannel(nidevice, [ao1 ao2], 'Voltage');
    s.outputSingleScan([Vxnew Vynew]); 
    set(handles.Vx, 'String', num2str(Vxnew));
    set(handles.Vy, 'String', num2str(Vynew));
    end
    pause(delay);
    zfocuscounter = zfocuscounter + 1;
    if zfocuscounter == N
        zfocuscounter = 0;
       if get(handles.zFeedback, 'Value') == 2
           figure(2)
           close(2)
           findfocus(handles)
       end
    end
end

% --- Executes on button press in TrackedSnapshot.
function TrackedSnapshot_Callback(hObject, eventdata, handles)
% hObject    handle to TrackedSnapshot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
    src = getselectedsource(vid);
    src.ExtendedShutter = str2num(get(handles.shuttertime, 'String'));   
  
    %find out whether to use full chip or ROI (Region Of Interest)
    if get(handles.FullChipOrROI, 'Value')==2
        %[xoff, yoff] is position of upper left corner of image
        xoff = str2num(get(handles.xcen, 'String')) 
        yoff = str2num(get(handles.ycen, 'String'))
        width = str2num(get(handles.width, 'String'))
        height = str2num(get(handles.height, 'String'))
        vid.ROIPosition = [xoff yoff width height];
    end    
    frame = getsnapshot(vid);
    rot = str2num(get(handles.rot, 'String'));
% Im=imrotate (frame,rot,'bilinear','crop');
% imagesc(Im)
%     [X Y] = centroid_fun(Im, handles);
    [X Y] = centroid_fun(frame, handles);
% --- Executes during object creation, after setting all properties.
% --- Executes on selection change in Zon.
function Zon_Callback(hObject, eventdata, handles)
% hObject    handle to Zon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Zon contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Zon
global ao3 nidevice;
Vz = str2num(get(handles.Vz, 'String'));
s = daq.createSession('ni');
s.addAnalogOutputChannel(nidevice, ao3, 'Voltage');
s.outputSingleScan(Vz); 
pause(0.05);
s.release();
    
% --- Executes on button press in Focus.
function Focus_Callback(hObject, eventdata, handles)
% hObject    handle to Focus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
findfocus(handles);


function findfocus(handles)
    Vzold = str2num(get(handles.Vz, 'String'));
    global ao3 ctr ctrclock nidevice;
    s = daq.createSession('ni');
    s.addCounterInputChannel(nidevice, ctr ,'EdgeCount'); 
    s.addAnalogInputChannel(nidevice,ctrclock,'Voltage'); % automatically configures clock 
    s.addAnalogOutputChannel(nidevice, ao3, 'Voltage');
    timeperpoint = 0.1;
    s.Rate= 1/timeperpoint;
    zscan = [(Vzold-0.5):0.02:(Vzold+0.5)]';
    s.queueOutputData(zscan);
    data = s.startForeground()
    figure(2)
    datacounts = [data(3:end, 1)-data(2:(end-1), 1)];
    plot(zscan(3:end), datacounts , 'o');
    axis tight;
    s.resetCounters;
    %find peak
    [maxdata maxi]=max(datacounts(:, 1))
    fitVz = zscan((maxi+2-5):(maxi+2+5));
    fitdata = datacounts((maxi-5):(maxi+5));
    p = polyfit(fitVz, fitdata, 2);
    hold on;
    plot(fitVz, polyval(p, fitVz), 'r');
    Vznew = -p(2)/(2*p(1));
    s = daq.createSession('ni');
    s.addAnalogOutputChannel(nidevice, ao3, 'Voltage');
    s.outputSingleScan(Vznew); 
    pause(0.05);
    s.release();
    set(handles.Vz, 'String', num2str(Vznew));
    
function [X Y] = centroid_fun(frame, handles)
    %first invert and threshold and plot
    threshold = str2num(get(handles.threshold, 'String'))
    if get(handles.invert, 'Value')==2
        b = 255-threshold;
        iframe = round((abs(b-frame)+b-frame)/2);
    else
        iframe = round((frame-threshold + abs(frame-threshold))/2);
    end
    axes(handles.axes1)
    imagesc(iframe)
    colormap('Gray');
    set(handles.figureTitle, 'String', 'Tracked image');
    %next calculate the centroid, note that this always uses the ROI
    width = str2num(get(handles.width, 'String'));
    height = str2num(get(handles.height, 'String'));
    Xind = 1:width;
    Yind = 1:height;
    X = round(sum(Xind.*sum(iframe, 1)/sum(sum(iframe)))*100)/100;
    Y = round(sum(Yind.*(sum(iframe, 2)/sum(sum(iframe)))')*100)/100;

% --- Executes on button press in quitbutton.
function quitbutton_Callback(hObject, eventdata, handles)
% hObject    handle to quitbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closepreview
%ramp piezo voltages to 0
global ao1 ao2 ao3 nidevice;
s = daq.createSession('ni');
s.addAnalogOutputChannel(nidevice, [ao1 ao2 ao3], 'Voltage')
s.outputSingleScan([0 0 0]); 
pause(0.05);
s.release();
close all;


function Vx_Callback(hObject, eventdata, handles)
% hObject    handle to Vx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vx as text
%        str2double(get(hObject,'String')) returns contents of Vx as a double
global ao1 nidevice;
Vxnew = str2num(get(handles.Vx, 'String'))
s = daq.createSession('ni');
s.addAnalogOutputChannel(nidevice, ao1, 'Voltage');
s.outputSingleScan(Vxnew); 


function Vy_Callback(hObject, eventdata, handles)
% hObject    handle to Vy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vy as text
%        str2double(get(hObject,'String')) returns contents of Vy as a double
global ao2 nidevice;
Vynew = str2num(get(handles.Vy, 'String'))
s = daq.createSession('ni');
s.addAnalogOutputChannel(nidevice, ao2, 'Voltage');
s.outputSingleScan(Vynew); 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%all callbacks/function below I do not use%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in FullChipOrROI.
function FullChipOrROI_Callback(hObject, eventdata, handles)
% hObject    handle to FullChipOrROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FullChipOrROI contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FullChipOrROI


% --- Executes during object creation, after setting all properties.
function FullChipOrROI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FullChipOrROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function width_Callback(hObject, eventdata, handles)
% hObject    handle to width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of width as text
%        str2double(get(hObject,'String')) returns contents of width as a double


% --- Executes during object creation, after setting all properties.
function width_CreateFcn(hObject, eventdata, handles)
% hObject    handle to width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function height_Callback(hObject, eventdata, handles)
% hObject    handle to height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of height as text
%        str2double(get(hObject,'String')) returns contents of height as a double


% --- Executes during object creation, after setting all properties.
function height_CreateFcn(hObject, eventdata, handles)
% hObject    handle to height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xcen_Callback(hObject, eventdata, handles)
% hObject    handle to xcen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xcen as text
%        str2double(get(hObject,'String')) returns contents of xcen as a double


% --- Executes during object creation, after setting all properties.
function xcen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xcen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ycen_Callback(hObject, eventdata, handles)
% hObject    handle to ycen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ycen as text
%        str2double(get(hObject,'String')) returns contents of ycen as a double


% --- Executes during object creation, after setting all properties.
function ycen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ycen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes during object creation, after setting all properties.
function Vx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function Vy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function threshold_Callback(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold as text
%        str2double(get(hObject,'String')) returns contents of threshold as a double


% --- Executes during object creation, after setting all properties.
function threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function gain_Callback(hObject, eventdata, handles)
% hObject    handle to gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gain as text
%        str2double(get(hObject,'String')) returns contents of gain as a double


% --- Executes during object creation, after setting all properties.
function gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function shuttertime_Callback(hObject, eventdata, handles)
% hObject    handle to shuttertime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of shuttertime as text
%        str2double(get(hObject,'String')) returns contents of shuttertime as a double


% --- Executes during object creation, after setting all properties.
function shuttertime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to shuttertime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in invert.
function invert_Callback(hObject, eventdata, handles)
% hObject    handle to invert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns invert contents as cell array
%        contents{get(hObject,'Value')} returns selected item from invert


% --- Executes during object creation, after setting all properties.
function invert_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minAdjustment_Callback(hObject, eventdata, handles)
% hObject    handle to minAdjustment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minAdjustment as text
%        str2double(get(hObject,'String')) returns contents of minAdjustment as a double


% --- Executes during object creation, after setting all properties.
function minAdjustment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minAdjustment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function feedbackRate_Callback(hObject, eventdata, handles)
% hObject    handle to feedbackRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of feedbackRate as text
%        str2double(get(hObject,'String')) returns contents of feedbackRate as a double


% --- Executes during object creation, after setting all properties.
function feedbackRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to feedbackRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end






function Vz_Callback(hObject, eventdata, handles)
% hObject    handle to Vz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vz as text
%        str2double(get(hObject,'String')) returns contents of Vz as a double


% --- Executes during object creation, after setting all properties.
function Vz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function N_Callback(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of N as text
%        str2double(get(hObject,'String')) returns contents of N as a double


% --- Executes during object creation, after setting all properties.
function N_CreateFcn(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in zFeedback.
function zFeedback_Callback(hObject, eventdata, handles)
% hObject    handle to zFeedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns zFeedback contents as cell array
%        contents{get(hObject,'Value')} returns selected item from zFeedback


% --- Executes during object creation, after setting all properties.
function zFeedback_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zFeedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Zon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zFeedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function rot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

unction rot_Callback(hObject, eventdata, handles)
% hObject    handle to zFeedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns zFeedback contents as cell array
%        contents{get(hObject,'Value')} returns selected item from zFeedback

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
global alpha; global run; global I2;

vid = videoinput('avtmatlabadaptor64_r2009b', 1);
vidRes = vid.VideoResolution; nBands = vid.NumberOfBands;
closepreview;  %close preview if still running

while run
    frame = getsnapshot(c.vid);
    close all

    
    tic
    %sharpen image
    f = fspecial('unsharp', 1);
    I1 = imfilter(flipdim(frame,1), f);
    
    %adjust contrast
    %figure 
    Ix = imtophat(flipdim(frame,1),strel('disk',33));
    I2 = imadjust(Ix);
    imshow(I2);
     
    %axes(handles.axes2);
    mserRegions = detectMSERFeatures(I2,'RegionAreaRange',[400 600], 'ThresholdDelta', 0.5,'MaxAreaVariation',0.05);
    hold on;
    
    try
    plot(mserRegions, 'showPixelList', false,'showEllipses',true);
    title('MSER regions'); hold off;
    catch
        disp('Null')
    end
    toc
   
    %edge detection
%     figure
%      BW = edge(I2,'canny');
%      imshow(BW)
     IBW=im2bw(I2,0.5)
    [centers, radii] = imfindcircles(IBW,[12 23])
   viscircles(centers, radii,'EdgeColor','b')
    
    pause(0.5)
end
%close all;
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

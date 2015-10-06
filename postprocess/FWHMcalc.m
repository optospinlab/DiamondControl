function varargout = FWHMcalc(varargin)
% Last Modified by GUIDE v2.5 23-Sep-2015 10:11:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FWHMcalc_OpeningFcn, ...
                   'gui_OutputFcn',  @FWHMcalc_OutputFcn, ...
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

% --- Outputs from this function are returned to the command line.
function varargout = FWHMcalc_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% End initialization code - DO NOT EDIT


% --- Executes just before FWHMcalc is made visible.
function FWHMcalc_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

global pathData; global device; global set;
global OD; global xrange; global yrange; global drange;
global xcur; global ycur; global dcur;
global BG; global A; global X; global Y; global p; global count;

count=0;

% User parameters-----------------------------------------------
% --------------------------------------------------------------
pathData = ['C:\Users\phys\Dropbox\Diamond Room' ... %'\diamondControl\Automation!\2015_9_17\Scan @ 12-49-33.33\'];
            '\diamondControl\Automation!\2015_9_30\Scan @ 23-6-28.09\'];

device = 'd_';
set = 's_';

OD = 1;       %No OD filter

% xrange = [1 3];
% yrange = [0 4];
% drange = [4 11];

xrange = [0 2];
yrange = [1 5];
drange = [0 19];


for i=1:3
    bg(i,:) = readSPE(['C:\Users\phys\Desktop\DiamondControl' ...
        '\Grating Transmission Analysis\2015_9_3\bg' num2str(i) '.spe']);
end

BG=smooth(mean(bg,1),25)';

% Norm_spec(1,:)=readSPE([ pathData 'normalization_spectrum.spe']); 
% Norm_spec=int64(Norm_spec)*OD;
% % --------------------------------------------------------------
% % --------------------------------------------------------------
% 
% Norm=mean(Norm_spec,1)/0.1722529; % From fresnel eqn.
% A=double(1./(Norm-BG));
A = 1;

axes(handles.axes1);

% First Plot

xcur=xrange(1); ycur=yrange(1); dcur=drange(1);

name = [device num2str(dcur) '_' set '['  num2str(xcur) ','  num2str(ycur) ']'];
S=load([pathData name '_spectrum.mat']);

Y=real(sqrt((double(S.spectrum)-BG).*A))*100*OD;
%X=linspace(633.812,640.601,512);
X=linspace(637.2 - 6.789*6/2, 637.2 + 6.789*6/2, 512);

p=plot(X,Y);
title(['device' num2str(dcur) '- Set '  '['  num2str(xcur) '  '  num2str(ycur) ']']);
xlim([X(1) X(512)]);
grid on;

brush on;


% --- Executes on button press in NEXT.
function NEXT_Callback(hObject, eventdata, handles)

global pathData; global device; global set;
global OD; global xrange; global yrange; global drange;
global xcur; global ycur; global dcur;
global BG; global A; global X; global Y;
global p;

flag=0;

button_state = get(hObject,'Value');
if button_state==1
    dcur=dcur+1;
    if dcur > drange(end)
        dcur=drange(1);
        ycur=ycur+1;
        if ycur > yrange(end)
            ycur=yrange(1);
            xcur=xcur+1;
            if xcur > xrange(end)
                disp('reached end of dataset');
                flag=1;
                xcur=0; ycur=0; dcur=0; 
                xrange=[0];yrange=[0];drange=[0];
            end
        end
    end
    
    if ~flag
        name = [device num2str(dcur) '_' set '['  num2str(xcur) ','  num2str(ycur) ']'];
        S=load([pathData name '_spectrum.mat']);

        Y=real(sqrt((double(S.spectrum)-BG).*A))*100*OD;
%         X=linspace(633.812,640.601,512); 
        X=linspace(637.2 - 6.789*6/2, 637.2 + 6.789*6/2, 512);

        p=plot(X,Y);
        title(['device' num2str(dcur) '- Set '  '['  num2str(xcur) '  '  num2str(ycur) ']']);
        xlim([X(1) X(512)]);
        ylim([min(Y)-0.5 max(Y)+0.5]);
        grid on;
    end   
    flag=0;
  set(hObject,'Value',0); %Reset the button state
end

% --- Executes on button press in Calc.
function Calc_Callback(hObject, eventdata, handles)
global FWHM_val; global X; global Y; global a_fit; global contrast;
global lambda; global Qfact; global p;

button_state = get(hObject,'Value');
if button_state==1
    
    dataObjs = get(gca, 'Children');
    lineObjs = findobj(dataObjs, 'type', 'line');
    is_brush = get(lineObjs, 'Brushdata');
    bX = X(find(is_brush==1));
    bY = Y(find(is_brush==1));
    
    if isempty(bX) || isempty(bY)
        disp('No data selected .... try again')
    else

        %rough guess of initial parameters
        %lorentzian is given by: 1/(1+x^2) + a + bx where x=(p-p0)/(w/2) p0->center w->FWHM    
        
%         a3 = 0.6^2;                 % Assume
%         a2 = (max(bX)+min(bX))/2;   % p0
%         a1 = -min(bY)*a3;           % Ymax*(w/2)^2 (Scaling factor)
%         
%         a5 = (bY(1)-bY(end))/(bX(1)-bX(end));
%         a4 = max(bY);

        a3 = (bX(end) - bX(1))/2;                 % Assume
        a2 = (max(bX) + min(bX))/2;   % p0
        a1 = abs(bY(1)-bY(end));           % Ymax*(w/2)^2 (Scaling factor)
        
        a5 = (bY(1)-bY(end))/(bX(1)-bX(end));
        a4 = (bY(1) + bY(end))/2;
        
        a0 = [a1,a2,a3,a4,a5]
        lorentz = @(param, x) param(1) ./ ((2*(x-param(2))./param(3)).^2 + 1) + a4 + a5*(x-a2);
        fit_error = @(param) sum((bY - lorentz(param, bX)).^2);

        % do the fit
        a_fit = fminsearch(fit_error, a0)

        % plot
        hold on;
        x_grid = linspace(min(X), max(X), 1000); % finer grid for interpolation
        plot(x_grid, lorentz(a0, x_grid),'m--');     % original guess
        p = plot(x_grid, lorentz(a_fit, x_grid), 'g','LineWidth',2);  % optimized curve
        FWHM_val = a_fit(3);
        contrast = abs((a_fit(1)/a4)) * 100;
        lambda = a_fit(2);
        Qfact = lambda/FWHM_val;
        set(handles.FWHMout,'String',num2str(FWHM_val));
        set(handles.cpl,'String',num2str(contrast));
        set(handles.Qfactor,'String',num2str(Qfact));
        set(handles.lambda0,'String',num2str(lambda));
        hold off;
        ylim([min(Y)-0.5 max(Y)+0.5]);
    end
    set(hObject,'Value',0); %Reset the button state
end

% --- Executes on button press in clr_btn.
function clr_btn_Callback(hObject, eventdata, handles)
global X; global Y;
global xcur; global ycur; global dcur;

plot(X,Y);
title(['device' num2str(dcur) '- Set '  '['  num2str(xcur) '  '  num2str(ycur) ']']);
xlim([X(1) X(512)]);
ylim([min(Y)-0.5 max(Y)+0.5])
grid on;

% --- Executes during object creation, after setting all properties.
function FWHMout_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function cpl_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Qfactor_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function Qfactor_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function lambda0_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function lambda0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
global xcur; global ycur; global dcur;
global a_fit; global contrast;
global lambda; global Qfact; global FWHM_val;
global p; global count;

count=count+1;

display('Saving...');

filename='C:\Users\phys\Desktop\DiamondControl\fitting\fitting_data.xls';
saveas(p, ['C:\Users\phys\Desktop\DiamondControl\fitting\' 'Fit_device' num2str(dcur) '- Set '  '['  num2str(xcur) '  '  num2str(ycur) ']' num2str(count) '.png']);
A={['['  num2str(xcur) '  '  num2str(ycur) ']'], num2str(dcur), FWHM_val, contrast, lambda, Qfact};
xlswrite(filename,A,1,['A' num2str(count)])

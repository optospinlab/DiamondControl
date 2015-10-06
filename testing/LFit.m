%data
pathData = 'C:\Users\phys\Dropbox\Diamond Room\diamondControl\Automation!\2015_9_17\Scan @ 12-49-33.33\';
device = 'd_';
set = 's_';

x = 1;  xrange = [1 3];
y = 0;  yrange = [0 4];
d = 0;  drange = [4 11];

for i=1:3
    bg(i,:) = readSPE(['C:\Users\phys\Desktop\DiamondControl\Grating Transmission Analysis\2015_9_3\bg' num2str(i) '.spe']);
end
BG=smooth(mean(bg,1),25)';
Norm_spec(1,:)=readSPE([ pathData 'normalization_spectrum.spe']);
Norm=mean(Norm_spec,1)/0.1722529;
A=double(1./(Norm-BG));

load([pathData 'd_7_s_[3,1]_spectrum.mat']);
trans=real(sqrt((double(spectrum)-BG).*A*factor))*100; %No OD

X = linspace(612.5+25.27,612.5+32.17,512);
Y = max(trans)-trans;

% rough guess of initial parameters
%lorentzian is given by: 1/(1+x^2) where x=(p-p0)/(w/2) p0->center w->FWHM

%a3 = ((max(X)-min(X))/10)^2; % (w/2)^2
a3 = 0.2^2; %Assume

%a2 = (max(X)+min(X))/2;      %  p0
a2=640.4; %Get from GUI

%a1 = max(Y)*a3;              % Ymax*(w/2)^2 (Scaling factor)
a1 = 11*a3; % Get from GUI

a0 = [a1,a2,a3];

% define lorentz inline, instead of in a separate file
lorentz = @(param, x) param(1) ./ ((x-param(2)).^2 + param(3));

% define objective function, this captures X and Y
fit_error = @(param) sum((Y - lorentz(param, X)).^2);

% do the fit
a_fit = fminsearch(fit_error, a0);

% quick plot
x_grid = linspace(min(X), max(X), 1000); % fine grid for interpolation
plot(X, Y, x_grid, lorentz(a_fit, x_grid), 'r', x_grid, lorentz(a0, x_grid), 'g')
legend('Measurement', 'Fit')
title(sprintf('a1_fit = %g, a2_fit = %g, a3_fit = %g', ...
    a_fit(1), a_fit(2), a_fit(3)), 'interpreter', 'none')

FWHM = sqrt(a3)*2
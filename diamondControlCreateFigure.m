files = dir('C:\Users\Tomasz\Dropbox\Diamond Room\Anneal Project\data\2016_06_20 Implantation Square Scans', '*.mat');

for n = 1:length(files)
    fname = files(n).name;
    load(fname);
    figure;
    surf(xrange,yrange,data);
    view([0 90]);
    shading flat;
    xlabel('Voltage');
    ylabel('Voltage');
    colorbar;
    
    [path,name,ext] = fileparts(fname);
    saveFname = [path name '_figure.fig'];
    
    savefig(saveFname)
    
    bigdata = zeros(200,200);
end



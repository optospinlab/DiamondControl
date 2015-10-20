function convertFDTD(fileIn, fileOut)
    X = tdfread(fileIn, '\t');
    
    x = X.data; %log(X.data);
    
%     x = x(451:end, :);
    
%     nw = 72;
%     w = 256 - nw;
    
    nw = 240;
    w = 256 - nw;
    
%     map = [ [linspace(1,1,w) linspace(1,.5,nw/2) linspace(.5,1,nw/4) linspace(1,1,nw/4)]' [linspace(1,1,w) linspace(1,.75,nw/2) linspace(.75,0,nw/2)]' [linspace(1,1,w + nw/4) linspace(1,0,nw/2) linspace(0,0,nw/4)]']
%     map = [ [linspace(1,1,256)]' [linspace(1,1,128) linspace(1,1,64) linspace(1,0,64)]' [linspace(1,1,128) linspace(1,0,64) linspace(0,0,64)]'] % linspace(1,0,nw/4) linspace(0,1,nw/4) 
%     map = [ [linspace(1,1,256)]' [linspace(1,1,w) linspace(1,.95,nw/3) linspace(.95,.65,nw/2) linspace(.65,0,nw/6)]' [linspace(1,1,w) linspace(1,.5,nw/4) linspace(.5,0,nw/4) linspace(0,0,nw/2)]'] % linspace(1,0,nw/4) linspace(0,1,nw/4) 
    map = [ [linspace(0,1,nw/2) linspace(1,1,w+nw/2)]' [linspace(0,1,nw/2) linspace(1,1,w) linspace(1,0,nw/2)]' [linspace(1,1,w+nw/2) linspace(1,0,nw/2)]']; % linspace(1,0,nw/4) linspace(0,1,nw/4) 
    
    imwrite(256*(x-min(min(x)))/(max(max(x))-min(min(x))), map, fileOut);
end
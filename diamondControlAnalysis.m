function diamondControlAnalysis
% LOADING FILES
filelist = {'_piezo_debug.png'; '_galvo.png'; '_galvo_debug.png'; '_galvo.mat'; '_spectrum.mat'};

% [fileNorm, pathNorm] = uigetfile('','Select a file in the folder for analysis')

pathNorm = '/Users/I/Desktop/Scan @ 16-7-19.188/'

device = 'd_';
set = 's_';

x = 0;  xrange = [0 3];
y = 0;  yrange = [0 4];
d = 1;  drange = [1 5];

final = cell(getDiff(xrange), getDiff(yrange), getDiff(drange), sum(size(filelist))-1);

for x = getArr(xrange)
    for y = getArr(yrange)
        for d = getArr(drange)
            name = [device num2str(d) '_' set '['  num2str(x) ','  num2str(y) ']'];
            for i = 1:(sum(size(filelist))-1)
                suffix = filelist{i};
                %[name suffix]
                switch suffix(end-2:end)
                    case 'mat'
                        final{x-xrange(1)+1, y-yrange(1)+1, d-drange(1)+1, i} = load([pathNorm name suffix]);
                    case 'png'
                        final{x-xrange(1)+1, y-yrange(1)+1, d-drange(1)+1, i} = imread([pathNorm name suffix]);
                end
            end
        end
    end
end

igoreEverythingExcept('fishyfishyfish', 'i')

function d = getDiff(range)
    d = range(2) - range(1) + 1;
end
function arr = getArr(range)
    arr = range(1):range(2);
end

function str = igoreEverythingExcept(everything, except)
    % There's probably a better way to do this in matlab, but I don't have
    % internet right now...
    str = '';
    
    for char = everything
        isExcept = false;
        for char2 = except
            isExcept = isExcept || (char2 == char);
        end
        
        if isExcept
            str = [str char];
        end
    end
end

% ANALYZING FILES

end
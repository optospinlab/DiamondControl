function readFiles(parentDirectory, outputXLS)
    cellArr = recursion(cell(1), parentDirectory, 1, 1);
    
    xlswrite(outputXLS, cellArr);
end

function [cellArr, nx, ny] = recursion(cellArr, parentDirectory, x, y)
    directory = dir(parentDirectory);
    for ii = 1:length(directory)
        file = directory(ii).name;
        display(['' file]);

%         strfind(file, '.mat')
        
        if ~isempty(strfind(file, '.mat'))   % Find .mat files.
            data = load([parentDirectory '\' file]);
            
            cellArr{y,x} = file;
            cellArr{y,x+1} = file(2);
            cellArr{y,x+2} = file(end-4);
            cellArr{y,x+3} = max(max(data.data));
            y = y + 1;
        elseif isempty(strfind(file, '.'))   % Find folders.
            cellArr{y,x} = file;
            [cellArr, ~, y] = recursion(cellArr, [parentDirectory '\' file], x+1, y);
        end
    end
    
    nx = x;
    ny = y;
end


function varargout = diamondControl(varargin)
    if ~isempty(varargin)
        diamondControlGUI(varargin);
    else
        f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');
        diamondControlGUI('Parent', f);
    end
    
    
    
    % main();
    
    function main()
        while c.running
            
        end
    end

    % Box Stuff =====
    function calculateBox()
        if c.boxCurr(3) ~= c.boxPrev(3) && c.boxCurr(3) ~= 0 && c.boxPrev(3) ~= 0
            type = mod(c.boxCurr(3) - c.boxPrev(3), 4);
            
            v1 = c.boxPrev(1:2);
            v2 = c.boxCurr(1:2);
            
            switch type
                case 0      % This should not happen becasue of our first if
                    error('renderBox error; something is terribly wrong!');
                case [1 3]  % If points are on one side...
                    if type == 3
                        v1 = c.boxCurr(1:2);
                        v2 = c.boxPrev(1:2);
                    end
                    
                    ortho = [0, 1; -1, 0]*(v2 - v1);
                    
                    c.BoxX(1) = v1(1);
                    c.BoxX(2) = v2(1);
                    c.BoxX(3) = v2(1) + ortho(1);
                    c.BoxX(4) = v1(1) + ortho(1);
                    c.BoxX(5) = v1(1);
                    
                    c.BoxY(1) = v1(2);
                    c.BoxY(2) = v2(2);
                    c.BoxY(3) = v2(2) + ortho(2);
                    c.BoxY(4) = v1(2) + ortho(2);
                    c.BoxY(5) = v1(2);
                    
                    c.BoxX(1) = v1(1);
                case 2      % If points are across the diagonal...
                    ortho = [0, 1; -1, 0]*(v2 - v1);
                    
                    c.BoxX(1) = v1(1);
                    c.BoxX(2) = (v1(1) + v2(1) + ortho(1))/2;
                    c.BoxX(3) = v2(1);
                    c.BoxX(4) = (v1(1) + v2(1) - ortho(1))/2;
                    c.BoxX(5) = v1(1);
                    
                    c.BoxY(1) = v1(2);
                    c.BoxY(2) = (v1(2) + v2(2) + ortho(1))/2;
                    c.BoxY(3) = v2(2);
                    c.BoxY(4) = (v1(2) + v2(2) - ortho(1))/2;
                    c.BoxY(5) = v1(2);
                    
                    c.BoxX(1) = v1(1);
            end
        end
    end
    
    function renderUpper()
        plot(axesUpper, c.boxX, c.boxY);
    end
end


function varargout = diamondControl(varargin)
    if ~isempty(varargin)
        c = diamondControlGUI(varargin);
    else
        f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');
        c = diamondControlGUI('Parent', f);
    end
    
global pw; global puh; global pmh; global plh; global bp; global bw; global bh; global gp;
    
    set(c.boxTL, 'Callback', @box_Callback);
    set(c.boxTR, 'Callback', @box_Callback);
    set(c.boxBL, 'Callback', @box_Callback);
    set(c.boxBR, 'Callback', @box_Callback);
    
    set(c.gotoButton, 'Callback', @goto_Callback);
    
    set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
    set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
    
    set(c.mouseEnabled, 'Callback', @mouseEnabled_Callback);
    
    % We do resizing programatically =====
    set(c.parent, 'ResizeFcn', @resizeUI_Callback);
    
    renderUpper();
    
    set(c.parent, 'Visible', 'On');
    
%     main();
%     
%     function main()
%         while c.running
%             pause(.5);
%             tick();
%         end
%     end
% 
%     function tick()
%         display('here');
%         renderUpper();
%     end

    % Box Stuff =====
    function mouseEnabled_Callback(hObject, ~)
        if get(c.mouseEnabled, 'Value')
            set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
        else
            set(c.upperAxes, 'ButtonDownFcn', '');
        end
    end
    function goto_Callback(hObject, ~)
        c.linAct = [str2double(get(c.gotoX, 'String')) str2double(get(c.gotoY, 'String'))];
        renderUpper();
    end
    function click_Callback(hObject, ~)
        set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
        set(c.lowerAxes, 'ButtonDownFcn', @click_Callback);
        
        if strcmp(get(c.parent, 'SelectionType'), 'alt')
            if c.axesMode == 0
                if hObject == c.upperAxes
                    c.axesMode = 1
                    set(c.lowerAxes, 'Visible', 'Off');
                    set(get(c.lowerAxes,'Children'), 'Visible', 'Off');
                else
                    c.axesMode = 2
                    set(c.upperAxes, 'Visible', 'Off');
                    set(get(c.upperAxes,'Children'), 'Visible', 'Off');
                end
            else
                c.axesMode = 0
                set(c.upperAxes, 'Visible', 'On');
                set(c.lowerAxes, 'Visible', 'On');
                set(get(c.upperAxes,'Children'), 'Visible', 'On');
                set(get(c.lowerAxes,'Children'), 'Visible', 'On');
            end

            resizeUI_Callback();
        elseif strcmp(get(c.parent, 'SelectionType'), 'normal') && hObject == c.upperAxes
            x = get(c.upperAxes,'CurrentPoint');
            c.linAct = x(1,1:2);
            renderUpper();
        end
    end
    function box_Callback(hObject, ~)
        switch hObject
            case c.boxTL
                type = 1;
            case c.boxTR
                type = 2;
            case c.boxBL
                type = 4;
            case c.boxBR
                type = 3;
            otherwise
                type = 0;
        end
        
        c.boxPrev = c.boxCurr;
        c.boxCurr = [c.linAct(1) c.linAct(2) type];
        
        calculateBox();
    end
    function calculateBox()
        if c.boxCurr(3) ~= c.boxPrev(3) && c.boxCurr(3) ~= 0 && c.boxPrev(3) ~= 0
%             c.boxPrev;
%             c.boxCurr;
            
            type = mod(c.boxCurr(3) - c.boxPrev(3), 4);
            
            v1 = c.boxPrev(1:2);
            v2 = c.boxCurr(1:2);
            
            switch type
                case 0      % This should not happen becasue of our first if
                    error('renderBox error; something is terribly wrong!');
                case {1, 3}  % If points are on one side...
                    if type == 3
                        v1 = c.boxCurr(1:2);
                        v2 = c.boxPrev(1:2);
                    end
                    
                    ortho = ([0, 1; -1, 0]*(v2 - v1)')';
                    
                    c.boxX(1) = v1(1);
                    c.boxX(2) = v2(1);
                    c.boxX(3) = v2(1) + ortho(1);
                    c.boxX(4) = v1(1) + ortho(1);
                    c.boxX(5) = v1(1);
                    
                    c.boxY(1) = v1(2);
                    c.boxY(2) = v2(2);
                    c.boxY(3) = v2(2) + ortho(2);
                    c.boxY(4) = v1(2) + ortho(2);
                    c.boxY(5) = v1(2);
                case 2      % If points are across the diagonal...
                    ortho = ([0, 1; -1, 0]*(v2 - v1)')';
                    
                    c.boxX(1) = v1(1);
                    c.boxX(2) = (v1(1) + v2(1) + ortho(1))/2;
                    c.boxX(3) = v2(1);
                    c.boxX(4) = (v1(1) + v2(1) - ortho(1))/2;
                    c.boxX(5) = v1(1);
                    
                    c.boxY(1) = v1(2);
                    c.boxY(2) = (v1(2) + v2(2) + ortho(2))/2;
                    c.boxY(3) = v2(2);
                    c.boxY(4) = (v1(2) + v2(2) - ortho(2))/2;
                    c.boxY(5) = v1(2);
            end
        else
            c.boxX = [-1 -1 -1 -1 -1];
            c.boxY = [-1 -1 -1 -1 -1];
        end
        
        renderUpper();
    end    
    function renderUpper()
        if c.axesMode ~= 2
%             if sum(c.boxX ~= -1) ~= 0 % If the vals are not all -1...
                p = plot(c.upperAxes, c.boxX, c.boxY, ':r', c.linAct(1), c.linAct(2), 'dk', c.boxPrev(1), c.boxPrev(2), 'pr', c.boxCurr(1), c.boxCurr(2), 'hr');
%                 set(c.upperAxes, 'HitTest', 'off');
                if get(c.mouseEnabled, 'Value')
                    set(c.upperAxes, 'ButtonDownFcn', @click_Callback);
                end
                set(get(c.upperAxes,'Children'), 'ButtonDownFcn', '');
                set(get(c.upperAxes,'Children'), 'HitTest', 'off');
                
               
%             else
%                 plot(c.upperAxes, c.linAct(1), c.linAct(2), 'd');
%             end

            xlim(c.upperAxes, [0 25]);
            ylim(c.upperAxes, [0 25]);
        end
    end
    function resizeUI_Callback(~, ~)
        display('here');
        p = get(c.parent, 'Position');
        w = p(3); h = p(4);

        % Axes Position =====
        display(c.axesMode);
        if c.axesMode == 0 % Both
            if (w-pw-2*gp < (h-3*gp)/2) % If Width is limiting
                S = w-pw-2*gp;
                set(c.lowerAxes,    'Position', [gp ((h/4)-(S/2)) S S]);
                set(c.upperAxes,    'Position', [gp ((3*h/4)-(S/2)) S S]);
            else                        % If Height is limiting
                S = (h-3*gp)/2;
                set(c.lowerAxes,    'Position', [(w-pw-S)/2 gp S S]);
                set(c.upperAxes,    'Position', [(w-pw-S)/2 2*gp+S S S]);
            end
        else
            if (w-pw-2*gp < h-2*gp)     % If Width is limiting
                S = w-pw-2*gp;
            else                        % If Height is limiting
                S = h-2*gp;
            end

            if c.axesMode == 1  % Upper only
                set(c.upperAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
            else                % Lower only
                set(c.lowerAxes,    'Position', [(w-pw-S)/2 (h-S)/2 S S]);
            end
        end

        % Panel Position =====
        set(c.statusPanel,      'Position', [w-pw h-puh pw puh]);
        set(c.controlPanel,     'Position', [w-pw h-puh-pmh pw pmh]);
        set(c.automationPanel,  'Position', [w-pw h-puh-pmh-plh pw plh]);
    end
end





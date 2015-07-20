function [V, V0, v, nxrange, nyrange, ndrange] = generateGrid()
    nxrange = [nxmin nxmax];    % Range of the major grid
    nyrange = [nymin nymax];
    
    ndrange = [ndmin ndmax];    % Range of the minor grid
    
    % These vectors will be used to make our major grid
    V1 = [x1 y1 z1]';    n1 = [nx1 ny1]';    % [x y z] - the position of the device in um;
    V2 = [x2 y2 z2]';    n2 = [nx2 ny2]';    % [nx ny] - the position of the device in the major grid.
    V3 = [x3 y3 z3]';    n3 = [nx3 ny3]';    % Fill in later! All of these coordinates will be loaded from the GUI...
    
    % This vector will be used to determine our device spacing inside one
    % grid.
    V4 = [x4 y4 z4]';    n4 = [nx4 ny4]';
    
    nd123 = nd123;  % The number of the device in the minor grid for 1,2,3
    nd4 = nd4;      % The number of the device in the minor grid for 4
    
    if ~dot(V2(1:2) - V1(1:2), V3(1:2) - V1(1:2))
        error('Position vectors are not orthogonal!');
    end
    
    if ~dot(n2 - n1, n3 - n1)
        error('Grid vectors are not orthogonal!');
    end
    
    % Find the V0 = [x y] of n0 = [0 0]
    V0 = V1 - dot(n1, n2-n1)*V2 - dot(n1, n3-n1)*V3;
    
    % Find the horizontal major grid vector from [0 0] to [1 0] in um
    Vx = (V1 - dot(n1-[1 0]', n2-n1)*V2 - dot(n1-[1 0]', n3-n1)*V3) - V0;
    
    % Find the vertical major grid vector from [0 0] to [0 1] in um
    Vy = (V1 - dot(n1-[0 1]', n2-n1)*V2 - dot(n1-[0 1]', n3-n1)*V3) - V0;
    
    % Structure the major grid in matrix form
    V = [Vx Vy];
    
    % Check to make sure V1, V2, V3 are recoverable...
    if (V1 ~= V*n1 + V0 || V2 ~= V*n2 + V0 || V3 ~= V*n3 + V0)
        error('Math is wrong... D:');
    end
    
    v = (V4 - (V*n4 + V0))/(nd4 - nd123);   % Direction of the linear minor grid. Note that z might be off...
    
    p = zeros(2, diff(nxrange)*diff(nyrange)*diff(ndrange));
    
    i = 1;
    
    for x = nxrange(1):nxrange(2)
        for y = nyrange(1):nyrange(2)
            for d = ndrange(1):ndrange(2)
                p(:,i) = V*([x y]') + V0 + d*v;
                
                i = i + 1;
            end
        end
    end
    
    scatter(UNNAMEDPLOT, p(1,:), p(2,:));
end

function automate(varin)
    [V, V0, v, nxrange, nyrange, ndrange] = varin;
    
    i = 1;
    
    c = clock;
    
    prefix = [num2str(c(1)) '_' num2str(c(2)) '_' num2str(c(3)) '_'];
    
    for x = nxrange(1):nxrange(2)
        for y = nyrange(1):nyrange(2)
            for d = ndrange(1):ndrange(2)
                GOTO(V*([x y]') + V0 + d*v);
                
                while GET() ~= V*([x y]') + V0 + d*v
                    pause(.1);
                end
                
                OPTIMIZE();
                
                GALVOSCAN();
                
                OPTIMIZE?();
                
                scan = GALVOSCAN();
                
                save([prefix 'device_' num2str(d) '@[' num2str(x) ',' num2str(y) '].mat'], 'scan');
                
                i = i + 1;
            end
        end
    end
    
    
end





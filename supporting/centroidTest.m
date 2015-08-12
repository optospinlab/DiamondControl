function centroidTest()
    data = load('C:\Users\phys\Dropbox\Diamond Room\Automation!\2015_7_23\Scan @0_39_30.823\device_1_set_[0,3]_galvo.mat');
    

    
    function [x, y] = myMean(data, X, Y)
        % New Method
        dim = size(data);
    
        data = imdilate(data, strel('diamond', 1));

        [labels, ~] = bwlabel(data, 8);
        measurements = regionprops(labels, 'Area', 'Centroid');
        areas = [measurements.Area];
        [~, indexes] = sort(areas, 'descend');

        centroid = measurements(indexes(1)).Centroid;

        x = linInterp(1, min(X), dim(2), max(X), centroid(1));
        y = linInterp(1, min(Y), dim(1), max(Y), centroid(2));
    
        % Old Method
        % Calculates the centroid.
%         total = sum(sum(data));
%         dim = size(data);
%         x = sum(data*((X((length(X)-dim(2)+1):end))'))/total;
%         y = sum((Y((length(Y)-dim(1)+1):end))*data)/total;
    end

    function y = linInterp(x1, y1, x2, y2, x)    % Perhaps make it a spline in the future...
        if x1 < x2
            y = ((y2 - y1)/(x2 - x1))*(x - x1) + y1;
        elseif x1 > x2
            y = ((y1 - y2)/(x1 - x2))*(x - x2) + y2;
        else
            y = (y1 + y2)/2;
        end
    end

end
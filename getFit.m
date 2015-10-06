function fit = getFit(x, y)
    sin2 = @(param, x) 100*(sin(param(1).*x + param(2)).^2);
    error = @(param) sum((y - sin2(param, x)).^2);
    fit = fminsearch(error, [0 0]);
end


function varargout = diamondControlWrapper(varargin)
    f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');

    diamondControl('Parent', f);
end





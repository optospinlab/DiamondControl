% Although DiamondControl.m can call itself, this file demonstrates how
% Diamond Control can be incorperated into another project. One simply
% needs to define a Parent for DiamondControl and the UI/etc will be
% created there. For instance, one could define a uitab to be the Parent.
function varargout = diamondControlWrapper(varargin)
    f = figure('Visible', 'off', 'tag', 'Diamond Control', 'Name', 'Diamond Control', 'Toolbar', 'figure', 'Menubar', 'none');

    diamondControl('Parent', f);
end





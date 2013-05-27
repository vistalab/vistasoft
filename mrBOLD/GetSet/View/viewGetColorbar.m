function val = viewGetColorbar(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param

    case 'twparams' 
        % Return travelling wave parameters.
        %   twparams = viewGet(vw, 'Travelling Wave Parameters');        
        val = retinoGetParams(vw);        
    case 'cmap'
        % Return the colormap for whichever data view (co, ph, amp, map) is
        % currently selected.
        %   cmap = viewGet(vw, 'color map');
        val = vw.ui.([vw.ui.displayMode 'Mode']).cmap;
    case 'cmapcolor'
        % Return color portion of current color overlay map.
        %   cmapColor = viewGet(vw, 'cmap color');
        val = viewGet(vw, 'cmap');
        nGrays = vw.ui.([vw.ui.displayMode 'Mode']).numGrays;
        val = val(nGrays+1:end,:);
    case 'cmapgrayscale'
        % Return grayscale portion of current color overlay map
        %   cmapGray = viewGet(vw, 'cmap grayscale');
        val = viewGet(vw, 'cmap');
        nGrays = vw.ui.([vw.ui.displayMode 'Mode']).numGrays;
        val = val(1:nGrays,:);
        
    
        otherwise
        error('Unknown viewGet parameter');
        
end

return

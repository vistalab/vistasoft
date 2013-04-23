function vw = viewSetVolume(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

switch param
    
    case {'nodes' 'edges' 'allleftnodes' 'allleftedges' ...
            'allrightnodes' 'allrightedges'}
        
        % Vol/Gray check
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            error(['Can only set %s property in ' ...
                'Volume / Gray views.'], param);
        end
        
        switch lower(param)
            case 'nodes',           vw.nodes = val;
            case 'edges',           vw.edges = val;
            case 'allleftnodes',	vw.allLeftNodes  = val;
            case 'allleftedges', 	vw.allLeftEdges  = val;
            case 'allrightnodes',   vw.allRightNodes = val;
            case 'allrightedges',	vw.allRightEdges = val;
        end
        
    case 'coords'
        % Vol/Gray/Flat check
        if ~ismember(vw.viewType, {'Volume' 'Gray' 'Flat'})
            error(['Can only set %s property in ' ...
                'Volume / Gray / Flat views.'], param);
        else
            vw.coords = val;
        end
        
    case 'mmpervox'
        vw.mmPerVox = val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return
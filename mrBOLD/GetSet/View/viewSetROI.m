function vw = viewSetROI(vw,param,val,varargin)
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
    
    case 'roi'
        vw = loadROI(vw, val);
    case 'rois'
        % Set ROI field in view struct. ROIs should be a struct.
        % Example: vw = viewSet(vw, 'ROIs', rois);
        vw.ROIs = val;
    case 'selectedroi'
        vw = selectROI(vw, val);
    case 'selroicolor'
        % Set the color of the currently selected or the requested ROI.
        % This can be a Matlab character for a color ('c', 'w', 'b', etc)
        % or an RGB triplet.
        %   vw = viewSet(vw, 'Selected ROI color', [1 0 0]);
        %   roi = 1; col = 'r'; vw = viewSet(vw, 'Selected ROI color', col, roi);
        if isempty(varargin) || isempty(varargin{1}),
            roi = vw.selectedROI;
        else
            roi = varargin{1};
        end
        vw.ROIs(roi).color = val;
    case 'roioptions'
        if ~isempty(val) && isstruct(val)
            vw = roiSetOptions(vw,val);
        else
            vw = roiSetOptions(vw);
        end
    case 'filledperimeter'
        vw.ui.filledPerimeter = val;
    case 'maskrois'
        vw.ui.maskROIs = val;
    case 'roivertinds'
        msh  = viewGet(vw, 'currentmesh');
        if isempty(msh), return; end
        
        % Parse varargin for ROIs and prefs
        if isempty(varargin) || isempty(varargin{1}),
            roi = vw.selectedROI;
        else
            roi = varargin{1};
            if isstruct(varargin{end}) && isfield(varargin{end}, 'layerMapMode');
                prefs = varargin{end};
            else
                prefs = mrmPreferences;
            end
        end
        % get ROI mapMode
        if isequal(prefs.layerMapMode, 'layer1'), roiMapMode = 'layer1';
        else roiMapMode = 'any';  end
        vw.ROIs(roi).roiVertInds.(msh.name).(roiMapMode) = val;
        
    case 'showrois'
        % Select one or more ROIs to show on meshes
        %   -2 = show all ROIs
        %   -1 = show selected ROIs
        %    0 = hide all ROIs
        %   >0 = show those ROIs (e.g., if showROIs = [1 3], then show ROIs
        %           1 and 3).
        % Examples:
        %   vw = viewSet(vw, 'Show ROIs', [1 2]) % show ROIs 1 and 2
        %   vw = viewSet(vw, 'Show ROIs', -2)    % show all ROIs
        if ~checkfields(vw, 'ui'), vw.ui = []; end;
        vw.ui.showROIs = val;
        
    case 'hidevolumerois'
        % Specifiy whether to show ROIs in volume or gray view. We
        % sometimes choose not to show them because if we click around in
        % the GUI, redrawing the ROIs can be slow.
        %
        % Examples:
        %   vw = viewSet(vw, 'Hide Volume ROIs', true)
        %   vw = viewSet(vw, 'Hide Volume ROIs', false)
        if ~checkfields(vw, 'ui'), vw.ui = []; end
        vw.ui.hideVolumeROIs = val;
        
    case 'roidrawmethod'
        % Specify how the ROIs will be visualized. 
        % Options:
        % 'perimeter'               % outlined ROI
        % 'filled perimeter'        % outlined ROI, but thicker 
        % 'boxes'                   % filled in ROI
        % 'patches'                 % translucent patches
        % 
        % Examples: 
        %   vw = viewSet(vw, 'roidrawmethod', 'filled perimeter')
        if ~checkfields(vw, 'ui'), vw.ui = []; end
        vw.ui.roiDrawMethod = val;
    case 'roiname'
        if isempty(varargin) || isempty(varargin{1})
            roi = vw.selectedROI;
        else
            roi = varargin{1};
        end
        vw.ROIs(roi).name = val;
    case 'roicoords'
        if isempty(varargin)||isempty(varargin{1}), roi = vw.selectedROI;
        else                                        roi = varargin{1}; end
        
        vw.ROIs(roi).coords = val;
        
    case 'roimodified'
        if isempty(varargin)||isempty(varargin{1}), roi = vw.selectedROI;
        else                                        roi = varargin{1}; end
        vw.ROIs(roi).modified = val;
        
    case 'roicomments'
        if isempty(varargin) || isempty(varargin{1})
            roi = vw.selectedROI;
        else
            roi = varargin{1};
        end
        vw.ROIs(roi).comments = val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return
function val = viewGetROI(vw,param,varargin)
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
%
% Wandell says we should use roiGet/Set/Create and have this function call
% those.  THe reason is so that we can interact with ROIs and not have to
% require a whole vw object.
%
% Vistasoft Team, many years ago.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'rois'
        % Return ROIs as struct. Includes all ROIs and all fields
        %   ROIs = viewGet(vw, 'ROIs', [roiVector]);
        if  ~isempty(varargin), % check whether user specified ROIs
            val = vw.ROIs(varargin{1});
        else
            val = vw.ROIs;
        end
    case 'roistruct'
        % Return selected or specified ROI as struct.
        %   ROI = viewGet(vw, 'ROI struct');
        %   ROI = viewGet(vw, 'ROI struct', 1);
        if  ~isempty(varargin), % check whether user specified the ROI
            selectedROI = varargin{1};
        else % if not look up the currently selected ROI in the view struct
            if ~viewGet(vw, 'selected ROI'), val = []; return;
            else selectedROI = viewGet(vw, 'selected ROI'); end
        end
        val = vw.ROIs(selectedROI);
    case 'roicoords'
        % Return the coordinates of the currently selected or the specified
        % ROI
        %   roiCoords = viewGet(vw, 'ROI coords');
        %   ROI = 1; roiCoords = viewGet(vw, 'ROI coords', ROI);
        if isempty(varargin) || isempty(varargin{1})
            val = vw.ROIs(vw.selectedROI).coords;
        else
            ROI = varargin{1};
            if isstruct(ROI), val = ROI.coords;
            else val = vw.ROIs(ROI).coords;
            end
        end
    case 'roiindices'
        % Return the indices of all voxels in the currently selected or the
        % specified ROI. Only implemented for gray / vol view. Could be
        % implemented for other views.
        %   roiIndices = viewGet(vw, 'ROI indices');
        %   ROI = 1; roiIndices = viewGet(vw, 'ROI indices', ROI);
        viewType = viewGet(vw, 'viewType');
        switch lower(viewType)
            case {'gray', 'volume'}
                if isempty(varargin) || isempty(varargin{1})
                    roicoords = viewGet(vw,  'roicoords');
                else
                    roicoords = viewGet(vw,  'roicoords', varargin{1});
                end
                
                % We need to be careful using intersectCols because it
                % sorts the data.
                [commonCoords, indROI, val] = intersectCols(roicoords, vw.coords); %#ok<*ASGLU>
                [tmp, inds] = sort(indROI);
                val = val(inds);
                
            otherwise
                warning('vista:viewError', 'Only implemented for gray or volume view');
                val = [];
        end
    case 'roivertinds'
        % Return mesh indices for each voxel in a gray view ROI
        %   roiVertexIndices = ...
        %           viewGet(vw, 'ROI Vertex Indices', [ROI],[mrmPrefs]);
        switch length(varargin)
            case 0
                val = roiGetMeshVertexIndices(vw);
            case 1
                val = roiGetMeshVertexIndices(vw, varargin{1});
            case 2
                val = roiGetMeshVertexIndices(vw, varargin{1}, varargin{2});
            otherwise
                val = roiGetMeshVertexIndices(vw, varargin{1}, varargin{2});
        end
    case 'roiname'
        % Return the name of the currently selected or the requested ROI.
        %   roiName = viewGet(vw, 'ROI name');
        %   roi = 1; roiName = viewGet(vw, 'ROI name', roi);
        if isempty(varargin) || isempty(varargin{1}), roi = vw.selectedROI;
        else                                          roi = varargin{1};end
        if numel(vw.ROIs) == 0, val = [];
        else                    val = vw.ROIs(roi).name;        end
        
    case 'roicomments'
        % Return the comments of the currently selected or the requested ROI.
        %   roiComments = viewGet(vw, 'ROI comments');
        %   roi = 1; roiComments = viewGet(vw, 'ROI comments', roi);
        if isempty(varargin) || isempty(varargin{1}), roi = vw.selectedROI;
        else                                          roi = varargin{1};end
        if numel(vw.ROIs) == 0, val = [];
        else                    val = vw.ROIs(roi).comments;   end
        
    case 'roimodified'
        % Return the modification date of the currently selected or the
        % requested ROI.
        %   roiName = viewGet(vw, 'ROI modified');
        %   roi = 1; roiName = viewGet(vw, 'ROI modified', roi);
        if isempty(varargin) || isempty(varargin{1}), roi = vw.selectedROI;
        else                                          roi = varargin{1};end
        if numel(vw.ROIs) == 0, val = [];
        else                    val = vw.ROIs(roi).modified; end
        
    case 'allroinames'
        % Return a cell array of the names of all currently loaded ROIs.
        %   roiNames = viewGet(vw, 'All ROI names');
        ROIs = viewGet(vw, 'ROIs');
        if isempty(ROIs), val = [];
        else
            val = cell(1, length(ROIs));
            for ii = 1:length(ROIs)
                val{ii} = vw.ROIs(ii).name;
                if isempty(val{ii})
                    % enforce char output
                    val{ii} = '';
                end
            end
        end
    case 'nrois'
        % Return the number of currently loaded ROIs.
        %   nrois = viewGet(vw, 'n ROIs');
        ROIs = viewGet(vw, 'ROIs');
        if isempty(ROIs), val = 0;
        else              val = length(ROIs); end
    case 'selectedroi'
        % Return the number of the currently selected ROI.
        %   selectedROI = viewGet(vw, 'Selected ROI');
        val = vw.selectedROI;
    case 'filledperimeter'
        % Return the value of the field "filledPerimeter". Not sure exactly
        % how this works, but we think this field is 1 if ROIs are drawn as
        % filled perimeter and 0 if not, but perhaps it can take other
        % values?
        %   filledPerimeter = viewGet(vw, 'filled perimeter');
        if ~checkfields(vw,'ui','filledPerimeter'), val = []; return;
        else  val = vw.ui.filledPerimeter; end
    case 'selroicolor'
        % Return the color of the currently selected or the requested ROI.
        % This can be a Matlab character for a color ('c', 'w', 'b', etc)
        % or an RGB triplet.
        %   selcol = viewGet(vw, 'Selected ROI color');
        %   roi = 1; selcol = viewGet(vw, 'Selected ROI color', roi);
        if isempty(varargin) || isempty(varargin{1}), roi = vw.selectedROI;
        else                                          roi = varargin{1};
        end
        if isfield(vw, 'ROIs') && ~isempty(vw.ROIs)
            val = vw.ROIs(roi).color;
        else
            val = [1 1 1]; % default
        end
    case 'prevcoords'
        % Return the coords of the previous ROI state.
        % But what does this mean? How does it work?
        %   prevCoords = viewGet(vw, 'previous coords');
        val = vw.prevCoords;
    case 'roistodisplay'
        % Return the number of each ROI that has been selected to be
        % displayed. This can be one ROI only (the currently selected ROI),
        % all ROIs, or a subset. A vector of index values is returned.
        % See roiSetOptions for an explanation of this format.
        %   roisToDisplay = viewGet(vw, 'ROIs To Display');
        if isempty(vw.ROIs), val = [];  % no ROIs to show
        elseif ~checkfields(vw, 'ui', 'showROIs'), val = 1:length(vw.ROIs);
        elseif vw.ui.showROIs==0, val = [];  % hide ROIs
        elseif all(vw.ui.showROIs > 0),
            % manual list
            val = vw.ui.showROIs;
        elseif vw.ui.showROIs==-1, val = vw.selectedROI;    % show selected
        elseif vw.ui.showROIs==-2, val = 1:length(vw.ROIs); % show all
        else  error('Invalid ROI specification.');
        end
        % for the 'manual list' option, catch the case where the manually-specified
        % list no longer matches the # of ROIs loaded. (This can happen
        % a lot). Default back to showing all ROIs
        if all(viewGet(vw, 'showROIs') > 0) && ...
                ~isempty( setdiff(val, 1:length(vw.ROIs)) )
            warning('vista:viewError', ['Manual ROI list selected, but the list doesn''t ' ...
                'match the loaded ROIs. Defaulting to showing ' ...
                'all ROIs. '])
            val = 1:length(vw.ROIs);
            if ismember( vw.name(1:4), {'INPL' 'VOLU' 'FLAT'} )
                vw.ui.showROIs = -2;
                updateGlobal(vw);
            end
        end
        
    case 'roidrawmethod'
        % Return the method for drawing ROIs, such as 'perimeter',
        % 'filledPerimeter'.
        %   ROIdrawMethod = viewGet(vw, 'ROI Draw Method');
        if ~checkfields(vw, 'ui', 'roiDrawMethod')
            val = []; return
        else
            val = vw.ui.roiDrawMethod;
        end
    case 'showrois'
        % Return the boolean to indicate whether ROIs are drawn or hidden.
        % Applies to views such as Volume, Gray, Inplane, Flat, and also
        % meshes.
        % [OK, not quite a Boolean because I see that values can be -2, for
        % example. What are all the possible values and what do they mean?]
        %   showROIs = viewGet(vw, 'Show ROIs');
        if ~checkfields(vw, 'ui', 'showROIs')
            val = []; return
        else
            val = vw.ui.showROIs;
        end
    case 'hidevolumerois'
        % Return the Boolean 'hideVolumeROIs'. If true, then ROIs in
        % Gray/Volume view are not drawn (but ROIs on meshes may still be
        % drawn.) The reason we might want to do this is because redrawing
        % ROIs in the Volume view can be very slow. This field works
        % indepently from the field 'showROIs', which controls whether ROIs
        % are displayed in any view and on meshes. So if showROIs is true
        % and hideVolumeROIs is false, ROIs will show on a mesh, an inplane
        % view, or a flat view, but not a Gray/Volume view. If showROIs is
        % false, no ROIs will be shown anywhere.
        %   hidevolumerois = viewGet(vw, 'Hide Volume ROIs');
        if ~checkfields(vw, 'ui', 'hideVolumeROIs')
            val = false; return
        else
            val = vw.ui.hideVolumeROIs;
        end
    case 'maskrois'
        % Return the Boolean 'maskROIs'. If maskROIs is true, then maps
        % that are displayed on meshes are masked out everywhere outside of
        % the currently displayed ROIs. The currently displayed ROIs might
        % be just the currently selected ROI, all the ROIs, or a subset of
        % ROIs. (See the case 'roisToDisplay'.)
        %   maskROIs = viewGet(vw, 'mask ROIs');
        if checkfields(vw,'ui','maskROIs'), val = vw.ui.maskROIs;
        else val = 0; return;
        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return

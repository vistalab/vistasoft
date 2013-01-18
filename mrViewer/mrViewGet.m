function val = mrViewGet(varargin);
%
% mrViewGet: Get the value of the specified property for
% a mrViewer UI.
%
% Can be used a number of ways:
%
% mrViewGet without any arguments returns the ui struct
% corresponding to the most current mrViewer UI. The most
% current UI is the one the selected figure belongs to;
% if the selected figure doesn't belong to a mrViewer UI,
% then it looks for the most recently-created UI. If no
% UIs are found, displays a warning and returns an empty
% matrix.
%
% mrViewGet(ui) lists the properties and set values for
% the specified ui, similar to GET.
%
% mrViewGet('PropertyName') returns the value of the
% specified property for the most current UI.
%
% mrViewGet(ui,'PropertyName') returns the value of the
% specified property for the specified UI.
%
% Properties include (non-case-sensitive):
%   'ImageCoords': Coordinates of the images being displayed
%   by the UI (in the ui.display struct, see mrViewUnderlay), in terms
%   of the UI's currently-selected space. Specifying
%       mrViewGet(ui,'imagecoords',N)
%   will return only the coordinates pertaining to the Nth image being
%   displayed. Otherwise, a cell array of image coordinates will be
%   returned. In all cases, the coords for each image are a 3xnPixels
%   matrix, with the rows being the row, column, and slice indices into
%   the base MR data.
%
%   'DataCoords': Coordinates of the images being displayed
%   by the UI (in the ui.display struct, see mrViewUnderlay), in terms
%   of the base MR data. Specifying  mrViewGet(ui,'datacoords',N) will
%   return only the coordinates pertaining to the Nth image being
%   displayed. Otherwise, a cell array of image coordinates will be
%   returned. In all cases, the coords for each image are a 3xnPixels
%   matrix, with the rows being the row, column, and slice indices into
%   the base MR data.
%
%   'ROI', [r]: Returns ROI struct for the selected ROI. If the index r is
%   omitted, returns the selected ROI.
%
%   'MapVals', [m], [roi]: Get values of the data map m in the selected
%   ROI. m is an index into the loaded data maps. ROI can be the name
%   of a loaded ROI, index into the ui.rois field, or 3xN list of 
%   coordinates in the base mr space. If omitted, returns the map value
%   at the cursor position. The returned values are of size 1 x nCoords,
%   where nCoords is the number of columns in roi.coords. For coordinates 
%   in the ROI for which data are not defined, returns a NaN. 
%
%   'OverlayVals', [roi]: Get values of the data map currently being
%   displayed as an overlay. If more than one overlays are displayed, the
%   returned value is a matrix of size nOverlays x nCoords. If omitted,
%   uses the cursor position as the ROI. 
%
%	'OverlayMask', [whichOverlays]: Returns a 3-D logical matrix, the size of
%	ui.mr.data, with a 1 where a given voxel passes the overlay thresholds
%	and a 0 otherwise. If the optional 'whichOverlays' argument is passed,
%	will only threshold according to the selected overlays; otherwise,
%	thresholds according to all overlays.
%
%	'CursorPosition': position of the mrViewer cursor, in the "base" space
%	(units of (rows, cols, slices) in mr.ui.data).
%
% ras, 07/05.
val = [];

if nargin==0
    % find most current UI:
    % first check current figure to see if it has a UI
    tag = get(gcf,'Tag');
    if strncmp(tag,'mrViewer',8)==1
        val = get(gcf,'UserData');
    else
        ud = get(gcf,'UserData');
        if isstr(ud) & strncmp(ud,'mrViewer',8)==1
            % The user data is pointing to the main UI figure
            fig = findobj('Tag',ud);
            val= get(fig,'UserData');            
        else
            % last thing to try: search for figures w/
            % tag 'mrViewer[#]', and get highest #
            tag = 'mrViewer1';
            if isempty(findobj('Tag',tag))
                warning('No mrViewer UIs found!')
                val = [];
            else
                i = 1;
                while ~isempty(findobj('Tag',sprintf('mrViewer%i',i+1)))
                    i = i + 1;
                end
                fig = findobj('Tag',sprintf('mrViewer%i',i));
                val = get(fig,'UserData');
            end
        end
    end

    return
end

if length(varargin)==1
    if isstruct(varargin{1})
        % request to print out UI info
        disp('mrViewer UI Info: ')
        ui = varargin{1};
        fprintf('Base MR file: %s\n', ui.mr.name);
        fprintf('Base MR path: %s\n\n', ui.mr.path);
        for i = 1:length(ui.maps)
            fprintf('Map %i file: %s\n', i, ui.maps(i).name);
            fprintf('Map %i path: %s\n\n', i, ui.maps(i).path);
        end
        disp('UI Settings:')
        disp(ui.settings)
        val = ui.settings;
    else
        ui = mrViewGet;
        val = mrViewGet(ui,varargin{1});
    end
    return
end

% if we've gotten here, we have both a UI struct and an argument to get
ui = varargin{1};
prop = varargin{2};
if length(varargin)>2
    args = varargin(3:end);
else
    args = {};
end

% allow an empty UI struct to be passed, meaning get the current one
if isempty(ui), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

switch lower(prop)
case {'imgcoords','imagecoords','imagecoordinates'},
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % coordinates of displayed images in selected data space %
    % (args can specify an image #, otherwise return cell of %
    % coords for all displayed images)                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(args)       % get coords for specified image
        selectedImages = args{1};
    else                    % get coords for all images
        selectedImages = 1:length(ui.display.images);
    end

    b = ui.settings.bounds;
    val = {};
    for i = selectedImages
        % get the coords corresponding to this slice
        rng = {[b(1,1):b(1,2)] [b(2,1):b(2,2)] [b(3,1):b(3,2)]};
        rng{ui.display.oris(i)} = ui.display.slices(i);
        [X Y Z] = meshgrid(rng{2},rng{1},rng{3});
        val{end+1} = [Y(:) X(:) Z(:)]'; clear X Y Z
    end

    % if an image was specified, return the coords directly
    if ~isempty(args),  val = val{1};  end

case {'datacoords'},
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % coordinates of displayed images in base data space     %
    % (args can specify an image #, otherwise return cell of %
    % coords for all displayed images)                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(args)       % get coords for specified image
        selectedImages = args{1};
    else                    % get coords for all images
        selectedImages = 1:length(ui.display.images);
    end

    val = {};

    for i = selectedImages
        coords = mrViewGet(ui,'ImageCoords',i);
        if ui.settings.space ~= 1
            %%%%%%%%%%%%%%%%%%%%%
            % Transformed Space %
            %%%%%%%%%%%%%%%%%%%%%
            % xform from image space -> data space
            % (this is the inverse of the xform we
            % store in spaces)
            s = ui.settings.space;
            if ~isempty(ui.spaces(s).coords)
                % do the direct-coord method, or
                % use an external function
            else
                xform = inv(ui.spaces(s).xform);
                coords = xform * [coords; ones(1,size(coords,2))];
                coords = coords(1:3,:);
            end
        end

        % return coords
        val{end+1} = coords;
    end

    % if an image was specified, return the coords directly
    if ~isempty(args),  val = val{1};  end
    
case {'cursorcoords' 'cursorpos' 'cursorposition' 'cursordatacoords'}
    % position of cursor in base space
    val = ui.settings.cursorLoc;
    
    if ui.settings.space ~= 1
        %%%%%%%%%%%%%%%%%%%%%
        % Transformed Space %
        %%%%%%%%%%%%%%%%%%%%%
        % xform from image space -> data space
        % (this is the inverse of the xform we
        % store in spaces)
        s = ui.settings.space;
        if ~isempty(ui.spaces(s).coords)
            % do the direct-coord method, or
            % use an external function
        else
            xform = inv(ui.spaces(s).xform);
            val = xform * [val(:); 1];
            val = val(1:3,:)';
        end
	end
    
case {'displayformat'},		val = ui.settings.displayFormat; 
case {'curslice', 'slice', 'selectedslice', 'firstslice'}
    val = ui.settings.slice;
    
case {'numslices' 'nslices'}
    val = ui.mr.dims(3);
    
case {'base' 'mr' 'anat' 'underlay'},   val = ui. mr;    
case {'maps'}, val = ui.maps;
case {'overlay' 'curmap' 'selectedmap'}, 
	if ~isempty(args), o = args{1}; else, o = 1; end	
    val = ui.maps(ui.overlays(o).mapNum);
	
case {'overlaysettings' 'overlaystruct'}
	if ~isempty(args), o = args{1}; else, o = 1:length(ui.overlays); end
	val = ui.overlays(o);
    
case {'roiviewmode' 'roidrawmode'}, val = ui.settings.roiViewMode;
		
case {'curroinum' 'roinum' 'selroinum' 'selectedroinum'}, 
	val = ui.settings.roi;     
case {'roi' 'selroi' 'curroi' 'selectedroi'}
    if isempty(args), r = ui.settings.roi; else, r = args{1}; end
    val = ui.rois(r);
    
case {'mesh' 'curmesh'}
    s = ui.settings.segmentation;
    if s==0 | isempty(ui.segmentation), val = []; return; end
    
    if isempty(ui.segmentation(s).mesh)     % load a mesh
        ui = mrViewLoad(ui, '', 'mesh');
    end        
    
    val = segGet(ui.segmentation(s), 'mesh');    
    
case {'zoom'}, val = ui.settings.zoom;
case {'imagezoom'}, % zoom in format [xmin xmax ymin ymax] for displayed iamges
    val = ui.settings.zoom;
    if ui.settings.displayFormat==2 % 3-axis view: zoom different for each
        warning('Zoom is 3-D in 3-axis view -- returning 3 x 2 matrix');
        return
    end
    otherDims = setdiff(1:3, ui.settings.ori);
    val = [val(otherDims(2),:) val(otherDims(1),:)];
        
case {'displayimages' 'images'}, val = ui.display.images; 
case {'croppedimages', 'zoomedimages'},  % images that are zoomed in on
     images = ui.display.images;
     zoom = round( mrViewGet(ui, 'imagezoom') );
     if ui.settings.displayFormat==2        % different zoom for each image
         for i = 1:3
             otherDims = setdiff(1:3, i); % orientation
             rows = zoom(otherDims(2),:);
             cols = zoom(otherDims(1),:);
             val{i} = images{i}(rows,cols,:);
         end
     else                                   % same zoom for each image
         for i = 1:length(images)
             val{i} = images{i}(zoom(3):zoom(4),zoom(1):zoom(2),:);
         end
     end
    
    
case {'colorbar' 'cbar'}
    if ~isempty(args), o = args{1}; else, o = 1; end
    val = ui.overlays(o).cbar;
    
case {'segmentationnum' 'segnum' 'cursegnum' 'cursegmentationnum'}
    val = ui.settings.segmentation;
    
case {'segmentation' 'seg' 'segstruct' 'cursegmentation' 'selectedsegmentation'}
    val = ui.segmentation( ui.settings.segmentation );
    
case {'curmeshnum' 'curmeshn' 'meshnum' 'selectedmeshnum'}
    s = ui.settings.segmentation;
    val = ui.segmentation(s).settings.mesh;

case {'curmesh' 'currentmesh' 'selectedmesh' 'mesh'}
    s = ui.settings.segmentation;
    m = ui.segmentation(s).settings.mesh;
    val = ui.segmentation(s).mesh{m};
	
case {'allmeshnames' 'meshlist'}
	val = {};
	for s = 1:length(ui.segmentation)
		for m = 1:length(ui.segmentation(s).mesh)
			val{end+1} = sprintf('%i %s', ...
								ui.segmentation(s).mesh{m}.id, ...
								ui.segmentation(s).mesh{m}.name);
		end
	end

case {'curmeshdir' 'selectedmeshdir' 'meshdir'}
    s = ui.settings.segmentation;
    val = ui.segmentation(s).params.meshDir;
    
case {'mapvals' 'mapdata'}
    if length(args) < 1, error('Need to specify a map index.'); end
    m = args{1};
    if length(args) >= 2,       roi = roiParse(args{2}, ui);
    else,                       roi = roiParse(ui.settings.cursorLoc');
	end
	% get xform from viewer coordinates -> map coordinates
	viewer2MapXform = inv(ui.maps(m).baseXform);
	
	% xform ROI coords to map coords
	roi = roiXformCoords(roi, viewer2MapXform, ui.maps(m).voxelSize(1:3));
	
	% sample the data at the map coordinates
	val = mrGet(ui.maps(m), 'data', roi.coords);
    
case {'overlayvals' 'overlaydata'}
    if isempty(args), roi = roiParse(ui.settings.cursorLoc'); 
    else,             roi = roiParse(args{1}, ui);
    end
    
    for o = 1:length(ui.overlays)
        val(o,:) = mrViewGet(ui, 'mapvals', ui.overlays(o).mapNum, roi);
	end
	
case {'overlaymask' 'datamask'}
    %% 3-D binary matrix with 1 where voxels pass the overlay thresholds,
    %% and 0 otherwise.
    if isempty(args), whichOverlays = find( ~([ui.overlays.hide]) ); 
    else,             whichOverlays = args{1};
	end
		
	% initialize empty matrix
	val = logical( zeros(ui.mr.dims(1:3)) );
	
	% input check
	if isempty(whichOverlays)
		warning('[mrViewGet(''overlaymask'')]: No overlays. Returning emtpy matrix.')
		return
	end	
	
	% get the coords for all slices in the base data space
	[X Y Z] = meshgrid( 1:size(val,2), 1:size(val,1), 1:size(val,3) );
	coords = [Y(:) X(:) Z(:)]';

	% restrict coords to those which pass the threshold
	% of this overlay
	[coords, imageMask] = mrViewRestrict(ui, coords, whichOverlays);
	
	% set those coords which pass the threshold to 1 (true)
	I = sub2ind( size(val), coords(1,:), coords(2,:), coords(3,:) );
	val(I) = true;
	
otherwise, warning('Unknown mrViewer property.')        

end

return


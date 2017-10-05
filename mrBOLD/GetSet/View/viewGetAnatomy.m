function val = viewGetAnatomy(vw,param,varargin)
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
    
    case 'anatomy'
        % Return the anatomical underlay image.
        
        switch viewGet(vw,'View Type')
            case 'Inplane'
                val = niftiGet(viewGet(vw,'Anatomy Nifti'),'Data');
            otherwise
                if isfield(vw.anat,'data') val = vw.anat.data;
                else val = vw.anat; end
        end
        
        
    case 'anatomymap'
        % Return the colormap for the anatomical underlay image.
        %   anataomyMap = viewGet(vw, 'Anatomy Map');
        val = round(vw.ui.phMode.cmap(1:64,:) * 255)';
    case 'anatomynifti'
        %Return the actual nifti struct stored in anat
        val = vw.anat;
    case 'inplaneorientation'
        %Return the orientation of the inplane as a 3 letter string (e.g.,
        %'PRS' for Posterior/Right/Superior as indices increase in dims
        %1-3)
        if isfield(vw, 'inplaneOrientation'), val = vw.inplaneOrientation; 
        else val = []; end               
    case 'anatclip'
        % Return anatomy clipping values from anatMin and anatMax sliders.
        %   anataomyClip = viewGet(vw, 'Anatomy Clip');
        val = getAnatClip(vw);
    case 'anatslicedim'
        %Returns the dimension of the matrix that is associated with
        %slices
        val = niftiGet(viewGet(vw,'Anatomy Nifti'),'sliceDim');
    case 'anatslicedims'
        %Returns the dimensions of each 2D array making up each slice
        val = niftiGet(viewGet(vw,'Anatomy Nifti'),'sliceDims');
    case 'anatsize'
        %Load an anatomy if one does not already exist
        if ~checkfields(vw, 'anat') || isempty(vw.anat), vw = loadAnat(vw); end
        switch vw.viewType
            case 'Inplane'
                val = niftiGet(viewGet(vw,'Anatomy Nifti'),'Dim');
                val = double(val(1:3));
            case {'Volume' 'Gray' 'generalGray' 'Flat'}
                val = size(vw.anat);
        end
    case 'anatomycurrentslice'
        % Return the anatomical underlay image for only one slice
        %   anat = viewGet(vw, 'Anatomy Current Slice', curSlice);
        if length(varargin) < 1
            error('Current slice not defined. Use: viewGet(vw,''anatomy'') instead');
        end
        val = viewGet(vw,'anat');
        val = val(:,:,varargin{1});
    case 'anatsizexyz'
        % The class data store the planes in a different order from the
        % vw.anat.  If you want sizes that work for the class data, call
        % this size.
        %   anatSizeXYZ = viewGet(vw, 'Anatomy Size For Class');
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            warning('vista:viewError', ['The XYZ size property only sensible for Volume/Gray ' ...
                'views. The returned value probably doesn''t reflect ' ...
                'actual dimensions for a .class file or canonical space.']);
        end
        val = viewGet(vw, 'anatomysize');
        val = val([2 1 3]);
    case 'brightness'
        % Return the value of the brightness slider bar for the anatomical
        % underlay image.
        %   brightness = viewGet(vw, 'brightness');
        val = get(vw.ui.brightness.sliderHandle,'Value');
    case 'contrast'
        % Return the value of the contrast slider bar for the anatomical
        % underlay image.
        %   contrast = viewGet(vw, 'contrast');
        val = get(vw.ui.contrast.sliderHandle,'Value');
    case 'mmpervox'
        % Return the size of a voxel in mm
        %   mmPerVox = viewGet(vw, 'mm per voxel');
        switch viewGet(vw,'View Type')
            case 'Inplane'
                val = niftiGet(viewGet(vw,'anat nifti'),'Pix Dim');
                % there can only be 3 dimensions of space: take only 3 dimensions of pix dim                
                val = val(1:3);
            case {'Volume' 'Gray' 'generalGray'}
                if isfield(vw, 'mmPerVox'),
                    val =  vw.mmPerVox;
                else
                    % not found -- try to read from anat file
                    anatFile = getVAnatomyPath;
                    val = readVolAnatHeader(anatFile);
                    % having read this, set it in the view, and if
                    % it's a global VOLUME view, set it so we won't
                    % need to read the file again:
                    vw.mmPerVox = val;
                    if strncmp(vw, 'VOLUME', 6)
                        updateGlobal(vw);
                    end
                end
            case {'Flat'}
                warning('vista:viewError', ['Voxel Resolution not constant for Flat views. ' ...
                    'it depends on the flattening spacing. ']);
                val = [];
        end
        
    case 'mmpervolvox'
        % Return the size of a gray/volume voxel in mm.
        % If we are in the gray or volume view, this is no different from
        % viewGet(vw, 'mm per vox'). If we are in a different viewType
        % (inplane, flat),  we need to initialize a hidden gray view
        % and then read voxel size.
        %  mmpervolvox = viewGet(vw, 'mm per vol vox');
        switch lower(viewGet(vw, 'view type'))
            case {'gray' 'volume'}
                val = viewGet(vw, 'mm per pix');
            otherwise
                val = readVolAnatHeader(vANATOMYPATH);
        end
        
    case 'ngraylayers'
        % Return the number of gray layers in the classification file.
        % Assumes a Gray or Volume view.
        %   nGrayLayers = viewGet(vw, 'Number Gray Layers');
        
        viewType = viewGet(vw, 'viewType');
        switch lower(viewType)
            case {'gray', 'volume'}
                val = max(unique(vw.nodes(6,:)));
            otherwise
                warning('vista:viewError', 'Need gray / volume view to get num gray layers');
                val = [];
        end
    case 'scannerxform'
        % Return the transform matrix from INPLANE coordinates (x,y,z, indices) to
        % scanner coordinates (in mm). Inplane dicoms are needed to get
        % this information.
        % The transform will yield: scannerCoords = scannerXform*ipCoords;
        %   scannerxform = viewGet(vw, 'Scanner transform');
        %   scannerxform = viewGet(vw, 'scannerXform', [rawFile]);
        if length(varargin) < 2, val = getScannerXform;
        else
            rawFile = varargin{1};
            val = getScannerXform(rawFile);
        end
    case 'b0dir'
        % Return the direction of the B0 field from a scan as a unit vector
        %   b0vector = viewGet(vw, 'b0 direction');
        try % we use a 'try' statement because the function will fail
            % if the raw anatomical inplane (dicom) is not available
            val = getB0direction(vw);
        catch ME
            warning(ME.message);
            val = [];
        end
    case 'b0angle'
        % Return the direction of b0 field from a scan as an angle in degrees
        %   b0angle = viewGet(vw, 'b0 angle');
        try % we use a 'try' statement because the function will fail
            % if the raw anatomical inplane (dicom) is not available
            [tmp, val] = getB0direction(vw);
        catch ME
            warning(ME.message);
            val = [];
        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return

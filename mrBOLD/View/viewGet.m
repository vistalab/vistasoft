function val = viewGet(vw,param,varargin)
% Get data from various view structures
%
%   val = viewGet(vw,param,varargin)
%
% Reads the parameters of a view struct.
% Access to these structures should go through this routine and through
%
%    viewSet
%
% At present, this is far from true.  Work towards that goal.
%
% These are the cases that can accessed via viewGet (as of July 5, 2011):
%
% See also viewSet, viewMapParameterField
%
%     ------------------------------------------------------------------
%     -- Session-related properties; selected scan, slice, data type ---
%     ------------------------------------------------------------------
%     'homedir'      
%     'sessionname'  
%     'subject'      
%     'name'         
%     'annotation'   
% 	  'annotations' 
%     'viewtype'
%     'subdir' 
%     'curscan'
%     'curslice'
%     'nscans'
%     'nslices'
%     'montageslices'
%     'dtname'
%     'curdt'
%     'dtstruct'
%
%     ------------------------------------------------------------------
%     -- Traveling-Wave / Coherence Analysis properties ----------------
%     ------------------------------------------------------------------
%     'coherence' 
%     'scanco'
%     'phase'
%     'scanph'
%     'amplitude'
%     'scanamp'
%     'refph'
%     'ampmap'
%     'coherencemap'
%     'correlationmap'
%     'cothresh'
%     'phwin'       
%
%     ------------------------------------------------------------------
%     -- colorbar-related params ---------------------------------------
%     ------------------------------------------------------------------
%     'twparams' 
%     'cmap'
%     'cmapcolor'
%     'cmapgrayscale'
%         
%     ------------------------------------------------------------------
%     --  Map properties -----------------------------------------------
%     ------------------------------------------------------------------
%     'map'
%     'mapwin'
%     'mapname'
%     'mapunits'
%     'mapclip'
%     'scanmap' 
%
%     ------------------------------------------------------------------
%     -- Anatomy / Underlay-related properties -------------------------
%     ------------------------------------------------------------------
%     'anatomy'
%     'anatomymap'
%     'anatomynifti'
%     'anatclip'
%     'anatslicedim'
%     'anatsize'
%     'anatsizexyz'
%     'brightness'
%     'contrast'
%     'mmpervox'
%     'mmpervolvox'
%     'ngraylayers'
%     'scannerxform'
%     'b0dir'
%     'b0angle'
%
%     ------------------------------------------------------------------
%     -- ROI-related properties ----------------------------------------
%     ------------------------------------------------------------------
%     'rois'
%     'roistruct'
%     'roicoords'
%     'roiindices'
%     'roivertinds'
%     'roiname'
%     'roimodified'
%     'allroinames'
%     'nrois'
%     'selectedroi'
%     'filledperimeter'
% 	  'selroicolor'
%     'prevcoords'
%     'roistodisplay'
%     'roidrawmethod'
%     'showrois'
%     'hidevolumerois'
%     'maskrois'
%
%     ------------------------------------------------------------------
%     --  Time-series related properties--------------------------------
%     ------------------------------------------------------------------
%     'tseriesdir'
%     'datasize'
%     'dim'
%     'tseries'
%     'tseriesslice'
%     'tseriesscan'
%     'tr'
%     'nframes'
%     'ncycles'
%
%     ------------------------------------------------------------------
%     --  Retinotopy/pRF Model related properties ----------------------
%     ------------------------------------------------------------------   
%     'framestouse'
%     'rmfile'
%     'rmmodel'
%     'rmcurrent'
%     'rmmodelnames'
%     'rmparams'
%     'rmstimparams'
%     'rmmodelnum'
%     'rmhrf'
%
%     ------------------------------------------------------------------
%     --   Mesh-related properties -------------------------------------
%     ------------------------------------------------------------------
%     'allmeshes'
%     'allmeshids'
%     'mesh'
%     'currentmesh'
%     'meshn'
%     'meshdata'
%     'nmesh'
%     'meshnames'
%     'meshdir'        
%
%     ------------------------------------------------------------------
%     --  Volume/Gray-related properties -------------------------------
%     ------------------------------------------------------------------
%     'nodes'
%     'xyznodes'
%     'nodegraylevel'
%     'nnodes'
%     'edges'
%     'nedges'
%     'allleftnodes'
%     'allleftedges'
%     'allrightnodes'
%     'allrightedges'
%     'coords'
%     'allcoords'
%     'coordsfilename'
%     'ncoords'           
%     'classfilename'
%     'classdata'
%     'graymatterfilename'        
%
%     ------------------------------------------------------------------
%     --  EM / General-Gray-related properties -------------------------
%     ------------------------------------------------------------------
%     'datavalindex'
%     'analysisdomain'      
%
%     ------------------------------------------------------------------
%     --  Flat-related properties --------------------------------------
%     ------------------------------------------------------------------
%     'graycoords'
%     'leftpath'
%     'rightpath'
%     'fliplr'
%     'imagerotation'
%     'hemifromcoords'
%     'roihemi'
%
%     ------------------------------------------------------------------
%     --  UI properties ------------------------------------------------
%     ------------------------------------------------------------------
%     'ishidden'
%     'ui'
%     'fignum'
%     'windowhandle'
%     'displaymode'
%     'anatomymode'
%     'coherencemode'
%     'correlationmode'
%     'phasemode'
%     'amplitudemode'
%     'projectedamplitudemode'
%     'mapmode'
%     'zoom'
%     'crosshairs'
%     'locs'
%     'phasecma'
%     'cmapcurrent'
%     'cmapcurmodeclip'
%     'cmapcurnumgrays'
%     'cmapcurnumcolors'
%     'flipud'


% TODO:
%  We need to have a call data = viewGet(vw,'data','co',roiName);
%  This would call getCurDataROI or just insert that function in place
%  here.
%
% ras 05/07: replaced all local variable names VOLUME, INPLANE, FLAT to just
% 'vw'. The previous format was misleading -- the local variables were
% not global variables and shouldn't have been capitalized -- and made it
% annoying to debug (which is often, since this function seems to
% break often).
%
% It also seems the majority of properties here are the same regardless of
% the view type: I think we should not break this up into volGet, ipGet,
% flatGet, but instead have a single, simpler function. For those params
% which depend on view type, the conditional can be placed underneath the
% type. This will save on a large amount of needless duplication (which
% translates into fixing the same d bug 3 times, every time).
%
% ras, 06/07: eliminated the subfunctions ipGet, volGet, flatGet;
% combined all into one big SWITCH statement.
%
% Added mrGlobals
%
% JW: 2/2011: viewSet and viewGet now take the input parameter field and
% call viewMapParameterField before the long switch/case. This function
% returns a standardized parameter field name. It removes spaces and
% captials, and maps multiple names (aliases) onto a single name. If you
% add a new parameter (new case) to viewGet or viewSet, please use only a
% single standardized parameter name in the viewGet and viewSet functions.
% You can put as many aliases as you like in viewMapParameterField.
% 
% For example: 
%    viewMapParameterField('curdt') 
% and
%   viewMapParameterField('Current Data TYPE') 
% both return 'curdt'. This means that
%    viewGet(vw, 'curdt') 
% and
%    viewGet(vw, 'Current Data TYPE') 
% are equivalent. Hence viewGet and viewSet should have the case 'curdt'.
% They do not need the case 'Current Data TYPE' or 'currentdatatype'.


if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];

%Format the parameter as lowercase and without spaces
param = mrvParamFormat(param);

% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);


%%%%%%%%%%%%%%%%%%%%%%%%
% Big SWITCH Statement %
%%%%%%%%%%%%%%%%%%%%%%%%
% This statement will check for all possible properties,
% for all view types. I tried to gruop them in a reasonable
% way.
switch param
    
    %% Session-related properties; selected scan, slice, data type
    case 'homedir'      
        % Return full path to directory.
        %   homedir = viewGet(vw, 'Home Directory');
        val = HOMEDIR; 
    case 'sessionname'  
        % Retrun name of session, such as 'BW090616-8Bars-14deg'.
        %   sessionName = viewGet(vw, 'session name');
        val = mrSESSION.sessionCode;
    case 'subject'      
        % Return name of subject, such as 'Wandell'
        %   subject = viewGet(vw, 'subject')
        val = mrSESSION.subject;
    case 'name'         
        % Return name of view, such as 'INPLANE{1}'
        %    name = viewGet(vw, 'view name');
        val = vw.name;
    case 'annotation'   
        % Return description of currently selected scan (string, such as
        % '14 Deg 8 Bars with blanks')
        %       annotation = viewGet(vw, 'annotation');
        if length(varargin) >= 1,   scan = varargin{1};
        else                        scan = viewGet(vw, 'CurScan'); end
        dt = viewGet(vw, 'DTStruct');
        val = dt.scanParams(scan).annotation;
	case 'annotations' 
        % Return a cell array with descriptions of each scan in current
        % dataType
        %   annotations = viewGet(vw, 'annotations');
        dt  = viewGet(vw, 'DT Struct');
        val = {dt.scanParams.annotation};		
    case 'viewtype'
        % Return the view type ('Gray', 'Volume', 'Inplane', 'Flat', etc) 
        %   viewType = viewGet(vw, 'View Type');
        val = vw.viewType;
    case 'subdir' 
        % Return the sub directory name (not the full path) with data for
        % current view 
        %   subdir = viewGet(vw, 'sub directory');
        val = vw.subdir;
    case 'viewdir'
        % Return the complete path combination of homedir and subdir
        % Will then try to create them if not already created
        val = fullfile(viewGet(vw,'Home Directory'),viewGet(vw,'Sub Directory'))
        if ~exist(val,'dir')
            fprintf('Trying to make %s...',str);
            try
                [~, message] = mkdir(val);
            catch
                fprintf('Whoops, didn''t succed. Maybe a permissions problem?');
                fprintf('\n Message: %s',message);
            end
            fprintf('\n');
        end
    case 'curscan'
        % Return the currently selected scan number
        %   curscan = viewget(vw, 'Current Scan');
        if checkfields(vw,'curScan')
            val = vw.curScan;
        else
            if checkfields(vw,'ui','scan','sliderHandle')
                val = round(get(vw.ui.scan.sliderHandle,'value'));
            else
                % Sometimes there is no window interface (it is hidden).  Then, we have
                % to find another way to determine the current scan.  Here, we ask the
                % user.  It would be possible to store this information in the VIEW
                % structure.  But we don't.  Ugh.
                val = 1; ieReadNumber('Enter scan number');
            end
        end
        
        
    case 'curslice'
        % Return the current slice number. This is the actual slice number
        % if we are in the Inplane view. It is the plane number (sag, cor,
        % or axi) of the currently selected plane if we are in the Volume
        % view. And it is 1 or 2 in the Flat view (for left or right).
        %   curslice = viewGet(vw, 'Current Slice');
        if isequal(vw.name,'hidden')
            % no UI or slider -- use tSeries slice
            curSlice = vw.tSeriesSlice;
            if isnan(curSlice), val = 1; end
            return
        end        
        switch vw.viewType
            case 'Inplane'
                val = vw.tSeriesSlice; % err on the side of not needing a UI
                if isnan(val) && checkfields(vw, 'ui', 'slice')
                    val = get(vw.ui.slice.sliderHandle,'val');
                end
            case {'Volume','Gray','generalGray'}
                sliceOri=getCurSliceOri(vw);
                val=str2double(get(vw.ui.sliceNumFields(sliceOri),'String'));
            case 'Flat'
                if isfield(vw,'numLevels') % test for levels view
                    %% flat-levels view (older, but still supported)
                    val = getFlatLevelSlices(vw);
                    val = val(1);
                else
                    %% regular flat view: slice is hemisphere, slice 3 means both
                    val = findSelectedButton(vw.ui.sliceButtons);
                end
        end
    case 'nscans'
        % Return the number of scans in the currently selected dataTYPE
        %   nscans = viewGet(vw, 'Number of Scans');
        if length(varargin) < 1, dataType = vw.curDataType;
        else dataType = varargin{1}; end
        if ischar(dataType)
            dataType = existDataType(dataType);
        end
        if dataType==0
            error('Invalid data type specified: %i', dataType);
        end
        val = length(dataTYPES(dataType).scanParams);
    case 'nslices'
        % Return the number of slices in the current view struct
        %   nslices = viewGet(vw, 'Number of Slices');
        switch vw.viewType
            case 'Inplane'
                if ~checkfields(vw, 'anat'), vw = loadAnat(vw); end
                val = niftiGet(viewGet(vw,'Anatomy Nifti'),'num slices');
            case {'Volume' 'Gray'}
                val = 1;
            case 'Flat'
                if isfield(vw,'numLevels') % acr levels view
                    val = 2 + sum(vw.numLevels);
                else
                    val = 2;
                end
        end
    case 'montageslices'
        % Return the current subset of slices that are visible in the GUI.
        %   montageSlices = viewGet(vw, 'Montage Slices');
        %
        % only for some view types: inplane montage, flat level
        % Well, this seems not to be true since it returns a value in the
        % Volume view.
        val = viewGet(vw, 'Current Slice');
        if viewGet(vw, 'ishidden') || ~ismember(vw.refreshFn,...
                {'refreshMontageView' 'refreshFlatLevelView'})
            warning('vista:viewError', 'MontageSlices View does not apply to this view type');
            return  % return current slice
        end
        nSlices = get(vw.ui.montageSize.sliderHandle, 'Value');
        val = val:val+nSlices-1;
        val = val(val <= viewGet(vw, 'numSlices'));
        
    case 'dtname'
        % Return the name of the currently selected dataTYPE
        %   dtName = viewGet(vw, 'Data TYPE Name');
        %
        % ras 06/07: note that I 'stole' the 'datatype' alias from
        % the dtnumber property: I think the name is more relevant
        val = dataTYPES( viewGet(vw, 'curdt') ).name;
    case 'curdt'
        % Return the number of the currently selected dataTYPE
        %   dtNum = viewGet(vw, 'Current Data TYPE');
        if isfield(vw, 'curDataType')
            val = vw.curDataType;
        else
            val = 0;
        end
    case 'dtstruct'
        % Return the currently selected dataTYPE struct
        %   dtStruct = viewGet(vw, 'DT struct');       
        curdt = viewGet(vw, 'Current Data TYPE');
        val   = dataTYPES(curdt);
        
        %% Traveling-Wave / Coherence Analysis properties
    case 'coherence' 
        % Coherence for all voxels, all scans in current dataTYPE        
        %   co = viewGet(vw, 'Coherence');        
        val = vw.co;
    case 'scanco'
        % Coherence for single scan
        %   scanco = viewGet(vw, 'scan coherence', 1);        
        if length(varargin) < 1, nScan = viewGet(vw, 'Current Scan');
        else                     nScan = varargin{1};   end
        if ~isempty(vw.co) && length(vw.co) >=nScan, val = vw.co{nScan};
        else                val = []; end
    
    case 'phase'
        % Phase for all voxels, all scans in current dataTYPE    
        %   ph = viewGet(vw, 'Phase');
        val = vw.ph;
    case 'scanph'
        % Phase values for single scan
        %   viewGet(vw,'Scan Phase',1);
        if length(varargin) < 1, nScan = viewGet(vw, 'curScan');
        else                     nScan = varargin{1}; end
        if ~isempty(vw.ph), val = vw.ph{nScan}; 
        else                val = []; end
    case 'amplitude'
        % Amplitude for all voxels, all scans in current dataTYPE    
        %   amp = viewGet(vw, 'Amplitude');
        val = vw.amp;
    case 'scanamp'
        % Amplitude values for single scan (selected scan or specified
        % scan).
        %   scan = 1; scanAmp = viewGet(vw,'scan Amp', scan);
        %   scanAmp = viewGet(vw,'scan Amp');
        if length(varargin) < 1, nScan = viewGet(vw, 'curScan');
        else                     nScan = varargin{1}; end
        if ~isempty(vw.amp), val = vw.amp{nScan};
        else                 val = []; end
    case 'refph'
        % Return the reference phase used for computing phase-referred
        % coherence. Should be [0 2*pi]?
        %   refph = viewGet(vw,'reference phase');
        if isfield(vw, 'refPh'),    val = vw.refPh;
        else                        val = [];       end
    case 'ampmap'
        % Return the colormap currently used to display amplutitude data.
        % Should be 3 x numColors.
        %   ampMap = viewGet(vw, 'amplitude color map');
        nGrays = viewGet(vw, 'curnumgrays');
        val = round(vw.ui.ampMode.cmap(nGrays+1:end,:) * 255)';
    case 'coherencemap'
        % Return the colormap currently used to display coherence data.
        % Should be 3 x numColors.
        %   cohMap = viewGet(vw, 'coherence color map');
        nGrays = viewGet(vw, 'curnumgrays');  val = round(vw.ui.coMode.cmap((nGrays+1):end,:) * 255)';
    case 'correlationmap'
        % Return the colormap currently used to display correlation data.
        % Should be 3 x numColors. 
        %   corMap = viewGet(vw, 'correlation color map');
        %
        % [Q: what is a correlation map and how does it differ from
        % coherence map?]
        nGrays = viewGet(vw, 'curnumgrays');  val = round(vw.ui.corMode.cmap((nGrays+1):end,:) * 255)';                
    case 'cothresh'
        % Return the coherence threshold. Should be in [0 1].
        %   cothresh = viewGet(vw, 'Coherence Threshold');
        if ~isequal(vw.name,'hidden')
            val = get(vw.ui.cothresh.sliderHandle,'Value');
        else
            % threshold vals: use accessor function, deals w/ hidden views
            if checkfields(vw, 'settings', 'cothresh')
                val = vw.settings.cothresh;
            else
                % arbitrary val for hidden views
                val = 0;
            end
        end
    case 'phwin'
        % Return  phWindow values from phWindow sliders (non-hidden views)
        % or from the view.settings.phWin field (hidden views). If can't
        % find either, defaults to [0 2*pi].
        %   phwin = viewGet(vw, 'phase window');
        val = getPhWindow(vw);
        
        % colorbar-related params: this code uses a simple linear
        % mapping from coAnal phase -> polar angle or eccentricity
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
        
        
        %% Map properties
    case 'map'
        % Return the parameter map for the current data type. Map is cell
        % array 1 x nscans.
        %   map = viewGet(vw, 'map');
        val = vw.map;
    case 'mapwin'
        % Return mapWindow values from mapWindow sliders (non-hidden views)
        % or from the view.settings.mapWin field (hidden views).        
        %   mapWin = viewGet(vw, 'Map Window');
        val = getMapWindow(vw);
    case 'mapname'
        % Return the name of the current paramter map (string), e.g.,
        % 'eccentricty'. 
        %   mapName = viewGet(vw, 'Map Name');
        val = vw.mapName;
    case 'mapunits'
        % Return the map units for the current paramter map (string), e.g.,
        % 'degrees'. The map units are for display only; they are not used
        % for calculations.
        %   mapUnits = viewGet(vw, 'Map Units');
        val = vw.mapUnits;
    case 'mapclip'
        % Return map clip values. These are the clip values for the
        % colorbar. They are not the clip values in the slider (which are
        % called 'mapwin'). Values outside of mapclip are colored the same
        % as the minimum or maximum value according to the color lookup
        % table. Values outside of mapwin are not shown at all.
        %   mapClip = viewGet(vw, 'Map Window');
        if checkfields(vw, 'ui', 'mapMode', 'clipMode')
            val = vw.ui.mapMode.clipMode;
            if isempty(val), val = 'auto';  end
        else
            warning('vista:viewError', 'No Map Mode UI information found in view. Returning empty');
            val = [];
        end
    case 'scanmap' 
        % Return the parameter map for the currently selected or the
        % specified scan.
        %   scanMap = viewGet(vw, 'scan map')
        %   scan = 1; scanMap = viewGet(vw, 'scan map', scan);
        if length(varargin) < 1,    nScan = viewGet(vw, 'curScan');
        else                        nScan = varargin{1}; end        
        % Sometimes there is no map loaded. If this is the case,
        % return an empty array rather than crashing
        nMaps=length(vw.map);
        if (nMaps>=nScan), val = vw.map{nScan};
        else               val=[];        end        

        %%
        % Anatomy / Underlay-related properties
    case 'anatomy'
        % Return the anatomical underlay image.
        val = niftiGet(viewGet(vw,'Anatomy Nifti'),'Data');
    case 'anatomymap'
        % Return the colormap for the anatomical underlay image.
        %   anataomyMap = viewGet(vw, 'Anatomy Map');
        val = round(vw.ui.phMode.cmap(1:64,:) * 255)';
    case 'anatomynifti'
        %Return the actual nifti struct stored in anat
        val = vw.anat;
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
                val = val(1:3);
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
        switch vw.viewType
            case 'Inplane' 
                val = niftiGet(viewGet(vw,'anat nifti'),'Pix Dim');
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

        %%%%% ROI-related properties
    case 'rois'
        % Return ROIs as struct. Includes all ROIs and all fields
        %   ROIs = viewGet(vw, 'ROIs');
        val = vw.ROIs;
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
        
        %%%%% Time-series related properties
    case 'tseriesdir'
        % Return tSeries directory for a view; make it if it does not
        % exist.
        %   makeIt = 0; tDir = viewGet(vw,'tSeriesDir',makeIt);
        %   makeIt = 1; tDir = viewGet(vw,'tSeriesDir',makeIt);
        %   tDir = viewGet(vw,'tSeriesDir')
        makeIt = 0;
        if ~isempty(varargin), makeIt = varargin{1}; end
        val = tSeriesDir(vw,makeIt);
    case 'datasize'
        % Return the size of the data arrays, i.e., size of co for
        % a single scan.
        %  dataSize = viewGet(vw, 'Data Size');
        %  scan = 1; dataSize = viewGet(vw, 'Data Size', scan);
        val = dataSize(vw);        
    case 'dim'
        % Return the dimension of data in current slice or specificed slice
        %   dim = viewGet(vw, 'Slice Dimension')
        %   scan = 1; dim = viewGet(vw, 'Slice Dimension', scan)        
        switch vw.viewType
            case 'Inplane'
                val = mrSESSION.functionals.cropSize; %TODO: Change this once we get functional data at the veiw level
            case {'Volume','Gray'}
                val = [1,size(vw.coords,2)];
            case 'Flat'
                val = [vw.ui.imSize];
        end
    case 'functionalslicedim'
        % Return the dimension of functional data in current slice or
        % specificed slice
        %   dim = viewGet(vw, 'Slice Dimension')
        %   scan = 1; dim = viewGet(vw, 'Slice Dimension', scan)
        switch vw.viewType
            case 'Inplane'
                val = mrSESSION.functionals.cropSize;
            case {'Volume','Gray'}
                val = [1,size(vw.coords,2)];
            case 'Flat'
                val = [vw.ui.imSize];
        end
        
    case 'tseries'
        % Return the time series of all data currently loaded into the view
        % struct.
        %   tseries = viewGet(vw, 'time series');
        val = vw.tSeries;
    case 'tseriesslice'
        % Return the time series for the currently selected slice if it is
        % loaded into the view struct (return blank otherwise).
        %   tseries = viewGet(vw, 'Time Series Slice');
        val = vw.tSeriesSlice;
    case 'tseriesscan'
        % Return the time series for the current scan (if it is loaded into
        % the view struct; return blank if it is not loaded).
        %   tseriesScan = viewGet(vw, 'time series scan');
        val = vw.tSeriesScan ;
    case {'tr' 'frameperiod' 'framerate'}
        % Return the scan TR in seconds
        %   tr = viewGet(vw,'tr')
        %   scan = 1; tr = viewGet(vw,'tr',scan)
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt   = viewGet(vw, 'dtStruct');
        val  = [dt.scanParams(scan).framePeriod];
        
    case 'nframes'
        % Return the number of time frames in the current or specified
        % scan.
        %   nframes = viewGet(vw,'nFrames');
        %   scan = 1; nframes = viewGet(vw,'nFrames',scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt  = viewGet(vw, 'dtStruct');
        val = [dt.scanParams(scan).nFrames];
        
    case 'ncycles'
        % Return the number of cycles in the current or specified scan
        % (assuming scan is set up for coranal). 
        %   nycles = viewGet(vw,'ncycles')
        %   scan = 1; nycles = viewGet(vw,'ncycles', scan)
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end        
        curDT = viewGet(vw,'curdt');
        dt    = dataTYPES(curDT);
        blockParms = dtGet(dt,'bparms',scan);
        % There are some issues with event and block that we need to figure out
        % here.
        
        if isfield(blockParms,'nCycles'), val = blockParms.nCycles;
        else                              val = 1;
        end
        
        %%%%% Retinotopy/pRF Model related properties
    
    case 'framestouse'
        % Return a vector of time frames in the current or specified
        % scan to be used for coranal (block) analyses
        %   frames = viewGet(vw,'frames to use');
        %   scan = 1; frames = viewGet(vw,'frames to use',scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms',scan);
        if checkfields(blockParms, 'framesToUse')
            val = blockParms.framesToUse;
        else
            val = 1: viewGet(vw,'nFrames',scan);
        end
        
    case 'rmfile'
        % Return the path to the currently loaded retinotopy model.
        %   rmFile = viewGet(vw, 'retinotopy model file');
        if checkfields(vw, 'rm', 'retinotopyModelFile')
            val = vw.rm.retinotopyModelFile;
        else
            val = []; 
        end
    case 'rmmodel'
        % Return the currently loaded retinotopy model struct.
        %   rm = viewGet(vw, 'retinotopy model');
        if checkfields(vw, 'rm', 'retinotopyModels')
            val = vw.rm.retinotopyModels;
        else
            val = [];
        end

    case 'rmcurrent'
        % Return the currently selected retinotopy model struct. Note that
        % there may be multiple models loaded.
        %   rm = viewGet(vw, 'rm current model');
        if checkfields(vw, 'rm', 'retinotopyModels')
            val = vw.rm.retinotopyModels{ viewGet(vw, 'rmModelNum') };
        else
            val = [];
        end
    case 'rmmodelnames'
        % Return the description of currently loaded retinotopy models.
        %   models = viewGet(vw, 'rm model names');
        %   models = viewGet(vw, 'retinotopy model names');
        models = viewGet(vw, 'Retinotopy Model');
        val = cell(1,numel(models));
        for n = 1:numel(models)
            val{n} = rmGet(models{n},'description');
        end
    case 'rmparams'
        % Return the retinotopy model parameters.
        %   params = viewGet(vw, 'Retinotopy Parameters');
        if checkfields(vw,'rm')
            val = vw.rm.retinotopyParams;
        end
    case 'rmstimparams'
        % Return the retinotopy model stimulus parameters. This is a subset
        % of the retinopy model parameters.
        %   stimParams = viewGet(vw, 'RM Stimulus Parameters');
        if checkfields(vw,'rm','retinotopyParams','stim')
            val = vw.rm.retinotopyParams.stim;
        end
    case 'rmmodelnum'
        % Return the retinotopy model number that is currently selected.
        % (There may be more than one model loaded.)
        %   modelNum = viewGet(vw, 'Retinotopy Model Number');
        if checkfields(vw, 'rm', 'modelNum') && ...
                ~isempty(vw.rm.modelNum)
            val = vw.rm.modelNum;
        else
            val = rmSelectModelNum(vw);
        end
    case 'rmhrf'
        % Return the hrf struct for the current retinopy model. This struct
        % contains a descriptor (such as 'two gammas (SPM style)') and the
        % parameters associated with this function.
        %   rmhrf = viewGet(vw, 'Retinotopy model HRF');
        if checkfields(vw,'rm','retinotopyParams','stim')
            val1 = vw.rm.retinotopyParams.stim.hrfType;
            switch(lower(val1))
                case {'one gamma (boynton style)','o','one gamma' 'b' 'boynton'}
                    val2 = vw.rm.retinotopyParams.stim.hrfParams{1};
                case {'two gammas (spm style)' 't' 'two gammas' 'spm'}
                    val2 = vw.rm.retinotopyParams.stim.hrfParams{2};
                case {'impulse' 'no hrf' 'none'}
                    val2 = [];
                otherwise
                    val2 = [];
            end
            val = {val1 val2};
        end
        
        %%%%% Mesh-related properties
    case 'allmeshes'
        % Return the structs for all currently loaded meshes.
        %   allmeshes = viewGet(vw, 'all meshes');
        if checkfields(vw,'mesh'), val = vw.mesh; end
    case 'allmeshids'
        % Return the ID list for all meshes. IDs are numbers generated by
        % mrMesh that are associated with each new mesh session. They are
        % typically 4 digit numbers starting at 1001. (why??)
        %   idList = viewGet(vw,'All Window IDs');
        nMesh = viewGet(vw,'nmesh');
        if nMesh > 0
            val = zeros(size(val));
            for ii=1:nMesh, val(ii) = vw.mesh{ii}.id; end
            val = val(val > -1);
        end        
    case 'mesh'
        % Return the mesh structure for the selected or the requested mesh.
        % If the mesh number is specificied, it indexes the cell array of
        % meshes currently attached to the view structure. The mesh number
        % bears no relation to the mesh ID number, which is generated by
        % the mesh server.
        %   msh = viewGet(vw, 'mesh');
        %   meshnum = 1; msh = viewGet(vw, 'mesh', meshnum);
        if ~isempty(varargin), whichMesh = varargin{1};
        else whichMesh = viewGet(vw,'currentmeshnumber'); end
        if ~isempty(whichMesh), val = vw.mesh{whichMesh}; end
    case 'currentmesh'
        % Return the mesh structure for the selected mesh. This is
        % redundant with the case 'mesh'.
        %   msh = viewGet(vw, 'Current Mesh');
        whichMesh = viewGet(vw,'Current Mesh Number');
        if ~isempty(whichMesh) && (whichMesh > 0), val = vw.mesh{whichMesh}; end
    case 'meshn'
        % Return the number of the currently selected mesh (index into the
        % cell array of meshes)
        %   msh = viewGet(vw, 'current mesh number');
        if checkfields(vw,'meshNum3d'), val = vw.meshNum3d; end
    case 'meshdata'
        % I think this is supposed to return the data displayed on the
        % current mesh, but I have just tried it and it doesn't seem to
        % work. So what does it do?
        %   meshData = viewGet(vw, 'current mesh data');
        if checkfields(vw,'mesh','data')
            selectedMesh = viewGet(vw,'current mesh number');
            val = vw.mesh{selectedMesh}.data;
        end
    case 'nmesh'
        % Return the number of meshes currently attached to the view
        % struct.
        %   nmesh = viewGet(vw, 'Number of Meshes');
        if checkfields(vw,'mesh'), val = length(vw.mesh); else val = 0; end
    case 'meshnames'
        % Return the name of all meshes currently attached to the view
        % struct.
        %   meshNames = viewGet(vw, 'mesh names');
        if checkfields(vw,'mesh')
            nMesh = viewGet(vw,'nmesh');
            val = cell(1,nMesh);
            for ii=1:nMesh
                if checkfields(vw.mesh{ii},'name')
                    val{ii} = vw.mesh{ii}.name;
                else val{ii} = [];
                end
            end
        end
    case 'meshdir'
        % Return the directory in which the currently selected mesh
        % resides. Default to anat dir if not found.
        %   meshDir = viewGet(vw, 'mesh directory');        
        val = fileparts(getVAnatomyPath);
        
        % meshes are kept separately for each hemisphere
        % try to guess the hemisphere based on cursor position
        % but check whether this location actually exists!
        pos = viewGet(vw, 'Cursor Position');
        
        if ~isempty(pos),			% infer from sagittal position (high=right, low=left)
            vs = viewSize(vw);
            if (pos(3) < vs(3)/2),	hemi = 'Left';
            else					hemi = 'Right';
            end
            tmp = fullfile(val, hemi, '3DMeshes');
            if exist(tmp,'dir'),
                val = tmp;
            end
        end
        
        %%%%% Volume/Gray-related properties
    case 'nodes'
        % Return the array of nodes. Only gray views have nodes. See help
        % for mrManDist.m for a description of the node structure. In
        % brief, nodes are 8 x nvoxels. The first 3 rows correspond to the
        % voxel location and the next 5 correspond to gray graph-related
        % data.
        %   nodes = viewGet(vw, 'nodes');
        if isfield(vw, 'nodes'), val = vw.nodes; 
        else
            val = [];
            warning('vista:viewError', 'Nodes not found.');
        end
    case 'xyznodes'
        % Return the xyz coordinates of the gray voxels as found in nodes
        % array. Assumes a Gray view. See case 'nodes' and help for
        % mrManDist for more information.
        %
        % Must call this sagittal, axial coronal or whatever the mapping is
        % ras, 06/07 -- I believe it's [cor axi sag]. coords is [axi cor sag].
        %
        % xyzNodes = viewGet(vw, 'xyz nodes');
        nodes = viewGet(vw,'nodes');
        val = nodes(1:3,:);
    case 'nodegraylevel'
        % Return the gray level of each voxel as determined by the nodes
        % array. Assumes a Gray view. See case 'nodes' and help for
        % mrManDist for more information.
        %   nodeGrayLevel = viewGet(vw, 'gray level');
        nodes = viewGet(vw,'nodes');
        val = nodes(6,:);
    case 'nnodes'
        % Return the number of nodes. Assumes a Gray view. See case 'nodes'
        % and help for mrManDist for more information. 
        %   nNodes = viewGet(vw, 'number of nodes');
        val = size( viewGet(vw, 'nodes'), 2 );
    case 'edges'
        % Return the edge structure of the gray graph. Assumes a Gray view.
        % See help for mrManDist for more information. 
        %   edges = viewGet(vw, 'edges');
        if isfield(vw, 'edges'), val = vw.edges; 
        else val = []; warning('vista:viewError', 'Edges not found.'); end
    case 'nedges'
        % Return the number of edges in the gray graph. Assumes a Gray
        % view. See case 'edges' and help for mrManDist for more
        % information.
        %   nEdges = viewGet(vw, 'number of edges');      
        val = length( viewGet(vw, 'edges') );
    case 'allleftnodes'
        % Return the subset of nodes in the Gray graph that are in the left
        % hemisphere. See mrgGrowGray and mrManDist.
        %   allLeftNodes = viewGet(vw, 'all left nodes');
        val = vw.allLeftNodes;
    case 'allleftedges'
        % Return the subset of edges in the Gray graph that are in the left
        % hemisphere. See mrgGrowGray and mrManDist.
        %   allLeftEdges = viewGet(vw, 'all left edges');
        val = vw.allLeftEdges;
		if isempty(val) && Check4File('Gray/coords')
			% Try laoding from the Gray/coords file
			load('Gray/coords', 'allLeftEdges')
			val = allLeftEdges;
		end
    case 'allrightnodes'
        % Return the subset of nodes in the Gray graph that are in the
        % right hemisphere. See mrgGrowGray and mrManDist.
        %   allRightNodes = viewGet(vw, 'all right nodes');
        val = vw.allRightNodes;
		if isempty(val) && Check4File('Gray/coords')
			% Try laoding from the Gray/coords file
			load('Gray/coords', 'allRightNodes')
			val = allRightNodes;
		end
		
    case 'allrightedges'
        % Return the subset of edges in the Gray graph that are in the
        % right hemisphere. See mrgGrowGray and mrManDist.
        %   allRightEdges = viewGet(vw, 'all right edges');
        val = vw.allRightEdges;
        
    case 'allnodes'
        % Return all nodes from Gray graph by taking union of allLeftNodes
        % and allRightNodes. 
        %
        % This is NOT necessarily the same as simply returning 'vw.nodes'.
        % When we install a segmentation, we can either keep all the nodes
        % in the gray graph, or only those that fall within the functional
        % field of view (to save space). When we do the latter, the fields
        % vw.coords, vw.nodes, and vw.edges contain only the coords, nodes,
        % and eges within the functional field of view. However the fields
        % vw.allLeftNodes, vw.allLeftEdges, vw.allRightNodes, and
        % vw.allRightEdges contain the edges and nodes for the entire
        % hemisphere
        %
        % Example: nodes = viewGet(vw, 'all nodes');
        val = [vw.allLeftNodes'; vw.allRightNodes']';
        
        
    case 'alledges'
        % Return all edges from Gray graph by taking union of allLeftEdges
        % and allRightEdges. See 'allnodes' for explanation.
        %
        % Example: edges = viewGet(vw, 'all edges');
         val = [vw.allLeftEdges vw.allRightEdges];
         
    case 'coords'
        % Return all the coordinates in the current view. If in Flat view,
        % return the coordinates for a particular slice (slice specified in
        % varargin{1}). If in Inplane view, slice specification is
        % optional. If in Gray or Volume view, slice specification is
        % ignored.
        %   <gray, volume or inplane> 
        %       coords = viewGet(vw, 'coords');
        %   <flat or inplane>
        %       slice  = viewGet(vw, 'current slice'); 
        %       coords = viewGet(vw,'coords', slice);
        try
            switch lower(viewGet(vw, 'viewType'))
                case 'flat'
                    %% separate coords for each flat hemisphere
                    if length(varargin) ~= 1,
                        error('You must specify which hemisphere.');
                    end
                    hname = varargin{1};
                    switch hname
                        case 'left'
                            val = vw.coords{1};
                        case 'right'
                            val = vw.coords{2};
                        otherwise
                            error('Bad hemisphere name');
                    end
                case {'gray', 'volume', 'hiddengray'}                    
                    val = vw.coords;
                case 'inplane'
                    % These coords are for inplane anat. Functional coords
                    % may have different values (if 
                    % upSampleFactor(vw,scan) ~= 1)
                    dims = viewGet(vw, 'anatomysize');
                    if length(varargin) >= 1  % then we want coords for just one slice
                        slice = varargin{1};
                        indices = 1+prod([dims(1:2) slice-1]):prod([dims(1:2) slice]);
                        val=indices2Coords(indices,dims);
                    else
                        indices = 1:prod(dims);
                        val=indices2Coords(indices,dims);
                    end
            end
        catch ME
            val=[];
            warning(ME.identifier, ME.message);
            fprintf('[%s]: Coords not found.', mfilename);
        end
        
    case 'allcoords'
        % Return all coords from Gray graph, including those that are not
        % included in the functional field of view. See 'allnodes' for
        % explanation. If session was initialized with the option 
        % 'keepAllNodes' == true, then this call will be identical to
        % viewGet(vw.coords).
        %
        % Example: coords = viewGet(vw, 'all coords');
        nodes = viewGet(vw, 'all nodes');
        val = nodes([2 1 3], :);
        
    case 'coordsfilename'
        % Return the path to the file in which coordinates are stored.
        % Assumes that a gray view has been created (though current view
        % can be any type).
        %   coordsFileName = viewGet(vw, 'coords file name');
        homeDir = viewGet(vw, 'homedir');
        if isempty(homeDir), val = ['Gray' filesep 'coords.mat'];
        else val = [homeDir filesep 'Gray' filesep 'coords.mat'];
        end
    case 'ncoords'
        % Return the number of coordinates in the current view. See case
        % 'coords'.
        %   nCoords = viewGet(vw, 'number of coords');
        val = size( viewGet(vw, 'Coords'), 2 );
           
    case 'classfilename'
        % Return the path to either the left or the right gray/white
        % classification file. 
        %   fname = viewGet(vw, 'class file name', 'left');
        %   fname = viewGet(vw, 'class file name', 'right');
        if (length(varargin) == 1), hemisphere = varargin{1};
        else error('You must specify right/left hemisphere.');
        end
        switch lower(hemisphere)
            case 'left'
                if ~checkfields(vw,'leftClassFile') || isempty(vw.leftClassFile);
                    [noData,val] = GetClassFile(vw, 0, 1);
                else
                    val = vw.leftClassFile;
                end
            case 'right'
                if ~checkfields(vw,'rightClassFile') || isempty(vw.rightClassFile)
                    [noData,val] = GetClassFile(vw, 1, 1);
                else
                    val = vw.rightClassFile;
                end
            otherwise
                error('Unknown hemisphere');
        end
        
    case {'classdata','class','classification','whitematter'}
        % classFileRight = viewGet(vw,'class data','right');
        if length(varargin) == 1, hemisphere = varargin{1};
        else error('You must specify right/left hemisphere.');
        end
        switch lower(hemisphere)
            case 'left'
                val = GetClassFile(vw, 0);
            case 'right'
                val = GetClassFile(vw, 1);
            otherwise
                error('Unknown hemisphere');
        end
        
    case {'graymatterfilename','graypath','grayfilename','grayfile'}
        % grayFile = viewGet(vw,'Gray matter filename','right');
        if length(varargin) == 1, hemisphere = varargin{1};
        else error('You must specify right/left hemisphere.');
        end
        switch lower(hemisphere)
            case 'left'
                if checkfields(vw,'leftPath')
                    val = vw.leftPath;
                end
            case 'right'
                if checkfields(vw,'rightPath')
                    val = vw.rightPath;
                end
            otherwise
                error('Unknown hemisphere');
        end
        
        %%%%% EM / General-Gray-related properties
    case 'datavalindex'
        if (~isfield(vw,'emStruct'))
            error('emStruct structure required in the generalGray view');
        end
        val=vw.emStruct.curDataValIndex;
        
    case 'analysisdomain'
        if (~isfield(vw.ui,'analysisDomainButtons'))
            error('This option requires a generalGray vw');
        end
        
        if (get(vw.ui.analysisDomainButtons(1),'Value')), val='time';
        else             val='frequency';
        end
        
        
        %%%%% Flat-related properties
    case 'graycoords'
        % 'graycoords' is also an alias for coords in volume/gray views:
        if ~isequal(vw.viewType, 'Flat')
            val = viewGet(vw, 'Coords');
            return
        end
        
        % Example usage for FLAT view:
        % val = viewGet(vw{1},'graycoords','left');
        if length(varargin) ~= 1,
            error('You must specify which hemisphere.');
        end
        hname = varargin{1};
        switch hname
            case 'left'
                val = vw.grayCoords{1};
            case 'right'
                val = vw.grayCoords{2};
            otherwise
                error('Bad hemisphere name');
        end
    case 'leftpath'
        if checkfields(vw,'leftPath'), val = vw.leftPath; end
    case 'rightpath'
        if checkfields(vw,'rightPath'), val = vw.rightPath; end
    case 'fliplr'
        if checkfields(vw,'flipLR'), val = vw.flipLR; end
    case 'imagerotation'
        if checkfields(vw,'rotateImageDegrees'),val = vw.rotateImageDegrees; end
    case 'hemifromcoords'
        if ~exist('varargin', 'var') || isempty(varargin)
            val = [];
            warning('vista:viewError','Need coords to determine hemisphere');
            return;
        else
            % get left and right nodes to compare to the coords
            l = viewGet(vw, 'allLeftNodes');
            r = viewGet(vw, 'allRightNodes');
            l = l(1:3, :);
            r = r(1:3, :);
            % get coords in proper orientation
            coords = varargin{1};
            if ~isequal(size(coords, 1), 3) && isequal(size(coords, 2), 3)
                coords = coords';
            end
            % nodes are [cor axi sag] but coords are [axi cor sag]
            x = coords(2, :);
            y = coords(1, :);
            z = coords(3, :);
            [tmp right] =  intersectCols(single([x; y; z]), r);
            [tmp left]  =  intersectCols(single([x; y; z]), l);
            val = nan(1,length(x));
            val(left) = 1;
            val(right) = 2;
            val(intersect(left , right)) = nan;
        end
    case 'roihemi'
        if ~exist('varargin', 'var') || isempty(varargin)
            coords = viewGet(vw, 'roiCoords');
        else
            coords = varargin{1};
        end
        hemi = viewGet(vw,  'hemiFromCoords', coords);
        hemi = round(nanmean(hemi));
        if hemi == 1, val = 'left' ;
        elseif hemi == 2, val = 'right';
        else val = []; warning('vista:viewError','Could not determine hemifield');
        end
%%%%% UI properties
    % RFBEDIT: Adding flexibility for hidden views
    case 'ishidden'
        val = strcmp(viewGet(vw, 'name'), 'hidden');
    case 'ui'
        if (checkfields(vw, 'ui'))
            val = vw.ui;
        else
            warning('vista:viewError','No user interface found. Returning empty...');
        end
    case 'fignum'
        if (checkfields(vw, 'ui', 'figNum'))
            val = vw.ui.figNum;
        else
            warning('vista:viewError','No figure number found. Returning empty...');
        end
    case 'windowhandle'
        if (checkfields(vw, 'ui', 'windowHandle'))
            val = vw.ui.windowHandle;
        else
            warning('vista:viewError','No window handle found. Returning empty...');
        end
    case 'displaymode'
        if (checkfields(vw, 'ui', 'displayMode'))
            val = vw.ui.displayMode;
        else
            warning('vista:viewError', 'No display mode found. Returning empty...');
        end
    case 'anatomymode'
        if (checkfields(vw, 'ui', 'anatMode'))
            val = vw.ui.anatMode;
        else
            warning('vista:viewError', 'No anatomy mode found. Returning empty...');
        end
    case 'coherencemode'
        if (checkfields(vw, 'ui', 'coMode'))
            val = vw.ui.coMode;
        else
            warning('vista:viewError', 'No coherence mode found. Returning empty...');
        end
    case 'correlationmode'
        if (checkfields(vw, 'ui', 'corMode'))
            val = vw.ui.corMode;
        else
            warning('vista:viewError', 'No correlation mode found. Returning empty...');
        end
    case 'phasemode'
        if (checkfields(vw, 'ui', 'phMode'))
            val = vw.ui.phMode;
        else
            warning('vista:viewError', 'No phase mode found. Returning empty...');
        end
    case 'amplitudemode'
        if (checkfields(vw, 'ui', 'ampMode'))
            val = vw.ui.ampMode;
        else
            warning('vista:viewError', 'No amplitude mode found. Returning empty...');
        end
    case 'projectedamplitudemode'
        if (checkfields(vw, 'ui', 'projampMode'))
            val = vw.ui.projampMode;
        else
            warning('vista:viewError', 'No projected amplitude mode found. Returning empty...');
        end
    case 'mapmode'
        if (checkfields(vw, 'ui', 'mapMode'))
            val = vw.ui.mapMode;
        else
            warning('vista:viewError', 'No map mode found. Returning empty...');
        end
    case 'zoom'
        if checkfields(vw, 'ui', 'zoom')
            val = vw.ui.zoom;
        else
            warning('vista:viewError', 'No UI zoom setting found. Returning empty...');
        end
    case 'crosshairs'
        if checkfields(vw, 'ui', 'crosshairs')
            val = vw.ui.crosshairs;
        else
            warning('vista:viewError', 'No crosshairs found. Returning empty...');
        end
    case 'locs'
        if ~isfield(vw, 'loc')
            if checkfields(vw, 'ui', 'sliceNumFields')
                % single-orientation vw: get from slice # fields
                str = (get(vw.ui.sliceNumFields, 'String'))';
                for n=1:3, val(n) = str2num(str{n}); end %#ok<ST2NM>
            else
                warning('vista:viewError', 'No cursor location found. Returning empty...');
            end
        else
            val = vw.loc;
        end
        
    case 'phasecma'
        % This returns only the color part of the map
        nGrays = viewGet(vw, 'curnumgrays');
        if (isempty(nGrays)), 
            warning('vista:viewError', 'Number of grays necessary to retrieve phase color map. Returning empty...'); 
            return;
        end
        if (checkfields(vw, 'ui', 'phMode', 'cmap'))
            val = round(vw.ui.phMode.cmap(nGrays+1:end,:) * 255)';
        else
            warning('vista:viewError', 'No phase color map found. Returning empty...');
        end
    case 'cmapcurrent'
        nGrays = viewGet(vw, 'curnumgrays');
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode) || isempty(nGrays)), 
            warning('vista:viewError', 'Display mode/number of grays necessary to retrieve color map. Returning empty...'); 
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'cmap'))
            val = round(vw.ui.(displayMode).cmap(nGrays+1:end,:) * 255)';
        else
            warning('vista:viewError', 'No color map found for display mode ''%s''. Returning empty...', displayMode);
        end

    case 'cmapcurmodeclip'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)), 
            warning('vista:viewError', 'Display mode necessary to retrieve clip mode. Returning empty...'); 
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'clipMode'))
            val = vw.ui.(displayMode).clipMode;
        else
            warning('vista:viewError', 'No clip mode found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'cmapcurnumgrays'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)), 
            warning('vista:viewError', 'Display mode necessary to retrieve number of grays. Returning empty...'); 
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'numGrays'))
            val = vw.ui.(displayMode).numGrays;
        else
            warning('vista:viewError', 'No number of grays found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'cmapcurnumcolors'
        displayMode = viewGet(vw, 'displayMode');
        if (isempty(displayMode)), 
            warning('vista:viewError', 'Display mode necessary to retrieve number of colors. Returning empty...'); 
            return;
        end
        
        displayMode = [displayMode 'Mode'];
        if (checkfields(vw, 'ui', displayMode, 'numColors'))
            val = vw.ui.(displayMode).numColors;
        else
            warning('vista:viewError', 'No number of grays found for display mode ''%s''. Returning empty...', displayMode);
        end
    case 'flipud'
        % Return the boolean indicating whether to invert the image u/d in
        % the graphical user interface.  It is sometimes convenient to do
        % this in the Inplane view if the top of the slice corresponds to
        % the bottom of the brain.
        % Example: 
        %   flipud = viewGet(vw, 'flip updown');
        if checkfields(vw, 'ui', 'flipUD'), val = vw.ui.flipUD;
        else                                val = 0; end
    otherwise
        error('Unknown viewGet parameter');
        
end		% big SWITCH statement

return


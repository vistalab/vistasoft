function vw = viewSet(vw,param,val,varargin)
%Organize methods for setting view parameters.
%  
%   vw = viewSet(vw,param,val,varargin)
%
% Example:
%   vw = viewSet(vw, 'cothresh', 0.1);
%
% Author: Wandell
%  
% See also viewGet, viewMapParameterField
%
% These are the cases that can be set (as of July 5, 2011):
%
% %%%%% Session-related properties; selected scan, slice, data type
%      'homedir'
%      'sessionname'
%      'subject'
%      'name'
%      'viewtype'
%      'subdir'
%      'curdt'
%      'curslice'
%      'curscan'
%      'datavalindex'
%
% %%%%% Traveling-Wave / Coherence Analysis properties
%      'coherence'
%      'scanco'
%      'phase'
%      'scanph'
%      'amplitude'
%      'scanamp'
%      'phwin'
%      'cothresh'
%      'refph'
%      'ampclip'
%      'framestouse'
%
% %%%%% Map properties
%      'map'
%      'mapname'
%      'mapunits'
%      'mapclip'
%      'mapwin'
%      'scanmap'
%
% %%%%% Anatomy / Underlay-related properties
%      'anatomy'
%      'brightness'
%      'contrast'
%
% %%%%% ROI-related properties
%      'roi'
%      'rois'
%      'selectedroi'
%      'roioptions'
%      'filledperimeter'
%      'maskrois'
%      'roivertinds'
%      'showrois'
%      'hidevolumerois'
%      'roidrawmethod'
%      'roiname'
%      'roicoords'
%      'roimodified'
%
% %%%%% Time-series related properties
%      'tseries'
%      'tseriesslice'
%      'tseriesscan'
%
% %%%%% Retinotopy/pRF Model related properties
%      'rmfile'
%      'rmmodel'
%      'rmparams'
%      'rmstimparams'
%      'rmmodelnum'
%
% %%%% Mesh-related properties
%      'leftclassfile'
%      'rightclassfile'
%      'leftgrayfile'
%      'rightgrayfile'
%
% %%%%% these params interface with the mrMesh functions
%      'mesh'
%      'currentmesh'
%      'allmeshes'
%      'addmesh'
%      'meshdata'
%      'meshn'
%      'deletemesh'
%      'recomputev2gmap'
%
% %%%%% Volume/Gray-related properties
%      'nodes'
%      'edges'
%      'allleftnodes'
%      'allleftedges'
%      'allrightnodes'
%      'allrightedges'
%      'coords'
%      'mmpervox'
%
% %%%%% UI properties
%      'initdisplaymodes'
%      'ui'
%      'anatomymode'
%      'coherencemode'
%      'correlationmode'
%      'phasemode'
%      'amplitudemode'
%      'projectedamplitudemode'
%      'mapmode'
%      'displaymode'
%      'phasecma'
%      'cmap'
%      'locs'
%      'flipud'

% ras, 06/07: eliminated subfunctions for each view (ipGet, volGet,
%			  flatGet); all one big SWITCH statement now.
%
% JW: 2/2011: viewSet and viewGet now take the input parameter field and
%               call viewMapParameterField before the long switch/case.
%               This function returns a standardized parameter field name.
%               It removes spaces and captials, and maps multiple names
%               (aliases) onto a single name. If you add a new parameter
%               (new case) to viewGet or viewSet, please use only a single
%               standardized parameter name in the viewGet and viewSet
%               functions. You can put as many aliases as you like in
%               viewMapParameterField.
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
%
%


if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

%%%%%%%%%%%%%%%%%%%%%%%%
% Big SWITCH Statement %
%%%%%%%%%%%%%%%%%%%%%%%%
% This statement will check for all possible properties,
% for all view types. I tried to gruop them in a reasonable
% way.
mrGlobals;

% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);

switch param
    
    %%%%% Session-related properties; selected scan, slice, data type
    case 'homedir'
        HOMEDIR = val;  %#ok<NASGU>
    case 'sessionname'
        vw.sessionCode = val;
        %TODO: Make a change to the view instead of session
    case 'subject'
        vw.subject = val;
        %TODO: Make a change to the view instead of session
    case 'name'
        vw.name = val;
    case 'viewtype'
        vw.viewType = val;
    case 'subdir'
        vw.subdir = val;
    case 'curdt'
        if isnumeric(val), vw = selectDataType(vw, val); end
        if ischar(val)
            match = false;
            for dt =1:length(dataTYPES) %#ok<*NODEF>
                if strcmpi(val, dataTYPES(dt).name), vw = viewSet(vw, 'curdt', dt); end
                match = true;
            end
            if ~match, warning('vista:viewError', 'DataTYPE %s not found', val); end
        end
        
    case 'curslice'
		sliceNum = val;
        vw.tSeriesSlice = sliceNum;
        
        if isequal(vw.name,'hidden')
            return
        end
        
        switch vw.viewType
            case 'Inplane'
                setSlider(vw,vw.ui.slice, sliceNum);
                
                % remove the trailing digits
                str = sprintf('%.0f', sliceNum);
                set(vw.ui.slice.labelHandle, 'String', str);
                
            case {'Volume', 'Gray'}
                volSize = viewSize(vw);
                sliceOri=getCurSliceOri(vw);
                sliceNum=clip(val,1,volSize(sliceOri));
                set(vw.ui.sliceNumFields(sliceOri), 'String',num2str(sliceNum));
                
            case 'Flat' % this case accomplishes nothing since the variable h is not used.
                if checkfields(vw, 'numLevels')
                    % 'flat-level' view
                    if val > 2 + vw.numLevels(1), h = 2;
                    else                          h = 1; end
                else
                    % regular flat view
                    if val <= 2
                        h = val; %sliceNum 
                    else
                        h = [1 2];  % both hemispheres at once
                    end
                end
                selectButton(vw.ui.sliceButtons,h)
        end
        
    case 'refreshfn'
        vw.refreshFn = val;
        
    case 'curscan'
        %vw = setCurScan(vw,val);
        vw.curScan = val;
        % If we have a GUI open, update it as well:
        if checkfields(vw, 'ui', 'scan'),
            setSlider(vw,vw.ui.scan,val,0);
        end
        
    case 'datavalindex'
        % Only works on the generalGray view type
        if ~isequal(vw.viewType, 'generalGray')
            error('Can only set DataValIndex in General Gray views.')
        end
        vw.emStruct.curDataValIndex=val;
        
        %%%%% Traveling-Wave / Coherence Analysis properties
    case 'coherence'
        % This must be a cell array of 1 x nScans
        vw.co = val;
    case 'scanco'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.co{scan} = val;
    case 'phase'
        vw.ph = val;
    case 'scanph'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.ph{scan} = val;
    case 'amplitude'
        vw.amp = val;
    case 'scanamp'
        if length(varargin) < 1, error('You must specify a scan number.'); end
        scan = varargin{1};
        vw.ph{scan} = val;
    case 'phwin'
        %vw = setPhWindow(vw, val);
        if length(val) ~= 2,
            error('[%s]: 2 values needed to set phase window', mfilename);
        end
        if strcmpi(viewGet(vw, 'name'), 'hidden')
            % hidden view: set in a special settings field
            vw.settings.phWin = val;
            
        else
            % non-hidden view: set in UI
            setSlider(vw, vw.ui.phWinMin, val(1));
            setSlider(vw, vw.ui.phWinMax, val(2));
            
        end
    case 'spatialgrad'
        vw.spatialGrad = val;
    case 'cothresh'
        vw = setCothresh(vw, val);
    case 'refph'
        vw.refPh = val;
    case 'ampclip'
        if checkfields(vw, 'ui', 'ampMode', 'clipMode')
            vw.ui.ampMode.clipMode = val;
            vw = refreshScreen(vw);
        else
            error('Can''t set Amp Clip Mode -- no UI information in this view.');
        end
        
    case 'framestouse'
        % Set the time frames in the current or specified
        % scan to be used for coranal (block) analyses
        % Example:
        %   scan = 1;
        %   nframes = viewGet(vw, 'nframes', scan);
        %   vw = viewSet(vw,'frames to use', 7:nframes, scan);
        %  
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt         = viewGet(vw, 'dtStruct');
        blockParms = dtGet(dt,'bparms');
        blockParms(scan).framesToUse = val;
        dt = dtSet(dt, 'blockparams', blockParms);
        dtnum = viewGet(vw, 'current dt');
        dataTYPES(dtnum) = dt; %#ok<NASGU>
        
        %%%%% Map properties
    case 'map'
        vw.map = val;
    case 'mapname'
        if isequal(lower(val), 'dialog')
            % dedicated dialog for map name / units / clip
            vw = mapNameDialog(vw);
        else
            vw.mapName = val;
        end
    case 'mapunits'
        vw.mapUnits = val;
    case 'mapclip'
        if checkfields(vw, 'ui', 'mapMode')
            vw.ui.mapMode.clipMode = val;
            vw = refreshScreen(vw);
        else
            warning('vista:viewError', ...
                'Can''t set Map Clip Mode -- no UI information in this view.');
        end
    case 'mapwin'
        vw = setMapWindow(vw, val);
    case 'scanmap'
        if length(varargin) < 1, scan = viewGet(vw, 'curscan'); 
        else                     scan = varargin{1}; end
        vw.map{scan} = val;
    case 'zoom'
           vw.ui.zoom = val;        
       
           %%%%% Anatomy / Underlay-related properties
    case 'anatomy'
        vw.anat.data = val;
    case 'brightness'
        vw = setSlider(vw, vw.ui.brightness, val);
    case 'contrast'
        setSlider(vw, vw.ui.contrast, val);
    case 'inplanepath'
        vw.anat.inplanepath = val;
    case 'anatinitialize'
        %Expects a path as the value
        %Read in the nifti from the path value
        vw = viewSet(vw,'Anatomy Nifti', niftiRead(val));
        %Calculate Voxel Size as that is not read in
        vw = viewSet(vw,'Anatomy Nifti', niftiSet(viewGet(vw,'Anatomy Nifti'),'Voxel Size',prod(niftiGet(vw.anat,'pixdim'))));

        %Let us also calculate and and apply our transform
        vw = viewSet(vw,'Anatomy Nifti',niftiApplyAndCreateXform(viewGet(vw,'Anatomy Nifti'),'Inplane'));
    case 'anatomynifti'
        vw.anat = val; %This means that we are passing in an entire Nifti!
        
        %%%%% ROI-related properties
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
        % What are the valid methods?  Indicate here!
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

        %% Time-series related properties
    case 'tseries'
        vw.tSeries = val;
    case 'tseriesslice'
        vw.tSeriesSlice = val;
    case 'tseriesscan'
        vw.tSeriesScan = val;
        
        %% Retinotopy/pRF Model related properties
    case 'rmfile'
        vw.rm.retinotopyModelFile = val;
    case 'rmmodel'
        vw.rm.retinotopyModels = val;
    case 'rmparams'
        vw.rm.retinotopyParams = val;
    case 'rmstimparams'
        vw.rm.retinotopyParams.stim = val;
    case 'rmmodelnum'
        if isequal(val, 'dialog')
            val = rmSelectModelNum(vw);
            vw.rm.modelNum = val;
        else
            vw.rm.modelNum = val;
        end
        
        %% Mesh-related properties
        % these params relate to the segmentation / coords.mat file
    case {'leftclassfile' 'rightclassfile' 'leftgrayfile' 'rightgrayfile'};
        
        %% Vol/Gray check
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            error(['Can only set %s property in ' ...
                'Volume / Gray views.'], param);            
        end
        
        % get the field name for this parameter
        switch lower(param)
            case 'leftclassfile'
                fieldName = 'leftClassFile';
            case 'rightclassfile'
                fieldName = 'rightClassFile';
            case 'leftgrayfile'
                fieldName = 'leftPath';
            case 'rightgrayfile'
                fieldName = 'rightPath';
        end
        
        % set field in view
        vw.(fieldName) = val;
        
        % also save this parameter in the coords file, so it remembers.
        %   eval( [fieldName ' = ''' val ''';'] );
        %   coordsFile = fullfile(viewDir(vw), 'coords.mat');
        %   if exist(coordsFile, 'file')
        % 	  save(coordsFile, fieldName, '-append');
        % 	  fprintf('Updated %s with new file information.', coordsFile);
        %   end
        
        %% these params interface with the mrMesh functions
    case {'mesh' 'currentmesh' 'allmeshes' 'addmesh' 'meshdata' ...
            'meshn'  'deletemesh'}
        %% Vol/Gray check
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            error(['Can only set %s property in ' ...
                'Volume / Gray views.'], param);            
        end
        
        switch lower(param)
            case 'mesh'
                % viewSet(vw,'mesh',val,whichMesh)
                if ~isempty(varargin), whichMesh = varargin{1};
                else whichMesh = viewGet(vw,'currentmeshn');
                end
                
                if isempty(val), vw = viewSet(vw, 'deleteMesh', whichMesh);
                else vw.mesh{whichMesh} = val;
                end
                
            case 'currentmesh'
                whichMesh = viewGet(vw,'currentmeshn');
                vw.mesh{whichMesh} = val;
            case 'allmeshes'
                vw.mesh = val;
            case 'addmesh'
                % viewSet(vw{1},'addmesh',msh,3);
                if ~isempty(varargin), newMeshNum = varargin{1};  % User specified the mesh number
                elseif(isfield(vw,'mesh')), newMeshNum = length(vw.mesh)+1; % add to meshes
                else newMeshNum = 1;                       % or make it the first mesh.
                end
                if ~meshCheck(val),warning('vista:viewError', 'Non-standard mesh being added'); end
                vw.mesh{newMeshNum} = val;
                
                % allow for GUI elements to specify the selected mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    h = vw.ui.menus.meshSelected;
                    
                    % index for new menu
                    n = newMeshNum + 1; % 1st entry=top menu
                    
                    % create the menu
                    label = sprintf('%i. %s', val.id, val.name);
                    cb = sprintf('%s = viewSet(%s, ''CurMeshNum'', %i); ', ...
                        vw.name, vw.name, newMeshNum);
                    h(n) = uimenu(h(1), 'Label', label, 'Callback', cb);
                    
                    % update the view handles
                    vw.ui.menus.meshSelected = h;
                    
                    
                    % if we're using the new gray menu, we want to make sure
                    % the mesh-specific options, such as projecting data onto
                    % the mesh or
                    set( allchild(vw.ui.menus.gray), 'Enable', 'on');
                    meshSettingsList(vw.mesh{newMeshNum});
                end
                
                % select the new mesh
                vw = viewSet(vw, 'currentmeshn', newMeshNum);
                
            case 'meshdata'
                curMesh = viewGet(vw,'meshn');
                vw.mesh{curMesh}.data = val;
            case 'meshn'
                vw.meshNum3d = val;
                
                % allow for GUI elements to specify the selected mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    try
                        h = vw.ui.menus.meshSelected;
                        set(h, 'Checked', 'off'); % de-select all menus
                        set(h(val+1), 'Checked', 'on'); % select appropriate menu (1st entry=top menu)
                        
                        if checkfields(vw, 'mesh')
                            meshSettingsList(vw.mesh{val});
                        end
                    catch ME
                        warning(ME.identifier, ME.message);
                    end
                end
                
            case 'deletemesh'
                % USAGE: viewSet(vw, 'Delete Mesh', meshNum);
                % allow several meshes to be specified for deletion at once
                if length(val) > 1
                    % we need to go from highest to lowest value: since
                    % removing a mesh reduces the total number of meshes, if we
                    % e.g removed #1 then #2, the second index would point to a
                    % mesh value which no longer exists
                    meshList =  sort(val(:), 'descend');
                    for ii = 1:length(meshList)
                        whichMesh = meshList(ii);
                        vw = viewSet(vw, 'deleteMesh', whichMesh);
                    end
                    return
                end
                
                % if a mesh window is open, close it:
                if vw.mesh{val}.id > 0
                    vw = meshCloseWindow(vw, val);
                end
                
                % remove the mesh entry from the mesh cell array:
                keep = setdiff(1:length(vw.mesh), val);
                vw.mesh = vw.mesh(keep);
                if ~isempty(vw.mesh), 
                    vw = viewSet(vw, 'currentmeshn', max(1,min(val)-1));
                end
                
                % Remove any menus specifying this mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    try
                        h = vw.ui.menus.meshSelected;
                        delete( h(val+1) ); % +1 because 1st entry is top menu
                        %h = h([1 keep+1]); % this line doesn't seem to do anything
                        vw.ui.menus.meshSelected = h(1:val);
                    catch ME
                        warning(ME.identifier, ME.message);
                        disp('Warning: Couldn''t remove deleted mesh menu.')
                    end
                end
                
                % If there are no meshes left in the array, we clear the mesh
                % array and select mesh 0.
                if isempty(vw.mesh)
                    vw = rmfield(vw, 'mesh');
                    vw = viewSet(vw,'currentmeshn',0);
                end
                
        end
        
    case 'recomputev2gmap'
        msh = viewGet(vw, 'Mesh');
        vertexGrayMap = mrmMapVerticesToGray( ...
            meshGet(msh, 'initialvertices'), ...
            viewGet(vw, 'nodes'), ...
            viewGet(vw, 'mmPerVox'), ...
            viewGet(vw, 'edges'));
        msh = meshSet(msh, 'vertexgraymap', vertexGrayMap);
        vw = viewSet(vw, 'Mesh', msh);
        
        %%%%% Volume/Gray-related properties
    case {'nodes' 'edges' 'allleftnodes' 'allleftedges' ...
            'allrightnodes' 'allrightedges'}
        
        %% Vol/Gray check
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
        %% Vol/Gray/Flat check
        if ~ismember(vw.viewType, {'Volume' 'Gray' 'Flat'})
            error(['Can only set %s property in ' ...
                'Volume / Gray / Flat views.'], param);            
        else
            vw.coords = val;
        end
        
    case 'mmpervox'
        vw.mmPerVox = val;
        
        %%%%% Flat-related properties
        % I guess there aren't any that aren't also Volume/Gray params?
        
        %%%%% UI properties
    case 'initdisplaymodes'
        vw = resetDisplayModes(vw);
    case 'ui'
        vw.ui = val;
    case 'anatomymode'
        vw.ui.anatMode = val;
    case 'coherencemode'
        vw.ui.coMode = val;
    case 'correlationmode'
        vw.ui.corMode = val;
    case 'phasemode'
        vw.ui.phMode = val;
    case 'fignum'
        vw.ui.figNum = val;
    case 'windowhandle'
        vw.ui.windowHandle = val;
    case 'mainaxishandle'
        vw.ui.mainAxisHandle = val;
    case 'colorbarhandle'
        vw.ui.colorbarHandle = val;
    case 'cbarrange'
        vw.ui.cbarRange = val;
    case 'amplitudemode'
        vw.ui.ampMode = val;
    case 'uiimage'
        vw.ui.image = val;
    case 'projectedamplitudemode'
        vw.ui.projampMode = val;
    case 'mapmode'
        vw.ui.mapMode = val;
    case 'displaymode'
        vw.ui.displayMode = val;
    case 'phasecma'
        nGrays = viewGet(vw, 'curnumgrays');
        
        % allow transposed version (3 x n) instead of usual matlab cmap order (n x 3)
        if size(val, 2) > 3 && size(val, 1)==3, val = val'; end
        if max(val(:)) > 1, val = val ./ 255;               end
        vw.ui.phMode.cmap((nGrays+1):end,:) = val ;
        
    case 'cmap' 
        % RFBEDIT: Adding flexibility for hidden views
        nGrays      = viewGet(vw, 'curnumgrays');
        displayMode = viewGet(vw, 'displayMode');
        
        % allow transposed version (3 x n) instead of usual matlab cmap order (n x 3)
        if size(val, 2) > 3 && size(val, 1)==3,	val = val'; end
        if max(val(:)) > 1, val = val ./ 255;		end
        
        displayMode = [displayMode 'Mode'];
        vw.ui.(displayMode).cmap(nGrays+1:end,:) = val;
        vw.ui.(displayMode).name = 'user';
        
    case 'locs'
        % cursor location as [axi cor sag]
        vw.loc = val;
        if checkfields(vw, 'ui', 'sliceNumFields')  % set UI fields
            for n = 1:3
                set(vw.ui.sliceNumFields(n), 'String', num2str(val(n)));
            end
        end
    case 'crosshairs'
        vw.ui.crosshairs = val;
    case 'flipud'
        % Boolean indicating whether to invert the image u/d in
        % the graphical user interface.  It is sometimes convenient to do
        % this in the Inplane view if the top of the slice corresponds to
        % the bottom of the brain.
        % Example:
        %   vw = viewSet(vw, 'flip updown', true);
        if checkfields(vw, 'ui'),   vw.ui.flipUD = val; end
    
      otherwise
        error('Unknown view parameter %s.', param);
        
end			% End big SWITCH statement

return;


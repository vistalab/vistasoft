function val = viewGet(vw,param,varargin)
% Get data from various view structures
%
%   val = viewGet(vw,param,varargin{:})
%
% Reads the parameters of a view struct. Lists out all of the possible
% parameters 
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
%     'refreshfn'
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
%     'spatialgrad'
%     'ncycles'
%     'framestouse'
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
%     'anatslicedims'
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
%     'anatomycurrentslice'
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
%     'functionalslicedim'
%     'tseries'
%     'tseriesslice'
%     'tseriesscan'
%     'tr'
%     'nframes'
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
%     'mainaxishandle'
%     'locs'
%     'phasecma'
%     'cmapcurrent'
%     'cmapcurmodeclip'
%     'cmapcurnumgrays'
%     'cmapcurnumcolors'
%     'flipud'
%     'uiimage'
%     'cbarrange'
%     'colorbarhandle'


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
% AS: 5/2013: viewGet and viewSet have now been split out into each
% function to prevent them from getting too long. As well, new
% functionality has been added for 'viewGet('list')' and 'viewGet('help')'
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

if ~exist('vw','var'), vw = getCurView; end

val = [];

if ischar(vw)
    %This means that we are using the new functionality to list the
    %parameter set
    
	vw = mrvParamFormat(vw);

    %Check to see if we are asking for just one or all parameters:
    if ~exist('param','var'), viewMapParameterField(vw, 1);
    else viewMapParameterField(vw,1,mrvParamFormat(param));
    end
 %Using the new functionality
    return %early since we don't want to go through the rest
end %if

if ~exist('param','var'), error('No parameter defined'); end

%Format the parameter as lowercase and without spaces
param = mrvParamFormat(param);

% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);
splitParam = viewMapParameterSplit(param);


switch splitParam
    case 'anatomy'
        val = viewGetAnatomy(vw,param,varargin{:});
    case 'colorbar'
        val = viewGetColorbar(vw,param,varargin{:});
    case 'em'
        val = viewGetEm(vw,param,varargin{:});
    case 'flat'
        val = viewGetFlat(vw,param,varargin{:});
    case 'map'
        val = viewGetMap(vw,param,varargin{:});
    case 'mesh'
        val = viewGetMesh(vw,param,varargin{:});
    case 'retinotopy'
        val = viewGetRetinotopy(vw,param,varargin{:});
    case 'roi'
        val = viewGetROI(vw,param,varargin{:});
    case 'session'
        val = viewGetSession(vw,param,varargin{:});
    case 'timeseries'
        val = viewGetTimeSeries(vw,param,varargin{:});
    case 'travelingwave'
        val = viewGetTravelingWave(vw,param,varargin{:});
    case 'ui'
        val = viewGetUI(vw,param,varargin{:});
    case 'volume'
        val = viewGetVolume(vw,param,varargin{:});
    otherwise
        error('Unknown viewGet parameter');
end %switch

return

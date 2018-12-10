function vw = viewSet(vw,param,val,varargin)
%Organize methods for setting view parameters.
%  
%   vw = viewSet(vw,param,val,val,varargin)
%
% Example:
%   vw = viewSet(vw, 'cothresh', 0.1);
%
% Author: Wandell
%  
% See also viewSet, viewMapParameterField
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
%      'ncycles'
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
%      'inplanepath'
%      'anatinitialize'
%      'anatomynifti'
%      'inplaneorientation'
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
%      'roicomments'
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
% JW: 2/2011: viewSet and viewSet now take the input parameter field and
%               call viewMapParameterField before the long switch/case.
%               This function returns a standardized parameter field name.
%               It removes spaces and captials, and maps multiple names
%               (aliases) onto a single name. If you add a new parameter
%               (new case) to viewSet or viewSet, please use only a single
%               standardized parameter name in the viewSet and viewSet
%               functions. You can put as many aliases as you like in
%               viewMapParameterField.
% 
% For example: 
%    viewMapParameterField('curdt') 
% and
%   viewMapParameterField('Current Data TYPE') 
% both return 'curdt'. This means that
%    viewSet(vw, 'curdt') 
% and
%    viewSet(vw, 'Current Data TYPE') 
% are equivalent. Hence viewSet and viewSet should have the case 'curdt'.
% They do not need the case 'Current Data TYPE' or 'currentdatatype'.
%
%


if ~exist('vw', 'var'),  error('No view defined.'); end
if notDefined('val'), val = []; end

%%%%%%%%%%%%%%%%%%%%%%%%
% Big SWITCH Statement %
%%%%%%%%%%%%%%%%%%%%%%%%
% This statement will check for all possible properties,
% for all view types.
mrGlobals;

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

if notDefined('param'), error('No parameter defined'); end

%Format the parameter as lowercase and without spaces
param = mrvParamFormat(param);

% Standardize the name of the parameter field with name-mapping function
param = viewMapParameterField(param);
splitParam = viewMapParameterSplit(param);


switch splitParam
    case 'anatomy'
        vw = viewSetAnatomy(vw,param,val,varargin{:});
    case 'colorbar'
        vw = viewSetColorbar(vw,param,val,varargin{:});
    case 'em'
        vw = viewSetEm(vw,param,val,varargin{:});
    case 'flat'
        vw = viewSetFlat(vw,param,val,varargin{:});
    case 'map'
        vw = viewSetMap(vw,param,val,varargin{:});
    case 'mesh'
        vw = viewSetMesh(vw,param,val,varargin{:});
    case 'retinotopy'
        vw = viewSetRetinotopy(vw,param,val,varargin{:});
    case 'roi'
        vw = viewSetROI(vw,param,val,varargin{:});
    case 'session'
        vw = viewSetSession(vw,param,val,varargin{:});
    case 'timeseries'
        vw = viewSetTimeSeries(vw,param,val,varargin{:});
    case 'travelingwave'
        vw = viewSetTravelingWave(vw,param,val,varargin{:});
    case 'ui'
        vw = viewSetUI(vw,param,val,varargin{:});
    case 'volume'
        vw = viewSetVolume(vw,param,val,varargin{:});
    otherwise
        error('Unknown viewSet parameter');        
end %switch

return;


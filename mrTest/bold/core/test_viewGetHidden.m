function test_viewGetHidden
%Validate calls to viewGet in the hidden inplane view. 
%
%   test_viewGetHidden()
%
% 
% Tests: intiHiddenInplane, viewSet, viewGet
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_viewGetHidden()
%
% See also MRVTEST TEST_VIEWGETINPLANE
%
% Copyright Stanford team, mrVista, 2012
%
%
% 
%   TODO: At the bottom of this function is a list of all viewGet calls that have
%   not yet been implemented in this function. Eventually we would like to
%   implement (i.e, validate) all cases that apply to INPLANE views.
%
%   To make life simple, we would like a number (or numbers) returned from
%   every call. Hence for calls that return text or cell arrays, we
%   calculate some simple statistic like the length of the array.
%
%   Some calls to viewGet, such as 'current scan' and 'current slice' can
%   change if the user has saved preferences with these values. This can
%   happen surreptitously if vista prefs are set to always save preferences
%   upon closing a session. Therefore, we first set the value of these
%   fields before proceeding to the viewGets.  For fields such as 'subject'
%   or 'number of frames' which will not change, we do not use a viewSet.


%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
stored = mrtGetValididationData('viewGetHidden');

% [pth, tmp]  = fileparts(viewGet(vw, 'Home Directory')); %#ok<ASGLU>\
% stored.homedir        = length(tmp);
% stored.sessionName    = length(viewGet(vw, 'session name'));
% stored.subject        = length(viewGet(vw, 'subject'))
% stored.name           = length(viewGet(vw, 'name'))
% stored.annotation = length(viewGet(vw, 'annotation', 1));
% stored.annotations = numel(viewGet(vw, 'annotations')); 
% stored.viewtype = length(viewGet(vw, 'View Type'));
% stored.subdir = length(viewGet(vw, 'subdir'));
% stored.curscan = viewGet(vw, 'curscan');
% stored.curslice = viewGet(vw, 'current slice');
% stored.nscans = viewGet(vw, 'num scans');
% stored.nslices = viewGet(vw, 'num slices');
% stored.dtname = length(viewGet(vw, 'dt name'));
% stored.curdt = viewGet(vw, 'current dt');
% stored.dtstruct = numel(fieldnames(viewGet(vw, 'dtstruct')));
% tmp       =  viewGet(vw, 'coherence');
% stored.coherence = nanmean(tmp{1}(:));
% tmp       =  viewGet(vw, 'scanco');
% stored.scanco = nanmean(tmp(:));
% tmp       =  viewGet(vw, 'phase');
% stored.phase = nanmean(tmp{1}(:));
% tmp       =  viewGet(vw, 'scanph');
% stored.scanph = nanmean(tmp(:));
% tmp       =  viewGet(vw, 'amplitude');
% stored.amplitude = nanmean(tmp{1}(:));
% tmp       =  viewGet(vw, 'scanamp');
% stored.scanamp = nanmean(tmp(:));
% vw = viewSet(vw, 'reference phase', pi);
% stored.refph = viewGet(vw, 'reference phase');
% vw = viewSet(vw, 'cothresh', .1);
% stored.cothresh = viewGet(vw, 'cothresh');
% vw = viewSet(vw, 'phasewin', [pi/4 3*pi/4]);
% stored.phasewin = viewGet(vw, 'phasewin');
% stored.twparams = viewGet(vw, 'twparams');
% vw=loadMeanMap(vw);
% tmp       =  viewGet(vw, 'map');
% stored.map = nanmean(tmp{1}(:));
% tmp       =  viewGet(vw, 'scanmap');
% stored.scanmap = nanmean(tmp(:));
% stored.mapwin = viewGet(vw, 'mapwin');
% stored.mapname = length(viewGet(vw, 'mapname'));
% stored.mapunits = length(viewGet(vw, 'mapunits'));
% stored.mapclip = viewGet(vw, 'mapclip');
% save(vFile, '-struct',  'stored')


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Get data structure:
vw = initHiddenInplane; 
mrGlobals;


%% Set data structure properties:
vw = viewSet(vw, 'current dt', 1); 
vw = viewSet(vw, 'current scan', 1); 

%%
% Home Directory
[pth, tmp]  = fileparts(viewGet(vw, 'Home Directory')); %#ok<ASGLU>
assertEqual(stored.homedir,length(tmp));

% session name
assertEqual(stored.sessionName, length(viewGet(vw, 'session name')));

% subject
assertEqual(stored.subject, length(viewGet(vw, 'subject')));

% name
assertEqual(stored.name, length(viewGet(vw, 'name')));

% annotation
%   This is empty in the sample data set so we must set it first
dt = viewGet(vw, 'dt struct');

for scan = 1:viewGet(vw, 'num scans')
    dt = dtSet(dt, 'annotation', sprintf('scan %d', scan), scan);
end
dtnum = viewGet(vw, 'current dt');
dataTYPES(dtnum) = dt;
 assertEqual(stored.annotation, length(viewGet(vw, 'annotation', 1)));

% annotations
assertEqual(stored.annotations, numel(viewGet(vw, 'annotations'))); 

% viewtype
assertEqual(stored.viewtype, length(viewGet(vw, 'View Type')));

% subdir 
assertEqual(stored.subdir, length(viewGet(vw, 'subdir')));

% current scan 
assertEqual(stored.curscan, viewGet(vw, 'curscan'));

% current slice (empty in hidden view)
assertEqual(stored.curslice, viewGet(vw, 'current slice'));

% n scans
assertEqual(stored.nscans, viewGet(vw, 'num scans'));

% n slices
assertEqual(stored.nslices, viewGet(vw, 'num slices'));

% dt name
assertEqual(stored.dtname, length(viewGet(vw, 'dt name')));

% curdt
assertEqual(stored.curdt, viewGet(vw, 'current dt'));

% dtstruct
assertEqual(stored.dtstruct, numel(fieldnames(viewGet(vw, 'dtstruct'))));

% coranal fields...
vw = loadCorAnal(vw);

% coherence
tmp       =  viewGet(vw, 'coherence');
assertEqual(stored.coherence, nanmean(tmp{1}(:)));

% scanco
tmp       =  viewGet(vw, 'scanco');
assertEqual(stored.scanco, nanmean(tmp(:)));

% phase
tmp       =  viewGet(vw, 'phase');
assertEqual(stored.phase, nanmean(tmp{1}(:)));

% scanph
tmp       =  viewGet(vw, 'scanph');
assertEqual(stored.scanph, nanmean(tmp(:)));

% amplitude
tmp       =  viewGet(vw, 'amplitude');
assertEqual(stored.amplitude, nanmean(tmp{1}(:)));

% scanph
tmp       =  viewGet(vw, 'scanamp');
assertEqual(stored.scanamp, nanmean(tmp(:)));

%refph
vw = viewSet(vw, 'reference phase', pi);
assertEqual(stored.refph, viewGet(vw, 'reference phase'));

%colormaps: NA for hidden views. If we implement v_viewGetINPLANE we can
%           use this bit of code.
%   val.ampmap = viewGet(vw, 'ampmap');
%   val.comap  = viewGet(vw, 'coherencemap');
%   val.cormap = viewGet(vw, 'correlationmap');
%   val.cmap   = viewGet(vw, 'cmap');
%   val.cmapcolor   = viewGet(vw, 'cmapcolor');
%   val.cmapgrayscale   = viewGet(vw, 'cmapgrayscale');


% cothresh
vw = viewSet(vw, 'cothresh', .1);
assertEqual(stored.cothresh, viewGet(vw, 'cothresh'));

% phasewin
vw = viewSet(vw, 'phasewin', [pi/4 3*pi/4]);
assertEqual(stored.phasewin, viewGet(vw, 'phasewin'));

% twparams - empty because travelling wave params are not set in this session
assertEqual(stored.twparams, viewGet(vw, 'twparams'));

% map properties
% scan = 1; forceSave = -1; % -1 = don't save at all
% vw = computeMeanMap(vw, scan, forceSave);
vw = loadMeanMap(vw);
vw = viewSet(vw, 'map window', [0 5000]);

% map
tmp       =  viewGet(vw, 'map');
assertVectorsAlmostEqual(stored.map, nanmean(tmp{1}(:)), 'relative');

% scanmap
tmp       =  viewGet(vw, 'scanmap');
assertVectorsAlmostEqual(stored.scanmap, nanmean(tmp(:)), 'relative');

% mapwin
assertVectorsAlmostEqual(stored.mapwin, viewGet(vw, 'mapwin'), 'relative');

% mapname
assertEqual(stored.mapname, length(viewGet(vw, 'mapname')));

% map units (empty in mean map)
assertEqual(stored.mapunits, length(viewGet(vw, 'mapunits')));

% map clip (empty in hidden view)
assertEqual(stored.mapclip, viewGet(vw, 'mapclip'));

cd(curDir)

mrvCleanWorkspace;

%% NYI

%         %%%%% Anatomy / Underlay-related properties
%     'anatomy'
%     'anatomymap'
%     'anatclip'
%     'anatsize'
%     'anatsizexyz'
%     'brightness'
%     'contrast'
%     'mmpervox'
%     'ngraylayers'
%     'scannerxform'
%     'b0dir'
%     'b0angle'
%         %%%%% ROI-related properties
%     'rois'
%     'roistruct'
%     'roicoords'
%     'roiindices'
%     'roivertinds'val.coherence         =  viewGet(vw, 'coherence')
%     'roiname'
%     'allroinames'
%     'selectedroi'
%     'filledperimeter'
% 	  'selroicolor'
%     'prevcoords'
%     'roistodisplay'
%     'roidrawmethod'
%     'showrois'
%     'hidevolumerois'
%     'maskrois'
%         %%%%% Time-series related properties
%     'tseriesdir'
%     'datasize'
%     'dim'
%     'tseries'
%     'tseriesslice'
%     'tseriesscan'
%     'tr'
%     'nframes'
%     'ncycles'
%         %%%%% Retinotopy/pRF Model related properties    
%     'framestouse'
%     'rmfile'
%     'rmmodel'
%     'rmcurrent'
%     'rmmodelnames'
%     'rmparams'
%     'rmstimparams'
%     'rmmodelnum'
%     'rmhrf'
%         %%%%% Mesh-related properties
%     'allmeshes'
%     'allmeshids'
%     'mesh'
%     'currentmesh'
%     'meshn'
%     'meshdata'
%     'nmesh'
%     'meshnames'
%     'meshdir'        
%         %%%%% Volume/Gray-related properties
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
%     'coordsfilename'
%     'ncoords'           
%     'classfilename'
%     'classdata'
%     'graymatterfilename'        
%         %%%%% EM / General-Gray-related properties
%     'datavalindex'val.scanmap = nanmean(tmp(:))
%     'analysisdomain'      
%         %%%%% Flat-related properties
%     'graycoords'
%     'leftpath'
%     'rightpath'
%     'fliplr'
%     'imagerotation'
%     'hemifromcoords'
%     'roihemi'
% %%%%% UI properties
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


%% End Script





function test_viewGetInplane
%Validate INPLANE graphical user interface
%
%   test_viewGetInplane()
%
% Tests: mrVista, viewSet, viewGet
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_viewGetInplane()
%
% See also MRVTEST, TEST_VIEWGETHIDDEN
%
% Copyright Stanford team, mrVista, 2012


%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = mrtInstallSampleData('functional','mrBOLD_01');

% This is the validation file
stored = mrtGetValididationData('viewGetHidden');


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Get view structure:
vw = mrVista('Inplane');
mrGlobals;

% Move back to original directory
cd(curDir)

%% Check some fields in the view structure
assertEqual(viewGet(vw, 'view type'), 'Inplane')

%% Set data structure properties:
vw = viewSet(vw, 'current dt', 1); 
vw = viewSet(vw, 'current scan', 1); 
vw = viewSet(vw, 'current slice', 1); 

%%
% Home Directory
[pth, tmp]  = fileparts(viewGet(vw, 'Home Directory')); %#ok<ASGLU>
assertEqual(stored.homedir,length(tmp));

% session name
assertEqual(stored.sessionName, length(viewGet(vw, 'session name')));

% subject
assertEqual(stored.subject, length(viewGet(vw, 'subject')));

% annotation
%   This is empty in the sample data set so we must set it first
dt = viewGet(vw, 'dt struct');
for scan = 1:viewGet(vw, 'num scans')
    dt = dtSet(dt, 'annotation', sprintf('scan %d', scan), scan);
end
dtnum = viewGet(vw, 'current dt');
dataTYPES(dtnum) = dt; %#ok<NASGU>
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

% % map clip (empty in hidden view)
% assertEqual(stored.mapclip, viewGet(vw, 'mapclip'));

close(viewGet(vw, 'figure number'))

mrvCleanWorkspace;





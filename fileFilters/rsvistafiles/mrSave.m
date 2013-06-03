function mrSave(mr, pth, format, varargin)
% Save an mr object to a file, using the specified format.
%
%    mrSave(mr, pth, format, [options]);
%
% The possible formats are:
%   'nifti': Compressed NIFTI-format file. Extra header information for
%   which the NIFTI headers don't have slots is kept in an extra, small
%   matlab (.mat) file with the same name.
%
%   'mat':  MATLAB file containing the mr structure.
%
%	'analyze': ANALYZE 7.5 format file.
%
%   'tseries': mrVista format tSeries directories. Creates a mrSESSION
%   structure if it doesn't already exist.
%
%   'inplane ': mrVista format inplane anatomy. Creates a mrSESSION
%   structure if it doesn't already exist.
%
%	'dat': mrGray vAnatomy.dat format. Add the optional flag '1' to cause
%	the anatomy to be reoriented from ANALYZE/NIFTI conventions to mrGray
%	conventions.
%
% ras, 07/05.
% ras, 05/08: added comments for some of the more recently-added formats.
% jw,  07/2011: allow ('scan', scannum) as inputs in varargin
%

mrGlobals; %Called to specify that the dataTYPES and other variables that
    % are loaded here are the same as the global variables

if notDefined('mr'), mr = mrLoad;                               end
if notDefined('pth'), pth = mrSelectDataFile('stayput','w');    end
if ~isempty(varargin) && strcmpi(varargin{1}, 'scan'),
       scan = varargin{2};
else
       scan = [];
end

if notDefined('format'),
    [p, f, ext] = fileparts(pth); %#ok<ASGLU>
    if ismember(lower(ext), {'.nii' '.gz' '.img'})
        format = 'nifti';
    else
        format = 'mat';
    end
end

if isequal(format,'nifti')
    % prune the extension, since the MEX file
    % writeFileNifti automatically adds this
    periods = strfind(pth,'.');
    if ~isempty(periods), pth=pth(1:periods(1)-1); end
end

% for quick conversions of format, allow mr to be a path
% specifying an mr object, and load it:
if ischar(mr), mr = mrLoad(mr);                                 end

switch format
    case 'mat',
        %% save as a matlab file, saving each field
        % of the mr struct as a separate variable
        % (for easy loading later)
        [p, f, ext] = fileparts(pth); %#ok<ASGLU>
        if ~isequal(lower(ext), '.mat')
            pth = [pth '.mat'];
        end
        mr.format = 'mat';
        mr.path = pth;
        save(pth, '-struct', 'mr');

    case 'nifti',
		mrSaveNifti(mr, pth);
        
    case 'analyze',
		mrSaveAnalyze(mr, pth);
		
    case {'1.0anat' 'inplane' 'inplaneanat'}
		pth = mrSaveInplaneAnat(mr, pth); 		

    case {'1.0tSeries' 'tseries'}        
		pth = mrSaveInplaneTseries(mr, pth, scan);     
		
	case {'dat' 'vanat'}
		if ~isequal( class(mr.data), 'uint8' )
			mr.data = rescale2(histoThresh(mr.data), [], [0 255]);
			mr.data = uint8(mr.data);
		end
		if length(varargin) >= 1 && isequal(varargin{1}, 1)
			mr.data = mrAnatRotateAnalyze(mr.data);
		end
			
		writeVolAnat(mr.data, mr.voxelSize(1:3), pth);
		
	otherwise
		error('Can''t write format: %s.', format);
end

fprintf('Saved MR data in %s.\n', pth);

return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function params = blockedAnalysisDefaults
% Default values for the blocked analyses.
params.blockedAnalysis = 1;
params.detrend = 1;
params.inhomoCorrect = 1;
params.temporalNormalization = 0;
params.nCycles = 6;
return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function params = scanParamsDefaults(mrSESSION, scan, annotation)
% Default scan parameters for a new scan.
params.annotation = annotation;
params.nFrames = mrSESSION.functionals(scan).nFrames;
params.framePeriod = mrSESSION.functionals(scan).framePeriod;
params.slices = mrSESSION.functionals(scan).slices;
params.cropSize = mrSESSION.functionals(scan).cropSize;
params.PfileName = mrSESSION.functionals(scan).PfileName;
%Added the inplanePath string to ensure that we maintain that data,
%regardless of what happens to PfileName
params.inplanePath = mrSESSION.functionals(scan).PfileName; 
params.parfile = '';
params.scanGroup = sprintf('Original: %i',scan);
return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function savePath = mrSaveInplaneAnat(mr, pth)
% save mr object as mrVista 1.0-format inplane anatomy file.
%
% anatPath = mrSaveTSeries(mr, pth);
%
% Creates mrSESSION.mat if it doesn't already exist, 
% otherwise updates it.
%
% pth should point to the session directory. Returns the path 
% to the saved anatomy file.
%
% ras, 07/07, broken off mrSave.
cd(pth);
savePath = fullfile(pth, 'Inplane', 'anat.mat');
ensureDirExists(fileparts(savePath));
anat = mr.data; %#ok<NASGU>
save(savePath, 'anat');

% init mrSESSION file if it doesn't exist
mrSessPath = fullfile(pth, 'mrSESSION.mat');
if ~exist(mrSessPath, 'file')
	initEmptySession;    
end
load(mrSessPath, 'mrSESSION', 'dataTYPES');

% fill in mrSESSION.inplanes
mrSESSION.inplanes.fullSize = mr.dims(1:2);
mrSESSION.inplanes.voxelSize = mr.voxelSize(1:3);
mrSESSION.inplanes.spacing = [];
mrSESSION.inplanes.nSlices = mr.dims(3);
mrSESSION.inplanes.examNum = [];
mrSESSION.inplanes.crop = [1 1; mr.dims(1:2)];
mrSESSION.inplanes.cropSize = mr.dims(1:2);
mrSESSION.inplanes.cornerCoords = [];

% fill in what we can
if checkfields(mr, 'hdr', 'image', 'dfov')
	mrSESSION.inplanes.FOV = mr.hdr.image.dfov;
end

if checkfields(mr, 'hdr', 'image', 'scanspacing')
	mrSESSION.inplanes.spacing = mr.hdr.image.scanspacing;
end

if checkfields(mr, 'info', 'cornerCoords')
	mrSESSION.inplanes.cornerCoords = mr.info.cornerCoords; %#ok<STRNU>
end

save(mrSessPath, 'mrSESSION', '-append');   
return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function saveDir = mrSaveInplaneTseries(mr, pth, scan)
% save mr object as mrVista 1.0-format tSeries files (Inplane view).
%
% tSeriesPath = mrSaveTSeries(mr, pth, [scan]);
%
% Adds mr as a new time series in the Original data type for a mrVista
% session. Creates mrSESSION.mat if it doesn't already exist, 
% otherwise updates it.
%
% pth should point to the session directory. Returns the path to the
% tSeries directory in which the files were saved.
%
% ras, 07/07, broken off mrSave.
cd(pth);

% init mrSESSION file if it doesn't exist
mrSessPath = fullfile(pth, 'mrSESSION.mat');
if ~exist(mrSessPath, 'file')
	initEmptySession;    
end

% set header info in mrSESSION.functionals, dataTYPES.scanParmas
if notDefined('scan'), scan = length(mrSESSION.functionals) + 1; end %#ok<NODEF>
f.PfileName = mr.path;
f.totalFrames = mr.dims(4);

f.firstName = '';  f.lastName = '';
if checkfields(mr, 'info', 'subject')
	sp = strfind(' ', mr.info.subject);
	if ~isempty(sp) % space in name
		f.firstName = mr.info.subject( 1:(sp(1)-1) );
		f.lastName = mr.info.subject( (sp(1)+1):end );
	else
		f.firstName = mr.info.subject;
	end
end

f.date = ''; f.time = '';
if checkfields(mr, 'info', 'date'), f.date = mr.info.date; end
if checkfields(mr, 'info', 'time'), f.time = mr.info.time; end

f.junkFirstFrames = 0;
f.nFrames = mr.dims(4);
f.slices =  1:mr.dims(3);
f.fullSize = mr.dims(1:2);
f.cropSize = mr.dims(1:2);
f.crop = [1 1; mr.dims(1:2)];
f.voxelSize = mr.voxelSize(1:3);
f.effectiveResolution = mr.voxelSize(1:3);
f.keepFrames = mr.keepFrames; %Keep Frames will now be udpated in both mrSESSION and dataTYPES
if checkfields(mr, 'info', 'effectiveResolution')
	f.effectiveResolution = mr.info.effectiveResolution;
end
f.framePeriod = mr.voxelSize(4);
f.reconParams = mr.hdr;

if scan==1
    mrSESSION = sessionSet(mrSESSION, 'Functionals', f);
	%mrSESSION.functionals = f;
else
    mrSESSION = sessionSet(mrSESSION, 'Functionals', ...
        mergeStructures(sessionGet(mrSESSION, 'Functionals', scan-1), f), scan);
end

%%%%%copy over params:
% Copy one field at a time, so we don't get type-mismatch errors.    

% scan params
srcScanParams = scanParamsDefaults(mrSESSION, scan, mr.name);
for f = fieldnames(srcScanParams)'
    dataTYPES(1).scanParams(scan).(f{1}) = srcScanParams.(f{1});
end
    
% blocked analysis params
srcBlockParams = blockedAnalysisDefaults;
for f = fieldnames(srcBlockParams)'
    dataTYPES(1).blockedAnalysisParams(scan).(f{1}) = ...
        srcBlockParams.(f{1});
end

% event analysis params
srcEventParams = er_defaultParams;
for f = fieldnames(srcEventParams)'
    dataTYPES(1).eventAnalysisParams(scan).(f{1}) = ...
        srcEventParams.(f{1});
end



% save the files
nSlices = mr.dims(3);
nFrames = mr.dims(4);
voxPerSlice = prod(mr.dims(1:2));
str = sprintf('Scan%i', scan);
saveDir = fullfile(pth, 'Inplane', 'Original', 'TSeries', str);
ensureDirExists(saveDir);

for slice = 1:nSlices
   tSeries = squeeze(mr.data(:,:,slice,:)); % rows x cols x time
   tSeries = reshape(tSeries, [voxPerSlice nFrames])'; %#ok<NASGU> % time x voxels 
   savePath = fullfile(saveDir, sprintf('tSeries%i.mat', slice));
   save(savePath, 'tSeries');
   fprintf('Saved slice %i data in %s.\n', slice, savePath);
end

save(mrSessPath, 'mrSESSION', 'dataTYPES', '-append');
return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function mrSaveAnalyze(mr, pth)
% save mr object as Analzye 7.5-format file.
%
% mrSaveAnalyze(mr, pth);
%
% ras, 07/07, broken off mrSave.
if checkfields(mr, 'info', 'comments')
	notes = mr.info.comments;
else
	notes = '';
end
analyzeWrite(mr.data, pth, mr.voxelSize, notes);

%% also save extra info in a .mat file
okFields = {'data' 'path' 'format' 'voxelSize' 'dims' 'extent'};
xtraFields = setdiff(fieldnames(mr), okFields);

% (we add an additional 'xform' field, b/c this is a way
% to store alignments to 'canonical' spaces from the header.
% we'll use R|A|S space as the canonical space.)
if checkfields(mr, 'spaces', 'xform') 
	xformNames = {mr.spaces.name};
	ii = cellfind(xformNames, 'R|A|S');
	if ~isempty(ii)
		xtraFields = [xtraFields {'M'}];
		mr.M = mr.spaces(ii).xform;
	end
end

if length(xtraFields) >= 1
	[p f] = fileparts(pth);

	xtraPth = fullfile(p, [f '.mat']); %#ok<NASGU>

	cmd = 'save(xtraPth, ''-struct'', ''mr''';
	for i = 1:length(xtraFields)
		cmd = [cmd ', ''' xtraFields{i} ''''];
	end
	cmd = [cmd ');'];
	eval(cmd);
end

return
% /-----------------------------------------------------------------/ %




% /-----------------------------------------------------------------/ %
function mrSaveNifti(mr, pth)
% save mr object as a compressed NIFTI file.
%
% mrSaveNifti(mr, pth);
%
% ras, 07/07, broken off mrSave.

% make sure a 'nii.gz' extension is present in the file
% path:
[p f ext] = fileparts(pth);
if ~isequal(ext,'gz'), pth = [pth '.nii.gz'];      end

% assign fields properly
s.data = mr.data;
s.fname = pth;
s.ndim = ndims(mr.data);
s.pixdim = mr.voxelSize;
% a whole bunch more -- this'll be hard

s.scl_slope = 0;
s.scl_inter = 0;
s.cal_min = 0;
s.cal_max = 0;
s.qform_code = 0;
s.sform_code = 1; % old format; losing space info
% *** TO DO: Set these using header data!
s.freq_dim = 0;
s.phase_dim = 0;
s.slice_dim = 0;
s.slice_code = 0;
s.slice_start = 0;
s.slice_end = 0;
s.slice_duration = 0;
s.qfac = 1;
s.quatern_b = 0; %qb;
s.quatern_c = 0; %qc;
s.quatern_d = 0; %qd;
s.qoffset_x = 0; %offset(1);
s.qoffset_y = 0; %offset(2);
s.qoffset_z = 0; %offset(3);
s.sto_xyz = eye(4);
s.toffset = 0;
s.xyz_units = 'mm';
s.time_units = 'sec';
s.intent_code = 0;
s.intent_p1 = 0;
s.intent_p2 = 0;
s.intent_p3 = 0;
s.intent_name = '';
s.descrip = '';
s.aux_file = 'none';

% write the file
% note 08/2008: the writeFileNifti MEX file doesn't work for some
% combinations of operating system / MATLAB version / CPU. Try a couple of
% things:
try
    writeFileNifti(s); 
catch %#ok<CTCH>
	warning(['[%s]: The MEX file "writeFileNifti" is not working on this ' ...
             'MATLAB version. Trying a fallback, more stable version. ' ...
             'The NIFTI should be the same, except the qform code may ' ...
             'not be properly set.'], mfilename);
    writeFileNifti_stable(s);
end
    
% also save extra info in a .mat file
okFields = {'data' 'path' 'info' 'format' 'voxelSize' 'dims' 'extent'};
xtraFields = setdiff(fieldnames(mr),okFields);
if length(xtraFields)>1
	xtraPth = fullfile(p,[f '.mat']); %#ok<NASGU>

	cmd = 'save(xtraPth, ''-struct'', ''mr''';
	for i = 1:length(xtraFields)
		cmd = [cmd ', ''' xtraFields{i} ''''];
	end
	cmd = [cmd ');'];
	eval(cmd);
end
return

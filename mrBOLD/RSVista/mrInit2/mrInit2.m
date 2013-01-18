function ok = mrInit2(varargin)
% Initialize a mrVista session. Replacement for mrInitRet. 
%
% USAGE: mrInit2 should be called when the current directory is the one 
% you wish to initialize. It can be called one of three ways:
%
%	(1) Interactively: type 'mrInit2' without arguments, and a series of
%		dialogues ('mrInitGUI') will collect the initialization parameters.
%
%	(2) With a params struct: mrInit2(params) will initialize without user
%		feedback. params is a struct with fields described below.
%	
%	(3) mrInit2('param', [value], 'param', [value]...) will also initialize
%		without user feedback. The 'param' strings are fields in the param
%		structs, the values are the value for that parameters. Any
%		non-specicified parameters will use the default values. 
%  
%
% INPUTS:
%   functionals: path string, or cell array of path strings, to the input
%   functional files. Defaults to looking in Raw/Pfiles/P*.mag for Lucas
%   P-mags. Input functionals can be any format readable by mrLoad,
%   including ANALYZE, NIFTI, or DICOM images.
%
%   inplane: path string to the input co-registered inplane anatomy.
%   Defaults to 'Raw/Anatomy/Inplane/I*.dcm' (again consistent w/ Lucas
%   Center conventions.) Can be any format readable by mrLoad.
%
%   params: structure which specifies the organization of the 'Original' 
%   data type in the new session. See mrInitDefaultParams for a full
%   description of the parameters. mrInitGUI calls a series of dialogs to
%   get these parameters interactively.
%
% OUTPUTS:
%     The main output is a new mrVista session, with the following files
%     and directory structure:
%       mrSESSION.mat: contains the variables:
%           * mrSESSION: contains info on the input inplanes and
%           functionals.
%           * dataTYPES: info on groups of scans. Initialized only to the
%           default first group, 'Original', which derives from the set of
%           functionals. Analysis parameters for traveling-wave / event
%           analyses are also stored here.
%       Inplane/ directory: contains:
%           * anat.mat: anatomy file. Soon, this should be replaced with a
%           more robust format, like anat.nii.gz (NIFTI) or anat.img
%           (ANALYZE).
%           * Original/: 'data directory' for the Original data type.
%               * Original/TSeries/: directory for time series data from the 
%                 functionals. Again, this is an older format: each scan
%                 has a directory ('/Scan2/'), and contains one MATLAB file
%                 for each slice ('tSeries4.mat'), which has the variable 
%                 'tSeries', format [nFrames x nVoxelsInSlice]. 
%           * If running motion compensation, will also create new data
%           types: 'MotionComp' for within-scan, and 'BwScansMotionComp'
%           for between scan. If running both, you can choose to do either
%           between or within-scan first, then the other on top of that.
%           (You may want to remove the intermediate within-scan data type
%           to save space, if it looks like things went well.)
%       
%   Also returns the variable ok, which is 1 if everything succeeded and 0
%   otherwise.
%             
% EXAMPLE:
%	Suppose we have a session with four functional files, named 'func1.img'
%	to 'func4.img', and an inplane file, 'inplane.img'. All files are
%	single ANALYZE-format images.
%
%	params.inplane = 'inplane.img';
%	for i=1:5, params.functionals{i} = sprintf('func%i.img', i); end
%	mrInit2(params);
%
%
% ras, 09/2006.


% PROGRAMMING NOTES:
% This code is intended to improve upon mrInitRet, addressing a few
% concerns:
%
% (1) More input file neutral. While mrInitRet was largely built to use 
%     Lucas Center P.mag files, mrInit2 is intended to allow any files
%     readable by the mrVista 2 mrLoad functions. Specifically, 
%     ANALYZE files are supported. Also, it's no longer required that 
%     you have the Inplane files be DICOM files in Raw/Anatomy/Inplane.
%     Although consistent naming is recommended, the input anatomy file can
%     also be any format or location.    
%
% (2) Scriptable. mrInitRet provided a nice 'wizard' of dialogs, but was
%     extremely hard to automate. This code is intended to be more modular,
%     and not require any user dialogs to run. If the optional 'params'
%     argument is not provided, it will provide a set of dialogs (mrInitGUI)
%     to get them. But otherwise, it runs without further input from the
%     user.
%  
% (3) Saves more info from the header files. Things like the corners of the
%     inplane in scanner coordinates were not extracted previously, making
%     it difficult to e.g. label left from right. These are now saved in
%     the mrSESSION file.
%
% (4) Free of several of the bugs that have been cropping up lately, e.g.
%     in EditSession.
%
% (5) Run Motion Compensation / Slice Timing Correction at the front end, 
%    so you can leave a session intitializing and have it also do these 
%    steps overnight.
% ras, 07/23/07: debugged / slight overhaul to be cleaner, rely more on
% mrLoad and mrSave to actually set the mrSESSION fields.
% ras, 05/08: fixed several bugs in the GUI processing stream for dealing
% with file patterns; the main code also properly tests that the specified
% session directory exists, and cleans up the workspace when it finishes.
%
% Modified by DY on 09/2008 to allow for within then between or between
% then within MC. Changed comments here and in mrInitDefaultParams.m to
% reflect this. Email DY if you would like to see an example wrapper script
% that sets all params. 

disp('Please call mrInit rather than mrInit2.  The latter will be deprecated.');
mrInit(varargin)
return

%%
ok = 0;
mrGlobals2;

%%%%% (0) ensure all input parameters are specified
if nargin==0		
	% get params interactively
    [params ok] = mrInitGUI;
	if ~ok, disp('mrInit2 Aborted.'); return; end
	
elseif length(varargin)==1 && isstruct(varargin{1})
	% params struct entered
	params = mrInitDefaultParams;
	params = mergeStructures(params, varargin{1});
	
else
	params = mrInitDefaultParams;
	
	% param/value pairs specified -- parse
	for i = 1:2:length(varargin)
		params.(varargin{i}) = varargin{i+1};
	end
	
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) cd to session dir; init empty session %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params.startTime = datestr(now);
fprintf('***** [%s] Initializing Session %s ***** (%s)\n', mfilename, ...
        params.sessionCode, params.startTime);
ensureDirExists(params.sessionDir);	
callingDir = pwd;
cd(params.sessionDir);
initEmptySession;
load mrSESSION mrSESSION dataTYPES
mrSESSION.description = params.description;
mrSESSION.sessionCode = params.sessionCode;
mrSESSION.subject = params.subject;
mrSESSION.comments = params.comments;
save mrSESSION mrSESSION -append;
save mrInit2_params params   % stash the params in case we crash

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2) figure out if we have a reasonable crop %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the inplanes and the first functional scan
% (we use mrParse becasue other steps, like the crop interface, 
% may have already loaded one or both -- this way, we don't load twice)
inplane = mrParse(params.inplane); 
func = mrLoadHeader(params.functionals{1});

% test that inplanes, functionals cover the same physical extent
% (due to some roundoff error, allow for a small fudge factor)
diff =  abs( inplane.extent(1:3) - func.extent(1:3) );
% if max(diff) > 1
%     % in this case, we might offer to do the 'scale FOV' thing that
%     % Junjie/Ress have used. But this would come later.
% 	fprintf('INPLANE: Voxel Size %s, Dimensions: %s, Extent %s \n', ...
% 		    num2str(inplane.voxelSize), num2str(inplane.dims), ...
% 			num2str(inplane.extent));
% 	fprintf('FUNCTIONALS: Voxel Size %s, Dimensions: %s, Extent %s \n', ...
% 		    num2str(func.voxelSize), num2str(func.dims), ...
% 			num2str(func.extent));
% 		
%     error(['The Functionals don''t seem to cover the same physical ' ...
%            'extent as the Inplanes. This may be a header issue, or ' ...
%            'they may not be corresponding data. ']);
% end

% get scale factor b/w inplane and time series
scaleFactor = round( func.voxelSize(1:3) ./ inplane.voxelSize(1:3) );

if ~isempty(params.crop)
    x1 = params.crop(1,1); x2 = params.crop(2,1);
    y1 = params.crop(1,2); y2 = params.crop(2,2);
    
    % the way we know the crops won't partial volume the functionals is if
    % the value of each corner, mod the scale factor, is non-zero. So,
    % subtract this remainder out:
    x1 = x1 - mod(x1, scaleFactor(2));
    x2 = x2 - mod(x2, scaleFactor(2));
    y1 = y1 - mod(y1, scaleFactor(1));
    y2 = y2 - mod(y2, scaleFactor(1));
    
    params.crop = [x1 y1; x2 y2];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (3) crop and save inplane anatomy %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(params.crop)
	inplane = mrCrop(inplane, params.crop);
end
mrSave(inplane, params.sessionDir, '1.0anat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (4) read, crop, and save functional time series %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for scan = 1:length(params.functionals)
	
	funcPath = mrGet(params.functionals{scan}, 'filename');
	[p f ext] = fileparts(funcPath);
	
    if isequal(lower(ext), '.mag')
        % if inputs are Lucas Center .mag files, we can read them a slice
        % at a time and be more memory-efficient:
        initMagFiles(params.functionals, scan, params, scaleFactor);
        
    else
        % generalized, more memory-hungry way
        func = mrParse(params.functionals{scan});  % this loads if needed
        
        if ~isempty(params.crop)
            funcCrop = params.crop ./ repmat(scaleFactor([2 1]), [2 1]);
            func = mrCrop(func, funcCrop);
        end
        
        % select keepFrames if they're provided
        if isfield(params, 'keepFrames') & ~isempty(params.keepFrames)
            nSkip = params.keepFrames(scan,1);
            nKeep = params.keepFrames(scan,2);
            if nKeep==-1
                % flag to keep all remaining frames
                nKeep = size(func.data, 4) - nSkip;
            end
            keep = [1:nKeep] + nSkip;
            func.data = func.data(:,:,:,keep);
            func.dims(4) = size(func.data, 4);
        end
        
        % assign annotation if it's provided
        if length(params.annotations) >= scan & ...
                ~isempty(params.annotations{scan})
            func.name = params.annotations{scan};
        end
        
        mrSave(func, params.sessionDir, '1.0tSeries');
        
    end
    
end

fprintf('[%s]: Finished initializing mrVista session. \t(%s)\n', ...
		mfilename, datestr(now));

%% compress raw files if selected
if checkfields(params, 'compressRawFiles') & params.compressRawFiles==1
	if ~isunix
		fprintf(['[%s]: Sorry, can only compress raw files ' ...
				 'in a unix-like environment.\n'], mfilename);
	else
		fprintf('[%s]: Attempting to compress raw files...\n', mfilename);
		try
			for i = 1:length(params.functionals)
				cmd = ['gzip -v ' params.functionals{ii}];
				[status result] = unix(cmd);
				if status==0
					% successful
					fprintf('%s\n', result)
				end
			end
		catch
			fprintf('[%s]: Failed to compress raw files.\n', mfilename);
			fprintf('Error = %s\n', lasterr);
		end
	end
end
		

%%%%%%%%%%%%%%%%%%%%%%%
% (5)  pre-processing %
%%%%%%%%%%%%%%%%%%%%%%%
%% update dataTYPES as needed.

% 2011.05.05 RFD: We always need the INPLANE view to initalize dataTYPES.
%% initialize an inplane view of the data if we need it
% if (params.sliceTimingCorrection==1) | (params.motionComp > 0) | ...
% 		(params.applyGlm==1) | (any(params.applyCorAnal > 0)) | ...
% 		(~isempty(params.scanGroups)) | (~isempty(params.glmParams)) | ...
% 		(~isempty(params.parfile)) | (~isempty(params.coParams))
%     INPLANE{1} = initHiddenInplane; % we'll need this
% end
INPLANE{1} = initHiddenInplane;

%% assign coherence analysis parameters
for s = cellfind(params.coParams)
	coParams = params.coParams{s};
	for f = fieldnames(coParams)'
		dataTYPES.blockedAnalysisParams(s).(f{1}) = coParams.(f{1});
	end	
end

%% assign GLM analysis parameters
for scan = cellfind(params.glmParams)
	er_setParams(INPLANE{1}, params.glmParams{scan}, scan);
end


%% slice timing correction
if params.sliceTimingCorrection==1
    INPLANE{1} = AdjustSliceTiming(INPLANE{1}, 0);
	INPLANE{1} = selectDataType(INPLANE{1}, 'Timed');
end

%% motion compensation
if params.motionComp > 1
    switch params.motionComp
        case 1, % between scans only
            newDataType = 'BwScansMotionComp';
            if ~existDataType(newDataType), addDataType(newDataType); end
            hI = initHiddenInplane(newDataType);
            [INPLANE{1}, M] = betweenScanMotComp(INPLANE{1}, hI, params.motionCompRefScan);
            INPLANE{1} = selectDataType(INPLANE{1}, newDataType);
			
        case 2, % within scans only
            INPLANE{1} = motionCompSelScan(INPLANE{1}, 'MotionComp', ...
										[], params.motionCompRefFrame);
            
        case 3, % both between and within scans
            motionCompNestaresFull(INPLANE{1}, [], ...
									params.motionCompRefScan, ...
									params.motionCompRefFrame);
            INPLANE{1} = selectDataType(INPLANE{1}, 'MotionComp');

        case 4, % both between and within scans
            motionCompNestaresWithin1st(INPLANE{1}, [], params.motionCompRefScan, params.motionCompRefFrame);
            mcdtName=['MotionComp_RefScan' num2str(params.motionCompRefScan)];
            INPLANE{1} = selectDataType(INPLANE{1}, mcdtName);

    end
end
    
%% group scans, assign parfiles, apply GLM
for scan = cellfind(params.parfile)
	er_assignParfilesToScans(INPLANE{1}, scan, params.parfile(scan));
end

if ~isempty(params.scanGroups)
	for ii = 1:length(params.scanGroups)
		INPLANE{1} = er_groupScans(INPLANE{1}, params.scanGroups{ii}, 2);

		if params.applyGlm==1
			glmParams = er_getParams(INPLANE{1}, params.scanGroups{ii}(1));
			applyGlm(INPLANE{1}, [], params.scanGroups{ii}, glmParams);
		end
	end	
end

%% apply coherence analysis
if any(params.applyCorAnal > 0)
	INPLANE{1} = computeCorAnal(INPLANE{1}, params.applyCorAnal, 1);
end

%%%%% we're done! hooray!
saveSession;	
fprintf('***** [%s] Finished Initializing Session %s (%s)*****\n', ...
		mfilename, mrSESSION.sessionCode, datestr(now));
mrvCleanWorkspace;
ok = 1;

cd(callingDir);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function initMagFiles(functionals, scan, params, scaleFactor);
% initialize a functional scan a slice at a time, the old way
mrGlobals2;
cd(params.sessionDir);
func = mrLoadHeader(functionals{scan});
voxPerSlice = prod( func.dims(1:2) );
nSlices = func.dims(3);
nFrames = func.dims(4);

% check that the tSeries dir exists
saveDir = fullfile(pwd, 'Inplane', 'Original', 'TSeries', sprintf('Scan%i', scan));
ensureDirExists(saveDir);

% parse the date of the mag file to determine if we use little endian
% byte order when reading the mag files
% (doesn't always parse this correctly -- 99% odds it's little endian)
% if (func.info.scanStart(1)>=2005) & (func.info.scanStart(2)>=3)
    littleEndian = 1;
% else
%     littleEndian = 0;
% end

fprintf('Saving Scan %i [%s], slice: ', scan, func.path);

for slice = 1:nSlices
    tSeries = readMagFile(functionals{scan}, slice, littleEndian);

	fclose all;  % gum
	
    % crop if specified
    if ~isempty(params.crop)
        x1 = params.crop(1,1) / scaleFactor(2);
        x2 = params.crop(2,1) / scaleFactor(2);
        y1 = params.crop(1,2) / scaleFactor(1);
        y2 = params.crop(2,2) / scaleFactor(1);
		funcCrop = [x1 y1; x2 y2];
        tSeries = tSeries(y1:y2, x1:x2, :, :);
		
		voxPerSlice = size(tSeries, 1) * size(tSeries, 2);
	else
		funcCrop = [1 1; func.dims(1:2)];
    end

    % note the transpose: size will be [nFrames voxPerSlice]
    tSeries = reshape(squeeze(tSeries), [voxPerSlice nFrames])';
	
	% keep the appropriate # of frames, if specified
	if size(params.keepFrames, 1) >= scan
		nSkip = params.keepFrames(scan,1);
		nKeep = params.keepFrames(scan,2);
		if nKeep==-1
			nKeep = size(tSeries, 1) - nSkip;
		end
		keep = [1:nKeep] + nSkip;
		try
			tSeries = tSeries(keep,:);
		catch
			warning( sprintf('Invalid keep frames for scan %i', scan) );
		end
	end

    tSeriesPath = fullfile( saveDir, sprintf('tSeries%i.mat', slice) );
    save(tSeriesPath, 'tSeries');
    fprintf('%i ', slice);
end

% need to manually update mrSESSION.functionals and dataTYPES
% (in the general version mrSave takes care of this)
f.PfileName = func.path;
if length(params.annotations) >= scan & ~isempty(params.annotations{scan})
	f.annotation = params.annotations{scan};
else
	f.annotation = sprintf('Scan %i', scan);
end
f.totalFrames = func.dims(4);
f.firstName = func.info.subject; % break into 2 later
f.lastName = func.info.subject;
f.date = func.info.date;
f.time = func.info.scanStart;
f.junkFirstFrames = 0;
f.nFrames = size(tSeries, 1);
f.slices = 1:nSlices;
f.fullSize = func.dims(1:2);
f.cropSize = fliplr( diff(funcCrop) ) + 1;
f.crop = funcCrop;
f.voxelSize = func.voxelSize(1:3);
f.effectiveResolution = func.hdr.effectiveResolution;
f.framePeriod = func.voxelSize(4);
f.reconParams = func.hdr;
if isempty(mrSESSION.functionals) | scan==1
	mrSESSION.functionals = f;
else
	mrSESSION.functionals(scan) = mergeStructures(mrSESSION.functionals(scan-1), f);
end

f.scanGroup = ''; % deal w/ scanGroups param
for i = 1:length(params.scanGroups)
    if ismember(scan, params.scanGroups{i})
        f.scanGroup = ['Original: ' num2str(params.scanGroups{i})];
    end
end
if length(params.parfile) >= scan & ~isempty(params.parfile{scan})
	f.parfile = params.parfile{scan};
end


if scan==1 
	dataTYPES.scanParams = sortfields(f);
else
	tmp = mergeStructures(dataTYPES.scanParams(scan-1), f);
	for f = fieldnames(tmp)'
		dataTYPES.scanParams(scan).(f{1}) = tmp.(f{1});
	end
end

%%%%%copy over params:
% Copy one field at a time, so we don't get type-mismatch errors.        
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

save mrSESSION mrSESSION dataTYPES -append

fprintf('done. \t(%s) \n', datestr(now));


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
function params = scanParamsDefaults(mrSESSION, scan, annotation);
% Default scan parameters for a new scan.
params.annotation = annotation;
params.nFrames = mrSESSION.functionals(scan).nFrames;
params.framePeriod = mrSESSION.functionals(scan).framePeriod;
params.slices = mrSESSION.functionals(scan).slices;
params.cropSize = mrSESSION.functionals(scan).cropSize;
params.PfileName = mrSESSION.functionals(scan).PfileName;
params.parfile = '';
params.scanGroup = sprintf('Original: %i',scan);
return
        
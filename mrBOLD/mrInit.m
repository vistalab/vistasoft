function ok = mrInit(varargin)
% Initialize a mrVista session. Replacement for mrInitRet, mrvInit and
% mrInit2.  Moved from mrRSTools (formerly mrVista2).
%
% USAGE: mrInit should be called when the current directory is the one 
% you wish to initialize. It can be called one of three ways:
%
%	(1) Interactively: type 'mrInit' without arguments, and a series of
%		dialogues ('mrInitGUI') will collect the initialization parameters.
%
%	(2) With a params struct: mrInit(params) will initialize without user
%		feedback. params is a struct with fields described below.
%	
%	(3) mrInit('param', [value], 'param', [value]...) will also initialize
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
%	mrInit(params);
%
%
% ras, 09/2006.


% PROGRAMMING NOTES:
% This code is intended to improve upon mrInitRet, addressing a few
% concerns:
%
% (1) More input file neutral. While mrInitRet was largely built to use 
%     Lucas Center P.mag files, mrInit is intended to allow any files
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

ok = 0;
mrGlobals; %This has replaced mrGlobals2

%%%%% (0) ensure all input parameters are specified
if nargin==0		
	% get params interactively
    [params ok] = mrInitGUI;
	if ~ok, disp('mrInit Aborted.'); return; end
	
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
initEmptySession; %Replace this save and then load of mrSESSION with that variable simply passed
                    % from one to the other
load mrSESSION mrSESSION dataTYPES
mrSESSION = sessionSet(mrSESSION,'description', params.description);
mrSESSION = sessionSet(mrSESSION,'sessionCode',params.sessionCode);
mrSESSION = sessionSet(mrSESSION,'subject',params.subject);
mrSESSION = sessionSet(mrSESSION,'comments',params.comments);

%New parameter creation
mrSESSION = sessionSet(mrSESSION,'Inplane Path',params.inplane); %Populates the mrSESSION inplane path var


save mrSESSION mrSESSION -append; 
save mrInit_params params   % stash the params in case we crash'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2) Load functional data, if it exists      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(params,'functionals') && ~isempty(params.functionals)
    func = mrLoadHeader(params.functionals{1});
    
    for scan = 1:length(params.functionals)
        
        funcPath = mrGet(params.functionals{scan}, 'filename');
        
        %We will need to replace this code with something that adds the paths to
        %the session variable and then performs these data processes on-the-fly
        %when functional data is called
        
        %Read in the nifti to the tS struct, then apply the same transform as
        %the inplane data. Then, transfer the necessary components to the
        %local func struct.
        tS = niftiRead(funcPath);
        tS = niftiApplyAndCreateXform(tS,'Inplane');
        %Need to move over:
        %Data
        func.data = niftiGet(tS,'Data');
        %Dims
        func.dims = niftiGet(tS, 'Dim');
        %PixDims
        func.pixdims = niftiGet(tS, 'Pix Dim');
        
        % select keepFrames if they're provided
        if isfield(params, 'keepFrames') && ~isempty(params.keepFrames)
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
        if length(params.annotations) >= scan && ...
                ~isempty(params.annotations{scan})
            func.name = params.annotations{scan};
        end
        
        mrSave(func, params.sessionDir, '1.0tSeries');
        
        %end
        
    end
    
end


fprintf('[%s]: Finished initializing mrVista session. \t(%s)\n', ...
		mfilename, datestr(now));

%%%%%%%%%%%%%%%%%%%%%%%
% (5)  pre-processing %
%%%%%%%%%%%%%%%%%%%%%%%
% update dataTYPES as needed.


INPLANE{1} = initHiddenInplane;

% assign coherence analysis parameters
for s = cellfind(params.coParams)
	coParams = params.coParams{s};
	for f = fieldnames(coParams)'
		dataTYPES.blockedAnalysisParams(s).(f{1}) = coParams.(f{1});
	end	
end

% assign GLM analysis parameters
for scan = cellfind(params.glmParams)
	er_setParams(INPLANE{1}, params.glmParams{scan}, scan);
end


% slice timing correction
if params.sliceTimingCorrection==1
    INPLANE{1} = AdjustSliceTiming(INPLANE{1}, 0);
	INPLANE{1} = selectDataType(INPLANE{1}, 'Timed');
end

% motion compensation
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
    
% group scans, assign parfiles, apply GLM
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

% apply coherence analysis
if any(params.applyCorAnal > 0)
	INPLANE{1} = computeCorAnal(INPLANE{1}, params.applyCorAnal, 1);
end

% All tasks are now complete
saveSession;	
fprintf('***** [%s] Finished Initializing Session %s (%s)*****\n', ...
		mfilename, mrSESSION.sessionCode, datestr(now));
mrvCleanWorkspace;
ok = 1;

cd(callingDir);

return
% /---------------------------------------------------------------------/ %




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
        

function params = mrInitDefaultParams
% Default initialization parameters for mrInit2.
%
% params = mrInitDefaultParams;
%
% There are default values to intialize a session, which can be entered
% into mrInit2 to actually initialize the session, or mrInitGUI to modify
% them using a series of dialogs. Feel free to modify the local version of
% this to suit your needs.
%
% Fields for params struct:
%     inplane (*required*): path to inplane anatomies. These are
%     generally T1-weighted MR images coregistered to the functionals.
%     Default: look for the folder Raw/Anatomy/Inplane.    
% 
%     functionals (*required*): cell array of paths to functional time
%     series for each scan. Default: check for mr files in Raw/Pfiles
%     or, failing that, Raw/Functionals.
% 
%     vAnatomy: if this file is specified and exists, will set the 
%     reference anatomy to be this file. The volume anatomy, and the
%     other files in the 'anatomy path' where the vAnatomy resides, are not
%     required for Inplane analyses, but are needed for Volume, Gray, and
%     Flat analyses. Gray matter segmentations should reside in the anatomy
%     path. Unlike earlier version of mrVista, the vAnatomy need not be in
%     the mrGray *.dat format, but can be other files such as ANALYZE or
%     NIFTI. 
% 
%     sessionDir: directory of session to initialize. Default: pwd.
% 
%     sessionCode: name of session. Default: get from directory name.
% 
%     subject: subject name. Default: get from inplane header.
% 
%     description: description of session. Default: empty.
%
%	keepFrames: [nScans x 2] matrix describing which frames to keep 
%			from each scan's time series. (Frames may be clipped from the
%			time series to remove early frames when the gradients are
%			stabilizing, or clip to a convenient length. Each row specifies
%			the keep frames for a scan: the first column is the number of
%			frames to skip before the first frame to be kept; the second
%			column is the number of remaining frames to keep (the total
%			number that will be present in that scan's time series).
%			A flag of -1 for the second column signals to mrInit2 to keep
%			all frames after the skip frames. Similarly, leaving the whole
%			field empty will cause all frames to be kept.
%			Default: empty: keep all frames.
%
%    annotations: {1 x nScans} cell array of strings specifying the
%           initial annotation for each scan. (This is displayed at the top in
%           mrVista windows, and in the scan list for mrVista2.)
%           Default is 'scan1' through 'scanN'.
% 
%    parfile: {1 x nScans} list of parfile paths for each scan. These
%           can be absolute, or relative to Stimuli/parfiles/. Default
%           is empty.
% 
%    coParams: {1 x nScans} cell array of coherence anaysis ("blocked analysis
%			params" in the outdated nomenclature) parameters for each scan.
%			Will only assign these to scans for which the cell is nonempty. 
%			Use coParamsDefault and coParamsEdit to initialize and edit 
%			these parameters. Default empty: don't assign any parameters.
%
%	glmParams: {1 x nScans} cell array of GLM analysis parameters
%			(also called "event-related" in our jargon, though this can
%			just as easily apply to block designs). Will only assign these
%			to scans for which the cell array is nonempty. Use 
%			er_defaultParams and er_editParams to initialize and edit these
%			parameters. Default empty: don't assign any parameters.
% 
%   scanGroups: cell array specifying sets of scans to group together
%           for GLM analyses. Ecah entry in the cell array should be a
%		    vector of scan numbers. mrInit2 will set this group in the 
%			Original data type, as well as any later data types such as
%			'MotionComp'. Default empty: don't set any scan groups.
%
%	applyGlm: flag to apply a General Linear Model to each scan group
%			that's been assigned. If the motionComp flags (below) are also
%			set, then will apply the GLMs to the MotionComp data.
%			Default 0, don't apply a GLM.
% 
%	applyCorAnal: an array specifying scans to which to apply a coherence
%			analysis. Default empty, don't compute any.
%
%   motionComp: flag to do motion correction. 0: don't do it; 1 do
%           between scans; 2 do within scans; 3 do both between and within
%           scans, with between first; 4 do both between and within with
%           within first. Default is 0. Currently this only supports the
%           "Nestares" code motion compensation, although the SPM-based
%           code should be added down the line (it can be run from within
%           mrVista).
% 
%   sliceTimingCorrection: if 1, will perform slice timing correction
%           before any other preprocessing. Default: 0, don't.
% 
%   motionCompRefScan: reference scan if running between-scans motion
%           compensation.
% 
%   motionCompRefFrame: reference frame if running within-scans motion
%           compensation.
%
% ras, 05/2007.
[p f ext] = fileparts(pwd);

params.inplane = '';
params.functionals = {};
params.vAnatomy = '';
params.sessionDir = pwd;
params.sessionCode = f;
params.subject = '';
params.description = '';
params.comments = '';
params.keepFrames = [];
params.annotations = {};
params.parfile = {};
params.coParams = {};
params.glmParams = {};
params.scanGroups = {};
params.applyGlm = 0;
params.applyCorAnal = [];
params.motionComp = 0;
params.sliceTimingCorrection = 0;
params.motionCompRefScan = 1;
params.motionCompRefFrame = 1;
params.alignment = [];

%% check for input files in the expected locations
% inplanes
defaultInplanePath = fullfile(params.sessionDir, 'Raw', 'Anatomy', 'Inplane');
if exist(defaultInplanePath, 'dir')
    % look for DICOM files
    pattern = fullfile(defaultInplanePath, '*.dcm');
    if ~isempty( dir(pattern) )
        params.inplane = defaultInplanePath;
    end
end

% functionals
defaultFuncPath1 = fullfile(params.sessionDir, 'Raw', 'functionals');
defaultFuncPath2 = fullfile(params.sessionDir, 'Raw', 'Pfiles');
if exist(defaultFuncPath1, 'dir')
    pattern = fullfile(defaultFuncPath1, '*.nii.gz');
    if ~isempty( dir(pattern) )       
        % todo: write a function automatically extract names of nifti files in
        %       default directory
        % params.functionals = mrInitMagFiles(defaultFuncPath1);
    end
elseif exist(defaultFuncPath2, 'dir')
    pattern = fullfile(defaultFuncPath2, 'P*.7.mag');
    if ~isempty( dir(pattern) )
        params.functionals = mrInitMagFiles(defaultFuncPath2);
    end
end

% volume anatomy
defaultVolAnatPath1 = fullfile(params.sessionDir, '3DAnatomy', 't1.nii.gz');
if exist(defaultVolAnatPath1, 'file')
    params.vAnatomy = defaultVolAnatPath1;
end



return

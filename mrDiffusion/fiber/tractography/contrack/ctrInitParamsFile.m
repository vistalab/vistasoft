function p = ctrInitParamsFile(p,spName)
% Creates parameters file for ConTrack pathway generation and scoring.
%
%  ctrInitParamsFile(params,spName)
%
% The params structure (p) contains information about a wide range of input
% and output parameters. The data in these files are processed here,
% creating a the final parameters file.
%
% Initialization parameters (needs clarification from Tony):
% 
%   localSubDir
%   roi1File, roi2File - ROI files are coordinate lists in ACPC space.
%   roiWayFile         - 'none' is possible.  otherwise, an ROI file
%   inSamplerOptsFile  - Structure of ConTrack parameters (see ctrCreate)
%   outSamplerOptsFile 
%
% Required file names (full paths)
%   fgFile - Stores the pathways that connect the two ROIs.
%   roiMaskFile - Binary image; non-zero within the ROIs, zero elsewhere.
%   xMaskFile - 
%   wmProbFile
%   scriptFileName
%
%   pdfFile: Probability distribution function file that
%       Used during tractography to represent scanner noise, shape
%       information of the tensor fit per voxel. 
%       Data stored: EVec3,EVec2,EVec1,k1,k2,Cl,EVal2,EVal3.
%
%   remoteSubDir
%   machineList
%
%
%Example: Normally runs from ctrInit, but you can also run it from a script
%by filling in the slots in the params structure such as:
% 
% Author: AJS
% Modified by DY 07/25/2008 to handle case where user has used the menu
% (Edit --> Full parameter list) to change additional parameters.
% 2008.09.22 MP added spName so that the ctrSampler file (p.samplerFile)
% can have a unique file name specified by the user. If no name is passed
% in the default directory and file name are used.
% 02/23/2009 ER modified to handle no ROIs (simply generates pdf.nii.gz,
% wmProb.nii.gz and a no-ROI contrack structure.

%% Set up input parameters
if notDefined('p'), error('Parameters required'); end

%% Derive a few additional parameters from existing ones

% Location is in ..\fibers\contrack (relative to the dt6 directory)
% This should be managed by ctrFileName() - which should be re-written.
% We will put the script in this same directory
p.dt6Dir       = mrvDirup(p.dt6File);
p.localSubjDir = mrvDirup(p.dt6Dir,1);
if notDefined('spName')
    p.samplerFile  = fullfile(p.localSubjDir,'fibers','conTrack',['ctrSampler_',p.timeStamp,'.txt']);
else
    p.samplerFile = spName;
end
p.logFile = fullfile(p.localSubjDir,'fibers','conTrack',['ctrLog_',p.timeStamp,'.txt']);
if (~isempty(p.roi1File) && ~isempty(p.roi1File))
[tmp,str1] = fileparts(p.roi1File);
[tmp,str2] = fileparts(p.roi2File);
p.roiMaskFile  = ctrFilename(str1,str2,p.timeStamp,'roi');
end
p.xMaskFile    = ctrFilename([],[],[],'xMask');  % None

%% Handling of WM Mask

% If the checkbox is checked, then we create a new wmProbFile.
% If not, and one exists, then we use that one.
if ~exist(fullfile(p.dt6Dir,'bin','wmProb.nii.gz'),'file') || p.wm
    ctrWMProbFile(p);
end

%% Handling pdf file
% If the checkbox is checked, then we create a new pdfFile.
% If not, and one exists, then we use that one.

if ~exist(fullfile(p.dt6Dir,'bin','pdf.nii.gz'),'file') || p.pddpdf
    ctrPDFFile(p);
end

%% Create the contrack structure
ctr = ctrCreate();

%% Create ROI mask image from ROI and waypoint  files -- only if both ROI files
%% are provided
xformToAcpc = eye(4);
if (~isempty(p.roi1File) && ~isempty(p.roi1File))
[ctr, xformToAcpc] = ctrROIMaskFile(p, ctr);
end

%% Write volume names to options file and save
% The parameters file stores file names relative to dt6Dir\bin.
% This helps with machine format independence, so we don't have to create
% the file and run the bash script on the same file system.
%
% Tony also calls this directory is also called the image directory for
% some reason. 

% If user has already used the menu to edit additional parameters (Edit -->
% Full Parameter List), use those values already set.
if isfield(p,'editFullParams') & p.editFullParams==1
    ctr = ctrSet(ctr, 'image_directory', p.image_directory);
    ctr = ctrSet(ctr, 'fa_filename',      'wmProb.nii.gz');
    ctr = ctrSet(ctr, 'pdf_filename',     'pdf.nii.gz');
    if isfield(p, 'roiMaskFile')&&~isempty(p.roiMaskFile)
        ctr = ctrSet(ctr, 'mask_filename',    p.roiMaskFile);
    end
    if isfield(p, 'xMaskFile')&&~isempty(p.xMaskFile)
    ctr = ctrSet(ctr, 'xmask_filename',   p.xMaskFile);
    end
    ctr = ctrSet(ctr,'desired_samples',p.dSamples);
    ctr = ctrSet(ctr,'max_nodes',p.maxNodes);
    ctr = ctrSet(ctr,'min_nodes',p.minNodes);
    ctr = ctrSet(ctr,'step_size',p.stepSize);

    % If user hasn't already edited the full parameters, set defaults
elseif ~isfield(p,'editFullParams') | (p.editFullParams==0)
    ctr = ctrSet(ctr, 'image_directory', fullfile(p.dt6Dir,'bin'));
    ctr = ctrSet(ctr, 'fa_filename',      'wmProb.nii.gz');
    ctr = ctrSet(ctr, 'pdf_filename',     'pdf.nii.gz');
    if isfield(p, 'roiMaskFile')&&~isempty(p.roiMaskFile)
        ctr = ctrSet(ctr, 'mask_filename',    p.roiMaskFile);
    end
    if isfield(p, 'xMaskFile')&&~isempty(p.xMaskFile)
    ctr = ctrSet(ctr, 'xmask_filename',   p.xMaskFile);
    end
    ctr = ctrSet(ctr,'desired_samples',p.dSamples);
    ctr = ctrSet(ctr,'max_nodes',p.maxNodes);
    ctr = ctrSet(ctr,'min_nodes',p.minNodes);
    ctr = ctrSet(ctr,'step_size',p.stepSize);
end


%% Save the parameter file
ctrSave(ctr,p.samplerFile,xformToAcpc);

return;



function dtiRawAlign(dwRaw, t1File, bvalsFile, outAcpcXform, outEddyCorrectXform)
%
% dtiRawAlign([dwRaw=uigetfile], [t1FileOrAcpcXformFile=uigetfile], [bvalsFile='bvals'], [outAcpcXform], [outEddyCorrectXform])
%
% Aligns the raw DW images in dwRaw (NIFTI format) to the mean
% b=0 image (computed based on bvals==0).
%
% HISTORY:
% 2007.01.10 RFD: wrote it.

%% Set defaults

% Initialize SPM default params
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;
% Set the following to true to allow a 12 parameter fit of the mean
% b=0 to the t1. Be careful- if you don't have quality, whole-brain
% DTI data, this can do bad things!
unwarpDti = true;

% For DW data, we may want things to be linear in log intensity
% space. So, we might want to do our trilinear interpolation on
% log-transformed images.
logInterp = false;

%% Load the raw DW data (in NIFTI format)
if(~exist('dwRaw','var')|isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)) error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(dwRaw);
else
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[junk,inBaseName,junk] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end

if(~exist('t1File','var')|isempty(t1File))
    [f,p] = uigetfile({'*.nii.gz';'*.mat'},'Select a T1 file or acpc transform mat file...',fullfile(dataDir,'t1.nii.gz'));
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    t1File = fullfile(p,f);
end

if(~exist('bvalsFile','var')|isempty(bvalsFile))
    bvalsFile = fullfile(dataDir,'bvals');
    [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvalsFile);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvalsFile = fullfile(p,f);
end

if(~exist('outAcpcXform','var')|isempty(outAcpcXform))
    outAcpcXform = fullfile(dataDir,[inBaseName 'AcpcXform']);
end

if(~exist('outEddyCorrectXform','var')|isempty(outEddyCorrectXform))
    outEddyCorrectXform = fullfile(dataDir,[inBaseName 'EcXform']);
end

if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end

interpParams = [1 1 1 0 0 0];
mnB0File =  fullfile(dataDir,[inBaseName '_b0.nii.gz']);
mnB0File = dtiRawComputeMeanB0(dwRaw, bvalsFile, mnB0File);
disp(['Loading eddycorrect reference image ' mnB0File '...']);
mnB0 = niftiRead(mnB0File);

dtiRawAlignToT1(mnB0, t1File, outAcpcXform);

dtiRawEddyCorrect(dwRaw, mnB0, ecFile);

return;

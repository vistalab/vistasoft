function  [ni, roiName] = dtiRoiNiftiFromMat(matRoi,refImg,roiName,saveFlag)
% 
% function dtiRoiNiftiFromMat([matRoi = mrvSelectFile],[refImg],[roiName], ... 
%                             [saveFlag=1])
% 
% This function will read in a matlab roi file (as used in mrDiffusion) and
% convert it to a nifti file that can be loaded in Quench. 
% 
% INPUTS:
%   matRoi   - the .mat roi file you want converted to nifti
%   refImg   - the nifti reference image. 
%   roiName  - the name for the new nifti roi defaults to
%              [matRoi.name '.nii.gz']
%   saveFlag - 1 = save the ROI, 0 = don't save, just return the struct.
% 
% OUTPUTS:
%   ni       - nifti structure cointaining roi data
%   roiName  - path to the saved nifti file
%
%   Saves your roi in the same directory as matRoi with the same
%   name (if you set saveFlag to 1 - which is the default).
% 
% WEB:
%   mrvBrowseSVN('dtiRoiNiftiFromMat');
% 
% EXAMPLE: 
%   matRoi = 'leftLGN.mat';
%   refImg = 't1.nii.gz';
%   ni     = dtiRoiNiftiFromMat(matRoi,refImg);
% 
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 


%% Check INPUTS

if ~exist('matRoi','var') || notDefined('matRoi') 
    matRoi = mrvSelectFile('r',{'*.mat';'*.*'},'Select ROI mat file');
    if isempty(matRoi); error('Canceled by user.'); end
end

% Read in the roi if it was passed in as a file name
if ~isstruct(matRoi) 
    roi = dtiReadRoi(matRoi);
else
    roi = matRoi;
end

% Select the reference image
if ~exist('refImg','var') || notDefined('refImg') 
    refImg = mrvSelectFile('r',{'*.nii.gz';'*.*'},'Select Reference Image');
    if isempty(refImg); error('Canceled by user.'); end
end

% Set the roiName to be the same as the matRoi if it's not passed in
if ~exist('roiName','var') || notDefined('roiName')
    try
        [p, f, ~] = fileparts(matRoi);
        roiName = fullfile(p, [f '.nii.gz']);
    catch  %#ok<CTCH>
        p = pwd;
        roiName = fullfile(p, [roi.name '.nii.gz']);
    end
end

% Be default we save the ROI
if notDefined('saveFlag')
    saveFlag = 1;
end


%% Handle the reference image
if ischar(refImg)
    ref   = niftiRead(refImg);
else
    ref = refImg;
end
xform = ref.qto_xyz;
bb = [-(size(ref.data).*ref.pixdim)/2; (size(ref.data).*ref.pixdim)/2-1];

%% Create the roiImg and xForm from the roi 
[roiImg, imgXform] = dtiRoiToImg(roi,xform,bb);

%% Set ROI as a nifti struct and save
ni = niftiCreate('data', uint8(roiImg),'qto_xyz', imgXform);
ni.fname = roiName;

if saveFlag
    niftiWrite(ni);
    fprintf('Saved: %s.nii.gz \n',roiName);
end

return



function fs_roisFromAllLabels(fsIn,outDir,type,refT1)
% 
% fs_roisFromAllLabels([fsIn=mrvSelectFile],[outDir=uigetdir],[type='nifti'],[refT1=[]])
% 
% This function will create an roi from each unique non-zero label value in
% a given freesurfer segmentation file and save each as an roi of filetype
% 'type' in the directory 'outDir'. Should 'fsIn' be an MGZ file we will
% convert that file to nifti using 'refT1' as a reference and save the
% resulting nifti in the same directory as the passed in 'fsIn'.
% 
% INPUTS:
%   fsIn    - the full path to your freesurfer segmentation file
% 
%   outDir  - the directory where you want all the rois stored
% 
%   type    - the file type for ROI output. Accepted types: 'nifti' 'mat'
% 
%   refT1   - if your fsIn file is of type 'mgz' then you need to provide a
%             reference file for conversion. This is the usually the t1
%             used when creating the segmentation. Defaults to empty, in
%             which case you'll have to select it in a gui if conversion is
%             necessary.
% 
% WEB RESOURCES:
%   mrvBrowseSVN('fs_roisFromAllLabels');
% 
% 
% SEE ALSO:
%   dtiRoiFromNifti.m, fs_mgzSegToNifti.m, fs_labelToNiftiRoi.m 
% 
% 
% EXAMPLE USAGE:
%   fsIn   = '/path/to/aparc+aseg.mgz';
%   outDir = '/save/directory/rois';
%   type   = 'mat';
%   refT1  = '/path/to/t1Anatomical.nii.gz';
%   fs_roisFromAllLabels(fsIn,outDir,type,refT1);
% 
%  
% (C) Stanford University, VISTA [2012]
% 


%% INPUTS

if notDefined('fsIn') || ~exist(fsIn,'file')
    [fileName path] = uigetfile({'*'},'Select the Freesurfer aparc_aseg Nifti or MGZ File',pwd);    
    if isnumeric(fileName); disp('Canceled by user.'); return; end
    fsIn = fullfile(path,fileName);
end

if notDefined('outDir') 
    outDir = uigetdir(pwd,'Select your output directory');
end

if ~exist(outDir,'dir'), mkdir(outDir); end

if notDefined('type')
    if nargin == 0
        type = questdlg('Which OUTPUT FILE TYPE would you like to use?','Output File Type','nifti','mat','nifti');
    else
        type = 'nifti';
    end
end

if notDefined('refT1')
    refT1 = [];
end


%% Check to see if the file is an mgz. If yes, convert it to nifti.

fsIn = f_fsMgzCheck(fsIn,refT1);


%% Read in the nifti

ni = niftiRead(fsIn);


%% Extract the unique, non-zero label values

allLabels = unique(ni.data);
remove    = find(allLabels==0);
if ~isempty(remove), allLabels(remove) = []; end


%% Loop over all the values and create the rois
for ii=1:numel(allLabels)
    name = fs_getROILabelNameFromLUT(allLabels(ii));
    saveName = fullfile(outDir,[num2str(allLabels(ii)) '_' name]);
    dtiRoiFromNifti(fsIn,allLabels(ii),saveName,type);
end

disp('DONE');

return






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            FUNCTIONS                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This funciton checks the file type of fsIn. If MGZ convert to NIFIT.
function fsIn = f_fsMgzCheck(fsIn,refT1)
[p f e] = fileparts(fsIn);
ismgz = strcmp(e,'.mgz');
if ismgz == 1
   % Warn the user that they have passed in a .mgz file and wait for their response
   sprintf('You have selected an mgz file. \nConverting to nifti using fs_mgzSegToNifti...');
   outName = fullfile(p,[f '.nii.gz']);
   fs_mgzSegToNifti(fsIn,refT1,outName);
   fsIn = outName;    
end




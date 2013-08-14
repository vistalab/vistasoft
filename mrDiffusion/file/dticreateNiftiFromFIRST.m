function dticreateNiftiFromFIRST(anatROI,FIRSTnifti,outFile)

% Usage: dticreateNiftiFromFIRST(anatROI,[FIRSTnifti],[outFile])
%
% anatROI = string with name of the desired anatomical ROI. Current choices
% implemented are:
% 'r_amygdala'
% 'l_amygdala'
% 'r_hippocampus'
% 'l_hippocampus'
%
% FIRSTnifti='/path/to/subjDir/FIRST/t1_sgm_all_th4_first.nii.gz';
%
% outFile='/path/to/subjDir/amg_class.nii.gz';
%
% This script uses the FSL FIRST classification to parse out, and
% label, the left and right Amygdalae. This classification can then be
% loaded into itkGray and edited. 
% 
% To use this script you must have already run FIRST using FSL. The file
% that will be read is the output file from FIRST
% (t1_sgm_all_th4_first.nii.gz). 
%
% Default behavior: without any input arguments, the function will allow
% user to browse for the nifti, then save the amygdala nifti in the current
% directory as 'anatROI_class.nii.gz'.
%
% For information on running FIRST you can visit FSL's website, or the lab
% wiki:
% http://white.stanford.edu/newlm/index.php/Anatomical_Methods#Preprocessin
% g_Using_FSL_Tools_.28ITKGray_Segmentation_Pipeline.29
%
% History:
% 06/18/2008 DY modified Bob's mrGrayAnatomy.m for Kids FFA project. This
% is a more generalized version of dti_FFA_amygdalaNifti.m
%
% TODO: Users can add more subcortical structures as they want them. The
% directions for doing this are on the vpnl wiki. Ask Davie or Bob for
% further questions. 

% Deal with first input argument: anatROI
if ~exist('anatROI','file') | isempty(anatROI)
    error('Must specify one of the available anatomical ROIs. See help for this function.');
end

% Define volume number. We discover this by loading the subject's FIRST
% nifit in FSLVIEW. Then we find the volume number that corresponds to the
% desired structure. We take this number and add 1, because FSL counts
% volumes starting from 0, but matlab counts starting from 1. Remember,
% structures that appear on the right-hand side are actually in the left
% hemisphere (FSLVIEW in neurological convention). 
switch anatROI
    case 'r_amygdala'
        left=0; volNum=11; % FSL volume = 10
    case 'l_amygdala'
        left=1; volNum=3; % FSL volume = 2
    case 'r_hippocampus'
        left=0; volNum=13; % FSL volume = 12
    case 'l_hippocampus'
        left=1; volNum=5 % FSL volume = 4
end

if ~exist('FIRSTnifti','file')
    [FIRSTnifti, path] = uigetfile('*.nii.gz', 'Pick a FIRST segmented nifti file');
    FIRSTnifti = fullfile(path,FIRSTnifti);
end

if ~exist('outFile','var')
    outFile = fullfile(pwd,[anatROI '_class.nii.gz']);
end


% Loads the 4D nifti data into variable 'ni'. 
ni=niftiRead(FIRSTnifti);

% Make sure left and right aren't flipped
ni = niftiApplyCannonicalXform(ni);
firstClass = ni.data(:,:,:,volNum);
xform = ni.qto_xyz;
clear ni;

% Gets the default labels
labels = mrGrayGetLabels();

% Create a matrix C, with all zeros. Put labels.xGray value wherever there
% was a non-zero value in firstClass. These non-zero values have specific
% meaning in the FSL world. There is a website that explains what the
% different values mean. Actually these values are all unique. Overlapping
% voxels are the sum of the value assigned to each structure (e.g., if
% hipp=12 and amyg=41, then an overlapping voxel would be 12+41=53). We
% currently include all non-zero values (including overlap), but someone
% may want to do something more clever.
%
% www.fmrib.ox.ac.uk/fsl/first/cma_subcortical_label.html.
c = zeros(size(firstClass),'uint8');
if left==1
    c(find(firstClass)) = labels.leftGray; 
elseif left==0
    c(find(firstClass)) = labels.rightGray; 
end

dtiWriteNiftiWrapper(c, xform, outFile, 1, 'mrGray class file','mrGray',1002);

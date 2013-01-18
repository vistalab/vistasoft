function status=fsl_concatSingleXFormToMultiple(singleMatFilename,multipleFileRoot,outputFileRoot)
% status=fsl_concatSingleXFormToMultiple(singleMatFilename,multipleFileRoot,outputFileRoot)
% Uses FSL's convert_xfm command with the -concat option to concatenate a
% single transform with a set of transforms in a directory. 
% This is so that we can do motion correction both within and between scans
% in a single operation. First we compute the within scan MC using mcflirt
% and save the transforms for each volume to the first volume in a
% directory. So there will be N of these transforms: MAT_0001, MAT_0002
% etc...
% Then we compute the between scan transforms for the mean of the motion
% corrected stacks to some base volume, perhaps a reference T2*-weighted
% image or the mean of the first functional scan. This will generate an
% additional transform TMAT_0001 for each scan. 
% Then... we'd like to combine TMAT with all the  MAT_nnnn files for each scan to give Nx
% CTMAT_nnnn files. We can then use apply4dxfm to apply this combined xform to the original 4d Analyze file
% so that the resulting file has only been resampled once.
% ARW 011106: Wrote it


% Find out where FSL lives.
fslBase='/raid/MRI/toolbox/FSL/fsl';
if (ispref('VISTA','fslBase'))
    disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
    fslBase=getpref('VISTA','fslBase');
    disp(fslBase);
end
fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref

% Split the input (multiple files) and output roots up so that we have the directories and
% filenames separately. 

[pathstrM,nameM,extM,versnM]=fileparts(multipleFileRoot);
[pathstrO,nameO,extO,versnO]=fileparts(outputFileRoot);


% Get all the files that match the multipleFileRoot:
DM=dir([multipleFileRoot,'*']);
nFilesFound=length(DM);
fprintf('\n%d files found in the input',nFilesFound);

% Check to see if the output directory exists. If it doesn't, make it
if(~exist(pathstrO,'dir'))
    fprintf('\nOutput directory does not exist: Making it...');
    mkdir(pathstrO);
end

% Now go through each file in DM and use convert_xfm
status=0;

for thisMat=1:nFilesFound
    outFileName=[pathstrO,filesep,nameO,sprintf('_%0.4d',thisMat-1)];
    fslCommand=[fslPath,filesep,'convert_xfm -omat ',outFileName,' -concat ',singleMatFilename,' ',pathstrM,filesep,DM(thisMat).name];
    %disp(fslCommand);
    status=system(fslCommand);
end





function dtiRawFixDcm2niiXform(niftiFile,niName)

% dtiFixDcm2niiXform(niftiFile,[niName])

% This function takes a nifti file created by dcm2nii and fixes the xform
% fields to work with the mrDiffusion preprocessing pipeline. 
% 
% It is no more than a simple wrapper for dtiSetQto. 

% History:
% 01/26/2011 - LMP
% 

if ~exist('niftiFile','var')
        [f, p]   = uigetfile({'*.nii.gz';'*.*'}, 'Please choose a Raw Nifti File', pwd);
        niftiFile = fullfile(p,f);
        if(isnumeric(f)); disp('User canceled.'); return; end
end

ni = niftiRead(niftiFile);
disp('Fixing dcm2nii xForm...');
ni = niftiSetQto(ni,ni.sto_xyz);

if exist('niName','var')
    ni.fname = niName;
end

d = pwd;
cd(mrvDirup(niftiFile));

writeFileNifti(ni);
disp('Done.');

cd(d);

return

%% t_vAnat2NIFTI
%
%
% In preparation

% DEBUGGING THIS.  NOT SURE ABOUT ALL THE FLIPS AND SO FORTH

% Go to the directory where you have a vAnatomy
[vData,mmPerVox] = readVolAnat('vAnatomy.dat');

vData = flipdim(flipdim(permute(vData,[3 2 1]),2),3);
mmPerVox = mmPerVox([3 2 1]);

xform = [diag(1./mmPerVox), size(vData)'/2; 0 0 0 1];
ni = niftiGetStruct(vData, inv(xform));
ni.fname = 't1.nii.gz';

writeFileNifti(ni);
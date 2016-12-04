function fname = niftiSaveVistaVolume(vw, data, fname)
% Convert a mrVista volume array to a nifti file with the same orientation
% and header as the volume anatomy.

mrGlobals;

mmPerVox = viewGet(vw, 'mmPerVox');

% Convert data field to RAS
[~, ~, ni] = mrLoadRet2nifti(data, mmPerVox);

% Load the volume anatomy
t1   = niftiRead(vANATOMYPATH);
[~, canxform] = niftiApplyCannonicalXform(t1);

ni = niftiApplyCannonicalXform(ni, inv(canxform));

data = niftiGet(ni, 'data');
ni = t1;
ni = niftiSet(ni, 'data', data);
ni = niftiSet(ni, 'filepath', fname);

writeFileNifti(ni);


end
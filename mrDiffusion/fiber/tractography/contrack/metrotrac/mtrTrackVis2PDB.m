function mtrTrackVis2PDB(volFile, trkFile, pdbFile)

% File format conversion from the .trk file format (TrackVis) to pdb files
%
% Parameters
% ----------
% volFile: A full-path to a nifti file, from which the qform will be read 
% trkFile: The trk file to be converted. 
% pdbFile: The output. 
% 
% Returns
% -------
% Nothing. 


% Load vol file to get AcPc xform
vol = niftiRead(volFile);
xformTo = vol.qto_xyz;
xformFrom = abs(vol.qto_ijk);
xformFrom(1:3,4)=0;
xformToAcPc = xformTo*xformFrom;

% Get mm dimensions of image
dim_mm = vol.dim(:).*abs(diag(vol.qto_xyz(1:3,1:3)));
clear vol;

% Load trks file
fg = read_trk_to_fg(trkFile);

% Remove really short fibers (<10 points)
%fg = dtiCleanFibers(fg, [], [], 11)

fg = dtiXformFiberCoords(fg,xformToAcPc);
fg = dtiClearQuenchStats(fg);
fg = dtiCreateQuenchStats(fg,'Length','Length', 1);
mtrExportFibers(fg,pdbFile,eye(4));

return;

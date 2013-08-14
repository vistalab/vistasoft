function mtrPDB2TrackVis(volFile, trkExFile, pdbFile, trkFile)
% TrackVis file is in mm coordinates, but without center shift
% PDB file is loaded in AcPc coordinates.

% Load vol file to get AcPc xform
vol = niftiRead(volFile);
xformFrom = vol.qto_ijk;
xformTo = abs(vol.qto_xyz);
xformTo(1:3,4)=0;
xformFromAcPc = xformTo*xformFrom;

% Get mm dimensions of image
dim_mm = vol.dim(:).*abs(diag(vol.qto_xyz(1:3,1:3)));

% Load trks example header file
trks.header = read_trk_hdr(trkExFile);

% Load PDB file
fg = mtrImportFibers(pdbFile);

% Get the fiber coords into mm (without AcPc shift)
fg = dtiXformFiberCoords(fg,xformFromAcPc);

% Get into trk coordinates
trks.fiber = {};
for ll=1:length(fg.fibers)
    trks.fiber{ll}.num_points = size(fg.fibers{ll},2);
    trks.fiber{ll}.points = fg.fibers{ll}';
end

trks.header.n_count = length(fg.fibers);
write_trk(trks,trkFile);

return;

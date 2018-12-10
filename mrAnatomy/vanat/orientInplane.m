function ni = orientInplane(vw, fname)

% Load it
ni = niftiRead(fname);

%If functional orientation is defined, make sure we use it
ipOrientation = viewGet(vw, 'Inplane Orientation');
if ~isempty(ipOrientation)
    vectorFrom = niftiCurrentOrientation(ni);
    xform      = niftiCreateXformBetweenStrings(vectorFrom,ipOrientation);
    ni         = niftiApplyXform(ni,xform);
else
    %Let us also calculate and and apply our transform
    ni = niftiApplyAndCreateXform(ni,'Inplane');
end

%Calculate Voxel Size as that is not read in (what is this used for??)
voxelSize = prod(niftiGet(ni,'pixdim'));
ni = niftiSet(ni,'Voxel Size',voxelSize);

end
function mtrMRD2FDTImage(fname)

ni = niftiRead(fname);
if length(size(ni.data)) == 3
    ni.data = ni.data(end:-1:1,:,:);
elseif length(size(ni.data)) == 4
    ni.data = ni.data(end:-1:1,:,:,:);
else
    error('Not 4d or 3d image file!');
end
writeFileNifti(ni);

return;

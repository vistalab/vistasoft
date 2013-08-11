function ni_img = mtrNiftiToCamino(inNiftiFilename, outDataType, outCaminoFilename)
%
% read in nifti image and write out camino data
%
% ni_img = mtrNiftiToCamino([inNiftiFilename], [outDataType], [outCaminoFilename])

if( ieNotDefined('inNiftiFilename') )
    [f,p] = uigetfile({'*.nii.gz'},'Select a NIFTI file for input...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    inNiftiFilename = fullfile(p,f); 
end

if( ieNotDefined('outDataType') )
    outDataType = 'double';
end

if( ieNotDefined('outCaminoFilename') )
    [pathstr, name, ext, versn] = fileparts(inNiftiFilename);
    [pathstr, name, ext, versn] = fileparts(fullfile(pathstr,name));
    outCaminoFilename = fullfile(pathstr,[name '.B' outDataType]);
end

ni_img = niftiRead(inNiftiFilename);
% put the 4th dimension in front if its there if scalar
% volume this does nothing
d = shiftdim(ni_img.data,3);
fid = fopen(outCaminoFilename,'wb','b');
fwrite(fid,d(:),outDataType); fclose(fid);

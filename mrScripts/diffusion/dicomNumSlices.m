% dicomNumSlices
%
% Usage: numSlices = dicomNumSlices;
%
% By Davie
% 2008/02/19
%
% From Bob:
% Most dicom-to-nifti functions (including my niftiFromDicom, which calls
% my dicomLoadAllSeries) guess the number of slices by loading all of the
% files and then counting the slices. For 4d sequences like DTI and fMRI,
% where you have a set of volumes acquired many times, you also need to
% look at the DICOM SliceLocation field, which tells you the slice's
% position in the volume (in physical space units). The number of unique
% slice locations is the 'official' DICOM indication of the number of
% slices. 
%
% Why a new function?: 
% Number of slices can be computed by dicomLoadAllSeries, but I couldn't
% get it to work for some reason. So here is a simple (but less general)
% hack. 
%
% This will take a long time to run (which is why I added printing status)

function numSlices = dicomNumSlices

d = dir('*.dcm*');

sliceLocations = zeros(length(d));

for ii=1:length(d)
    curFile=d(ii).name;
    info=dicominfo(curFile);
    sliceLocations(ii)=info.SliceLocation;
    fprintf('\n Loaded slice %d',ii);
    clear info
end

numSlices = unique(sliceLocations);
numSlices = length(numSlices)-1; % subtract 1, b/c there is a 0 location 
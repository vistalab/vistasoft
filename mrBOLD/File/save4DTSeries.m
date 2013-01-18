function save4DTSeries(view,tMat,scan);
%
% save4DTSeries(view,tMat,scan);
% 
% Save a 4D tSeries (tMat) in the proper format
% for the specified view and scan.
%
% Currently works for inplane tSeries only.
%
% ras 03/05.
if ~isequal(view.viewType,'Inplane')
    error('Sorry, only Inplanes for now.')
end

nSlices = numSlices(view);
nTR = numFrames(view,scan);
dims = sliceDims(view,scan);
nx = dims(1);
ny = dims(2);

tMat = int16(tMat);

for slice = 1:nSlices
    sliceData = squeeze(tMat(:,:,slice,:));
    tSeries = reshape(sliceData,nx*ny,nTR)';
    savetSeries(tSeries,view,scan,slice);
end

return
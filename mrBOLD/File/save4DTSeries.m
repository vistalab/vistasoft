function save4DTSeries(vw,tMat,scan)
%
% save4DTSeries(view,tMat,scan);
% 
% Save a 4D tSeries (tMat) in the proper format
% for the specified view and scan.
%
% Currently works for inplane tSeries only.
%
% ras 03/05.
if ~isequal(viewGet(vw,'View Type'),'Inplane')
    error('Sorry, only Inplanes for now.')
end

nSlices = numSlices(vw);
nTR = numFrames(vw,scan);
dims = sliceDims(vw,scan);
nx = dims(1);
ny = dims(2);

tMat = int16(tMat);

for slice = 1:nSlices
    sliceData = squeeze(tMat(:,:,slice,:));
    tSeries = reshape(sliceData,nx*ny,nTR)';
    tSeriesFull(slice) = tSeries;
end
savetSeries(tSeriesFull,vw,scan);

return
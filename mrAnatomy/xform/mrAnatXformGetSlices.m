function sl = mrAnatXformGetSlices(xform, acpcSlices, sliceDim)
%
% sl = mrAnatXformGetSlices(xform, acpcSlices, [sliceDim=3])
%
% Simple wrapper to replace to get image-space slice numbers for a list of
% ac-pc slices.
%
% E.g.:
% ni = niftiRead('/path/to/brain.nii.gz');
% acpcSlices = [40:2:60];
% sl = mrAnatGetSliceIndices(inv(ni.qto_xyz), acpcSlices, 3);
% showMontage(ni.data, sl);
%
% HISTORY:
% 2009.09.18 RFD wrote it.
%

if(~exist('sliceDim','var') || isempty(sliceDim))
   sliceDim = 3; 
elseif(numel(sliceDim)>1||sliceDim>3||sliceDim<1)
    error('sliceDim must be 1, 2, or 3.');
end

acCoords = zeros(numel(acpcSlices),3);
acCoords(:,sliceDim) = acpcSlices(:);
tmp = mrAnatXformCoords(xform,acCoords);

sl = round(tmp(:,sliceDim))';

return;

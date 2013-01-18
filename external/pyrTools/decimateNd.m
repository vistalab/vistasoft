function array = DecimateNd(array, factor)

% array = DecimateNd(array, factor);
%
% Decimate the array by the specified integer factor. The factor must be an
% integer divisor of all dimensions of the input array.
%
% Ress, 2/04

dims = size(array);
if any(mod(dims, factor))
  disp('Error: decimation factor must be an integer divisor of all array dimensions!')
  return
end

nDims = length(dims);
[sDims, iDims] = sort(dims);
array = permute(array, iDims);
shiftInds = [2:nDims, 1];

for iD=1:nDims
  sDims(1) = sDims(1) / factor;
  tempDims = [factor, sDims];
  array = squeeze(mean(reshape(array, tempDims), 1));
  array = permute(array, shiftInds);
  sDims = sDims(shiftInds);
end

array = ipermute(array, iDims);

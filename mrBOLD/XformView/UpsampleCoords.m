function newCoords = UpsampleCoords(coords, factor)

% newCoords = UpsampleCoords(coords, factor);
%
% Returns a coordinate array that oversamples the input coords by the
% specified factor. 
%
% Ress, 2/04

% Determine a few index parameters
factor = ceil(factor);
i1 = factor - 1;
i0 = -i1;
stride = 1 / factor;
dims = size(coords);
nCoords = dims(2);

% Initialize the upsampled coordinates:
newCoords = zeros(3, nCoords*(2*factor-1)^3);
iC = 1;

for iz=i0:i1
  offset(3) = iz * stride;
  for iy=i0:i1
    offset(2) = iy * stride;
    for ix=i0:i1
      offset(1) = ix * stride;
      offsetCoords = coords;
      for ii=1:3, offsetCoords(ii, :) = offsetCoords(ii, :) + offset(ii); end
      newCoords(:, iC:(iC+nCoords-1)) = offsetCoords;
      iC = iC + nCoords;
    end
  end
end

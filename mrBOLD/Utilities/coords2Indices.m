function indices = coords2Indices(coords,dims)
%
% indices = coords2Indices(coords,dims)
%
% coords: MxN array of coordinates, M is the dimensionality.
%   e.g., coords might be 3x100 with y,x,z values in each
%   column. 
%
% dims: size of each dimension.  E.g., dims=[100,200,8] means
%   that the 1st row of coords takes on values between 1:100,
%   2nd row between 1:200, 3rd row between 1:8.
%
% indices: 1xN vector that can be used to pick off the indexed
%   values of an array with dimensions dims.
%
% gmb, 1/23/98
% ARW 01/30/14 : Added cast to prod : dims are sometimes ints

if find(coords)
  indices = coords(1,:);

  for d = 2:length(dims)
    indices = indices + (coords(d,:)-1) * prod(double(dims(1:d-1)));
  end
  
else
  indices = [];
end

return;

%%% Debug

coords2Indices([1:10],[10])
coords2Indices([1:10],[9])
sub2ind([10],[1:10])
sub2ind([9],[1:10])

coords = [1 2 3;
          1 2 3];
coords2Indices(coords,[3 3])
sub2ind([3 3],coords(1,:),coords(2,:))

coords = [1 2 3 1 2 3;
          1 2 3 1 2 3;
	      1 1 1 3 3 3];
coords2Indices(coords,[3 3 3])
sub2ind([3 3 3],coords(1,:),coords(2,:),coords(3,:))

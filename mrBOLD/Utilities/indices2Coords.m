function coords = indices2Coords(indices,dims)
%
% coords = indices2Coords(indices,dims)
% 
% AUTHOR:  Boynton
% PURPOSE: (Author: Wandell)
%   Well, the comments are pretty hard to figure out and the code ain't
% that easy either.  But I think that this routine suppose that there is
% an array, say X, with dims = size(X).
% Then, if we address the array via X(indices), this routine
% tells us which of the array coordinates, in the form (x1, x2 ... xNdims),
% where Ndims = length(dims), correspond to the list of values in indices.  
% This is quite what it says below (the original comments).  But I think 
% it does this.
%
% indices: 1xN vector that can be used to pick off the indexed
%   values of an array with dimensions dims.
%
% dims: size of each dimension.  E.g., dims=[100,200,8] means
%   that the 1st row of the returned values, coords,
%   takes on values between 1:100,
%   2nd row between 1:200, 3rd row between 1:8.
%
% coords: MxN array of coordinates, M is the dimensionality. (I think this
%   means that M is length(dims)).
%   e.g., coords might be 3x100 with y,x,z values in each
%   column. 
%   And he doesn't say, but I think that N is the number of indices.
%
% gmb, 1/23/98

% Why is this a find?  Does he mean to check whether indices is empty?
if find(indices)
   
   % Force indices to be a row vector
   indices = indices(:)';
   
   % Allocates an array to store the coords that will be returned
   coords = zeros([length(dims),length(indices)]);
   
   % Create the array coords using a Boyntonesque formula
   for d = length(dims):-1:1
      coords(d,:) = floor((indices-1) / prod(dims(1:d-1))) + 1;
      indices = indices - (coords(d,:)-1)*prod(dims(1:d-1));
   end
   
else
   coords = [];
end

return;

%%% Debug

dims=[10];
coords = [1:10];
indices=coords2Indices(coords,dims)
coords=indices2Coords(indices,dims)

dims=[3 3];
coords = [1 2 3;
          1 2 3];
indices=coords2Indices(coords,dims)
coords=indices2Coords(indices,dims)

dims=[3 3 3];
coords = [1 2 3 1 2 3;
          1 2 3 1 2 3;
	  1 1 1 3 3 3];
indices=coords2Indices(coords,dims)
coords=indices2Coords(indices,dims)




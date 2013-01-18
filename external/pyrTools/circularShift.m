function result = circularShift(matrix, colshift, rowshift)
% CIRCULARSHIFT: Circular shifting of a matrix/image, i.e., pixels that get
% shifted off one side of the image are put back on the other side.
%
% result = circularShift(matrix, colshift, rowshift)
% 
% EPS, DJH '96

lastrow = size(matrix, 1);
lastcol = size(matrix, 2);

result = matrix;

% Shift the cols
if (colshift>0)
  result = [result(:,[lastcol-colshift+1:lastcol]) ...
	    result(:,[1:lastcol-colshift])];
else
  colshift = -colshift;
  result = [result(:,[colshift+1:lastcol]) ...
	    result(:,[1:colshift])];
end

% Shift the rows
if (rowshift>0)
  result = [result([lastrow-rowshift+1:lastrow],:) ; ...
	    result([1:lastrow-rowshift],:)];
else
  rowshift = -rowshift;
  result = [result([rowshift+1:lastrow],:) ; ...
	    result([1:rowshift],:)];
end


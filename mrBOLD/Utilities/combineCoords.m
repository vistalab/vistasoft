function coords = combineCoords(coords1, coords2, action)
%
% coords = combineCoords(coords1, coords2, action)
%
% Combines coords1 and coords2, removing duplicates, used for
% example to merge ROI coordinates into one big ROI.
%
% Possible values of action:
%	'intersect' / 'and': Take only coordinates that lie in coords1 AND
%						 coords2. 
%	'union' / 'or': Take coordinates that lie in coords1 OR coords2.
%	
%	'xor': Take coordinates that only lie in EITHER coords1 or coords2,
%			but not both.
%	'a not b' / 'setdiff': Take coordinates that lie in coords1 BUT NOT
%			coords2.
%
% coords, coords1, and coords2: 3xN arrays of (y,x,z) coordinates
% dims is size of volume
%
% rmk 10/30/98 
% djh, 2/2001, updated to use intersect(coords1,coords2,'rows')
% ras, 04/10/05, deals w/ empty coords
% ras, 03/28/07, added some comments, more flexibility in specifying the
% action.

% Matlab functions work on rows, not cols
coords1 = coords1';
coords2 = coords2';
	
% made a little more complex, in case we 
% run into empty sets of coords:
if isempty(coords1)
	switch lower(action)
      case {'intersection' 'intersect' 'and'}
         coords = [];
      case {'union' 'or'}
         coords = coords2;
      case 'xor'
         coords = coords2;
      case {'a not b' 'anotb' 'setdiff'}
         coords = [];
	end
elseif isempty(coords2)
	switch lower(action)
      case {'intersection' 'intersect' 'and'}
         coords = [];
      case {'union' 'or'}
         coords = coords1;
      case 'xor'
         coords = coords1;
      case {'a not b' 'anotb' 'setdiff'}
         coords = coords1;
	end
else
	switch lower(action)
      case {'intersection' 'intersect' 'and'}
         coords = intersect(coords1, coords2, 'rows');
      case {'union' 'or'}
         coords = union(coords1, coords2,'rows');
      case 'xor'
         coords = setxor(coords1, coords2, 'rows');
      case {'a not b' 'anotb' 'setdiff'}
         coords = setdiff(coords1, coords2, 'rows');
	end
end

% Transpose back to 3xN
coords = coords';

return

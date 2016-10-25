function dt33 = dti6to33(dt6, icoord)
% Converst an array of dt6 elements to symmetric 3x3 matrices
%
%   dt33 = dti6to33(dt6, icoord)
% 
% icoord: Specifies which coordinate contains the 6 numbers.
%         The rest of the coordinates are untouched.
% Default is icoord = 4 for XxYxZx6xN format, in which case the
%    result is XxYxZx3x3xN.
%
% To recover the Q for (x,y,z) and subject N use
%    result(x,y,z,:,:,N)
% 
% See also:
%   dti33to6
%
% HISTORY:
%   2004.02.11 ASH (armins@stanford.edu) wrote it.
%
% (c) Stanford VISTA Team

sz = size(dt6);

if ~exist('icoord','var'),
  if(prod(sz)==6), 	icoord = find(max(sz)==sz);
  else              icoord = 4;
  end
end

if (icoord > length(sz)), disp('Wrong input format'), return
elseif (sz(icoord) ~= 6), disp('Wrong input format'), return
end

i6 = icoord;
ia = 1:i6-1;
ib = i6+1:length(sz);

% This is pretty confusing.  A comment would help.
dt6 = permute(dt6, [i6,ia,ib]);
L = prod([sz(ia) sz(ib)]);
dt6 = reshape(dt6, [6 L]);
dt33 = zeros([3 3 L]);
dt33(1,1,:) = dt6(1,:);
dt33(1,2,:) = dt6(4,:);
dt33(1,3,:) = dt6(5,:);
dt33(2,1,:) = dt6(4,:);
dt33(2,2,:) = dt6(2,:);
dt33(2,3,:) = dt6(6,:);
dt33(3,1,:) = dt6(5,:);
dt33(3,2,:) = dt6(6,:);
dt33(3,3,:) = dt6(3,:);
dt33 = reshape(dt33, [3,3,sz(ia),sz(ib)]);
dt33 = permute(dt33, [ia+2,1,2,ib+1]);

return
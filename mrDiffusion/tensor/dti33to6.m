function dt6 = dti33to6(dt33, icoord)
% dt6 = dti33to6(dt33, icoord)
% 
% Converts an array so that each symmetric 3x3 element is replaced by
% a dt6 element.
%
% icoord specifies which is the first coordinate that contains the numbers.
% The rest of the coordinates are untouched.
% Default is icoord = 4 for XxYxZx3x3xN format, in which case the
% result is XxYxZx6xN.
%
% See also:
%   dti6to33
%
% HISTORY:
%   2004.02.11 ASH (armins@stanford.edu) wrote it.
%

sz = size(dt33);
if ~exist('icoord'),
    icoord = 4;
end
if (icoord > length(sz)-1), disp('Wrong input format'), return
elseif (sz(icoord) ~= 3 | sz(icoord+1) ~= 3), disp('Wrong input format'), return
end

i33 = [icoord, icoord+1];
ia = 1:icoord-1;
ib = icoord+2:length(sz);

dt33 = permute(dt33, [i33,ia,ib]);
L = prod([sz(ia) sz(ib)]);
dt33 = reshape(dt33, [3 3 L]);
dt6 = zeros([6 L]);
dt6(1,:) = dt33(1,1,:);
dt6(2,:) = dt33(2,2,:);
dt6(3,:) = dt33(3,3,:);
dt6(4,:) = (dt33(1,2,:) + dt33(2,1,:))/2;
dt6(5,:) = (dt33(1,3,:) + dt33(3,1,:))/2;
dt6(6,:) = (dt33(2,3,:) + dt33(3,2,:))/2;
dt6 = reshape(dt6, [6,sz(ia),sz(ib)]);
dt6 = permute(dt6, [ia+1,1,ib-1]);

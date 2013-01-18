%==============================================================================
function [Y,dY] = rigid2D(w,X)
% JM: 2006/07/05
%
% given w and a collection of points X = [X^1;X^2] computes Y = [Y^1;Y^2] where
% X is assumed on a nodal or cell-centered grid
%
% [ Y^1 ] = [ c   -s ] [X_1]   [w_2]
% [ Y^2 ] = [ s    c ] [X_2]   [w_3], 
% with  c = cos(w(1)); s = sin(w(1));
%
% if nargout > 1, we also return the derivative dwY,
%
% dY = [ x_1, x_2, 1, 0,   0,   0;...
%        0  , 0,   0, x_1, x_2, 1     ]
%
% if nargin == 0, we return a starting guess: w = [1;0;0;0;1;0]

Y  = [];
dY = [];

if nargin == 0,
  Y = [0;0;0];
  return;
end;

n  = length(X)/2;
X1 = X(1:n);
X2 = X(n+1:2*n);

D  = [cos(w(1)),-sin(w(1));sin(w(1)),cos(w(1))];
dD = [-sin(w(1)),-cos(w(1));cos(w(1)),-sin(w(1))];

  Y = [(D(1,1)*X1 + D(1,2)*X2 + w(2));...
       (D(2,1)*X1 + D(2,2)*X2 + w(3))];

if nargout<2, 
  return; 
end;
     
dY = [dD(1,1)*X1+dD(1,2)*X2,ones(size(X1)), zeros(size(X1));...
      dD(2,1)*X1+dD(2,2)*X2,zeros(size(X1)),ones(size(X1))     ];

return;
%==============================================================================

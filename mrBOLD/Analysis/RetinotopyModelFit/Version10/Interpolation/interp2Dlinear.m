%==============================================================================
% Copyright (C) 2006, Jan Modersitzki, Nils Papenberg, and Hanno Schumacher,
% see copyright.m; this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
% function [Tk,dTk] = interp2Dlinear(TD,Omega,X,doderivative)
%
% (c) NP, Safir, Luebeck 2006
% this is a function for linear interpolation 
% input:
%     - TD      :   the data that has to be interpolated (a 3D matlab
%     matrix)
%     - Omega   :   the image domain
%     - X       :   the interpolaiton points (a long vector; see getGrid
%     for example)
%     - doderivative : flag for computing the derivative
%
% output:
%     - Tk      : the interpolated function values (same format as X)
%     - dTk     : the derivative of the linear interpolated function with
%     respect to X (computed when doderivative is 1)
%
function [Tk,dTk] = interp2Dlinear(TD,Omega,X,doderivative);


Tk = [];
dTk = [];

% if no input is given a testcase will be created and then
% the derivative test will be started
if nargin == 0
  fprintf('%s\n',mfilename);
  Omega = [1, 1];
  TD = [2 2; 1 1];
  
  X = [-1;0.25];
  X = getGrid(Omega,[128,128]);
  interp2Dlinear(TD,Omega,X);
  
  return;
end;
% if nargout == 0 start a derivative test
if nargout == 0
  % derivative test
  fprintf('derivative(%s)\n',mfilename);
  [fc,dfc] = feval(mfilename,TD,Omega,X,1);
  v   = randn(size(X));
%   %save v1 v
%   load v1
%   e = zeros(size(v));
%   e(1) = v(1);
%   v = e;
%   v
  dfv = dfc*v;
  hh  = logspace(0,-10,11);
  fprintf('%12s %12s %12s \n','h','|fc-ft|','|fc+vdfc-ft|');
  for j=1:length(hh),
    Xt = X + hh(j)*v;
    ft = feval(mfilename,TD,Omega,Xt,0);
    n1 = norm(fc(:)-ft(:));
    n2 = norm(fc(:)+hh(j)*dfv-ft(:));
    fprintf('%12.4e %12.4e %12.4e\n',hh(j),n1,n2);
  end;
  return;
end;

% if doderivative is not explicitly given
% a derivative is computed if two output arguments are given
if isempty(doderivative), doderivative = (nargout > 0); end;
% n is the number of interpolation points
% mD is the size of the interpolation dat
n = length(X)/2;
mD = size(TD);

% zeropadding to avoid bad cases
% so we do an embedding of TD into a field of zeros
offset = 1;
To = zeros(size(TD)+2*offset);
To(offset+(1:size(TD,1)),offset+(1:size(TD,2))) = TD;


% get pixelsize, pay attention to the change of order from m to mD
hD = Omega./mD([2,1]);
% for easier reading
hD1 = hD(1);
hD2 = hD(2);
% for easier reading

% alloc memory for output






% alloc memory for output
Tk = zeros(n,1);
if doderivative, dTk = zeros(n,2); end;

X1 = X(1:n); X2 = X(n+(1:n));

% transform grid X to integer grid
X1 = (1/hD1)*X1 + 0.5;
X2 = (1/hD2)*X2 + 0.5;

% so if we have no good points, we have to format the
% derivative for numerical reasons

G = find( 0 < X1 & X1 < mD(2) + 1 & ...
          0 < X2 & X2 < mD(1) + 1    );

if isempty(G), dTk = sparse(n,2*n); return; end;

% dj is the size we have to go to get the
% neigbhour in j direction
d1 = size(To,1);
d2 = -1;

% now we get into more detail
% Kj storages the noninteger part of Xj
K1 = floor(X1(G)); K2 = floor(X2(G));
Xi1 = X1(G) - K1;  Xi2 = X2(G) - K2;

K = offset + (offset + K1 - 1)*d1 + (mD(1) - K2 +1);

% compute Tk
Tk(G) = (To(K)    .* (1-Xi1) + To(K+d1)    .*Xi1) .* (1-Xi2) ...
  + (To(K+d2) .* (1-Xi1) + To(K+d1+d2) .*Xi1) .* (Xi2);

% if derivative is needed compute it
if doderivative,
  dTk(G,1) = (To(K+d1)    - To(K)   ) .* (1-Xi2) ...
    + (To(K+d1+d2) - To(K+d2)) .* (Xi2);
  dTk(G,2) = (To(K+d2)    - To(K)   ) .* (1-Xi1) ...
    + (To(K+d1+d2) - To(K+d1)) .* (Xi1);
end;

% set the derivative to its matrix form
if doderivative
  dTk = spdiags([dTk(:,1)/hD1, dTk(:,2)/hD2],[0,n],n,2*n);
end;

return;

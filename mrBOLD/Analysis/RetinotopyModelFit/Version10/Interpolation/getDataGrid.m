%==============================================================================
% Copyright (C) 2006, Jan Modersitzki and Nils Papenberg, see copyright.m;
% this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
%function Z = getDataGrid(Omega,TD)
%JM: 2006/02/24
%generates a equidistant grid for the domain Omega, note:
%this grid correspond to the standard ij visualization of the data,
%for example for Omega = [4,3] and
%
%      | 1 4 7 10 |          | 0.5 1.5 2.5 3.5 |       | 2.5 2.5 2.5 2.5 |
% TD = | 2 5 8 11 | and Z1 = | 0.5 1.5 2.5 3.5 |, Z2 = | 1.5 1.5 1.5 1.5 |
%      | 3 6 9 12 |          | 0.5 1.5 2.5 3.5 |       | 0.5 0.5 0.5 0.5 |
%==============================================================================
function Z = getDataGrid(Omega,TD)
dim = length(Omega);

switch dim,
case 1,
  error('nyi')
case 2,
  p  = size(TD);
  h  = Omega./p([2,1]);       % note: change from ij to xy
  z1 = h(1)/2:h(1):Omega(1);
  z2 = h(2)/2:h(2):Omega(2);
  z2 = fliplr(z2);            % note: y direction top-down to bottom-up
  [Z1,Z2] = meshgrid(z1,z2);
  Z  = {Z1,Z2};
case 3,
  p  = size(TD);
  h  = Omega./p([2,1,3]);     % note: change from ij to xy
  z1 = h(1)/2:h(1):Omega(1);
  z2 = h(2)/2:h(2):Omega(2);
  z2 = fliplr(z2);            % note: y direction top-down to bottom-up
  z3 = h(3)/2:h(3):Omega(3);
  z3 = fliplr(z3);
  [Z1,Z2,Z3] = meshgrid(z1,z2,z3);
  Z  = {Z1,Z2,Z3};
otherwise,
  error('nyi');
end;
return;
%==============================================================================

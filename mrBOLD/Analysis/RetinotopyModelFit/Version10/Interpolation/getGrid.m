%==============================================================================
% Copyright (C) 2006, Jan Modersitzki and Nils Papenberg, see copyright.m;
% this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
%function [X,h,n] = getGrid(Omega,m,mode);
% JM: 2006/02/24 2006/03/17 2006/07/05
% generates an equidistant grid for the domain Omega
%
% Omega: (0,Omega(1))x(0,Omega(2))x(0,Omega(3))
% m:     (m(1),m(2),m(3)) number of cells in the directions
% mode:  cell-centered (*), staggered (>,^) and nodal (O)
%
% X:     collection of coordinates of grid points X= (X^1;X^2;X^3)
% h:     Omega/m grid sizes
% n:     lengthes of X^1,X^2,X^3 (useful for staggered grids)
%
% (0,Omega(2))           (Omega(1),Omega(2))
%   |         |         |
% --O----^----O----^----O--  2D example: 
%   |         |         |    O: nodal grid
%   |         |         |    >: face staggered in x
%   >    *    >    *    >    ^: face staggered in y
%   |         |         |    *: cellcentered
%   |         |         |
% --O----^----O----^----O---
%   |         |         |
%   |         |         |
%   >    *    >    *    >    
%   |         |         |
%   |         |         |
% --O----^----O----^----O---
%   |         |         |
%
% (0,0)                 (Omega(1),0)
%
% the points are computed using meshgrid and converted so a single vector:
% (example cell-centered)
%
% [x^1_{1,1},x^2_{1,1}]       [x^1_{1,2},x^2_{1,2}]       ... [x^1_{1,m(1)},x^2_{1,m(1)}]
% [x^1_{2,1},x^2_{2,1}]       [x^1_{2,2},x^2_{2,2}]       ... [x^1_{2,m(1)},x^2_{2,m(1)}]
% .                           .                           .   .
% .                           .                            .  .
% .                           .                             . .
% .                           .                              ..
% [x^1_{m(2),1},x^2_{m(2),1}] [x^1_{m(2),2},x^2_{m(2),2}] ... [x^1_{m(2),m(1)},x^2_{m(2),m(1)}]
% 
% X = [  x^1_{1,1},x^1_{1,2},...,x^1_{1,m(1)},...
%        x^1_{2,1},x^1_{2,2},...,x^1_{2,m(1)},...
%        ...
%        x^1_{m(2),1},x^1_{m(2),2},...,x^1_{m(2),m(1)},...
%        ...
%        x^2_{1,1},x^2_{1,2},...,x^2_{1,m(1)},...
%        x^2_{2,1},x^2_{2,2},...,x^2_{2,m(1)},...
%        ...
%        x^2_{m(2),1},x^2_{m(2),2},...,x^2_{m(2),m(1)}
%     ]
%
% this reordering requires permutation of MATLAB ordering, see mesh2vecNd below.
%==============================================================================
function [X,h,n] = getGrid(Omega,m,mode);

if ~exist('mode','var'), mode = 'cell centered';  end;

X = [];
n = 0;
dim = length(Omega);
h   = Omega./m;

switch dim,
  case 1,
    switch mode,
      case {'centered','cell-centered','cell centered'},
        X = h(1)/2:h(1):Omega(1);
        n = m(1);
      case {'stg','staggered','nodal'},
        X = 0:h(1):Omega(1);
        n = m(1)+1;
    end;
  case 2,
    switch mode,
      case {'centered','cell-centered','cell centered'},
        x1 = h(1)/2:h(1):Omega(1);
        x2 = h(2)/2:h(2):Omega(2);
        [X1,X2] = meshgrid(x1,x2);
      case {'stg','staggered'},
        x1 = 0:h(1):Omega(1);
        x2 = h(2)/2:h(2):Omega(2);
        [X1,dum] = meshgrid(x1,x2);
        x1 = h(1)/2:h(1):Omega(1);
        x2 = 0:h(2):Omega(2);
        [dum,X2] = meshgrid(x1,x2);
      case {'nodal'},
        x1 = 0:h(1):Omega(1);
        x2 = 0:h(2):Omega(2);
        [X1,X2] = meshgrid(x1,x2);
    end
    n = [prod(size(X1)),prod(size(X2))];
    X = mesh2vec2D(X1,X2,mode);
  case 3,
    switch mode,
      case {'centered','cell-centered','cell centered'},
        x1 = h(1)/2:h(1):Omega(1);
        x2 = h(2)/2:h(2):Omega(2);
        x3 = h(3)/2:h(3):Omega(3);
        [X1,X2,X3] = meshgrid(x1,x2,x3);
      case {'stg','staggered'},
        x1 = 0:h(1):Omega(1);
        x2 = h(2)/2:h(2):Omega(2);
        x3 = h(3)/2:h(3):Omega(3);
        [X1,dum,dum] = meshgrid(x1,x2,x3);
        x1 = h(1)/2:h(1):Omega(1);
        x2 = 0:h(2):Omega(2);
        x3 = h(3)/2:h(3):Omega(3);
        [dum,X2,dum] = meshgrid(x1,x2,x3);
        x1 = h(1)/2:h(1):Omega(1);
        x2 = h(2)/2:h(2):Omega(2);
        x3 = 0:h(3):Omega(3);
        [dum,dum,X3] = meshgrid(x1,x2,x3);
      case {'nodal'},
        x1 = 0:h(1):Omega(1);
        x2 = 0:h(2):Omega(2);
        x3 = 0:h(3):Omega(3);
        [X1,X2,X3] = meshgrid(x1,x2,x3);
    end
    n = [prod(size(X1)),prod(size(X2)),prod(size(X3))];
    X = mesh2vec3D(X1,X2,X3,mode);
end;
 
return;

%==============================================================================

function X = mesh2vec2D(x1,x2,mode);

switch mode,
  case {'centered','cell centered'},
    m = [size(x1,2),size(x1,1)];
    n = m(1)*m(2);
    J = permute(reshape(1:n,m(2),m(1)),[2,1]);
    J = reshape(J,n,1);
    X = [x1(J);x2(J)];
  case {'stg','staggered'},
    m  = [size(x1,2)-1,size(x1,1)];
    n1 = (m(1)+1)*m(2);
    J1 = permute(reshape(1:n1,m(2),m(1)+1),[2,1]);
    J1 = reshape(J1,n1,1);
    n2 = m(1)*(m(2)+1);
    J2 = permute(reshape(1:n2,m(2)+1,m(1)),[2,1]);
    J2 = reshape(J2,n2,1);
    X = [x1(J1);x2(J2)];
  case {'nodal'},
    m = [size(x1,2)-1,size(x1,1)-1];
    n = (m(1)+1)*(m(2)+1);
    J = permute(reshape(1:n,m(2)+1,m(1)+1),[2,1]);
    J = reshape(J,n,1);
    X = [x1(J);x2(J)];
end;

%==============================================================================

function X = mesh2vec3D(x1,x2,x3,mode);

switch mode,
  case {'centered','cell centered'},
    m = [size(x1,2),size(x1,1),size(x1,3)];
    n = m(1)*m(2)*m(3);
    J = permute(reshape(1:n,m(2),m(1),m(3)),[2,1,3]);
    J = reshape(J,n,1);
    X = [x1(J);x2(J);x3(J)];
  case {'stg','staggered'},
    m  = [size(x1,2)-1,size(x1,1),size(x1,3)];
    n1 = (m(1)+1)*m(2)*m(3);
    J1 = permute(reshape(1:n1,m(2),m(1)+1,m(3)),[2,1,3]);
    J1 = reshape(J1,n1,1);
    n2 = m(1)*(m(2)+1)*m(3);
    J2 = permute(reshape(1:n2,m(2)+1,m(1),m(3)),[2,1,3]);
    J2 = reshape(J2,n2,1);
    n3 = m(1)*m(2)*(m(3)+1);
    J3 = permute(reshape(1:n3,m(2),m(1),m(3)+1),[2,1,3]);
    J3 = reshape(J3,n3,1);
    X = [x1(J1);x2(J2);x3(J3)];
  case {'nodal'},
    m = [size(x1,2)-1,size(x1,1)-1,size(x1,3)-1];
    n = (m(1)+1)*(m(2)+1)*(m(3)+1);
    J = permute(reshape(1:n,m(2)+1,m(1)+1,m(3)+1),[2,1,3]);
    J = reshape(J,n,1);
    X = [x1(J);x2(J);x3(J)];
end;

%==============================================================================

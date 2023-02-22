% function [x1,x2,x3] = vec2array(X,m,flag)
%
% (c) NP, JM; SAFIR, Luebeck, 2006
%
% This function performs a basis change, nothin else
% it changes from the vector representation of a grid
% to its matlab-matrix representation
% X's dimension should be in {2,3}
% input:
%   - X     : intput gird (see getGrid for example)
%   - m     : size of grid
%   - flag  : kind of grid (one of 
%               'centered', 'cell centered' (which means the same),
%               'stg', 'staggered',
%               'nodal')
%
% output:
% - x1,x2,x3 : the matlab-matrix representation of the grid
%   if X is a 2D grid (which means length(m) == 2), x3 is empty
%
function [x1,x2,x3] = vec2array(X,m,flag)
x1 = [];
x2 = [];
x3 = [];

flag = sprintf('%s-%d',flag,length(m));

switch flag,
  case {'centered-2','cell centered-2'},
    n   = prod(m);
    x1 = reshape(X(1:n)+0,m);    
    x2 = reshape(X(n+1:2*n)+0,m);    
  case {'stg-2','staggered-2'},
    n1 = (m(1)+1)*m(2);
    x1 = reshape(X(1:n1)+0,m(1)+1,m(2));    
    n2 = m(1)*(m(2)+1);
    x2 = reshape(X(n1+(1:n2))+0,m(1),m(2)+1);
  case {'nodal-2'},
    n   = prod(m+1);
    x1 = reshape(X(1:n)+0,m+1);    
    x2 = reshape(X(n+1:2*n)+0,m+1);    

  case {'centered-3','cell centered-3'},
    n   = prod(m);
    x1 = reshape(X(1:n)+0,m);    
    x2 = reshape(X(n+1:2*n)+0,m);    
    x3 = reshape(X(2*n+1:3*n)+0,m);    
  case {'stg-3','staggered-3'},
    n1 = (m(1)+1)*m(2)*m(3);
    x1 = reshape(X(1:n1)+0,m(1)+1,m(2),m(3));    
    n2 = m(1)*(m(2)+1)*m(3);
    x2 = reshape(X(n1+(1:n2))+0,m(1),m(2)+1,m(3));
    n3 = m(1)*m(2)*(m(3)+1);
    x3 = reshape(X(n1+n2+(1:n3))+0,m(1),m(2),m(3)+1);
  case {'nodal-3'},
    n   = prod(m+1);
    x1 = reshape(X(1:n)+0,m+1);   
    x2 = reshape(X(n+1:2*n)+0,m+1);    
    x3 = reshape(X(2*n+1:3*n)+0,m+1);    

  otherwise,
    error('nyi')
end;
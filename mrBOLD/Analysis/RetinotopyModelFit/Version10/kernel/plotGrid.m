%==============================================================================
% Copyright (C) 2006, Jan Modersitzki and Nils Papenberg, see copyright.m;
% this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
% this is only for output and does not need any explaination

function varargout = plotGrid(y,Omega,m,varargin);

if length(m) > 2,
  % 3D !!
  varargout = {[]};
  return;
end;

y1 = reshape(y(1:prod(m)),m);
y2 = reshape(y(1+prod(m):end),m);

grid1 = 1;
grid2 = 1;
color = 'r';

for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;


K1 = 1:grid1:m(1); %K1 = [K1,m(1)];
K2 = 1:grid2:m(2); %K2 = [K2,m(2)];

% and plot the grid 
hold on
l = 0;
for j=1:length(K2),  l=l+1; pp(l) = plot(y1(:,K2(j)),y2(:,K2(j)));  end;
for j=1:length(K1),  l=l+1; pp(l) = plot(y1(K1(j),:),y2(K1(j),:));  end;
hold off

if length(color) == 1, color = char(color); end;
set(pp,'color',color);

if nargout == 1,
  varargout = {pp};
end;

return;
%==========================================================================

function [y,dy,d2y] = cos4(x,sigma)
% JM-2004/05/24 kernel function cos^4 
% y(J) = 4/(3*sigma)*cos(pi/2/sigma*x(J)).^4;

% persistent fcall
% if ~exist('fcall','var') | isempty(fcall), fcall = 0;  end;
% 
% if nargin == 0,
%   fprintf('fcall = %d\n',fcall)
%   fcall = 0;
%   return;
% end;
% fcall = fcall + 1;

y = 0*x;    
J = find(-sigma<x&x<sigma);
x = (pi/sigma)*x(J);

y(J) = 1/(6*sigma)*(3+4*cos(x)+cos(2*x));

if nargout>1,
  dy = 0*y;
  dy(J) = -pi/(3*sigma^2)*(2*sin(x)+sin(2*x));

  if nargout>2,
    d2y    = 0*y;
    d2y(J) =  -2*pi^2/(3*sigma^3)*(cos(x)+cos(2*x));
  end;
end;
  
return;
% ==============================================================================
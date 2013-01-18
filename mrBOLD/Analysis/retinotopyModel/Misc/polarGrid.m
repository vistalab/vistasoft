function [x,y]=polarGrid(bounds,nrings,nspokes)
% polarGrid - make polar grid of points with x-meridians.
%
%  [x,y]=polarGrid(bounds,distance);
%
% Example: 
%  [x,y]=polarGrid([-3 3],8,16);
%  plot(x,y,'o');axis equal;
% makes and plots a polar grid between -3 and 3, the rings are log-spaced
% to (roughly) match cortical magnification factor, whereas the spokes are
% linearly distributed.
%
% 2008/08 SOD: wrote it.

if nargin < 3,
    help(mfilename);
    return;
end;

% maximal radius and eccentricity points
rmax = sqrt(sum(bounds.^2));
r = logspace(log10(1),log10(rmax+1),nrings)-1;

% compute angle points
th = linspace(0,2*pi,nspokes+1);
th = th(1:end-1)+pi/4;

% combine
nr = numel(r);
r  = r(:)*ones(1,numel(th));
th = ones(nr,1)*th(:)';
r  = [0;r(:)];
th = [0;th(:)];

% cartesian coordinates
x = r.*cos(th);
y = r.*sin(th);


% limit just in case
keep = x>=bounds(1) & x<=bounds(2) & y>=bounds(1) & y<=bounds(2);
x = x(keep);
y = y(keep);

return

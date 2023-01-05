function [x, y, z] = rfPlot(params, RF, parent, peak)
% rfPlot - script to visualize cropped RF
%
% [x, y, z] = rfPlot(params, RF, [parent=axes in new figure]);
%
% Will produce a plot illustrating the estimated location of a 
% 2D Gaussian receptive field, with a grid.
%
% RF is a 
% the 'parent' argument directs where to display the plot. Default
% is to create a new figure with its own axes.
%
% 2006/02 SOD: wrote it.
% 2006/09 RAS: added optional 'parent' argument, so you can
% direct the plot to a subplot axes.
% 2008/06 RAS: updated calculation of RF grid to use the X, Y sample points
% in params.analysis.X (and .Y). This replaces a previous method using the
% sample rate; I've found that when you recompute the stimulus (e.g.
% rmRecomputeParams), X/Y sample points for which no stimulus was presented
% are omitted from the analysis. We use this sampling grid to be
% consistent, and prevent bugs in code like rmPlotGUI.
% 2008/07 SOD: reverted back to original. See comments below at the 
% relevant code. Must validate rmRecomputeParams.
if ~exist('parent','var') || isempty(parent), figure; parent = gca;      end;
if ~exist('peak','var'), peak = [];      end;

[x,y] = prfSamplingGrid(params);
z    = NaN(size(x));
z(params.stim(1).instimwindow) = RF;
z    = reshape(z,size(x));

% plot
axes(parent);
cla;
hold on;
surf(x,y,z,'LineStyle','none');

%draw lines at every degree
mylines = 0; %[-floor(params.analysis.fieldSize):floor(params.analysis.fieldSize)];
for ll = 1:numel(mylines),
    for n=1:2,
        if n==1,
            ii = find(x==mylines(ll) & isfinite(z));
            [xs, is] = sort(y(ii));
        else
            ii = find(y==mylines(ll) & isfinite(z));
            [xs, is] = sort(x(ii));
        end;
        if ~isempty(is),
            ii = ii(is);
            h  = line(x(ii),y(ii),z(ii));
            if mylines(ll)==0,
                set(h,'LineWidth',1,'Color',[0 0 0]);
            else
                set(h,'LineWidth',0.5,'Color',[0 0 0]);
            end;
        end;
    end;
end;

minz = min(z(:));
maxz = peak;
if isempty(maxz), maxz = max(z(:)); end;
if isnan(maxz), maxz = 0.1; minz = -0.1; end;
if minz==maxz,
    minz = minz - 0.1;
    maxz = maxz + 0.1;
end;


% scale axis
axis([min(x(:)) max(x(:)) min(y(:)) max(y(:)) minz maxz]);
axis image;

% scale colorbar to be centered on zero
caxis([-1 1].*max(abs(minz),abs(maxz)));

% axis labels
xlabel('x (deg)'); 
ylabel('y (deg)'); 
zlabel('BOLD amplitude (%/deg^2/sec)'); 
title('pRF profile');
hold off;

return

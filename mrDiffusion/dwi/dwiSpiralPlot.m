function [uData,h] = dwiSpiralPlot(inData)
% Spiral out plot from plotted data structure
%
%    [uData,h] = dwiSpiralPlot(inData)
%
%  inData.x  - x values
%  inData.y  - y vales
%  inData.data - image 
%  imagesc(inData.x,inData,y,inData.data)%
%
% Create a graph showing the inData.data values (which are in the format of
% an image), with a spiral ordering, starting from the middle of the image
% and spiraling out to the edge.
%
% Points with a value of 0 are assumed to be irrelevant (because that's
% what we do in dwiPlot).
%
% The inData are a structure produced, generally, by dwiPlot.
% 
% Examples:
%
% See also:  dwiPlot, dwiGet, dtiADC, t_mrdTensorImage
%
%
% (c) Stanford VISTA Team 2012

if notDefined('inData'), error('inData structured required'); end

h = [];
uData = [];

% Spiral out
nPts = size(inData.data,1);

% The matlab function spiral creates a spiral with nPts on the image plane.
% The spiral function creates an array of values that is nPts x nPts.
% The values are dark in the middle of the matrix and increase as one
% spirals out.  Have a look.
% nPts = 10; s = spiral(nPts); imagesc(s); colormap(gray)
s = spiral(nPts); 

% If we sort the values in s, we find the arrangement of points from the
% center to the periphery.  We store this order in the idx.
[junk,idx] = sort(s(:)); %#ok<ASGLU>

% Place the data in the idx order
d = inData.data(idx);

% Remove 0s, which are NaNs originally
d = d(d > 0);

% s is an image matrix of size nPts x nPts.
% Find the midpoint rows.
midPoint = round(nPts/2);

% Pick up the values from the middle to the right edge of the image.  These
% mark the positive x-axis and thus they are the points where the spiral
% crosses each time.
% First get the whole row and then keep only the values on the right side.
cycles = s(midPoint,:); cycles = cycles(midPoint:end);

% Store the data for plotting
uData.data = d; uData.cycles = cycles;

% If there are no output argument, plot and store the data.
% If there are output arguments, figure that the data are all the user
% wants.
if nargout == 0
    h = mrvNewGraphWin;
    plot(d,'-o');
    set(gca,'xtick',cycles); grid on;
    xlabel(sprintf('Spiral out ordering (%d x %d)',nPts,nPts));
    set(gca,'userdata',uData);
end

end

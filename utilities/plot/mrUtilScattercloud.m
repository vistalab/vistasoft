function h = mrUtilScattercloud(x,y,n,l,clm,cmap)
%SCATTERCLOUD display density of scatter data
%   SCATTERCLOUD(X,Y) creates a scatterplot of X and Y, displayed over a
%   surface representing the smoothed density of the points.  The density is
%   determined with a 2D histogram, using 25 equally spaced bins in both
%   directions.
%   SCATTERCLOUD(X,Y,N) uses N equally spaced bins.
%   SCATTERCLOUD(X,Y,N,L) uses L as a parameter to the smoothing algorithm.
%    Defaults to 1.  Larger values of L lead to a smoother density, but a
%    worse fit to the original data.
%   SCATTERCLOUD(X,Y,N,L,CLM) uses CLM as the color/linestyle/marker for
%    the scatter plot.  Defaults to 'k+'.
%   SCATTERCLOUD(X,Y,N,L,CLM,CMAP) uses CMAP as the figure's colormap.  The
%    default is 'flipud(gray(256))'.
%   H = SCATTERCLOUD(...) returns the handles for the surface and line
%    objects created.
%
%   Example:
%
%     scattercloud(1:100 + randn(1,100), sin(1:100) + randn(1,100),...
%                  50,.5,'rx',jet(256))


error(nargchk(2,6,nargin),'struct');

x = x(:);
y = y(:);

if length(x) ~= length(y)
    error('SCATTERCLOUDDataVectorSizesDoNotMatch','The number of elements in x and y do not match')
end

if nargin < 6
    cmap = flipud(gray(256));
end


if nargin < 5
    clm = 'k+';
end

if nargin < 4
    l = 1;
end    

if nargin < 3
    n = 25;
end

% min/max of x and y
minX = min(x);
maxX = max(x);
minY = min(y);
maxY = max(y);

% edge locations
xEdges = linspace(minX,maxX,n);
yEdges = linspace(minY,maxY,n);

% shift edges
xDiff = xEdges(2) - xEdges(1);
yDiff = yEdges(2) - yEdges(1);
xEdges = [-Inf, xEdges(2:end) - xDiff/2, Inf];
yEdges = [-Inf, yEdges(2:end) - yDiff/2, Inf];

% number of edges
numX = numel(xEdges);
numY = numel(yEdges);

% hold counts
C = zeros(numY,numX);

% do counts
for i = 1:numY-1
    for j = 1:numX-1
        C(i,j) = length(find(x >= xEdges(j) & x < xEdges(j+1) &...
                             y >= yEdges(i) & y < yEdges(i+1)));
    end
end

% get rid of Infs from the edges
xEdges = [xEdges(2) - xDiff,xEdges(2:end-1), xEdges(end-1) + xDiff];
yEdges = [yEdges(2) - yDiff,yEdges(2:end-1), yEdges(end-1) + yDiff];

% smooth the density data, in both directions.
C = localSmooth(localSmooth(C,l)',l)';

% create the graphics
ax = newplot;
s = surf(xEdges,yEdges,zeros(numY,numX),C,...
         'EdgeColor','none',...
         'FaceColor','interp');
view(ax,2);
colormap(ax,cmap);
grid(ax,'off');
holdstate = get(ax,'NextPlot');
set(ax,'NextPlot','add');
p = plot(x,y,clm);
axis(ax,'tight');
set(ax,'NextPlot',holdstate)

% outputs
if nargout
    h = [s;p];
end


function B = localSmooth(A,L)
r = size(A,1);
I = eye(r);
D1 = diff(I);
D2 = diff(I,2);
B = (I + L ^ 2 * D2' * D2 + 2 * L * D1' * D1) \ A;




function h = grayhot(m, k)
%GrayHOT    Gray-red-yellow-white color map
%   GrayHOT(M) returns an M-by-3 matrix containing a "hot" colormap.
%   GrayHOT, by itself, is the same length as the current figure's
%   colormap. If no figure exists, MATLAB creates one.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(grayhot)
%
%   See also HSV, GRAY, PINK, COOL, BONE, COPPER, FLAG, 
%   COLORMAP, RGBPLOT.

%   modified from Matlab's hot.m


if nargin < 1, m = size(get(gcf,'colormap'),1); end
n = fix(3/8*m);

% gray level to replace black
if nargin < 2, k = .5; end

% r = [(1:n)'/n; ones(m-n,1)];
% g = [zeros(n,1); (1:n)'/n; ones(m-2*n,1)];
% b = [zeros(2*n,1); (1:m-2*n)'/(m-2*n)];

r = [linspace(k,1,n)'; ones(m-n,1)                      ];
g = [linspace(k,0,n)'; (1:n)'/n;    ones(m-2*n,1)       ];
b = [linspace(k,0,n)'; zeros(n,1);  (1:m-2*n)'/(m-2*n)  ];

h = [r g b];





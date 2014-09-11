% INPUT:
% 1. rf, something like a 128x128 matrix of values. a required parameter
% 2. contourBounds, a vector of "levels". If blank. uses the default of
% contourf
%
% OUTPUT:
%
%
% if making changes to this function, also make changes to:
% make_pRFcontours
% make_pRFcontoursWithError


function [figHandle] = ff_pRFasContours(rf, contourBounds, varargin)



figure(); 


if nargin == 1
    [rf, figHandle] = contourf(rf); 
end

if nargin == 2
    [rf, figHandle] = contourf(rf, contourBounds); 
end

% make square, turn axes labels off
axis square
set(gca,'xtick',[], 'ytick',[]); 

% label the contour plot and make label readable
labHandle = clabel(rf,figHandle, 'FontSize', 24, 'FontWeight', 'bold'); 


% decrease number of contour labels


% change colormap
colormap gray

% add colorbar
hColorbar = colorbar; 
set(hColorbar, 'FontSize', 16); 



end
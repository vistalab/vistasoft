% INPUT:
% 1. rf, something like a 128x128 matrix of values. 
% 2. contourBounds: the levels we want to plot.
% if there is only level v that we want to draw, contourBounds should be of
% the form [v v]
% 3. bootAllSamples: a m x m x n matrix, where 
%    - m is the size of length (or width) of rf
%    - n is the number of bootstrapping steps we take
%
% OUTPUT:
% white background, black contour line, colored shaded error region
%
% if making changes to this function, also make changes to:
% make_pRFcontoursWithError


function [handleFig] = ff_pRFasContoursWithErrorBars(rf, contourBounds, bootAllSamples, varargin)

figure(); 

[rf, handleFig] = contour(rf, contourBounds); 

set(handleFig, 'LineColor','k');
set(handleFig, 'LineWidth', 2); 

% make square, turn axes labels off
axis square
set(gca,'xtick',[], 'ytick',[]); 



% change colormap
colormap gray

% % title or some form of informative legend
% title(['pRF coverage: ' num2str(contourBounds(1))])
handleLeg = legend(num2str(contourBounds(1))); 
set(handleLeg, 'FontSize', 16)



%% beta mode: testing with error bars

if nargin == 3

    figure(); 

end




% label the contour plot and make label readable
% clabel(rf,handleFig, 'FontSize', 24, 'FontWeight', 'bold'); 

% add colorbar
% hColorbar = colorbar; 
% set(hColorbar, 'FontSize', 16); 



end
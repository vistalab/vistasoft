function vw = bicolorCmap(vw)
%
% vw = bicolorCmap(vw);
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   winter colors - values in which map < 0
%   black - values in which map=0
%   autumn colors - values in which map > 0
%
% This is useful for plotting contrast maps in which both
% positive and negative effects are displayed (for related updates, see
% loadParameterMap, computeContrastMap).
%
% ras, 03/04, off of hotCmap
% ras, 05/05, now takes view as an input arg rather
% than a map, and returns a view as well.

numGrays  = vw.ui.mapMode.numGrays;
numColors = vw.ui.mapMode.numColors;

% get map for current scan
scan = viewGet(vw, 'curScan');
if ~isempty(vw.map) && ~isempty(vw.map{scan})
    map = vw.map{scan};
    
    % we have a map on which we want to base
	% the bicolor cmap. Find out whether the
	% map only contains positive or negative 
	% values, or if it crosses zero, and set
	% the map appropriately:
	hi = max(map(:));
	lo = min(map(:));
	
	rng = linspace(lo,hi,numColors);
	
	if lo >= 0 % all positive
        colors = hot(numColors);  % autumn(numColors);
	elseif hi < 0 % all negative 
        colors = flipud(cool(numColors)); % flipud(winter(numColors));
	else        % crosses zero
        colors = zeros(numColors,3);
        neg = length(find(rng < 0));
        colors(neg,:) = [0 0 0]; % black when crosses
        colors(1:neg-1,:) = flipud(winter(neg-1)); % flipud(fliplr(hot(neg-1)));
        colors(neg+1:end,:) = autumn(numColors-neg); % hot(numColors-neg);
	end
    
    clipMode = [lo hi];

%     % let's go ahead and map the absolute value
% 	% of the map onto the 'co' field for this scan:
% 	% this only works for parameter maps, but that may 
% 	% be all we care about at this point:
% 	vw.co{scan} = normalize(abs(map));

    % actually, since it's hard to figure out the significance level 
    % using that method, we'll instead set the co value to 1/100 of
    % the absolute value of the map: that is, if I set cothresh=0.02,
    % that's thresholding by p < 10e-2 in both directions:
    vw.co{scan} = abs(map ./ 100);
    
else
    
    % no map to access, just make
    % a color map w/ autumn and winter 
    % split along the middle:
    colors = flipud(winter(numColors/2));
    colors = [colors; autumn(numColors-size(colors,1))];
    clipMode = 'auto';
    
end

% combine grayscale / color parts of map
cmap = [gray(numGrays);colors];

% set the param map field appropraitely (this is locked
% in right now, so it may be difficult to do this
% for co/amp/ph modes, but I doubt that'd be needed).
vw.ui.mapMode.cmap = cmap;
vw.ui.mapMode.name = 'bicolorCmap';
vw.ui.mapMode.clipMode = clipMode;


return

function rx = rxRefresh3View(rx, recenter);
%
% rx = rxRefresh3View(rx, [recenter=0]);
%
% Refresh the interpolated 3-view window for mrRx. 
% If the recenter flag is greather than 0, will try to recenter
% the image based on the last point clicked in the current
% axes. 
%
% ras, 02/08/2008.
if ~exist('rx', 'var') | isempty(rx)
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ~exist('recenter', 'var') | isempty(recenter),    recenter = 0; end

%% if recentering, get the new position
if recenter > 0
	%% recenter from selected point in cur axes
	% get the selected point
	pts = get(gca,'CurrentPoint');
	locX = round(pts(1,1));
	locY = round(pts(1,2));
	
	% figure out R/L, A/P, S/I coordinates, based on orientation
	switch recenter % this flag doubles as an orientation indicator
		case 1, % row
			loc(3) = locX;
			loc(2) = locY;        
			loc(1) = str2num( get(rx.ui.interpLoc(1), 'String') );
		case 2, % column
			loc(3) = locX;
			loc(2) = str2num( get(rx.ui.interpLoc(2), 'String') );        
			loc(1) = locY;
		case 3, % slice
			loc(3) = str2num( get(rx.ui.interpLoc(3), 'String') );
			loc(2) = locX;       
			loc(1) = locY;
		otherwise, warning('Invalid axes.'); return;  
	end
	
	% update UI controls
	for i = 1:3
		set( rx.ui.interpLoc(i), 'String', num2str(loc(i)) );
	end
else
	%% get position from UI controls
	for i = 1:3
		loc(i) = str2num( get(rx.ui.interpLoc(i), 'String') );
	end
	
end

%% make sure the location is an integer
loc = round(loc);

%% refresh images
% do we show just the interp slice, or both interp and ref?
compareFlag = get(rx.ui.interp3ViewCompare, 'Value');

% do the refresh
for ori = 1:3
	axes(rx.ui.interp3ViewAxes(ori));    cla
	
	if compareFlag==0
		% just show the interp slice
		[interpImg interpImg3D] = rxInterpSlice(rx, loc(ori), ori);

		h = imagesc(interpImg3D); axis image; axis off;
		set(h, 'ButtonDownFcn', sprintf('rxRefresh3View([], %i);', ori));
	else
		% overlay interp, reference images
		% get interpolated image
		interp = rxInterpSlice(rx, loc(ori), ori);

		% get reference image
		switch ori
			case 1, ref = squeeze( rx.ref(loc(ori),:,:) );
			case 2, ref = squeeze( rx.ref(:,loc(ori),:) );
			case 3, ref = rx.ref(:,:,loc(ori));
		end

		% adjust contrast, brightness, etc.
		[interp ref] = rxGetComparisonImages(rx, interp, ref);
		compareImg = rxCompare(interp, ref, 1);
		
		% show the comparison image
		h = imagesc(compareImg); axis image; axis off;
		set(h, 'ButtonDownFcn', sprintf('rxRefresh3View([], %i);', ori));		
	end
end


%% draw crosshairs
gapSize = .1; % gap size as proportion of axis bounds
AX = axis;
d = [gapSize gapSize] .* [AX(4)-AX(3) AX(2)-AX(1)];
sz = rx.rxDims;
color = [1 0.5 0.5];

axes(rx.ui.interp3ViewAxes(1));                           
l(1) = line([loc(3) loc(3)], [1 loc(2)-d(2)], 'Color', color, 'Tag', 'xHairs');    % 2 X lines
l(2) = line([loc(3) loc(3)], [loc(2)+d(2) sz(2)], 'Color', color, 'Tag', 'xHairs');            
l(3) = line([1 loc(3)-d(1)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');    % 2 Y lines
l(4) = line([loc(3)+d(1) sz(3)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');

axes(rx.ui.interp3ViewAxes(2));                           
l(5) = line([loc(3) loc(3)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs'); % 2 X lines
l(6) = line([loc(3) loc(3)], [loc(1)+d(2) sz(1)], 'Color', color, 'Tag', 'xHairs');
l(7) = line([1 loc(3)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs'); % 2 Y lines
l(8) = line([loc(3)+d(1) sz(3)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');

axes(rx.ui.interp3ViewAxes(3));       
l(9) = line([loc(2) loc(2)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs');
l(10) = line([loc(2) loc(2)], [loc(1)+d(2) sz(1)], 'Color', color, 'Tag', 'xHairs');
l(11) = line([1 loc(2)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
l(12) = line([loc(2)+d(1) sz(2)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');


%% if the AC, PC, or mid-sag points are marked, display them as appropriate
if isfield(rx, 'acpcPoints') & ~isempty(rx.acpcPoints)
	labels = {'AC' 'PC' 'MidSag'};
	for i = 1:3
		pt = round( vol2rx(rx, rx.acpcPoints(:,i))' );
		
		% Nan indicates this point not yet marked -- skip:
		if any(isnan(pt)), continue; end
		
		% display point for orientations where the point is visible
		for ori = find(pt==loc)
			axes(rx.ui.interp3ViewAxes(ori));  
			
			pos2D = pt( setdiff(1:3, ori) );
			xx = pos2D(2);  yy = pos2D(1);
			text(xx, yy, 'o', 'Color', 'w', 'HorizontalAlignment', 'center');
			text(xx, yy - 15, labels{i}, 'HorizontalAlignment', 'center', ...
					'Color', 'w');
		end
	end
end

%% show ROIs
for R = rx.rois
	prefs.color = R.color;
	
	roiCoords = vol2rx(rx, R.volCoords, 1);

	% get position from UI controls
	for i = 1:3
		loc(i) = str2num( get(rx.ui.interpLoc(i), 'String') );
	end

	for ori = 1:3
		inSlice = find( round(roiCoords(ori,:)) == loc(ori) );

		prefs.axesHandle = rx.ui.interp3ViewAxes(ori);
		h = outline( roiCoords(setdiff(1:3, ori),inSlice), prefs );
		set(h, 'ButtonDownFcn', sprintf('rxRefresh3View([], %i);', ori))
	end
end

%% update in mrRx GUI
if ishandle(rx.ui.controlFig)
	set(rx.ui.controlFig, 'UserData', rx);
end

return
	
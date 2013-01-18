function vw = setMapWindow(vw, mapWindow)
%
% setMapWindow(vw,mapWindow)
%
% Sets mapWindow slider values
% ras, 01/07 -- deals w/ hidden views
% ras, 07/09 -- forces slider range to conform to the new window.
% Previously this required you to run UpdateMapWindow. This logic is not
% flexible enough for many analyses.
% jw: 08/2011 -- keep mapWinMin and mapWinMax ranges the same. if we extend
%                   one, then we extend the other.

if ~exist('vw', 'var') || isempty(vw),  vw = getCurView;  end

if checkfields(vw, 'ui', 'mapWinMin', 'sliderHandle')
	% ensure that the slider ranges allow for this map window
	sliderMin = get(vw.ui.mapWinMin.sliderHandle, 'Value');
	if sliderMin > min(mapWindow)
		set(vw.ui.mapWinMin.sliderHandle, 'Min', min(mapWindow));
        set(vw.ui.mapWinMax.sliderHandle, 'Min', min(mapWindow));
	end
	
	sliderMax = get(vw.ui.mapWinMax.sliderHandle, 'Value');
	if sliderMax < max(mapWindow)
		set(vw.ui.mapWinMax.sliderHandle, 'Max', max(mapWindow));
		set(vw.ui.mapWinMin.sliderHandle, 'Max', max(mapWindow));
	end

	% now set the slider values.
    setSlider(vw, vw.ui.mapWinMin, mapWindow(1)); 
    setSlider(vw, vw.ui.mapWinMax, mapWindow(2));
	
	
else    % hidden view
    vw.settings.mapWin = mapWindow;
    
end

return

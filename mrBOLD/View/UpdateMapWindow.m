function vw = UpdateMapWindow(vw)
%
% vw = UpdateMapWindow
%
% Sets the MapWindow sliders to correspond to current parameter map (if any
% is present).
%
% Ress, 6/03
% ras, 11/04 -- doesn't always throw out the prev. set points
% jw,  2/10  -- avoid error if map range is not defined (e.g., due to all map
%                               values being NaNs)
if isempty(vw.map), return, end

parMap = viewGet(vw,'map');

if isfield(vw, 'ui') && isfield(vw.ui,'windowHandle'); % test for non-hidden vw    
    % Find min/max and reset sliders
	minVal = inf;
	maxVal = -inf;
    for iScan = 1:viewGet(vw, 'numScans')
        if length(parMap) >= iScan && ~isempty(parMap{iScan})
            % the 'mrvMinmax' function ignores NaNs and Infs, this helps
            % prevent slider-setting errors
            rng = mrvMinmax( parMap{iScan}(:) );

            % deal with NaNs to avoid error when setting map window limits
            if isempty(rng), rng = [0 1]; end
            
            minVal = min(minVal, rng(1));
            maxVal = max(maxVal, rng(2));
        end
    end
    
    % deal w/ min/max being switched
    if (minVal>maxVal), tmp=maxVal; maxVal=minVal; minVal=tmp; end
    
    % if new min/max are outside current set pts, keep same set pts;
    % otherwise, reset points to minVal & maxVal
    setVals = viewGet(vw, 'mapWin');
    setMin = setVals(1); setMax = setVals(2);
%    if setMin < minVal
        setMin = minVal;
%    end 
%    if setMax > maxVal
        setMax = maxVal;
%    end

	vw = resetSlider(vw, vw.ui.mapWinMin, minVal, maxVal, setMin);
	vw = resetSlider(vw, vw.ui.mapWinMax, minVal, maxVal, setMax);
end

return
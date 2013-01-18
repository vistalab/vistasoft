function rx = rxShowROIs(rx, rxSlice)
%
% rx = rxShowROIs(rx, rxSlice);
%
% Show any ROIs loaded in a mrRx prescription. This includes showing it on
% the rx figure, the interpolated slice, and the reference slice (if any
% of these figures are open)
%
%
% ras, 08/2006.
if ~exist('rx', 'var') || isempty(rx)
    cfig = findobj('Tag',  'rxControlFig');
    rx = get(cfig, 'UserData');
end

if ~isfield(rx, 'rois') || isempty(rx.rois)
    % exit quietly
    return
end

prefs.method = 1;
prefs.lineWidth = 1;

if ishandle(rx.ui.rxAxes)
    % we'll need this info later...
    volSlice = get(rx.ui.volSlice.sliderHandle,'Value');
    volSlice = uint8(volSlice);
    ori = findSelectedButton(rx.ui.volOri);
end

%% MAIN LOOP
for R = rx.rois
    prefs.color = R.color;
    
    %% draw on interpolated and reference slices, if they're open
    if ishandle(rx.ui.interpAxes) || ishandle(rx.ui.refAxes)
        roiCoords = vol2rx(rx, R.volCoords, 1);
        
        inSlice = find(round(roiCoords(3,:))==rxSlice);
        
        if ishandle(rx.ui.interpFig)
            prefs.axesHandle = rx.ui.interpAxes;
            outline(roiCoords(:,inSlice), prefs);
        end
        if ishandle(rx.ui.refFig)
            prefs.axesHandle = rx.ui.refAxes;
            outline(roiCoords(:,inSlice), prefs);
        end
        if ishandle(rx.ui.compareFig)
            prefs.axesHandle = rx.ui.compareAxes;
            outline(roiCoords(:,inSlice), prefs);
        end
        
    end
    
    %% draw ROIs in prescription figure, if it's open
    if ishandle(rx.ui.rxAxes)
        % account for Radiological L/R flip, if needed
        h_flipLR = findobj('Tag', 'rxRadiologicalMenu');
        if isequal(get(h_flipLR, 'Checked'), 'on');
            R.volCoords(3,:) = rx.volDims(3) - R.volCoords(3,:);
        end
        
        % get 2D points in current rx slice within this ROI
        switch ori
            case 1, % axi
                pts = R.volCoords([2 3], round(R.volCoords(1,:))==volSlice);
            case 2, % cor
                pts = R.volCoords([1 3], round(R.volCoords(2,:))==volSlice);
            case 3, % sag
                pts = R.volCoords([1 2], round(R.volCoords(3,:))==volSlice);
        end
        
        % draw
        prefs.axesHandle = rx.ui.rxAxes;
        outline(pts, prefs);
    end
    
end

return

function rx = rxCenterOnROI(rx, n);
%
% rx = rxCenterOnROI(rx, [roiNum=last loaded ROI]);
%
% Center the open view windows for a mrRx session
% on the specified ROI. (If the 2nd arg is omitted,
% will center on the last roi in rx.rois).
%
% ras, 01/2007.
if notDefined('rx'), rx = get(findobj('Tag', 'rxControlFig'), 'UserData'); end

if ~isfield(rx, 'rois') | isempty(rx.rois)
    warning('No ROIs Loaded.')
    return
end

if notDefined('n'), n = length(rx.rois); end

% get center-of-gravity of the ROI
cog = round( mean(rx.rois(n).volCoords, 2) );

if ishandle(rx.ui.rxAxes)       % center on Rx figure
    ori = findSelectedButton(rx.ui.volOri);
    rxSetSlider(rx.ui.volSlice, cog(ori));
end

if ishandle(rx.ui.interpAxes) | ishandle(rx.ui.refAxes)
    % we'll need to xform the center-of-gravity into the Rx space
%     interpCog = round( vol2rx(rx, cog) );

    % empirically-needed changes to xform: not sure why this is
    % necessary...
    xform = rx.xform;
    xform([1 2],:) = xform([2 1],:);
    xform(:,[1 2]) = xform(:,[2 1]);
    interpCog = inv(xform) * [cog; 1];
        
    rxSetSlider(rx.ui.rxSlice, interpCog(3));        
end

rxRefresh(rx);

return
    

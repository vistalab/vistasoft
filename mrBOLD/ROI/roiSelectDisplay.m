function vw = roiSelectDisplay(vw,promptStr)
% Select a subset of the ROIS
%
%   vw = roiSelectDisplay(vw,promptStr)
%
% The selected ROIs are assigned to the variable vw.ui.showROIs
% They are positive if we show the whole ROI and negative if we show just
% the ROI outlines.
% The drawing mode is inherited from the current sign of ui.showROIs.  If
% that is zero, the mode is positive.
%
% Example:
%     tmp = roiSelectDisplay(vw,'Select subset of ROIs')
% 

if notDefined('vw'),        vw = getCurView;            end
if notDefined('promptStr'), promptStr = 'Select ROIs '; end

R = viewGet(vw,'rois');

if isempty(R), disp('No ROIs.'); return; end

% There should be an roiGet/Set routine to get the names
% -ras: maybe; but probably not for this poor, molested codebase.
% there's a nice functional roiGet/Set in mrVista2.
roiNames = {R.name};
[sList ok] = listdlg('PromptString', promptStr, ...
    'SelectionMode', 'multiple', ...
    'ListString', roiNames);

if ok
    % Set the display mode
    % (ras 01/07: now the rendering method is handled separately)
    vw.ui.showROIs = sList;
end


return;
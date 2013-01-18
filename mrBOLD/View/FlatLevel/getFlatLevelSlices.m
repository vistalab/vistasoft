function slices = getFlatLevelSlices(view);
% slices = getFlatLevelSlices(view);
%
% Parse the UI settings, and return the
% appropriate slices for display from 
% flat multi-level view.
%
% (Background: the anat, map, amp, co,
% and ph fields of the flat view are 
% all treated as images of size x by y by
% nSlices, where the slice order is:
% left across levels, right across levels,
% separate left levels, separate right levels.
% This ordering helps facilitate ROI specification,
% and leaves the multi-level view back-compatible
% with ROIs defined in the old view. The 
% slice therefore reflects a combination of
% what hemisphere is being examined, whether
% it's looking at separate levels or across levels,
% and if separate levels, which levels are being 
% looked at.)
%
% ras 09/04
ui = viewGet(view,'ui');

% which hemisphere
hemi = findSelectedButton(ui.sliceButtons);

% which view mode -- separate levels or avg across levels?
viewMode = findSelectedButton(ui.levelButtons);

% if viewing separate levels, which levels are selected?
if viewMode==2
    firstLevel = get(ui.level.sliderHandle,'Value');
    extraLevels = str2num(get(ui.level.numLevelEdit,'String'));
else
    firstLevel = 1; extraLevels = 0;
end

% figure out the slice nums:
if viewMode==1
	% if across levels, it's just the hemisphere number
    slices = hemi;
else
    % if separate levels, combine hemi with level info
    offset = 2 + (hemi-1)*view.numLevels(1);
    slices = offset + (firstLevel:firstLevel+extraLevels);
    slices = slices(slices <= 2+sum(view.numLevels));
end

return

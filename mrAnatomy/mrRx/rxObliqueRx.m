function rx = rxObliqueRx(rx);
%
% rx = rxObliqueRx(rx);
%
% Add an Rx positioned (for most alignment situations in KGS / Wandell
% Lab land) roughly perpindicular to the calcarine sulcus, 
% for aligning oblique inplanes to a volume anatomy using mrRx.
%
% ras 01/06.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

% % store the existing settings
% rx = rxStore(rx, 'Last Setting');

% ras 01/06:
% I find these rotations / flips cover the most common case,
% where the first slice is the most anterior, pretty well:
voxRatio = rx.rxVoxelSize ./ rx.volVoxelSize;
trans = rx.volDims/2 - rx.rxDims/2 + [60 0 0];
rot = deg2rad([90 63 90]);
scale = [1 -1 1];
newXform = affineBuild(trans, rot, scale, [0 0 0]);

% if there's an Rx Figure open, set it to sagittal view, which
% is easiest to prescribe off of:
if ishandle(rx.ui.volOri(1))
    selectButton(rx.ui.volOri, 3);
end

rx = rxSetXform(rx, newXform, 1);
rx = rxStore(rx, 'Oblique Rx');


return

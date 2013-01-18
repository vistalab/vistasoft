function rx = rxMidCorRx(rx);
%
% rx = rxMidCorRx(rx);
%
% Add a mid-coronal Rx for aligning coronal inplanes
% to a volume anatomy using mrRx.
%
% ras 08/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

% % store the existing settings
% rx = rxStore(rx,'Last Setting');

% I find these rotations / flips cover the most common case,
% where the first slice is the most anterior, pretty well;
% and allow the 'axial rotate' slider to do the intuitive thing,
% namely, a pitch rotation:
voxRatio = rx.rxVoxelSize ./ rx.volVoxelSize;
trans = rx.volDims/2 - (rx.rxDims/2 .* voxRatio);;
rot = deg2rad([-90 90 90]);
scale = [1 1 1];
newXform = affineBuild(trans, rot, scale, [0 0 0]);

% if there's an Rx Figure open, set it to axial view, which
% is easiest to prescribe off of:
if ishandle(rx.ui.volOri(1))
    selectButton(rx.ui.volOri, 1);
end
    
rx = rxSetXform(rx,newXform);
rx = rxStore(rx, 'Mid Coronal Rx');

return

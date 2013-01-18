function rx = rxMidSagRx(rx);
%
% rx = rxMidSagRx(rx);
%
% Add a mid-sagittal Rx for aligning coronal inplanes
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
trans = rx.volDims/2 - rx.rxDims/2;
rot = deg2rad([-90 90 90]);
scale = [1 1 1];
newXform = affineBuild(trans, rot, scale, [0 0 0]);

rx = rxSetXform(rx, newXform);
rx = rxStore(rx, 'Mid-Sag Rx');
    
return

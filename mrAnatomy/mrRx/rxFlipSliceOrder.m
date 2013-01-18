function rxFlipSliceOrder(rx,ori);
%
% rxFlipSliceOrder(rx,[ori]);
% 
% Adjust the xform for a prescription
% such that what was the first slice
% is now the last slice, and so on.
%
% This depends on the orientation in which
% you are viewing the slices, it seems:
% the manipulations that successfully flip when
% obliquely-prescribed slices can be readily viewed
% on axial slices is different than when it can be
% readily viewed on sag slices. I may be wrong, 
% but I empirically need different flips, rotations to
% get them to work. So, you can specify ori (1=axi,
% 2=cor, 3=sag) as the orientation on which you are
% (or could be) viewing the Rx, or else the code will
% check if the rx window is open, and use the setting
% there.
%
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('ori')
    if checkfields(rx,'ui','rxFig') & ishandle(rx.ui.rxFig)
        ori = findSelectedButton(rx.ui.volOri);
    else
        ori = 1;
    end
end

% break xform down into component translations,
% rotations, etc.:
[trans rot flip] = affineDecompose(rx.xform);
rot = rad2deg(rot);

switch ori
    case 1, % axial
        % to flip the order, I'm going
        % to set an S/I (or rows) flip,
        % and a 180 degree rotation to 
        % the coronal (about cols axis)
        % rotation param:
        flip(2) = -1*flip(2);

        % b/c of flip, reverse rotation directions
        rot = -1 .* rot; 

        % now rotate
        rot(1) = mod(360+rot(1),360) - 180; % rot from -180 -- 180
    case 2, % coronal
    case 3, % sagittal
        % to flip the order, I'm going
        % to set an A/P (or slices) flip,
        % and a 180 degree rotation to 
        % the axial (about rows axis)
        % rotation param:
        flip(3) = -1*flip(3);

        % b/c of flip, reverse rotation directions
        rot = -1 .* rot; 

        % now rotate
        rot(2) = mod(360+rot(2),360) - 180; % rot from -180 -- 180
end

% % also update translations to opposite side of brain
% trans = rx.volDims - trans;

% get a new xform matrix:
newXform = affineBuild(trans, deg2rad(rot), flip, [0 0 1]);

% set the rx, ui controls:
rx = rxSetXform(rx,newXform);

return

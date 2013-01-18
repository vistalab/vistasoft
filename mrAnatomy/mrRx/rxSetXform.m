function rx = rxSetXform(rx, xform, aboutCenter)
%
% rx = rxSetXform(rx, xform, [aboutCenter]);
%
% Sets the xform field of a mrRx struct,
% and also sets UI controls of the GUI
% to agree with this transform.
%
% The aboutCenter flag is an optional flag
% specifying whether the rotations in the
% new xform are intended to rotate about the
% center of prescription or not. (E.g., mrVista
% alignments rotate about the corner, b/c the 
% math is more straightforward). If 0 [default],
% this means that further adjustment is needed to 
% ensure the rotations act about the center, so the
% xform is adjusted to compensate (the mapping of 
% points is the same though).
%
% ras 03/05.
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end   

if notDefined('aboutCenter')
    aboutCenter = 0; 
end

if aboutCenter==0
    % we center the rx at 0,0,0 to rotate about the
	% center -- this compensatory translation ensures
	% that zero settings return an unchanged matrix.
	% Because of this, the UI settings reflect a diff't
	% set of rotations from that in the mrVista alignment.
	% Compute the modified xform (after a similar set of
	% changes in rxRefresh, it will return the original
	% mrVista xform matrix):
	shift = [eye(3) -rx.rxDims([2 1 3])'./2; 0 0 0 1];
	xform = shift*xform/shift;
end

% set prev xform field
rx.prevXform = rx.xform;

% set xform field
rx.xform = xform;

% set ui controls to agree w/ the xform
[trans rot flip] = affineDecompose(rx.xform);
rot = rad2deg(rot+pi) - 180;
if ishandle(rx.ui.controlFig)
    rxSetSlider(rx.ui.corTrans, trans(1));
    rxSetSlider(rx.ui.axiTrans, trans(2));
    rxSetSlider(rx.ui.sagTrans, trans(3));
    rxSetSlider(rx.ui.corRot, rot(1));
    rxSetSlider(rx.ui.axiRot, rot(2));
    rxSetSlider(rx.ui.sagRot, rot(3));
    set(rx.ui.corFlip, 'Value', (flip(1)<0));
    set(rx.ui.axiFlip, 'Value', (flip(2)<0));
    set(rx.ui.sagFlip, 'Value', (flip(3)<0));

    % set the control fig w/ the new rx:
    set(rx.ui.controlFig, 'UserData', rx);
    rxRefresh(rx, 0);
end

return

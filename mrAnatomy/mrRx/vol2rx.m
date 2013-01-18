function rxCoords = vol2rx(rx, volCoords, xyFlag);
%
% rxCoords = vol2rx(rx, volCoords, [xyFlag=0]);
%
% For mrRx:
%
% Given points in a volume, get equivalent 
% coordinates in the prescription/reference
% space, given the current xform matrix.
%
% Both rxCoords and volCoords are 3 x N matrices, where
% each column is the (y,x,z) coordinate of a point in that
% particular space (prescription or volume, respectively).
% Coords need not be integers.
%
% The xyFlag is an optional flag indicating whether the xform
% is supposed to flip the x/y directions. (more explanation as I 
% understand it myself -- this is mainly needed for mrVista ROIs).
% It flips the first two rows and columns of the xform before 
% transforming. Set this to 1 if you notice the xformed coords
% appear to be rotated sideways on a slice (a la mrVista ROIs).
%
% Some notes:
%
% * For loaded anatomical files, mrRx tries to get the
% dimensions as: (rows or y) = superior -> inferior, 
% (cols or x) = anterior -> posterior, (slices or z) ->
% left -> right. This is the same format as the vAnatomy.dat
% files, and appears as a series of sagittal images w/ the
% eyes pointing left. 
%
% * It can't always do this, though: e.g. for motion-correcting
% inplanes, the dims are the same as an inplane view, which
% depends on the prescription.
%
% ras 03/05.
% ras 09/07: added xyFlag; still not sure why this is needed for ROIs, but
% it works.
if ~exist('rx', 'var') | isempty(rx)
    rx = get(findobj('Tag','rxControlFig'), 'UserData');
end

if ~exist('xyFlag', 'var') | isempty(xyFlag)
	xyFlag = 0;
end

xform = rx.xform;

if xyFlag==1
	xform([1 2],:) = xform([2 1],:);
	xform(:,[1 2]) = xform(:,[2 1]);
end

nPoints = size(volCoords,2);
rxCoords = inv(xform) * [volCoords; ones(1,nPoints)];
rxCoords = rxCoords(1:3,:);

return
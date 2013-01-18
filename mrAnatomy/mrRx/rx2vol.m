function volCoords = rx2vol(rx,rxCoords);
%
% volCoords = rx2vol(rx,rxCoords);
%
% For mrRx:
%
% Given points in a prescription (or in the reference
% volume, which is usually the same dimensions), get
% equivalent coordinates in the volume space, given the
% current xform matrix.
%
% Both rxCoords and volCoords are 3 x N matrices, where
% each column is the (y,x,z) coordinate of a point in that
% particular space (prescription or volume, respectively).
% Coords need not be integers.
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
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

nPoints = size(rxCoords,2);
volCoords = rx.xform * [rxCoords; ones(1,nPoints)];
volCoords = volCoords(1:3,:);

return
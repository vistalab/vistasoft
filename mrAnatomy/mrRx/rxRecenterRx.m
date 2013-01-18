function rx = rxRecenterRx(rx,recenter3D);
%
% rx = rxRecenterRx(rx,[recenter3D]);
%
% Recenter a prescription using the mouse,
% on the Rx Figure.
%
% The clicked-on location will be the center
% of the prescription in the two dimensions 
% being displayed in the Rx Figure's image, but
% the third dimension will be ignored. E.g.,
% if you're looking at the prescription on axials,
% it will recenter along the sagittal and coronal,
% but not axial, dimensions. This can be overridden
% if the recenter3D argument is entered as 1 [default
% is 0, ignore 3rd dimension].
%
%
% ras 03/05.
% ras 01/06: think I fixed why it wasn't always working -- the mapping
% of necessary rotations for the xform matrix (which goes: 
%   coronal rotation, axial rotation, sagittal rotation
% ), and the orientation button order (which goes:
%   axial, coronal, sagittal
%   and which corresponds to the mrVista conventions) is weird. This
% seems to work, as long as you set 3D recenter to be the default.
% setting it to 0 is nice, if the rx is orthogonal to where you're viewing
% the volume, but weird if it's oblique w.r.t. the slice axis.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('recenter3D')
    recenter3D = 1;
end

if ~ishandle(rx.ui.rxFig)
    % exit quietly
    return
end

%%%%%params
slice = get(rx.ui.volSlice.sliderHandle,'Value');
ori = findSelectedButton(rx.ui.volOri);

pt = get(gca,'CurrentPoint');
x = pt(1,1); y = pt(1,2);

%%%%%figure out offset from current location
% center of current rx (vol coordinate system)
cen = rx2vol(rx,[rx.rxDims/2]')';

% desired location (vol coordinate system)
switch ori
    case 1, tgt = [y slice x]; % axial
    case 2, tgt = [slice y x]; % coronal
    case 3, tgt = [x y slice]; % sagittal
    otherwise, return; % not yet implemented
end

offset = tgt - cen;

if recenter3D ~= 1
    % ignore dimension orthogonal to view
    order = [2 1 3]; % weird mapping of orientation buttons -> trans axes
    offset(order(ori)) = 0; 
end

%%%%%update existing rx
[trans rot scale skew] = affineDecompose(rx.xform);
trans = trans + offset;
newXform = affineBuild(trans, rot, scale, skew);
rx = rxSetXform(rx, newXform);

return

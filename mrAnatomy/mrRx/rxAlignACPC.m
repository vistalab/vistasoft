function rx = rxAlignACPC(rx, pts);
%
% rx = rxAlignACPC(rx, [pts=use set points]);
%
% Rotate a volume to AC/PC space based on specified AC, PC, and
% mid-sag points.
%
% BACKGROUND: AC/PC space is a standard way of bringing different brains 
% into a comparable coordinate system without distorting or skewing the 
% brains. In this space, the anterior commissure (AC) is set at point
% (0, 0, 0), and the brain is rotated such that the posterior commissure
% (PC) in the same axial slice. Because this is a rigid-body rotation,
% without scaling, the (y) or coronal coordinate of the PC varies, but the
% x (sag) and z (axial) dimensions are defined as 0, as with the AC. 
% The rotation also usually uses a third point (mid-sagittal), in the same 
% coronal slice as the AC, but along the mid-sagittal line, to rotate
% the brain such that the plane which best separates cortical hemispheres 
% runs along (x,0,0). 
%
% This function allows the user to set the locations corresponding to the AC,
% PC, and mid-sagittal points. The function rxAlignACPC then sets the
% current alignment to bring the prescription into AC/PC space based on
% those points. 
%
% More information on AC/PC alignment is available at:
%	http://white.stanford.edu/newlm/index.php/Anatomical_Methods
%
%
% ras, 02/08/2008. The core of this code was adapted from 
% code in mrAnatAverageAcpcNifti.
cfig = findobj('Tag','rxControlFig');

if ~exist('rx', 'var') | isempty(rx),    rx = get(cfig,'UserData'); end

if notDefined('pts'),	pts = rxGetACPC(rx, 0);			end

if any(isnan(pts(:,1:2)))
	error('Can''t recenter -- some points not specified.')
end

% reorder dimensions: the code adapted from mrAnat*Acpc* assumes
% the first element in each point is the "X" (or left->right) coordinate,
% the second element is the "Y" or (pos->ant) coordinate, and the
% third element is the "Z" or (inf->sup) coordinate.
% For the mrRx conventions, the elements are:
% (1) sup->inf
% (2) ant->pos
% (3) left->right
pts(3,:) = rx.volDims(3) - pts(3,:);
pts(2,:) = rx.volDims(2) - pts(2,:);
pts = pts([3 2 1],:);

% grab each point to deal with separately
ac = pts(:,1)';
pc = pts(:,2)';
midsag = pts(:,3)';

	
% The first landmark should be the anterior commissure (AC)- our origin
origin = ac;

% Define the current image axes by re-centering on the origin (the AC)
imY = pc - origin;		imY = imY ./ norm(imY);
imZ = midsag - origin;	imZ = imZ ./ norm(imZ);

% x-axis (left-right) is the normal to [ac, pc, mid-sag] plane
imX = cross(imZ, imY);

% Make sure the vectors point right, superior, anterior
if(imX(1)<0) imX = -imX; end
if(imY(2)<0) imY = -imY; end
if(imZ(3)<0) imZ = -imZ; end

% Project the current image axes to the cannonical AC-PC axes. These
% are defined as X=[1,0,0], Y=[0,1,0], Z=[0,0,1], with the origin
% (0,0,0) at the AC. Note that the following are the projections
x = [0 1 imY(3)]; x = x./norm(x);
y = [1  0 imX(3)]; y = y./norm(y);
z = [0  -imY(1) 1]; z = z./norm(z);

% Define the 3 rotations using the projections. We have to set the sign
% of the rotation, depending on which side of the plane we came from.
rot(1) = sign(x(3)) * acos(dot(x,[0 1 0])); % rot about x-axis (pitch)
rot(2) = sign(y(3)) * acos(dot(y,[1 0 0])); % rot about y-axis (roll)
rot(3) = sign(z(2)) * acos(dot(z,[0 0 1])); % rot about z-axis (yaw)

scale = rx.volVoxelSize([3 2 1]);

% Affine build assumes that we need to translate before rotating. But,
% our rotations have been computed about the origin, so we'll pass a
% zero translation and set it ourselves (below).
rx2VolXform = affineBuild([0 0 0], rot, scale, [0 0 0]);
adjustment = inv(rx2VolXform);

% % Insert the translation.
% adjustment(1:3,4) = [origin + rx.rxVoxelSize / 2]';

newXform = adjustment * rx.xform;

% set this xform in the mrRx GUI
rx = rxSetXform(rx, newXform);

return



%% OLDER CODE (SIMPLER, BUT NOT ACCURATE)
% % the align code used in mrAnatAverageAcpcNifti is complex and not readily
% % understood (by me at least). I'm using a simpler approach here, which
% % should work: the (sag, cor, axi) positions of the AC, PC, and midsag
% % points, respectively should be:
% % AC:		(0, 0, 0)
% % PC:		(0, -r1, 0)
% % Midsag:	(0, 0, +r2)
% %
% % Where all positions are measured relative to the center of the
% % prescription, r1 is the magnitude of the distance between AC and PC, and 
% % r2 is the magnitude of the distance between AC and misag.
% %
% % Since we have all three points specified in the current prescription, and
% % know what they should be, we can solve for the best affine transform to
% % achieve this (as with rxFinePoints).
% r1 = sqrt( sum( (ac - pc) .^ 2 ) );
% r2 = sqrt( sum( (ac - midsag) .^ 2 ) );
% 
% targetCoords = [0 0 0; 0 -r1 0; 0 0 r2]';
% 
% %% get the optimal transform
% % NOTE: tbe final transform can be broken into two parts.
% % The first is the existing xform from the volume into rx space;
% % the second is an adjustment that rotates the rx space to be ac/pc
% % aligned. Final xform is adjustment * currXform
% 
% % solve for the optimal adjustment
% [adjustment, fiterr] = affineSolve(targetCoords, pts);
% 
% newXform = adjustment * rx.xform;


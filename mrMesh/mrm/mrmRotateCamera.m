function mrmRotateCamera(id, rotVec, zoom, frustum, host, origin)
% Rotate camera view on a mrMesh window. 
%
%  mrmRotateCamera(id, rotVec, [zoom], [frustum], [host], [origin])
%
% id:  mrMesh window id, stored in the mesh object usually
% host: Usually local host, also stored in the mesh object
% rotvec:  Rotation vector whose entries are either a string (one of ) or a
%          vector of angles (radians).
%          'front','back','left','right','bottom','top'
% origin:
% zoom:
% frustum:
%
%    viewVectors = {[pi -pi/2 0],[pi pi/2 0],[pi 0 0],[0 0 pi],[pi/2 -pi/2
%    0],[-pi/2 -pi/2 0]};
%
% Examples - See Debug routines F5
%   msh = dtiGet(dtiH,'mesh'); % If you have a mrDiffusion guidata in dtiH
%   mrmRotateCamera(msh.id,'front',1);
%
%  To get the rotations and zooms out, try this: 
%   p.actor=0; p.get_all=1; 
%   [id,stat,r] = mrMesh('localhost', 174, 'get', p);
%   zoom = diag(chol(r.rotation'*r.rotation))';
%   rotMat = r.rotation/diag(zoom);
%
% There may be slight rounding errors allowing the inputs to
% asin/atan go outside of the range (-1,1). May want to clip those.
% 
% rot(2) = asin(rotMat(1,3));
% if (abs(rot(2))-pi/2).^2 < 1e-9,
% 	rot(1) = 0;
% 	rot(3) = atan2(-rotMat(2,1), -rotMat(3,1)/rotMat(1,3));
% else
% 	c      = cos(rot(2));
% 	rot(1) = atan2(rotMat(2,3)/c, rotMat(3,3)/c);
% 	rot(3) = atan2(rotMat(1,2)/c, rotMat(1,1)/c);
% end
% rot(1) = -rot(1); % flipped OpenGL Y-axis.
% fprintf('rot=[%0.6f %0.6f %0.6f];\nzoom=[%0.3f %0.3f %0.3f];\nfrustum=[%0.6f %0.6f %0.6f %0.6f];\n',rot,zoom,r.frustum);
%
% Detailed programming confusions:
%
%   The 'zoom' here is probably not what you think it is. It is
% literally a 'zoom' lens on the camera. However, the apparent zooming of a
% scene that occurs during user interaction is actually a change in the
% field-of-view of the camera (frustum). The effects on the scene are
% similar, but not identical. If you want to get at the frustrum, look at
% r.frustrum (a 1x4 array). While I don't fully understand how these four
% numbers relate to the viewing frustum volume, by trial and error I've
% gleaned the following: 
% 1. you usually don't want to muck with the last two entries. I believe
% that they define the far-plane, which can affect what objects in the
% scene are seen. Playing with them produces some really weird effects.
% 2. The first entry doesn't seem to do anything, but it is by default set
% to be equal to the second.  
% 3. The second entry is what has the 'zoom' effect. 
%
% If you want to play with the frustum send in a 1x4 array and have fun. If
% you just want to have a zoom effect that uses the same mechanism as the
% user-interaction zooming, then pass a scalar for the frustum and we'll do
% something reasonable with it, like use it to only set the first two
% entries.
%
% Origin is a 1x3 vector.  Added this in so users can properly reconstruct
% the view a user had if the origin was changed (done by pushing middle
% mouse and moving about).
%
% HISTORY:
% 2003.10.20 RFD (bob@white.stanford.edu) wrote it.
% 2006.02.10 RFD Added comments about frustum/zoom and option to set
% frustum.
% 2010.06.30 RFB Added origin input arg

if(~exist('host','var') || isempty(host)), host = 'localhost'; end
if(~exist('zoom','var') || isempty(zoom)), zoom = 1; end

if(ischar(rotVec))
    viewList={'front','back','left','right','bottom','top'};
    viewVectors = {[pi -pi/2 0],[pi pi/2 0],[pi 0 0],[0 0 pi],[pi/2 -pi/2 0],[-pi/2 -pi/2 0]};
    ii = strmatch(lower(rotVec), viewList);
    if(isempty(ii))
        error(['Named cannonical view "' rotVec '" not recognized.']);
    end
    rotVec = viewVectors{ii};
end

v = rotVec;
Rx = [1 0 0 ; 0 cos(v(1)) -sin(v(1)); 0 sin(v(1)) cos(v(1))];
Ry = [cos(v(2)) 0 sin(v(2)); 0 1 0; -sin(v(2)) 0 cos(v(2))];
Rz = [cos(v(3)) -sin(v(3)) 0; sin(v(3)) cos(v(3)) 0; 0 0 1];

% We send a structure, p, to mrMesh.  In this case the structure contains
% the parameters needed to set the view.  The fields are actor, rotation,
% frustum and origin.  The zoom is folded into the rotation.
% When we understand what these are better, we will comment them in the
% header.
p.actor = 0; % The camera is always actor 0.
if(length(zoom)==3), p.rotation = Rx*Ry*Rz*(diag(zoom(:)));
else                 p.rotation = Rx*Ry*Rz*(eye(3)*zoom(1));
end

if(exist('frustum','var') && ~isempty(frustum))
    if(length(frustum)==1)
        g.actor = 0; g.get_frustum = 1;
        [id,stat,res] = mrMesh(host, id, 'get', g);
        % Not sure what all 4 numbers are in the Frustum, but we usually
        % only want to much with the first two, and we usually want them to
        % be equal.
        p.frustum = [frustum frustum res.frustum(3:4)];
    else
    	p.frustum = frustum;
    end
end
if (exist('origin', 'var') && ~isempty(origin)), p.origin = origin; end

[id,stat,res] = mrMesh(host, id, 'set', p);

return;

%%  Experiments with this code

% To make a movie:
ltr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

% Set the background color
p.color=[0,0,0,1];
%p.color=[.3,.3,.3,1];

host = 'localhost';
id = 174;
mrMesh(host, id, 'background', p);
%n = 61;
%rot = linspace(0, 2*pi, n);
%rot = rot(1:end-1);
rot = [-pi/4:pi/32:pi];
n = length(rot);
%pitch = linspace(.5*pi, 1.5*pi, n);
pitch = -pi/2.5;
zoom = 1;
movDir = '/tmp/mrmMovie';
mkdir('/tmp', 'mrmMovie');
clear M;
for(ii=1:length(pitch))
    for(jj=1:length(rot))
        mrmRotateCamera(id, [pitch(ii) 0 rot(jj)], zoom);
        f.filename = 'nosave';
        [id,stat,res] = mrMesh(host, id, 'screenshot', f);
        M((ii-1)*length(rot)+jj) = im2frame(permute(res.rgb, [2,1,3])./255);
        fname = sprintf('%c%0.2d.png', ltr(ii), jj);
        fname = fullfile(movDir, fname);
        %imwrite(permute(res.rgb,[2,1,3])./255, fname);
    end
end
%figure; movie(M,-3)
movie2avi(M,'/tmp/mrmMovie.avi');

% NOTES:
% From: http://www.makegames.com/3drotation/
%
% The method I just showed you is only one of several common ways to build a 
% rotation matrix. There are other ways to do it. Perhaps the simplest rotation 
% matrix is the one you get by rotating a view around one of the three coordinate 
% axes. This is frequently documented and proved elsewhere, so I will just list 
% the matrices here.

% Rx = [1 0 0 0; 0 cos(phi) -sin(phi) 0; 0 sin(phi) cos(phi) 0; 0 0 0 1];
% Ry = [cos(theta) 0 sin(theta) 0; 0 1 0 0; -sin(theta) 0 cos(theta) 0; 0 0 0 1];
% Rz = [cos(psi) -sin(psi) 0 0; sin(psi) cos(psi) 0 0; 0 0 1 0; 0 0 0 1];
% R = Rx*Ry*Rz;

% Where theta, phi, and psi are the rotations around the X, Y and Z 
% axes. Notice these are the rotation matrices for a left handed 
% system. To change them for a right handed system, just remember 
% the sine function is an odd function, so
%  sin(-theta) = -sin(theta)
% Change the signs of all the sine terms to change the handedness.

% There is one more way to build a matrix that I want to mention, 
% but I won't derive it here because I want to get back to talking 
% about the closed set of special orthogonal matrices. You can build 
% a rotation matrix to rotate about any arbitrary axis like this:
%
% R = [t*x^2+c    t*x*y-s*z  t*x*z+s*y 0; ...
%      t*x*y+s*z  t*y^2+c    t*y*z-s*x 0; ...
%      t*x*z-s*y  t*y*z+s*x  t*z^2+c   0; ...
%      0          0          0         1];
% 
% Where c=cos(theta), s=sin(theta), t=1-cos(theta)
% and (x,y,z) is a unit vector on the axis of rotation. This matrix 
% is presented in Graphics Gems (Glassner, Academic Press, 1990). I 
% worked out a derivation in this article. Use this matrix to rotate 
% objects about their center of gravity, or to rotate a foot around an 
% ankle or an ankle around a kneecap, for example. It less useful for 
% changing the point of view than the other rotation matrices. If you 
% want, you can verify that rotating around a coordinate axis is a 
% special case of this matrix. But I'll leave that to you. I'd rather 
% get on with the good stuff.
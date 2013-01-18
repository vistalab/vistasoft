function [rot,zoom,frustum,origin] = mrmGetRotation(id)
% Get rotation and zoom
%
%   [rot,zoom,frustum] = mrmGetRotation(id)
%

p.actor=0; p.get_all=1;
[id,stat,r] = mrMesh('localhost', id, 'get', p);
zoom = diag(chol(r.rotation'*r.rotation))';
rotMat = r.rotation/diag(zoom);
frustum = r.frustum;
origin = r.origin;
% Note- there may be slight rounding errors allowing the inputs to
% asin/atan go outside of the range (-1,1). May want to clip those.
rot(2) = asin(rotMat(1,3));
if (abs(rot(2))-pi/2).^2 < 1e-9,
    rot(1) = 0;
    rot(3) = atan2(-rotMat(2,1), -rotMat(3,1)/rotMat(1,3));
else
    c      = cos(rot(2));
    rot(1) = atan2(rotMat(2,3)/c, rotMat(3,3)/c);
    rot(3) = atan2(rotMat(1,2)/c, rotMat(1,1)/c);
end
rot(1) = -rot(1); % flipped OpenGL Y-axis.
%fprintf('rot=[%0.6f %0.6f %0.6f];\nzoom=[%0.3f %0.3f %0.3f];\nfrustum=[%0.6f %0.6f %0.6f %0.6f];\n',rot,zoom,r.frustum);

return
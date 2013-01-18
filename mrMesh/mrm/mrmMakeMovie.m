function mrmMakeMovie(id,rotBegin,rotEnd)
%
%
% Function to make a movie of brain rotating left to ventral view.  This
% should really be a more general function, but this is a start.
%
%   written by amr Jun 2010
%


if ~exist('id','var'), id = 500; end
if ~exist('rotBegin','var')
    mrmRotateCamera(id,'left')
    [rotBegin,zoom1] = mrmGetRotation(id);
end

if ~exist('rotEnd','var')
    mrmRotateCamera(id,'bottom')
    [rotEnd,zoom2] = mrmGetRotation(id);
end

%keyboard
% Set the background color
p.color=[0,0,0,1];
%p.color=[.3,.3,.3,1];

host = 'localhost';
%id = 174;
mrMesh(host, id, 'background', p);

% % rotate left to bottom
rotY = [rotBegin(2):-pi/128:rotEnd(2)];
rotZ = [rotBegin(3):pi/128:rotEnd(3)];
rotX = ones(1,length(rotY))*pi;

% rotate bottom to left
% rotY = [rotEnd(2):pi/64:rotBegin(2)];
% rotZ = [rotEnd(3):-pi/64:rotBegin(3)];
% rotX = ones(1,length(rotY))*pi;

n = length(rotX);
%pitch = linspace(.5*pi, 1.5*pi, n);
%pitch = -pi/2.5;
%zoom = 1;
movDir = '/biac3/wandell7/data/Words/Meshes/';
movFile = 'mrmRotateVentralToLeft.avi';

%mkdir('/tmp', 'mrmMovie');
clear M;
%for(ii=1:length(pitch))
f.filename = 'nosave';
for(ii=1:length(rotX))
    mrmRotateCamera(id, [rotX(ii) rotY(ii) rotZ(ii)], zoom1);

    [id,stat,res] = mrMesh(host, id, 'screenshot', f);
    M((1-1)*length(rotX)+ii) = im2frame(permute(res.rgb, [2,1,3])./255);

    %fname = sprintf('%c%0.2d.png', ltr(ii), jj);
    %fname = fullfile(movDir, fname);
    %imwrite(permute(res.rgb,[2,1,3])./255, fname);
end
%end
%figure; movie(M,-3)
movie2avi(M,fullfile(movDir,movFile)); %'/tmp/mrmMovieAllFrames.avi');

return






function [rot,zoom] = mrmGetRotation(id)
% Get rotation and zoom
p.actor=0; p.get_all=1; 
[id,stat,r] = mrMesh('localhost', id, 'get', p);
zoom = diag(chol(r.rotation'*r.rotation))';
rotMat = r.rotation/diag(zoom);
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
rot(3) = -rot(3);
fprintf('rot=[%0.6f %0.6f %0.6f];\nzoom=[%0.3f %0.3f %0.3f];\nfrustum=[%0.6f %0.6f %0.6f %0.6f];\n',rot,zoom,r.frustum);

return
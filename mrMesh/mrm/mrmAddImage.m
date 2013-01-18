function im = mrmAddImage(host, id, img, origin, rotation)
% Add image to mrMesh scene as an OpenGL texture.
% im = mrmAddImage(host, id, img, origin, rotation)
%
% Adds the grayscale image (0-1 range) to the mrMesh scene specified by the
% mrMesh host and window id. Returns the mrMesh image struct, including the
% actor of the added texture (in im.actor).
% 
% Example: 
% rot = [0 0 1; 0 1 0; 1 0 0];
% org = [0 0 0];
% im = mrmAddImage('localhost', 1000, img, org, rot)
%
% HISTORY:
% 2007.08.23 RFD: wrote it, based on code from dtiMrMeshAddImages.

% image size must be 2^n (openGL requirement)
% 
imSize = 2.^ceil(log2(size(img')));

im.class = 'image';
im.width = imSize(1); 
im.height = imSize(2);
im.tex_width = imSize(2);
im.tex_height = imSize(1);
% 1 is opaque. 0 is completely transparent.
im.transparency = 1;

[id,s,r] = mrMesh(host, id, 'add_actor', im);
im.actor = r.actor;
% Pad up to the new (2^n) image size
sz = size(img');
pos = floor((imSize-sz)./2)+1;
imData = zeros(imSize);
imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = img';
im.texture = repmat(imData(:)', 3,1);

im.rotation = rotation;
im.origin = origin;
[id,s,r] = mrMesh(host, id, 'set', im);

return;

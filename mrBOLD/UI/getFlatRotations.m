function [rotations,flipLR] = getFlatRotations(view)
%
%  [rotations,flipLR] = getFlatRotations(view)
%
% Gets rotation field from FLAT
% Returns a [2x1]  pair of rotations if sucessful.
% Returns [0 0] if no such field present.
% Also returns a pair of flags indicating whether a L/R flip happens.

if (~strcmp(view.viewType,'Flat'))
    error('getFlatRotation called for non-flat view');
end

if (~isfield(view,'rotateImageDegrees'))
    rotations=[0 0];
else
    rotations=view.rotateImageDegrees;
end

if (~isfield(view,'flipLR'))
    flipLR = [0 0]; % If this flag is set, coordinates are flipped L/R : The rotation matrix becomes -c s; s c
    return;
else
    flipLR = view.flipLR;
end

return

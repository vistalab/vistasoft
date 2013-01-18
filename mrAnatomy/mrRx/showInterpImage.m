function showInterpImage(vol,trans,rot,slice);
%
% showInterpImage(vol,trans,rot,slice);
%
% a test function for building up tools to coregister
% functional slices (for motion-correction, but the tools
% could be more general). This function takes a 3D volume
% vol, applies the specified translations and rotations
% (each 1 x 3 vectors -- see spm_matrix), and displays
% the selected interpolated slice, next to the original,
% un-interpolated slice.
%
% Centers volume at 0,0,0 before applying xform,
% so rotations are about the center of the volume.
% translations are in addition to this recentering.
%
% 02/05 ras.
if ieNotDefined('slice')
    slice = 1;
end

if ieNotDefined('trans')
    trans = ceil(size(vol)/2);
else 
    % add recentering to additional translation
    trans = trans + ceil(size(vol)/2);    
end

if ieNotDefined('rot')
    rot = [0 0 0];
end

% for speed / memory, might not want to 
% sample all coords in interp slice:
sampleSpacing = 1;

% build up coords for interp slice
xsz = size(vol,2);
ysz = size(vol,1);
zsz = size(vol,3);
xrng = [1:sampleSpacing:xsz] - ceil(xsz/2);
yrng = [1:sampleSpacing:ysz] - ceil(ysz/2);
[X Y Z] = meshgrid(yrng,xrng,slice-ceil(zsz/2));
coords = [X(:) Y(:) Z(:) ones(size(Z(:)))]';

% get the transformation matrix
P = [trans([2 1 3]) rot 1 1 1 0 0 0]; % params for xform
A = spm_matrix(P);

% get new coords for the interp slice
newCoords = A * coords;

% interpolate
origImg = vol(:,:,slice);
interpVals = myCinterp3(vol,[ysz xsz],zsz,newCoords(1:3,:)',max(origImg(:)));
interpImg = reshape(interpVals,[ysz xsz]);

% display
% figure('Color','w','Name',['Slice ' num2str(slice)]);
clf
subplot(2,1,1);
imshow(origImg,[min(origImg(:)) max(origImg(:))]);
title Original
subplot(2,1,2);
imshow(interpImg,[min(interpImg(:)) max(interpImg(:))]);
title Interpolated

return

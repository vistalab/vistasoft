function newFrame_img = mrSPM_rotateFrame(oldFrame_img, rotateMatrix, params)
% rotates the image
% FORMAT newFrame_img = mrSPM_rotateFrame(oldFrame_img, rotateMatrix, params)
% oldFrame_img - the image to rotate as a 3-D array.
% rotateMatrix - the parameters describing the rigid body rotation returned
%   by mrSPM_coregTwoFrames; 
%   a mapping from voxels in frameA_img to voxels in frameB_img
%   is attained by:  matB\spm_matrix(coregRotMatrix(:)')*matA
%
% params - a structure of additional parameters for rotating image:
%       mat - a 4x4 affine transformation matrix mapping from
%           voxel coordinates to real world coordinates
%       voxels - vector of (x,y,z) voxel sizes:
%           they can be computed as sqrt(sum(mat(1:3,1:3).^2));
% newFrame_img - the rotated image as a 3-D array.
%_______________________________________________________________________
% MA, 11/11/2004: needs SPM2 toolbox to run
    M  = inv(spm_matrix(rotateMatrix));
    matOld = params.mat;
    matNew = M * matOld;
    if isfield(params,'voxels')
        voxels = params.voxels;
    else
        voxels = sqrt(sum(matNew(1:3,1:3).^2));
    end;

    % not sure whether this is the right matrix to pass into mrAnatResliceSpm:
    Mrot = inv(matNew); 
%Mrot = inv(matOld); % temporary for testing mrAnatResliceSpm!!!

    % bb = [-90,90; -126,90; -72,108]';    %- default
	% define bounding box in image space
	% bb = [-size(oldFrame_img)/2; size(oldFrame_img)/2-1]; 
    % - not sure if this is correct; rather it should be:
% 	bb = [-size(oldFrame_img)/2+0.5; size(oldFrame_img)/2-0.5];
% 	% now convert to mm space
% 	%bb = matOld * [bb,[0;0]]';
%     bb = [diag(voxels) [0 0 0]'; [0 0 0 1]] * [bb,[0;0]]'; % this would work for negative elements
% 	bb = bb(1:3,:);
% 	bb = bb'; 
    
    bSplineParams = [7 7 7 0 0 0];

% This is how it should be for consistency with spm_coreg:                
bb = [1 1 1; size(oldFrame_img)];

% If you want to use spline interpolation order 7 comment out this line
% bSplineParams = [1 0; 1 0; 1 0];

Mrot = inv(matOld\matNew);
voxels = [1 1 1];

    [newFrame_img, trash] = mrAnatResliceSpm(oldFrame_img, Mrot, ...
        bb, voxels, bSplineParams, 0);
    newFrame_img(isnan(newFrame_img)) = 0;   %replace NaNs with 0s
    
return
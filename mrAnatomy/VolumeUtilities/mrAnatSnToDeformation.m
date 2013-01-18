function [deform,mat] = mrAnatSnToDeformation(sn, vox, bb)
%
% [deform,mat] = mrAnatSnToDeformation(sn, vox, bb)
%
% Generate deformation field given SPM2 spatial normalization params.
%
% Adapted from the function spm_write_defs in spm_sn2def.m (spm2/toolbox/Deformation/)
% The original code is copyright by John Ashburner.
% 
%

%[bb0,vox0] = bbvox_from_V(sn.VG);
[bb0,vox0] = bbvox_from_V(sn.VF);
if(~exist('vox','var') || isempty(vox)), vox = vox0; end;
if(~exist('bb','var') || isempty(bb)),  bb  = bb0;  end;
bb  = sort(bb);
vox = abs(vox);

if 1 %nargin>=3,

	if any(~isfinite(vox)), vox = vox0; end;
	if any(~isfinite(bb)),  bb  = bb0;  end;
	bb  = sort(bb);
	vox = abs(vox);

	% Adjust bounding box slightly - so it rounds to closest voxel.
	bb(:,1) = round(bb(:,1)/vox(1))*vox(1);
	bb(:,2) = round(bb(:,2)/vox(2))*vox(2);
	bb(:,3) = round(bb(:,3)/vox(3))*vox(3);
 
	M   = sn.VG(1).mat;
	vxg = sqrt(sum(M(1:3,1:3).^2));
	ogn = M\[0 0 0 1]';
	ogn = ogn(1:3)';
 
	% Convert range into range of voxels within template image
	x   = (bb(1,1):vox(1):bb(2,1))/vxg(1) + ogn(1);
	y   = (bb(1,2):vox(2):bb(2,2))/vxg(2) + ogn(2);
	z   = (bb(1,3):vox(3):bb(2,3))/vxg(3) + ogn(3);
 
	og  = -vxg.*ogn;
	of  = -vox.*(round(-bb(1,:)./vox)+1);
	M1  = [vxg(1) 0 0 og(1) ; 0 vxg(2) 0 og(2) ; 0 0 vxg(3) og(3) ; 0 0 0 1];
	M2  = [vox(1) 0 0 of(1) ; 0 vox(2) 0 of(2) ; 0 0 vox(3) of(3) ; 0 0 0 1];
	mat = sn.VG.mat*inv(M1)*M2; 
	%dim = [length(x) length(y) length(z)];
else
	dim    = sn.VG.dim(1:3);
	x      = 1:dim(1);
	y      = 1:dim(2);
	z      = 1:dim(3);
	mat    = sn.VG.mat;
end;

%[pth,nm,xt,vr]  = fileparts(deblank(sn.VF.fname));
%VX = struct('fname',fullfile(pth,['y1_' nm '.img']),  'dim',[dim 16], ...
%	'mat',mat,  'pinfo',[1 0 0]',  'descrip','Deformation field - X');
%VY = struct('fname',fullfile(pth,['y2_' nm '.img']),  'dim',[dim 16], ...
%	'mat',mat,  'pinfo',[1 0 0]',  'descrip','Deformation field - Y');
%VZ = struct('fname',fullfile(pth,['y3_' nm '.img']),  'dim',[dim 16], ...
%	'mat',mat,  'pinfo',[1 0 0]',  'descrip','Deformation field - Z');

%VX = struct('fname',fullfile(pth,['y_' nm '.img']),  'dim',[dim 16], ...
%        'mat',mat,  'pinfo',[1 0 0]',  'descrip','Deformation field', 'n',1);
%VY = VX; VY.n = 2;
%VZ = VX; VZ.n = 3;

%X = x'*ones(1,dim(2));
%Y = ones(dim(1),1)*y;
[X,Y] = ndgrid(x,y);

st = size(sn.Tr);

if (prod(st) == 0),
	affine_only = 1;
	basX = 0; tx = 0;
	By = 0; ty = 0;
	Bz = 0; tz = 0;
else
	affine_only = 0;
	Bx = spm_dctmtx(sn.VG(1).dim(1),st(1),x-1);
	By = spm_dctmtx(sn.VG(1).dim(2),st(2),y-1);
	Bz = spm_dctmtx(sn.VG(1).dim(3),st(3),z-1); 
end,

deform = zeros([length(x) length(y) length(z) 3],'single');
if (~affine_only)
    coefX = reshape(sn.Tr(:,:,:,1),st(1)*st(2),st(3));
    coefY = reshape(sn.Tr(:,:,:,2),st(1)*st(2),st(3));
    coefZ = reshape(sn.Tr(:,:,:,3),st(1)*st(2),st(3));
end
Mult = sn.VF.mat*sn.Affine;

% Cycle over planes
%-------------------------------------------------------------------------
for j=1:length(z)

    % Nonlinear deformations
    %---------------------------------------------------------------------
    if (~affine_only)
        % 2D transforms for each plane
        tx = reshape( coefX * Bz(j,:)', st(1), st(2) );
        ty = reshape( coefY * Bz(j,:)', st(1), st(2) );
        tz = reshape( coefZ * Bz(j,:)', st(1), st(2) );

        X1 = X    + Bx*tx*By';
        Y1 = Y    + Bx*ty*By';
        Z1 = z(j) + Bx*tz*By';

        deform(:,:,j,1) = Mult(1,1)*X1 + Mult(1,2)*Y1 + Mult(1,3)*Z1 + Mult(1,4);
        deform(:,:,j,2) = Mult(2,1)*X1 + Mult(2,2)*Y1 + Mult(2,3)*Z1 + Mult(2,4);
        deform(:,:,j,3) = Mult(3,1)*X1 + Mult(3,2)*Y1 + Mult(3,3)*Z1 + Mult(3,4);
    else
        deform(:,:,j,1) = Mult(1,1)*X + Mult(1,2)*Y + (Mult(1,3)*z(j) + Mult(1,4));
        deform(:,:,j,2) = Mult(2,1)*X + Mult(2,2)*Y + (Mult(2,3)*z(j) + Mult(2,4));
        deform(:,:,j,3) = Mult(3,1)*X + Mult(3,2)*Y + (Mult(3,3)*z(j) + Mult(3,4));
    end
end
return


%_______________________________________________________________________
function [bb,vx] = bbvox_from_V(V)
vx = sqrt(sum(V.mat(1:3,1:3).^2));
o  = V.mat\[0 0 0 1]';
o  = o(1:3)';
bb = [-vx.*(o-1) ; vx.*(V.dim(1:3)-o)];
return;

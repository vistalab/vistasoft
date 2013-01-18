function [XYZ] = mrAnatGetImageCoordsFromSn(sn, XYZ, voxelSpaceFlag, nonlinearFlag)
%
% [oXYZ] = mrAnatGetImageCoordsFromSn(sn, XYZ, [voxelSpaceFlag=false], [nonlinearFlag=true])
% 
% Transform standard coordinates (eg, MNI) with sn3d or sn parameters to
% recover the image-space coordinates. 
%
% Note that the returned coords are in mm from the origin. This is useful
% because we often want to get actual image coords for an image that is
% different from the one used to normalize (eg. normalize using T1, but get
% coords for an EPI). To convert the returned coords to actual image
% indices, do this:
%
%   imIndices = inv(im.mat)*[XYZ; 1]
%
% where im.mat is the xform to physical space (eg. in mm; centered on ac).
% If you are getting the image coords for the same exact image that was
% used to do the normalization, you can use:
%
%   imIndices = inv(sn.VF.mat)*[XYZ; 1]
%
% Or, just set 'voxelSpaceFlag' to true.
%
% HISTORY:
% 2003.12.09 RFD Copied code written by Sue Whitfield. Modified slightly to
% suit our purposes.
% 2005.01.12 RFD: added conditional so we can do SPM2 style sn3d's. We
% still suppport the SPM99 sn3d's. (Again, with help from Sue Whitfield's
% code.)
% 2005.06.16 RFD: renamed from dtiGetImageCoordsFromSn3d and moved to Anatomy.

if nargin < 2
  error('Not enough arguments');
end
if(~exist('voxelSpaceFlag','var') || isempty(voxelSpaceFlag))
    voxelSpaceFlag = false;
end
if(~exist('nonlinearFlag','var') || isempty(nonlinearFlag))
    nonlinearFlag = true;
end
 
tmp = find(size(XYZ)==3 | size(XYZ)==4); 
if isempty(tmp)
  % in fact can be 4 by N N by 4, to allow (fourth row = 1) format
  error('XYZ must by 3 by N, or N by 3')
elseif tmp==2
  XYZ = XYZ';
end

% from mm space to voxel space.
[x y z] = deal(XYZ(1,:),XYZ(2,:),XYZ(3,:));
if(isfield(sn, 'MG'))
    % spm99-style deformation
    Mult = inv(sn.MG);
    [x,y,z] = mmult(x, y, z, Mult);
    if(voxelSpaceFlag)
        Mult = sn.VF.mat\sn.MF*sn.Affine;
    else
        Mult = sn.MF*sn.Affine;
    end
    if (prod(sn.Dims(2,:)) == 0 || ~nonlinearFlag), % no nonlinear components in sn file
        [x,y,z] = mmult(x, y, z, Mult);
    else % nonlinear components
        % first apply nonlinear, then affine
        [x,y,z] = build_transform(sn.Transform,[sn.Dims(2,:); sn.Dims(1,:)], x, y, z);
        [x,y,z] = mmult(x, y, z, Mult);
    end
else
    % spm2-style deformation
%     % Code derived from spm2:
%     if (isempty(sn.Tr) | ~nonlinearFlag), % no nonlinear components in sn file
%         [X3,Y3,Z3]  = mmult(x,y,z, sn.VG.mat\sn.VF.mat*sn.Affine);
%     else % nonlinear components
%         % first apply nonlinear, then affine
%         BX = spm_dctmtx(sn.VG(1).dim(1),size(sn.Tr,1),x-1);
%         BY = spm_dctmtx(sn.VG(1).dim(2),size(sn.Tr,2),y-1);
%         BZ = spm_dctmtx(sn.VG(1).dim(3),size(sn.Tr,3),z-1);
%         for j=1:length(z),   % Cycle over planes
% 		    tx = get_2Dtrans(sn.Tr(:,:,:,1),BZ,j);
% 		    ty = get_2Dtrans(sn.Tr(:,:,:,2),BZ,j);
% 		    tz = get_2Dtrans(sn.Tr(:,:,:,3),BZ,j);
% 		    X1 = x    + BX*tx*BY';
% 		    Y1 = y    + BX*ty*BY';
% 		    Z1 = z(j) + BX*tz*BY';
% 		    [X3(j),Y3(j),Z3(j)]  = mmult(X1,Y1,Z1, sn.VG.mat\sn.VF.mat*sn.Affine);
%         end
%     end
    % Code from Sue and Paul. I think it's equivalent to the spm2 code, but
    % a little more efficient.
    Mult = inv(sn.VG.mat);  %  was inv(MG) in SPM99
    [x,y,z] = mmult(x,y,z,Mult);
    if(voxelSpaceFlag)
        Mult = sn.Affine;
    else
        Mult = sn.VF.mat*sn.Affine;
    end
    if (isempty(sn.Tr) || ~nonlinearFlag), % no nonlinear components in sn.mat file
        [x,y,z]  = mmult(x, y, z, Mult);
    else % nonlinear components
        % first apply nonlinear, then affine
        %[X2,Y2,Z2] = build_transform(Transform,[Dims(2,:); Dims(1,:)],X,Y,Z);
        %   SPM2 translation:  Transform->Tr, 
        %                      Dims(2,:)->size(Tr),
        %                      Dims(1,:)->VG.dim
        dim = sn.VG.dim;
        if(length(dim==3)) dim(4) = 0; end
        [x,y,z] = build_transform2(sn.Tr, [size(sn.Tr); dim], x, y, z);
        [x,y,z]  = mmult(x, y, z, Mult);
    end
end
XYZ = [x;y;z];
return;

%_______________________________________________________________________
%_______________________________________________________________________
function [TX,TY,TZ] = build_transform(T,dim,TX,TY,TZ)
T = reshape(T,[dim(1,:) 3]);
BX = basis_funk(TX,dim(2,1),dim(1,1));
BY = basis_funk(TY,dim(2,2),dim(1,2));
BZ = basis_funk(TZ,dim(2,3),dim(1,3));
for i3=1:dim(1,3),
	for i2=1:dim(1,2),
		B2 = BZ(:,:,i3).*BY(:,:,i2);
		for i1=1:dim(1,1),
			B  = B2.*BX(:,:,i1);
			TX = TX + T(i1,i2,i3,1)*B;
			TY = TY + T(i1,i2,i3,2)*B;
			TZ = TZ + T(i1,i2,i3,3)*B;
		end;
	end;
end;
return;
%_______________________________________________________________________
%_______________________________________________________________________
function [TX,TY,TZ] = build_transform2(T,dim,TX,TY,TZ)
% Note dim is size 2x4 for this SPM2 version, not 2x3 as in SPM99.
% No reshape needed. T is a 4D array.  was T = reshape(T,[dim(1,:) 3]);
BX = basis_funk(TX,dim(2,1),dim(1,1)); 
BY = basis_funk(TY,dim(2,2),dim(1,2));
BZ = basis_funk(TZ,dim(2,3),dim(1,3));
for i3=1:dim(1,3),
	for i2=1:dim(1,2),
		B2 = BZ(:,:,i3).*BY(:,:,i2);
		for i1=1:dim(1,1),
			B  = B2.*BX(:,:,i1);
			TX = TX + T(i1,i2,i3,1)*B;
			TY = TY + T(i1,i2,i3,2)*B;
			TZ = TZ + T(i1,i2,i3,3)*B;
		end;
	end;
end;
return;

%_______________________________________________________________________
function B = basis_funk(X,N,kk)
B = zeros([size(X) kk]);
B(:,:,1) = ones(size(X))/sqrt(N);
for k=2:kk,
    B(:,:,k) = sqrt(2/N)*cos((X-0.5)*(pi*(k-1)/N));
end;
return;

%_______________________________________________________________________
function T2 = get_2Dtrans(T3,B,j)
d   = [size(T3) 1 1 1];
tmp = reshape(T3,d(1)*d(2),d(3));
T2  = reshape(tmp*B(j,:)',d(1),d(2));
return;

%_______________________________________________________________________
function [X2,Y2,Z2] = mmult(X1,Y1,Z1,Mult);
if length(Z1) == 1,
	X2= Mult(1,1)*X1 + Mult(1,2)*Y1 + (Mult(1,3)*Z1 + Mult(1,4));
	Y2= Mult(2,1)*X1 + Mult(2,2)*Y1 + (Mult(2,3)*Z1 + Mult(2,4));
	Z2= Mult(3,1)*X1 + Mult(3,2)*Y1 + (Mult(3,3)*Z1 + Mult(3,4));
else,
	X2= Mult(1,1)*X1 + Mult(1,2)*Y1 + Mult(1,3)*Z1 + Mult(1,4);
	Y2= Mult(2,1)*X1 + Mult(2,2)*Y1 + Mult(2,3)*Z1 + Mult(2,4);
	Z2= Mult(3,1)*X1 + Mult(3,2)*Y1 + Mult(3,3)*Z1 + Mult(3,4);
end;
return;


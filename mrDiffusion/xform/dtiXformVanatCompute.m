function [xformVAnatToAcpc] = dtiXformVanatCompute(dtiT1, dtiT1ToAcpcXform, vAnatomy, vAnatMm, vAnatTal, scaleFlag)
%
% [xformVAnatToAcpc] = dtiXformVanatCompute(dtiT1, dtiT1ToAcpcXform, vAnatomy, vAnatMm, [vAnatTal], [scaleFlag=false])
%
% Computes the affine transform that will convert coordinates from the DTI
% ac-pc space to the vAnatomy space. Ie.
%   xform * [vAnatCoords 1]' = dtiImgCoords
%   inv(xform) * [dtiImgCoords 1]' = vAnatCoords
%
%
% HISTORY:
% 2004.04.30 RFD (bob@white.stanford.edu) wrote it.
% 2006.08.11 RFD: cleaned up a bit and changed calling
% convention. vAnatTal is now optional. A reasonable guess is used
% if it isn't passed. One more thing- the output xform is
% completely different! It now does something much more logical- it
% converts vAnatomy coords to acpc coords.

if(~exist('vAnatTal','var')), vAnatTal = []; end
if(~exist('scaleFlag','var')||isempty(scaleFlag)), scaleFlag = false; end

disp('Coregistering (using SPM tools)...');
%figure(999); hist(t1.cannonical_img(:),255); [clip,y] = ginput(2);
dtiT1 = double(dtiT1);
clip = [0,max(dtiT1(:))];
VG.uint8 = uint8(round((dtiT1-min(clip))*(255/(max(clip)-min(clip)))));
VG.mat = dtiT1ToAcpcXform;
%[imgSlice,x,y,z] = dtiGetSlice(VG.mat, double(VG.uint8), 3, 0);
%figure; imagesc(imgSlice); axis image xy; colormap gray;
%VG.mat = diag([sqrt(sum(dtiAcpcXform(1:3,1:3).^2)) 1]);
%figure(999); hist(b0.cannonical_img(:),255); [x,y] = ginput(2);

VF.uint8 = uint8(round(vAnatomy));
if(~isempty(vAnatTal))
  % GET XFORM FROM TAL FILE
  % We want a transform that will go into ac-pc space (ie.
  % Talairach, but without any scaling). We can compute that by
  % adjusting the scale factors in the talairach transform.
  swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
  vAnatAcpcXform = vAnatTal.vol2Tal.transRot'*swapXY;
  [trans,rot,scale,skew] = affineDecompose(vAnatAcpcXform);
  % We also have to rescale the translations.
  scaleDiff = vAnatMm./scale;
  trans = trans.*abs(scaleDiff);
  scale = vAnatMm.*sign(scale);
  vAnatAcpcXform = affineBuild(trans,rot,scale,skew);
  VF.mat = vAnatAcpcXform;
  %VF.mat = diag([vAnatMm 1]);
else
  % Guess a reasonable vAnatomy xform
  origin = size(VF.uint8)./2;
  % Gleaned from trial and error:
  VF.mat = [fliplr(diag(vAnatMm([3 2 1]).*[1 -1 -1])), -origin([3 2 1])'.*[1 -1 -1]' ; [0 0 0 1]];
  %VF.mat = affineBuild([0 0 0],[0 0 pi],[1 1 1])*VF.mat;
end

f.cost_fun = 'nmi';
f.sep = [4 2];
f.fwhm = [7 7];
f.params = [0 0 0 0 0 0];
if(scaleFlag) f.params(7:9) = [1 1 1]; end
rotTrans = spm_coreg(VG,VF,f);
xformVAnatToAcpc = spm_matrix(rotTrans(end,:));
xformVAnatToAcpc = xformVAnatToAcpc\VF.mat;
%xformVAnatToAcpc = xform*VG.mat\VF.mat;
%xform = inv(VF.mat\spm_matrix(rotTrans(:)'));

return;



[f,p] = uigetfile('*.dat','Select vAnatomy file...');
[vAnatomy,vAnatMm] = readVolAnat(fullfile(p,f));
h = guidata(gcf);
dtiT1 = h.bg(4).img;
dtiT1ToAcpcXform = dtiGet(h,'t1toacpcxform');
xformVAnatToAcpc = dtiXformVanatCompute(dtiT1, dtiT1ToAcpcXform, vAnatomy, vAnatMm);
h.xformVAnatToAcpc = xformVAnatToAcpc;
guidata(gcf, h);


figure; imagesc(dtiGetSlice(dtiT1ToAcpcXform,dtiT1,3,0)); axis equal tight
figure; imagesc(dtiGetSlice(xformVAnatToAcpc,vAnatomy,3,0)); axis equal tight

figure; imagesc(dtiGetSlice(VF.mat,vAnatomy,1,0)); axis equal tight

[dti,x,y,z] = dtiGetSlice(diag([sqrt(sum(dtiAcpcXform(1:3,1:3).^2)) 1]), dtiT1, 3, 20, 0);
figure; imagesc(dti); axis equal tight
[vanat,x2,y2,z2] = dtiGetSlice(inv(xform), vAnatomy, 3, 20, 0);
figure; imagesc(vanat); axis equal tight

figure; imagesc(vAnatomy(:,:,60)); axis equal tight
[dti,x,y,z] = dtiGetSlice(xform, dtiT1, 3, 60, 0);
figure; imagesc(dti); axis equal tight

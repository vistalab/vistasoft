function [xformSrcToDst,xformSrc] = mrAnatRegister(srcIm, dstIm, xform, estParams, affineFlag)
%
% [xformDstToSrc,xformDst] = mrAnatRegister(srcIm, dstIm, [xform=eye(4)], [estParams=spm_defaults], [affineFlag=false])
%
% Thin wrapper to SPM's spm_coreg, a mutual info image
% coregistration algorithm.
%
% Example:
% xform =  mrAnatRegister(srcIm,targetIm);
% bb = [1 1 1; size(targetIm)];
% newSrcIm =  mrAnatResliceSpm(srcIm, xform, bb, [1 1 1]);
%
% HISTORY:
% ??? RFD: wrote it (shamefully without any help text).
% 2007.01.04 RFD: added some help text and fixed the spm_defaults
% thing to make it compatible with spm5.

if(~exist('xform','var')||isempty(xform))
  xform = eye(4);%[eye(3), [size(dstIm)/2]'; 0 0 0 1];
end
if(~exist('estParams','var')||isempty(estParams))
  spm_defaults; global defaults;
  estParams = defaults.coreg.estimate;
end
[t,r,s,k] = affineDecompose(xform);
if(exist('affineFlag','var')&&~isempty(affineFlag)&&affineFlag)
    % Do full affine fit (12-params)
    estParams.params = [t r s k];
else
    % Rigid-body (6-params)
    estParams.params = [t r];
end

if(isstruct(srcIm))
    VF.uint8 = srcIm.data;
    VF.mat = srcIm.qto_xyz;
else
    VF.uint8 = srcIm;
    VF.mat = [eye(3), -[size(srcIm)/2]'; 0 0 0 1];
end
if(~strcmp(class(VF.uint8),'uint8'))
  VF.uint8 = uint8(mrAnatHistogramClip(double(VF.uint8), 0.4, 0.99)*255+0.5);
end

if(isstruct(dstIm))
    VG.uint8 = dstIm.data;
    VG.mat = dstIm.qto_xyz;
else
    VG.uint8 = dstIm;
    VG.mat = [eye(3), -[size(dstIm)/2]'; 0 0 0 1];
end
if(~strcmp(class(VG.uint8),'uint8'))
  VG.uint8 = uint8(mrAnatHistogramClip(double(VG.uint8), 0.4, 0.99)*255+0.5);
end

xformParams = spm_coreg(VG,VF,estParams);
xformSrc = inv(VF.mat)*spm_matrix(xformParams(end,:));
xformSrcToDst = xformSrc*VG.mat;

return;

% Test code:
[dstIm,dstMm,dstHdr] = loadAnalyze('ah05_t1anat_avg_9');
[f,p] = uigetfile('*.img','Select the source image...');
[srcIm,srcMm,srcHdr] = loadAnalyze(fullfile(p,f));

%xform = mrAnatRegister(srcIm, dstIm);
%srcIm2 = mrAnatResliceSpm(srcIm, xform);

% Alternative code:
spm_defaults;
Vref.uint8 = uint8(mrAnatHistogramClip(dstIm, 0.4, 0.99)*255+0.5);
Vref.mat = dstHdr.mat;
Vin.uint8 = uint8(mrAnatHistogramClip(srcIm, 0.4, 0.99)*255+0.5);
Vin.mat = srcHdr.mat;
xformParams = spm_coreg(Vref,Vin,defaults.coreg.estimate);
% Top map VG voxels to VF voxels:
%xform = VF.mat\spm_matrix(xformParams)*VG.mat;
xform = inv(Vin.mat)*spm_matrix(xformParams);

%bb = [-size(dstIm)/2; size(dstIm)/2-1];
%bb = Vref.mat*[bb,[0;0]]';
%bb = bb(1:3,:)';
% THis is the original bounding box used for the reference image (see
% mrAnatAverageAcpcAnalyze). We should be able to recover it from the image
% header, but the origin isn't set properly.
bb = [-90,90; -126,90; -72,108]';
[srcIm2,srcIm2mat] = mrAnatResliceSpm(srcIm, xform, bb, dstMm);
srcIm2(srcIm2<0) = 0;
newOrigin = inv(srcIm2mat)*[0 0 0 1]'; newOrigin = newOrigin(1:3)'-dstMm/2;
figure;imagesc(makeMontage(srcIm2));axis image;colormap gray;
figure;imagesc(makeMontage(dstIm));axis image;colormap gray;

[junk,outName] = fileparts(f); outName = fullfile(p,[outName '_aligned']);
saveAnalyze(int16(srcIm2+0.5),outName, dstMm, srcHdr.descrip, newOrigin);




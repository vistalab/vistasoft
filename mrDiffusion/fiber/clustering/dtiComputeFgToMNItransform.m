function [sn, def]=dtiComputeFgToMNItransform(dt6File)

%Returns two matrices; "sn" that takes MNI space into subject DTI space,
%and "def" that can be applied to a FG to warp the fibers into standard
%space: fg_sn = dtiXformFiberCoords(fg, def);

%Input: e.g., dt6File =
%'/biac3/wandell4/data/reading_longitude/dti_y3/vr060802/dti06/dt6.mat';

%ER 04/2008
%Basically parts of  RD's code in dtiFindMoriTracts     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%1. Compute normalization
% Load a dt6 file
dt = dtiLoadDt6(dt6File);

% Spatially normalize it with the MNI (ICBM) template
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
template = fullfile(tdir,'MNI_EPI.nii.gz');
[sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(dt.b0, dt.xformToAcpc, template);
%SN is the transformation matrix?
%

% check the normalization // this block is optional
mm = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
bb = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim]);
b0 = mrAnatHistogramClip(double(dt.b0),0.3,0.99);
b0_sn = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0], 0);
tedge = bwperim(Vtemplate.dat>50&Vtemplate.dat<170);
im = uint8(round(b0_sn*255)); 
im(tedge) = 255;
showMontage(im);


%Compute inverse tranform for warping the fibers in 'fg' to the standard space:
[def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(sn);
def.inMat = inv(sn.VF.mat);
def.outMat = [];

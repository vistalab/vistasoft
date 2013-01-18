function [sn, def, checkIm]=dtiComputeDtToMNItransform(dt)
%
% [sn, def, checkIm]=dtiComputeDtToMNItransform(dt)
% 
% Returns two xform structs; "sn" that takes MNI space into subject DTI space,
% and "def" that can be applied to a FG to warp the fibers into standard
% space: fg_sn = dtiXformFiberCoords(fg, def);
%
% lut is a quantized, compact version of def that is useful for quick
% coordinate look-ups.
%
% checkIm is an image that is useful for checking the accuracy of the
% alignment. E.g., showMontage(checkIm).
%
% Input is either a dt struct (as produced by dtiLoadDt6) or a filename
% pointing to a dt6 file. E.g.:
% dt = '/biac3/wandell4/data/reading_longitude/dti_y3/vr060802/dti06/dt6.mat';
% [sn,def] = dtiComputeDtToMNItransform(dt);
%
% ER 04/2008
% Basically parts of  RD's code in dtiFindMoriTracts   
% 2008.08.19 RFD: added checkIm as output and changed def to simply use the
% coord lut returned by mrAnatComputeSpmSpatialNorm. This is quantized to
% 1mm, but is more than accurate enough for volumetric spatial normalization.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%1. Compute normalization
if(ischar(dt))
    % Then assume dt is a filename- load the dt6 file
    dt = dtiLoadDt6(dt);
end

% Spatially normalize it with the MNI (ICBM) template
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
template = fullfile(tdir,'MNI_EPI.nii.gz');
[sn, Vtemplate, def] = mrAnatComputeSpmSpatialNorm(dt.b0, dt.xformToAcpc, template);

% if(nargout>1)
% %Compute inverse tranform for warping the fibers in 'fg' to the standard space:
% [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(sn);
% def.inMat = inv(sn.VF.mat);
% def.outMat = [];
% end

if(nargout>2)
    % check the normalization // this block is optional
    mm = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
    bb = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim]);
    b0 = mrAnatHistogramClip(double(dt.b0),0.3,0.99);
    b0_sn = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0], 0);
    tedge = bwperim(Vtemplate.dat>50&Vtemplate.dat<170);
    checkIm = uint8(round(b0_sn*255));
    checkIm(tedge) = 255;
end

return;


% To run this on a bunch of subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_y1234/';
inDir = 'dti06';

d = dir(fullfile(bd,'*0*'));
n = 0;
for(ii=1:length(d))
  tmp = fullfile(bd,d(ii).name,inDir,'dt6.mat');
  if(exist(tmp,'file'))
	n = n+1;
    sc{n} = d(ii).name;
	fn{n} = tmp;
  end
end

for(ii=1:length(fn))
    disp(['Processing ' sc{ii} '...']);
    [sn, def, checkIm] = dtiComputeDtToMNItransform(fn{ii});
% WORK HERE
    lutFile = fullfile(handles.dataDir,'MNI_coordLUT.nii.gz');
    newXform.coordLUT = invDef.coordLUT;
    newXform.inMat = invDef.inMat;
    intentCode = 1006; % NIFTI_INTENT_DISPVECT=1006
    intentName = ['To' curSs];
    % NIFTI format requires 4th dim to be time, so we put the deformation vector [x,y,z] in the 5th dim.
    tmp = reshape(newXform.coordLUT,[size(newXform.coordLUT(:,:,:,1)) 1 3]);
    try
        dtiWriteNiftiWrapper(tmp,inv(newXform.inMat),lutFile,1,'',intentName,intentCode);
        dtiSetFilenameInDT6(handles.dataFile,'lutMNI',lutFile);
    catch
        disp('Could not save LUT transform- check permissions.');
    end

    save(fn{ii}, 't1NormParams', '-APPEND');
end

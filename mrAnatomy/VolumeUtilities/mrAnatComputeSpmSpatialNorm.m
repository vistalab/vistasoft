function [sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(img, xform, templateFileName, params)
%
% [sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(img, xform, [templateFileName='MNI_T1'], [params=spm defaults])
%
% Simple wrapper to the spm2 spatial normalization routine. Does a little
% pre-processing on the input img (a 3d array) and will prompt for a
% template file if none is provided. xform is the starting 4x4 affine guess-
% ideally, it should take the input image space to ac-pc space (ie. centered on
% the ac, in mm).
%
% This function will also return the inverse deformation in the form of a
% coordinate look-up-table (LUT), if you request the 3rd output.
% mrAnatXformCoord can use invDef to warp the template to the source image
% space. (You use the sn to warp the source image to the template.) Also,
% you can get the template standard space of a source image coordinate with:
%   ssCoord = mrAnatXformCoords(invDef, acpcCoord)
%
% E.g.:
% 
%
% HISTORY:
% 2004.12.07 RFD: wrote it.
% 2005.08.05 RFD: renamed (was dtiSpmNormalize).
% 2008.03.27 RFD: added a source image weighting mask to avoid warping
% artificial edges created by incomplete brain coverage int he source
% image.


if(~exist('templateFileName','var')||isempty(templateFileName))
  templateFileName = 'MNI_T1';
end

templateDir = fullfile(fileparts(which('mrDiffusion.m')),'templates');
if(~exist(templateFileName,'file'))
  templateFileName = fullfile(templateDir, [templateFileName '.nii.gz']);
end

if(~exist(templateFileName,'file'))
    templateFileName = fullfile(templateDir, 'templates', 'MNI_T1.nii.gz');
    [f,p] = uigetfile({'*.nii.gz','NIFTI gz';'*.mnc','MINC'; '*.img','Analyze';'*.*','All'},...
                      'Select the template...', templateFileName);
    if(isnumeric(f)) disp('User cancelled.'); return; end
    templateFileName = fullfile(p,f);
end

if(~exist('params','var')||isempty(params))
    spm_defaults; global defaults;
    params = defaults.normalise.estimate;
    if strmatch(templateFileName(end-2:end), '.gz') %A hack for this function to work in SPM8 which attempts to plot, but can't with GZ images. Hence, supress the plot.
        params.graphics=0;
    end
end

Vtemplate = mrAnatLoadSpmVol(templateFileName);

if(~strcmp(class(img),'uint8'))
    img = double(img);
    img = img-min(img(:));
    img = uint8(img./max(img(:))*255);
end
if(length(Vtemplate.dim)==4)
    Vin.dim = [size(img) spm_type(class(img))];
else
    % The type number (dim(4) has been removed in spm5.
    Vin.dim = [size(img)];
end
Vin.dat = img;
Vin.mat = xform; 
Vin.pinfo = [1 0]';
% Create a source weighting image to ignore voxels with NaNs or zeros.
% These are most likely voxels that were outside the FOV of the initial
% measurement. Doing this will avoid warping an artifical edge created by
% incomplete brain coverage.
Vsw.dim = Vin.dim;
Vsw.dat = uint8(~isnan(img)&img~=0);
try
    Vsw.dat = imfill(Vsw.dat, 'holes');
catch
    % hole-filling usually isn't critical, so we can safely skip it.
end
Vsw.mat = Vin.mat;
Vsw.pinfo = Vin.pinfo;
sn = spm_normalise(Vtemplate, Vin, '', '', Vsw, params);
%sn = spm_normalise(Vtemplate, Vin, '', '', '', params);
sn.VF = rmfield(sn.VF, 'dat');
sn.VG.fname = Vtemplate.fname;

if(nargout>2)
    disp('Computing inverse deformation...');
    [invDef.deformX, invDef.deformY, invDef.deformZ] = mrAnatInvertSn(sn);
    defX = invDef.deformX; defY = invDef.deformY; defZ = invDef.deformZ; 
    if(max(abs(defX(:)))<127.5 && max(abs(defY(:)))<127.5 && max(abs(defZ(:)))<127.5)
        defX(isnan(defX)) = -127; defY(isnan(defY)) = -127; defZ(isnan(defZ)) = -127;
        invDef.coordLUT = int8(round(cat(4,defX,defY,defZ)));
    else
        defX(isnan(defX)) = -999; defY(isnan(defY)) = -999; defZ(isnan(defZ)) = -999;
        invDef.coordLUT = int16(round(cat(4,defX,defY,defZ)));
    end
    invDef.inMat = inv(sn.VF.mat);
end

return;

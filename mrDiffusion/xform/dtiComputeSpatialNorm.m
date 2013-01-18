function [checkIm,dt,def] = dtiComputeSpatialNorm(dt, spaceName)
%
% [checkIm,dt,def] = dtiComputeSpatialNorm(dt6File, [spaceName='MNI'])
%
% Computes the spatial normalization parameters and saves them in the dt6
% file. Will also save the LUT NIFTI in the same directory.
%
% Space name should be either MNI (default) or SIRL54.
%
% E.g.:
% fileName = 'dti06/dt6.mat';
% [checkIm,dt,def] = dtiComputeSpatialNorm(dtiLoadDt6(fileName), 'SIRL54');
% showMontage(checkIm);
% % Use normalization to save some fibers in a standard space:
% fibersFile = 'fibers/IPSproject/LIPS_FOI';
% fg = dtiReadFibers(fibersFile);
% dtiWriteFiberGroup(fg, [fibersFile '_SIRL54'], [], 'SIRL54', def);
% 
%
% 2008.08.22 RFD: wrote it.
%

if(~exist('spaceName','var')||isempty(spaceName))
    spaceName = 'MNI';
end

% Load the dt6 if it isn't already loaded
if(ischar(dt))
    % Then assume dt is a filename- load the dt6 file
    dt = dtiLoadDt6(dt);
end
dataDir = fileparts(dt.dataFile);

% Spatially normalize it with the MNI (ICBM) template
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
template = fullfile(tdir,[spaceName '_EPI.nii.gz']);
if(~exist(template,'file')), error(['Template "' template '" not found!']); end
[sn, Vtemplate, def] = mrAnatComputeSpmSpatialNorm(dt.b0, dt.xformToAcpc, template);

% Now save the inverse deformation in the LUT file.
lutFile = fullfile(dataDir,[spaceName '_coordLUT.nii.gz']);
% TODO: check to see if it exists before clobbering it!
intentCode = 1006; % NIFTI_INTENT_DISPVECT=1006
intentName = ['To' spaceName];
% NIFTI format requires 4th dim to be time, so we put the deformation vector [x,y,z] in the 5th dim.
tmp = reshape(def.coordLUT,[size(def.coordLUT(:,:,:,1)) 1 3]);

dtiWriteNiftiWrapper(tmp, inv(def.inMat), lutFile, 1, '', intentName, intentCode);
dtiSetFilenameInDT6(dt.dataFile, ['lut' spaceName], lutFile);

% Save the forward deformation (sn) in the archaicly named 't1NormParams'
% field in the dt6 file.
if(isfield(dt,'t1NormParams'))
    t1NormParams = dt.t1NormParams;
    t1NormParams(end+1).name = spaceName;
    t1NormParams(end+1).sn = sn;
else
    t1NormParams(1).name = spaceName;
    t1NormParams(1).sn = sn;
end
save(dt.dataFile, 't1NormParams', '-APPEND');

if(nargout>0)
    % check the normalization
    mm = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
    bb = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim]);
    b0 = mrAnatHistogramClip(double(dt.b0),0.3,0.99);
    b0_sn = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0], 0);
    tedge = bwperim(Vtemplate.dat>50&Vtemplate.dat<170);
    checkIm = uint8(round(b0_sn*255));
    checkIm(tedge) = 255;
end

return;



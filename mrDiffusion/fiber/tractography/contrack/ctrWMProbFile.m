function ctrWMProbFile(p)
%Create white matter probability file
%
%   ctrWMProbFile(params)
%
% The file is written out into the directory dt6Dir/bin with the name
% wmProb.nii.gz
% 
% 
% Modified 07/26/08 DY: 3T data hack: 
% Main issue is the b0, where the contrast is expected to be quite
% different at 3T vs. 1.5T. (Diffusion parameters, like FA and MD,should be
% independent of field strength.) Tony and Bob used the b0 part of
% the masking to eliminate a few regions of artifact that are very hard
% to elimate via diffusion params alone. E.g., regions with very low b0 due
% to large sinuses with slow-moving blood produce diffusion params that
% look a lot like regular WM. But, for ConTrack, I think you can afford to
% take a more liberal approach and just pass in an empty b0 (2nd argin).

if notDefined('p'), error('Parameter stucture needed.'); end

dt = dtiLoadDt6(p.dt6File);

wmProb = dtiFindWhiteMatter(dt.dt6,[],dt.xformToAcpc);

% Save the white matter file in nifti format
wmProbFile = fullfile(p.dt6Dir,'bin','wmProb.nii.gz');
dtiWriteNiftiWrapper(wmProb,dt.xformToAcpc,wmProbFile);

return;
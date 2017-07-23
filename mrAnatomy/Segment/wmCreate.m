function wmProb = wmCreate(nifti,prct)
% Create a white matter probability nifti file
%
%   wmProb = wmCreate(nifti,prct)
%
% Pick the brightest pixels as the white matter.  The percentile number was
% picked visually for these data.
% 
% Required inputs
%   nifti:  A T1 nifti
%   prct:   The percentile to use for defining the white matter mask
%
% Return
%  wmProb:  A nifti struct with values of 200 (white) or 0
%
% See also:  There are many ways to get a brain mask, such as
%            mrAnatExtractBrain, that require FSL tools.  We should
%            probably consider what we want to do as a general utility
%            within vistasoft for brain mask identification.  Not using
%            external tools is useful, as here.
% TODO
%    Much.  This is a temporary hack to work with dtiError().
%
% BW Scitran Team, 2017

if notDefined('nifti'), error('DWI nifti struct required.\n'); end
if notDefined('prct'),prct = 75; end

v = prctile(nifti.data(:),prct);
wmProb = nifti;

% This is a hack based on the fact that we use 180 in the dtiError
% calculation.  We need to have a wmProb function that is more general.
wmProb.data = mean(single(nifti.data > v)*200,4);

end

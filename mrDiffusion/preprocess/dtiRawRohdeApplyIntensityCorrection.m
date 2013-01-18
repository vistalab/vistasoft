function newDwImg = dtiRawRohdeApplyIntensityCorrection(mc, phaseDir, origDwImg)
% Applies intensity correction given Rohode eddy/motion params in mc
%
%   newDwImg = dtiRawRohdeApplyIntensityCorrection(mc, phaseDir, origDwImg)
%
% mc is the 14 motion/eddy parameters, with translations in 1-3, rotations
% in 4-6. The remaining 8 elements are the eddy-current warping parameters
% (Rohde et al's 'c' parameters used to estimate their b_eddy).
%
% phaseDir specifies the phase-encoding direction, either a 1x3 with a '1'
% indicating the phase-encode dir, or a scalar value of 1, 2 or 3.
%
% Applies the Rohde intensity correction to origDwImg, which should be the
% ORIGINAL diffusion-weighted image volume for which the Rohde parameters
% in mc were estimated. We undo the motion correction to apply this, since
% it is specified in the motion-corrected image space.
%
%   Rohde, Barnett, Basser, Marenco and Pierpaoli (2004). Comprehensive
%   Approach for Correction of Motion and Distortion in Diffusion-Weighted
%   MRI. MRM 51:103-114.
%
% HISTORY:
%
% 2007.05.03 RFD wrote it.

if(numel(phaseDir)>1) phaseDir = find(phaseDir); end
if(length(phaseDir)>1 || phaseDir<1 || phaseDir>3) error('phaseDir specification error.'); end

sz = size(origDwImg);
% For our purposes here, ndgrid and meshgrid are equivalent- the only
% difference is which dim increases fastest, but this doesn't matter for a
% simple list of coords. 
[X,Y,Z] = ndgrid([1:sz(1)],[1:sz(2)],[1:sz(3)]);
x = [X(:), Y(:), Z(:)];

% x and y are coordinate lists (names are same as used in Rohde et. al.
% paper). x is a list of coords in native image space, y is a list of the
% corresponsding coordinates in motion-corrected space. 
motionMat = affineBuild(mc(1:3),mc(4:6));
y = mrAnatXformCoords(motionMat,x);

% Intensity correction (ic) is computed in motion-corrected space (y):
c = mc(7:14);
if(phaseDir==1)
    ic = 1 + c(1) + c(4)*y(:,2) + c(5)*y(:,3) + 2*c(7)*y(:,1) - 2*c(8)*y(:,1);
elseif(phaseDir==2)
    ic = 1 + c(2) + c(4)*y(:,1) + c(6)*y(:,3) - 2*(c(7)+c(8))*y(:,2);
else
    ic = 1 + c(3) + c(5)*y(:,1) + c(6)*y(:,2) + 4*c(8)*y(:,3);
end

% We want to apply ic (in motion-corrected space) to the original,
% uncorrected space. This is easier for the downstream processing pipeline,
% since we will likely reslice the original to a standard space and thus
% never actually generate a motion-corrected version. Otherwise, we would
% be forced to resample twice. So, we interpolate ic back to the
% uncorrected space x.
ic = myCinterp3(double(ic),[sz(1) sz(2)], sz(3), x, 1.0);
ic = reshape(ic,sz);
% Now apply it:
newDwImg = double(origDwImg).*ic;

return;

% Rohde et. al. only work out the intensity correction for phaseDir = 2.
% Here we solve for the other two options. Writing their eq. 12 out:
% c1*y1 + c2*y2 + c3*y3 + c4*y1*y2 + c5*y1*y3 + c6*y2*y3 + (c7*y1^2 - c7*y2^2) + (2*c8*y3^2 - c8*y1^2 - c8*y2^2)
%
% For phaseDir = 1:
% c1    + 0     + 0     + c4*y2    + c5*y3    + 0        + (2*c7*y1 - 0      ) + (0         - 0       - 2*c8*y1)
% c1 + c4*y2 + c5*y3 + 2*c7*y1 - 2*c8*y1
%
% For phaseDir = 2:
% NOTE: there is a typo in the Rohde paper where they solve for this
% derivative. In eq. 13, they present: c2 + c4*y1 + c6*y3 + 2*(c7+c8)*y2
% 0     + c2*y2 + 0     + c4*y1    + 0        + c6*y3    + (0       - 2*c7*y2) + (0         - 0       - 2*c8*y2)
% c2 + c4*y1 + c6*y3 - 2*c7*y2 - 2*c8*y2
% c2 + c4*y1 + c6*y3 - 2*(c7+c8)*y2
% 
% For phaseDir = 3:
% 0     +       + c3*y3 + 0        + c5*y1    + c6*y2    + (0       - 0      ) + (4*c8*y3   - 0       - 0     )
% c3 + c5*y1 + c6*y2 + 4*c8*y3
%
% Or, simply:
% eq = 'c1*y1 + c2*y2 + c3*y3 + c4*y1*y2 + c5*y1*y3 + c6*y2*y3 + (c7*y1^2 - c7*y2^2) + (2*c8*y3^2 - c8*y1^2 - c8*y2^2)';
% maple(['diff(' eq ',y1)'])
% maple(['diff(' eq ',y2)'])
% maple(['diff(' eq ',y3)'])





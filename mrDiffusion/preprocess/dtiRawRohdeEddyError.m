function err = dtiRawRohdeEddyError(mc, phaseDir, srcIm, trgIm, sampDensity)
%  Minimization function for Rohode eddy/motion correction
% err = dtiRawRohdeEddyError(c, phaseDir, srcIm, trgIm, sampDensity)
%
% mc is a 1x14 array of the 6 motion params (translations, rotations) and
% the 8 eddy-correct params (c). 
%
% Apply the Rohde 14-parameter motion/eddy-current deformation to the
% source image and return normalized mutual information between the
% transformed source and target images.
%
% If the srcIm and trgIm  are not changing after the first call, you can pass
% an empty array for each of those since the joint-hist routine keeps a
% data cache. 
%
%   Rohde, Barnett, Basser, Marenco and Pierpaoli (2004). Comprehensive
%   Approach for Correction of Motion and Distortion in Diffusion-Weighted
%   MRI. MRM 51:103-114.
%
% TODO: The calculations should be done on physical-space coords (ie.
% scaled by mmPerVox).
%
%
% HISTORY:
%
% 2007.05.02 RFD wrote it.
% 2007.05.10 RFD: added data cache and in-place coord xform to
% mrAnatFastInterp3. That makes this function about 4-5x faster.

sz = size(trgIm);

mc = mc(:)';

% Allow rigid-body xform:
if(length(mc)==6) mc = [mc 0 0 0 0 0 0 0 0 0];
else mc = [mc phaseDir]; end

% Create the joint histogram
H = dtiJointHist(trgIm, srcIm, mc, sampDensity);

% Smooth the histogram
fwhm = 7;
lim  = ceil(2*fwhm);
s = (fwhm/sqrt(8*log(2)))^2+eps;
% Note- for small FWHM, the following will not be accurate.
krn = (1/sqrt(2*pi*s))*exp(-([-lim:lim].^2)/(2*s));
krn = krn./sum(krn);
H = conv2(krn,krn,H);

% Compute cost function
H  = H+eps;
sh = sum(H(:));
H  = H/sh;
s1 = sum(H,1);
s2 = sum(H,2);
% Normalised Mutual Information of:  Studholme,  Hill & Hawkes (1998).
% "A normalized entropy measure of 3-D medical image alignment".
% in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA,
% pp. 132-143.
err = (sum(s1.*log2(s1))+sum(s2.*log2(s2)))/sum(sum(H.*log2(H)));
% flip the sign so minimization maximizes NMI
err= -err;

return;


% OLD CODE:
% t = mc(1:3);
% r = mc(4:6);
% c = mc(7:14);
% % Convert Euler angles into a rotation matrix
% R = [cos(r(2))*cos(r(3)),                                   cos(r(2))*sin(r(3)),  sin(r(2)); 
%      sin(r(1))*-sin(r(2))*cos(r(3))+cos(r(1))*-sin(r(3)),   sin(r(1))*-sin(r(2))*sin(r(3))+cos(r(1))*cos(r(3)),  sin(r(1))*cos(r(2));
%      cos(r(1))*-sin(r(2))*cos(r(3))+-sin(r(1))*-sin(r(3)),  cos(r(1))*-sin(r(2))*sin(r(3))+-sin(r(1))*cos(r(3)), cos(r(1))*cos(r(2))];
% % Apply rotation
% x = R*x;
% % Apply translation
% x(1,:) = x(1,:)+t(1);
% x(2,:) = x(2,:)+t(2);
% x(3,:) = x(3,:)+t(3);
% % Apply warping
% oneSq = x(1,:).^2;
% twoSq = x(2,:).^2;
% b_eddy = c(1).*x(1,:) + c(2).*x(2,:) + c(3).*x(3,:) ...
%         + c(4).*x(1,:).*x(2,:) + c(5).*x(1,:).*x(3,:) ...
%         + c(6).*x(2,:).*x(3,:) + c(7).*(oneSq-twoSq)...
%         + c(8).*(2*x(3,:).^2 - oneSq - twoSq);
% x(phaseDir,:) = x(phaseDir,:) - b_eddy;
%     
% % This will also do the coord xform, but is slower
% % xf.phaseDir = phaseDir;
% % xf.ecParams = mc;
% % x = mrAnatXformCoords(xf,x,false);
% 
% srcIm = reshape(mrAnatFastInterp3(srcIm, x),sz);

%srcIm = reshape(mrAnatFastInterp3(srcIm, x, [mc phaseDir]), sz);
%err = mrAnatComputeMutualInfo(srcIm,trgIm,sampDensity);

function [t1,pd] = relaxFitT1(data,flipAngles,tr,b1Map)
%
% [t1,pd] = relaxFitT1(data,flipAngles,tr,b1Map)
% 
% Computes a linear fit of the the T1 estimate for all voxels. The data can
% be passed as either a 4d array of X x Y x Z x nT1Measurements or an array of
% size nVoxels x nT1Measurements. The b1Map can be either be a scalar (to
% correct for a constant bias across the whole image), or an image the same
% size as one of the t1 measurments (ie. either X x Y x Z or nVoxels x 1).
%
% We allow multiple b1 maps to correct for different sets of measurements.
% If there is more than 1 b1 map, then each row of the flip angle array
% will be corrected by the corresponding b1 map. E.g., flipAngles(1,:) will
% be corrected by b1Map(:,:,:,1), flipAngles(2,:) will be corrected by
% b1Map(:,:,:,2), etc. The flip angle corresponding to each t1 should be
% specified using the linear index. E.g., flipAngle(1) for t1(:,:,:,1),
% flipAngle(2) for t1(:,:,:,2), etc.
%
% Returns:
%   T1: T1 estimate (seconds)
%   PD: a proton density (PD) map that includes spin-density (M0), scanner
%       scaling constant (G), and T2*: 
%            PD = M0 * G * exp(-TE / T2*).
%       (When TE/T2* is near zero, the exponential term is irrelevant.)
%
% SEE ALSO:
% 
%    relaxMtFit.m to fit the f and k maps to the output of this function.
%
% HISTORY:
% 2008.02.26 RFD: wrote it.

if(~exist('b1Map','var')||isempty(b1Map))
  b1Map = 1;
end

theta = flipAngles*pi/180;
szT1 = size(data);
szB1 = size(b1Map);
if(numel(szT1)>2)
   nVox = prod(szT1(1:3));
   nT1 = szT1(4);
   data = reshape(data,nVox,nT1);
   if(numel(b1Map)>1)
       if(numel(szB1)>3), nB1 = szB1(4);
       else nB1 = 1; end
       b1Map = reshape(b1Map,nVox,nB1);
   else
       nB1 = 1;
   end
else
   nVox = size(data,1);
   nT1 = size(data,2);
   nB1 = size(b1Map,2);
end
if(nB1>1)
    if(size(theta,1)~=nB1)
        error('The number of B1 maps must match the number of rows in the flip angle array.');
    end
    b1Inds = repmat([1:nB1]',1,size(theta,2));
else
    b1Inds = repmat([1],1,numel(theta));
end
theta = theta(:)';
b1Inds = b1Inds(:)';
   
% The code below (esp ndfun) doesn't work when we have Inf or NaN, so:
b1Map(~isfinite(b1Map)) = 1;
data(~isfinite(data)) = 0;

%% LINEAR T1 FIT
%
% Fit a line to the data in each voxel to estimate T1.
% We'll use an eigenvector formulation since we already have a 
% vectorized eigenvector decompostion coded up.

% Build a matrix M where M = [x1-x0 y1-y0; x2-x0 y2-y0; ... xn-x0 yn-y0]. 
% To make it work with ndfun, we need to reshape things a bit.
M = zeros(nT1,2,nVox);
for(ii=1:nT1)
  correctedFlip = theta(ii).*b1Map(:,b1Inds(ii));
  M(ii,1,:) = abs(data(:,ii)./tan(correctedFlip));
  M(ii,2,:) = abs(data(:,ii)./sin(correctedFlip));
end
M0 = mean(M,1);
for(ii=1:size(M,1))
  M(ii,:,:) = M(ii,:,:) - M0;
end
% The best-fitting line is the eigenvector corresponding to
% the largest eigenvalue of eig(M'*M):
[vec,val] = ndfun('eig',ndfun('mult',permute(M,[2 1 3]),M));
% The slope (m) of the line is simply the ratio of y to x and the
% intercept (b) is y-m*x
% Note that the eigenvalues from ndfun are sorted in descending
% order, opposite from Matlab's 'eig'.
m = vec(2,1,:)./vec(1,1,:);
%b = M0(:,2,:)-m.*M0(:,1,:);

% *** CHECK THIS
%m(m<=0) = NaN;
m = abs(squeeze(m));
m(m<0.5) = 0.5;

t1 = (-tr/1000)./log(m);
% Clip to plausible values
t1(isnan(t1)|t1<0.1) = 0.1;
t1(t1>5) = 5;

%pd = b./(1-m);
%pd(pd>5e5) = 5e5;

pd = zeros(nVox,nT1);
% We could use m here, but we've already clipped t1 to plausible values, so recomputing 
% the slope here provides a sane range of pd values.
t1tr = exp(-tr/1000./t1);
for(ii=1:nT1)
    correctedFlip = theta(ii).*b1Map(:,b1Inds(ii));
    pd(:,ii) = data(:,ii)./sin(correctedFlip).*((1-cos(correctedFlip).*t1tr)./(1-t1tr));
end
% Could do least squares for better PDmap?
pd = mean(pd,2);

if(numel(szT1)>ndims(data))
   t1 = reshape(t1,szT1(1:3));
   pd = reshape(pd,szT1(1:3));
end

return

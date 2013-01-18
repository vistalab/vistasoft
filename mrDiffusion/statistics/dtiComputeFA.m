function [fa,md,rd,ad] = dtiComputeFA(eigVal)
% Computes fractional anisotropy (FA) from tensor eigenvalues
%
%   [fa,md,rd,ad] = dtiComputeFA(eigVal)
%
% eigVal  XxYxZx3xN (or nx3xN) array of tensor eigenvalues (N is No. of subjects)
% fa      XxYxZxN (or nxN) array of FA values
% md      XxYxZxN (or nxN) array of Mean Diffusivity values (10^-^6 mm^2/sec)
% rd      XxYxZxN (or nxN) array of Radial Diffusivity values
%
% HISTORY: 
% 2003.12.04 ASH (armins@stanford.edu) wrote it.
% 2003.12.04 RFD (bob@white.stanford.edu) added check to avoid divide-by-zero.
% 2004.02.19 ASH added extra dimension for subjects
% 2005.05.02 RFD: added option to pass in a dt6 array.
% 2006.07.12 ASH added indexed format
% 2006.07.13 RFD: fixed the features that ASH so rudely clobbered yesterday.
% 2007.02.28 RFD: added rd return arg. 

% Programming:  Since this returns MD as an option, how about renaming the
% function.  Or giving it a flag about which to return.  Or something.

% Check inputs
if (ndims(eigVal)==2)
    Ind = 1;    % eigVal in indexed nx3 format
    eigVal = shiftdim(eigVal, -2);
elseif(ndims(eigVal)==3),
    if(size(eigVal,2)==3 && size(eigVal,3)~=3)
        Ind = 1;    % Data in indexed nx3xN format
        eigVal = shiftdim(eigVal, -2);
    else
        Ind = 2;    % Data in XxYx3 format
        eigVal = shiftdim(eigVal, -1);
    end
else
    Ind = 0;    % eigVal in XxYxZx3xN format
end
if (ndims(eigVal)<4 || ndims(eigVal)>5),
    error('Wrong input format');
end

if(size(eigVal,4) ~= 3),
    if(size(eigVal,4)==6)
        [eigVec, eigVal] = dtiEig(eigVal);
        clear eigVec;
    else
    error('Wrong input format');
    end
end

% Main
epsilon = 1e-10;  % Avoid division by zero

% Mean diffusivity
md = sum(eigVal,4)/3;

%
stdevDiffusivity = sqrt(sum((eigVal-repmat(md,[1,1,1,3,1])).^2,4));
normDiffusivity = sqrt(sum(eigVal.^2,4));
nz = normDiffusivity > epsilon;

% Formula for fractional anisotropy
fa = repmat(NaN, size(md));
fa(nz) = sqrt(3/2).*(stdevDiffusivity(nz)./normDiffusivity(nz));
fa = squeeze(fa);

% Mean diffusivity
md = squeeze(md);

% If requested, return rd and ad
if(nargout>2)
    % Radial diffusivity is the average of the two smaller eigenvalues
    rd = squeeze((eigVal(:,:,:,2)+eigVal(:,:,:,3))/2);
end
if(nargout>3)
    % Axial diffusivity - the largest eigenvalue
    ad = squeeze(eigVal(:,:,:,1));
end

return

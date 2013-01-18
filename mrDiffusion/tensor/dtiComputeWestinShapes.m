function [cl, cp, cs] = dtiComputeWestinShapes(eigVal, denominator)
%
% [cl, cp, cs] = dtiComputeWestinShapes(eigVal, [denominator='lsum'])
% Computes Westin's shape indices
%'denominator' is a parameter allowing to choose an appropriate definition
%for Westin shapes.
%
% denominator='lsum' (default):
%    cl = (lambda_1 - lambda_2) / (lambda_1 + lambda_2 + lambda_3)
%    cp = 2 * (lambda_2 - lambda_3) / (lambda_1 + lambda_2 + lambda_3)
%    cs = 3 * lambda_3 / (lambda_1 + lambda_2 + lambda_3)
%
% This was the originial formulation described in:
%
% C-F. Westin, S. Peled, H. Gubbjartsson, R. Kikinis, and F.A. Jolesz.
% Geometrical diffusion measures for MRI from tensor basis analysis.
% In Proceedings 5th Annual ISMRM, 1997.
%
% denominator='l1':
%
% In later work, Westin et. al. adopted a simpler normalization
% formulation (e.g., see Westin et. al. 2002 Med. Image Anal.; PMID:
% 12044998) where the constants are dropped and the denominator is simply
% lambda_1. This definition produces cl+cp+cs=1 which is convenient for
% tensor shape representation in barycentric coordinates.
% In practice, the two methods produce very similar maps.
% cl = (lambda_1 - lambda_2) / (lambda_1)
% cp = 2 * (lambda_2 - lambda_3) / (lambda_1)
% cs = 3 * lambda_3 / (lambda_1)
%
% eigVal: XxYxZx3 or nx3xN array of tensor eigenvalues. Or, you can pass
% the dt6 array (XxYxZx6) and we'll compute the eigenvalues for you.
%
%
% HISTORY:
% 2004.07.22 RFD (bobd@stanford.edu) & ASH wrote it.
% 2007.01.02 SHC made changes to allow nx3xN format.
% 2009.01.05 EIR added option of using a more recent definition of Westin shapes

if ~exist('denominator', 'var')
    denominator='lsum';
end


if size(eigVal,4)==6
    [eigVec, eigVal] = dtiEig(eigVal);
    clear eigVec;
end

% Check inputs
switch ndims(eigVal)
    case 2,
        Ind    = 1; % Data in indexed nx6 format
        eigVal = shiftdim(eigVal, -2);
    case 3,
        if size(eigVal,2)==6 && size(eigVal,3)~=6
            Ind    = 1; % Data in indexed nx6xN format
            eigVal = shiftdim(eigVal, -2);
        else
            Ind    = 2; % Data in XxYx6 format
            eigVal = shiftdim(eigVal, -1);
        end
    otherwise,
        Ind = 0; % Data in XxYxZx6xN format
end

epsilon = 1e-10;
switch denominator
    case 'lsum'
        denum=sum(eigVal,4);

    case 'l1'
        denum=eigVal(:, :, :, 1);
    otherwise fprintf('Wrong denominator option');
end

nz = denum>epsilon;

% Avoid divide-by-zero (we'll replace these values with zeros below).
denum(~nz) = 1;

cl = (eigVal(:,:,:,1)-eigVal(:,:,:,2))./denum;
cp = 2*(eigVal(:,:,:,2)-eigVal(:,:,:,3))./denum;
cs = 3*eigVal(:,:,:,3)./denum;

if strcmp(denominator,'l1')
    cp=cp./2;
    cs=cs./3;
end



cl(~nz) = 0; cp(~nz) = 0; cs(~nz) = 0;
cl(cl>1.0) = 1.0;
cp(cp>1.0) = 1.0;
cs(cs>1.0) = 1.0;
cl(cl<0.0) = 0.0;
cp(cp<0.0) = 0.0;
cs(cs<0.0) = 0.0;

% Adjust output
switch Ind
    case 1,
        cl = shiftdim(cl, 2);
        cp = shiftdim(cp, 2);
        cs = shiftdim(cs, 2);
    case 2,
        cl = shiftdim(cl, 1);
        cp = shiftdim(cp, 1);
        cs = shiftdim(cs, 1);
end

return;

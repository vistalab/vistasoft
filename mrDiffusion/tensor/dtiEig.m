function [eigVec, eigVal] = dtiEig(Y, Ind)
% Computes eigenvalues and eigenvectors of a DTI data array in dt6 format
%
%     [eigVec, eigVal] = dtiEig(DT_ARRAY, [Ind=autodetect])
% 
% The dt6 format is : [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz].
%
% 'Ind' is the data format flag. It is usually auto-detected by checking
% some heuristics (e.g., looking for the dim with exactly 6 elements). In
% some cases, it can't be guessed (e.g., you have multiple dims that
% happen to have 6 elements). In that case, set Inds explicitly:
%   Ind = 0;    % Data in XxYxZx6xN format
%   Ind = 1;    % Data in indexed nx6 format or indexed nx6xN format
%   Ind = 2;    % Data in XxYx6 format
% 
% Input:
%   DT_ARRAY    Data array of size XxYxZx6xN (or nx6xN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   (n is the number of voxels).
% Output:
%   eigVec      XxYxZx3x3xN (or nx3x3xN) array of eigenvectors 
%   eigVal      XxYxZx3xN (or nx3xN) array of eigenvalues
%
% The eigenvectors and eigenvalues are sorted in descending order of the
% three eigenvalues. E.g., eigVec(:,:,:,:,1) is the eigenvector
% corresponding to eigVal(:,:,:,1).  The first vector/value is guaranteed to be the
% largest eigenvalue.
%
% See also:     dtiEigComp.m
% Utilities:    dtiSplitTensor.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).

% HISTORY:
% 2006.07.12 ASH (armins@stanford.edu) Wrote it as a wrapper to dtiSplitTensor.m
% 2009.07.05 RFD: added option to explicitly set Ind.

% Check inputs
if(~exist('Ind','var')||isempty(Ind))
    if(ndims(Y)==2),
        Ind = 1;    % Data in indexed nx6 format
    elseif(ndims(Y)==3)
        if(size(Y,2)==6 && size(Y,3)~=6)
            Ind = 1;    % Data in indexed nx6xN format
        else
            Ind = 2;    % Data in XxYx6 format
        end
    else
        Ind = 0;    % Data in XxYxZx6xN format
    end
end
if(Ind==1)
    Y = shiftdim(Y, -2);
elseif(Ind==2)
    Y = shiftdim(Y, -1);
elseif(Ind~=0)
    error('Ind must be 0, 1 or 2.');
end

if (ndims(Y)<4 || ndims(Y)>5), error('Wrong input format');end
if (size(Y,4) ~= 6), error('Wrong input format'); end

% Main
[eigVec,eigVal] = dtiSplitTensor(Y);

% Adjust output
if(Ind==1)
    eigVec = shiftdim(eigVec, 2);
    eigVal = shiftdim(eigVal, 2);
elseif(Ind==2)
    eigVec = shiftdim(eigVec, 1);
    eigVal = shiftdim(eigVal, 1);
end

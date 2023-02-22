function ADC = dtiADC(Q,bvecs)
%Compute the ADC in the bvecs directions from a set of tensors (Q)
%
%   ADC = dtiADC(Q,bvecs)
%
% Q is a set of 3x3 tensors. Typically each Q is from a fiber node
% location. The original format was to have Q be an M x 9 matrix, so that
% each row is a single tensor.  It is now allowable for Q to be a 3x3xM
% array (LITTLE TESTED).
%
% The bvecs and bvals are the measurement directions and bvals used to
% calculate the tensor. These data can be read using dwiLoad and there are
% sample data in vistadata/diffusion.
%
% The ADC is a matrix with 
%   rows =  number of directions and 
%   cols = number of tensors.  
% So if there are 150 bvecs and 20 tensors, ADC is 150 x 20.
%
% Signal equation:
%  dSig = S0 exp(-bval*(bvec*Q*bvec))
%  ADC = diag(bvec*Q*bvec')
%
% These tensors describe how each fiber should contribute to the total
% signal loss at that point.
%
% Examples:
%  TODO - I haven't tested the 3x3xM format enough!  
%  We should have a means of converting between Mx9 and 3x3xM format.
%
% See also: fgTensors, t_mrd, s_mictDirectionBasis, s_mictSimple
%
% (c) Stanford VISTA Team
%
% Check whether the units are properly preserved here, in terms of the
% square root of bvals.  This should be checked with fgTensors, which is
% the way the computation is done.

if notDefined('Q'),     error('Quadratic forms are required'); end
if notDefined('bvecs'), error('bvecs are required'); end

nDirs = size(bvecs,1);

if ismatrix(Q)  && size(Q,2) == 9% Q in rows
    nTensors = size(Q,1);
    ADC = zeros(nDirs,nTensors);
    
    % Compute the ADCs
    for ii=1:nTensors
        % This is the quadratic form of the tensor:
        q = reshape(Q(ii,:),3,3);
        ADC(:,ii) = diag(bvecs*q*bvecs');
    end
    
elseif size(Q,1) == 3  && size(Q,2) == 3 % 3D array
    nTensors = size(Q,3);  % This works even for Q a 2D matrix
    ADC = zeros(nDirs,nTensors);
    
    % Compute the ADCs
    for ii=1:nTensors
        ADC(:,ii) = diag(bvecs*Q(:,:,ii)*bvecs');
    end
else
    error('Bad format for Q');
end

return

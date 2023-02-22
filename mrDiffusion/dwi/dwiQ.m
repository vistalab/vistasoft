function Q = dwiQ(dwi,coords,space)
% Compute the quadratic form (tensor) at the Nx3 coords
%
%   Q = dwiQ(dwi,coords)
%
% dwi is a dwiLoad structure
% coords:  Nx3 coords
% space:   The coordinate frame - either image or acpc
%
% Uses a simple (non-robust method) to derive the tensor that predicts the
% ADC values at each coordinate.  That is, for a unit column vector, 
%  ADC = u'Qu.
%
% The diffusion distance in each direction can be computed from the tensor
% using ... The diffusion signal in a direction can be computed from the
% tensor using ...
%
% See also: dtiRawFitTensor
%
% Example:
%
% (c) Stanford Vista Team, 2012

if notDefined('dwi'),    error('DWI structure required'); end
if notDefined('coords'), error('image space coords required'); end
if notDefined('space'),  space = 'image'; end

space = mrvParamFormat(space);
switch space
    case 'image'
        ADC = dwiGet(dwi,'adc data image',coords);
    case 'acpc'
        ADC = dwiGet(dwi,'adc data acpc',coords);
    otherwise
        error('Unknown space %s\n');
end

% Set up the matrix for estimating the tensor from a regression
b = dwiGet(dwi,'diffusion bvecs');
V = [b(:,1).^2, b(:,2).^2, b(:,3).^2, 2* b(:,1).*b(:,2), 2* b(:,1).*b(:,3), 2*b(:,2).*b(:,3)];

% Now, we divide the matrix V by the measured ADC values to obtain the qij
% values in the parameter, tensor
tensor = V\ADC;
% predADC = V*tensor;
% mrvNewGraphWin; plot(predADC,ADC,'o'); axis equal

% We convert the format from a vector to a 3x3 Quadratic
% They are packed in a Q matrix that is 3 x 3 x nCoords
nCoords = size(tensor,2);
Q = zeros(3,3,nCoords);
for ii=1:nCoords
    Q(:,:,ii) = dt6VECtoMAT(tensor(:,ii));  % eigs(Q)
end

end
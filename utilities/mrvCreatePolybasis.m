function [pBasis, pTerms, spatialSamples] = mrvCreatePolybasis(boxS,pOrder,BasisFlag)
% Build 2D polynomial matrix
%
% Syntax:
%  [pBasis, pTerms, spatialSamples] = mrvCreatePolybasis(boxS,pOrder,BasisFlag)
%
% Brief description:
%    Creates a polynomial basis set, potentially orthogonormal.
%    Currently implemented for 2nd and 3rd order, 1D, 2D and 3D
%    spatial dimensions
%
% Inputs:
%   boxS:         Size of the box (2 or 3 dimensions)
%   pOrder:       polynomial order (linear, quadratic, cubic)
%   BasisFlag:    Normalize pBasis if true to be unit length.
%                 if 'svd' use svd to Orthogonalize pBasis.
%                 if 'qr' use qr to  Orthogonalize thepBasis.
%
% Outputs:
%   pBasis:         Polynomial basis functions for nth order and some
%                   number of dimensions.
%   spatialSamples: Cell array of the spatial samples for each dimension  
%   pTerms:         String defining the polynomial terms
%
% Description
%   Generates a matrix for a polynomial basis, the columns of pBasis.
%   The terms in each column are described in pTerms.  The pBasis can
%   be made orthonormal to simplify estimation of the parameters of
%   the best fitting polynomial to the data set.
%
%   See the examples at the head of the code for how to specify the
%   polynomial basis and how to estimate the polynomial parameters
%   given data and a basis.
%   
%
% AM & BW 2013

% Examples:
%{
 boxS = [12 10]; pOrder = 3;
 pBasis = mrvCreatePolybasis(boxS,pOrder);
 mrvNewGraphWin; imagesc(pBasis);
%}
%{
 % Even number of spatial samples
 boxS = [12 10]; pOrder = 3; 
 pBasis = mrvCreatePolybasis(boxS,pOrder,'qr');
 imagesc(pBasis);
 % Orthonormal
 imagesc(pBasis'*pBasis)
%}
%{
 boxS = [12 10]; pOrder = 2; 
 pBasis = mrvCreatePolybasis(boxS,pOrder,'qr');
 thisBasis = pBasis*[0 0 1 0 1 0]';
 mrvNewGraphWin; mesh(reshape(thisBasis,boxS(2),boxS(1)));
%}
%{
 % Check 3D case, odd number of samples
 boxS = [7 7 7]; pOrder = 2; BasisFlag = 'qr';
 [pBasis, pTerms, nSamples] = mrvCreatePolybasis(boxS,pOrder,BasisFlag);
 mrvNewGraphWin; imagesc(pBasis);
 mrvNewGraphWin; imagesc(pBasis'*pBasis);
%}
%{
 % Approximate data with a lower order polynomial
 boxS = [12 10]; pOrder = 3; BasisFlag = 'qr';
 [pBasis, pTerms, sSamples] = mrvCreatePolybasis(boxS,pOrder,BasisFlag);

 % Generate data
 in = rand(size(pBasis,2),1);
 data = pBasis*in; 
 mrvNewGraphWin; imagesc(reshape(data,boxS(2),boxS(1)));
 data = data(:); 

 % Estimate the parameters
 params   = pBasis'*data;
 max(abs(in - params))

 % Compare
 estimate = pBasis*params;
 estimate = reshape(estimate,boxS(2),boxS(1)); 
 mrvNewGraphWin; imagesc(estimate);
%}

%% Manage the parameters

if notDefined('boxS'),      error('Box size required'); end
if notDefined('pOrder'),    pOrder = 3; end
if notDefined('BasisFlag'), BasisFlag = false; end

sDim = length(boxS);

% I am worried - it appears the number of samples have to be odd for
% all this to work!
nSamples = floor(boxS/2);
spatialSamples = cell(sDim,1);
for ii=1:length(boxS)
    if isodd(boxS(ii))
        spatialSamples{ii} = -nSamples(ii):nSamples(ii);
    else
        spatialSamples{ii} = -nSamples(ii):(nSamples(ii)-1);
    end
end

spatialSamplesX = spatialSamples{1};
if length(boxS) > 1
    spatialSamplesY = spatialSamples{2};
end
if length(boxS) > 2
    spatialSamplesZ = spatialSamples{3};
end

%% Create the polynomial basis
switch pOrder
    case 1  % 1st order polynomial
        if sDim == 1
            X = spatialSamplesX(:);
            pBasis = [ones(size(X)), X];
            pTerms = '[1, X]';
            %   W=[0 1];
        elseif sDim == 2
            [X, Y] = meshgrid(spatialSamplesX,spatialSamplesY);
            X = X(:);     Y = Y(:);
            pBasis = [ones(size(X)), X, Y];
            pTerms = '[1, X, Y]';
            %   W=[0 1 1];
        elseif sDim == 3
            [X, Y, Z] = meshgrid(spatialSamplesX,spatialSamplesY,spatialSamplesZ);
            X = X(:); Y = Y(:); Z = Z(:);
            pBasis = [ones(size(X)), X, Y  Z ];
            pTerms = '[1, X, Y, Z ]';
            % W=[0 1 1 1];
        else
            error('Not yet implemented')
        end
        
    case 2  % 2nd order polynomial
        if sDim == 1
            % Three parameters
            X = spatialSamplesX(:);
            X2 = X(:).^2;
            pBasis = [ones(size(X)), X, X2];
            pTerms  = '[1, X, X2]';
        elseif sDim == 2
            % Six parameters
            [X, Y] = meshgrid(spatialSamplesX,spatialSamplesY);
            X = X(:);     Y = Y(:);
            X2 = X(:).^2; Y2 = Y(:).^2;
            XY = X(:).*Y(:);
            pBasis = [ones(size(X)), X, X2, Y, Y2, XY];
            pTerms  = '[1, X, X2, Y, Y2, XY]';
        elseif sDim == 3
            % Ten parameters
            [X, Y, Z] = meshgrid(spatialSamplesX,spatialSamplesY,spatialSamplesZ);
            X = X(:); Y = Y(:); Z = Z(:);
            X2 = X(:).^2; Y2 = Y(:).^2; Z2 = Z(:).^2;
            XY = X(:).*Y(:); XZ = X(:).*Z(:);  YZ = Y(:).*Z(:);
            pBasis = [ones(size(X)), X, X2, Y, Y2, XY  Z  Z2 XZ YZ];
            pTerms  = '[1, X, X2, Y, Y2, XY, Z, Z2, XZ, YZ]';
        else
            error('Not yet implemented')
        end
        
    case 3
        
        if sDim == 1
            X = spatialSamplesX(:);
            X2 = X(:).^2;
            X3 = X(:).^3;
            pBasis = [ones(size(X)), X, X2, X3];
            pTerms  = '[1, X, X2, X3]';
        elseif sDim == 2
            % 10 parameters
            [X, Y] = meshgrid(spatialSamplesX,spatialSamplesY);
            X = X(:);     Y = Y(:);
            X2 = X(:).^2; Y2 = Y(:).^2;
            X3 = X(:).^3; Y3 = Y(:).^3;
            XY = X(:).*Y(:);
            X2Y = X2.*Y(:); XY2 = X(:).*Y2(:);
            
            pBasis = [ones(size(X)), X, X2, Y, Y2, XY, X3, Y3, X2Y, XY2];
            pTerms  = '[1,  X, X2, Y, Y2,  XY, X3, Y3, X2Y, XY2]';
            
        elseif sDim == 3
            % Twenty parameters
            [X, Y, Z] = meshgrid(spatialSamplesX,spatialSamplesY,spatialSamplesZ);
            X = X(:); Y = Y(:); Z = Z(:);
            X2 = X(:).^2; Y2 = Y(:).^2; Z2 = Z(:).^2;
            X3 = X(:).^3; Y3 = Y(:).^3; Z3 = Z(:).^3;
            
            XY = X(:).*Y(:); XZ = X(:).*Z(:);  YZ = Y(:).*Z(:);
            XYZ = X(:).*Y(:).*Z(:);
            X2Y = X2.*Y(:); X2Z = X2.*Z(:);
            XY2 = X(:).*Y2(:); XZ2 = X(:).*Z2(:);
            Y2Z = Y2(:).*Z(:); YZ2 = Y(:).*Z2(:);
            
            pBasis = [ones(size(X)), X, X2, Y, Y2, XY ,X3, Y3, X2Y, XY2, Z, Z2, Z3, XZ, YZ, XYZ, X2Z, Y2Z, XZ2, YZ2];
            pTerms  = '[1, X, X2, Y, Y2, XY ,X3, Y3, X2Y, XY2, Z, Z2, Z3, XZ, YZ, XYZ, X2Z, Y2Z, XZ2, YZ2]';
        end
        
    otherwise
        error('Order %d not built',pOrder);
end

%% Manage the orthonormal transform

if BasisFlag
    if ischar(BasisFlag)
        % One of the two orthonormalization methods
        BasisFlag = lower(BasisFlag);
        switch BasisFlag
            case {'svd'}
                % SVD Orthogonalize the pBasis
                nCols = size(pBasis,2);
                [U, ~, ~] = svd(pBasis, 'econ');
                pBasis = U(:,1:nCols);
            case {'qr'}
                % QR Orthogonalize the pBasis
                nCols = size(pBasis,2);
                [Q, ~] = qr(pBasis);
                pBasis = Q(:,1:nCols);
                % Make sure the first one (mean) is positive
                if pBasis(1,1) < 0, pBasis(:,1) = -1*pBasis(:,1); end
            otherwise
                error('BasisFlag %d not known.',BasisFlag);
        end
    else
        % BasisFlag is true, not not a method. So, just adjust the
        % vector length of basis vectors, but don't orthogonalize.
        sFactor = sqrt(diag(pBasis'*pBasis));
        pBasis = pBasis * diag(1./sFactor);
    end
end

end

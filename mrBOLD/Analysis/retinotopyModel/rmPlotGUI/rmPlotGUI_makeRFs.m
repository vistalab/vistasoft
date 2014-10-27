function RFs = rmPlotGUI_makeRFs(modelName, rfParams, X, Y)
% For Retinotopy Model GUI: Create pRFs based on the model type.
%
%   RFs = rmPlotGUI_makeRFs(modelName, rfParams, X, Y);
%
% Given a set of pRF parameters, the name of the model, and a sampling grid
% (X, Y), produce an RF or set of RFs for use in the GUI.
%
% ras, 11/2008.
switch modelName,
    case {'2D pRF fit (x,y,sigma, positive only)',...
          '2D RF (x,y,sigma) fit (positive only)',...
          '1D pRF fit (x,sigma, positive only)'};
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(5), rfParams(6), rfParams(1), rfParams(2));
            
    case {'2D pRF fit (x,y,sigma_major,sigma_minor)' ...
            'oval 2D pRF fit (x,y,sigma_major,sigma_minor,theta)'};
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(5), rfParams(6), rfParams(1), rfParams(2));
        
    case 'unsigned 2D pRF fit (x,y,sigma)';
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(3), 0, rfParams(1), rfParams(2));
        
    case {'Double 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
          'Difference 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
          'Difference 1D pRF fit (x,sigma, sigma2, center=positive)'},
        RFs = rfGaussian2d(X, Y, rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));
        
    case {'Two independent 2D pRF fit (2*(x,y,sigma, positive only))'},
        RFs = rfGaussian2d(X, Y, rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));
        
    case {'Sequential 2D pRF fit (2*(x,y,sigma, positive only))'},
        RFs = rfGaussian2d(X, Y, rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));
        
    case {'Mirrored 2D pRF fit (2*(x,y,sigma, positive only))'},
        RFs = rfGaussian2d(X, Y, rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));
        RFs = sum(RFs,2);

    case 'fitprf'
        % the model:
        %   y = gain * (prf (dot) stimulus) ^ (exponent)

        % Making the 2D pRF is complicated. Here is why. Kendrick uses a
        % square grid and no units. He then makes a 2D Gaussian given the
        % center and size of the pRF in units of pixels (not degrees). He
        % then forces the vector length of this pRF to be equal to one. We
        % would like to re-create this same 2D pRF because the gain we have
        % stored for our model was calculated assuming this Gaussian.
        % However we need to return a 2D Gaussian within a circular
        % aperture, whose coordinates (in degrees of visual angle) are
        % described by the variables X,Y. We don't have X and Y in units of
        % pixels and we cannot easily create the pRF using Kendrick's code
        % and then crop out the regions outside our circular aperture.
        % Instead, we use a rather tedious alternative approach. We create
        % the Gaussian on a square grid using Kendrick's method. Then we
        % figure out the scale factor we need to multiply this by to get a
        % vector length of 1. Then we create a 2D Gaussian using Serge's
        % code, and we rescale by the appropriate scale factor. There must
        % be an easier way...
                        
        % kendrick's method of making a 2d gaussian
        nPts = (length(unique(X))-1)/2; 
        if nPts ~= 50, 
            warning('[%s]: The pRF sampling grid usually has 50 points. The number we calculate is %d.', mfilename, nPts);
        end
        sz = max(abs(X));
        rows  = rfParams(2) * nPts/sz + nPts;
        cols  = rfParams(1) * nPts/sz + nPts;
        sigma = rfParams(3) * nPts / sz;
        RFs1 = flatten(makegaussian2d(nPts*2+1,rows,cols,sigma,sigma,[],[],0));
        RFs2 = unitlength(RFs1,[],[],0);
        r = sum(RFs2) ./ sum(RFs1);
       
        % serge's method
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(3), rfParams(6), rfParams(1), rfParams(2));
        RFs = RFs * r;                
    case {'css' '2D nonlinear pRF fit (x,y,sigma,exponent, positive only)'}
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(3), rfParams(6), rfParams(1), rfParams(2));
        
    otherwise,
        error('Unknown modelName: %s', modelName);
end;
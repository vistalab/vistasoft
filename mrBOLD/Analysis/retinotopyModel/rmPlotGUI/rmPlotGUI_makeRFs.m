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
              
    case {'css' '2D nonlinear pRF fit (x,y,sigma,exponent, positive only)'}
        RFs = rfGaussian2d(X, Y, rfParams(3), rfParams(3), rfParams(6), rfParams(1), rfParams(2));
        
    otherwise,
        error('Unknown modelName: %s', modelName);
end;
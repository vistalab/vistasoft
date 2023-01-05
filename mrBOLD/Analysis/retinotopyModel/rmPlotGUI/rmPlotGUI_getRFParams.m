function rfParams = rmPlotGUI_getRFParams(model, modelName, viewType, coords, params)
% For the retinotopy model GUI: get PRF params for a single voxel.
%
%  rmParams = rmPlotGUI_getRFParams(model, modelName, viewType, coords, params)
%
% ras, 11/2008. Trying to make the large GUI code more modular and
% more manageable.
switch modelName,
    case {'2D pRF fit (x,y,sigma, positive only)',...
          '2D RF (x,y,sigma) fit (positive only)',...
          '1D pRF fit (x,sigma, positive only)'};
        rfParams = zeros(1,6);
        
        rfParams(1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(3) = rmCoordsGet(viewType, model, 'sigmamajor',coords);
        rfParams(5) = rmCoordsGet(viewType, model, 'sigmaminor',coords);
        rfParams(6) = rmCoordsGet(viewType, model, 'sigmatheta',coords);
        
    case {'2D pRF fit (x,y,sigma_major,sigma_minor)' ...
            'oval 2D pRF fit (x,y,sigma_major,sigma_minor,theta)'};
        rfParams = zeros(1,4);
        
        rfParams(1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(3) = rmCoordsGet(viewType, model, 'sigmamajor',coords);
        rfParams(5) = rmCoordsGet(viewType, model, 'sigmaminor',coords);
        rfParams(6) = rmCoordsGet(viewType, model, 'sigmatheta',coords);
        
    case 'unsigned 2D pRF fit (x,y,sigma)';
        rfParams = zeros(1,4);
        
        rfParams(1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(3) = rmCoordsGet(viewType, model, 'sigmamajor',coords);
        
    case {'Double 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
          'Difference 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
          'Difference 1D pRF fit (x,sigma, sigma2, center=positive)'},
        rfParams = zeros(2,4);
        
        % get RF parameters
        rfParams(1,1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(1,2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(1,3) = rmCoordsGet(viewType, model, 'sigmamajor',coords);
        rfParams(2,1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(2,2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(2,3) = rmCoordsGet(viewType, model, 'sigma2major',coords);
        
    case {'Two independent 2D pRF fit (2*(x,y,sigma, positive only))',...
          'Mirrored 2D pRF fit (2*(x,y,sigma, positive only))',...
          'Shifted 2D pRF fit (2*(x,y,sigma, positive only))'},
        rfParams = zeros(2,3);
        
        % get RF parameters
        rfParams(1,1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(1,2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(1,3) = rmCoordsGet(viewType, model, 's',coords);
        rfParams(2,1) = rmCoordsGet(viewType, model, 'x02', coords);
        rfParams(2,2) = rmCoordsGet(viewType, model, 'y02', coords);
        rfParams(2,3) = rmCoordsGet(viewType, model, 's2',coords);
        
    case {'Sequential 2D pRF fit (2*(x,y,sigma, positive only))'},
        rfParams = zeros(2,3);
        
        % get RF parameters
        rfParams(1,1) = rmCoordsGet(viewType, model, 'x0', coords);
        rfParams(1,2) = rmCoordsGet(viewType, model, 'y0', coords);
        rfParams(1,3) = rmCoordsGet(viewType, model, 's',coords);
        rfParams(2,1) = rmCoordsGet(viewType, model, 'x02', coords);
        rfParams(2,2) = rmCoordsGet(viewType, model, 'y02', coords);
        rfParams(2,3) = rmCoordsGet(viewType, model, 's2',coords);
        
    case {'fitprf' 'css' '2D nonlinear pRF fit (x,y,sigma,exponent, positive only)' ...
            '2D nonlinear pRF fit with boxcar (x,y,sigma,exponent, positive only)'}
        rfParams = zeros(1,6);
        
        
        rfParams(1) =  rmCoordsGet(viewType, model, 'x0', coords);        % x coordinate (in deg)        
        rfParams(2) = rmCoordsGet(viewType, model, 'y0', coords);         % y coordinate (in deg)        
        rfParams(3) =  rmCoordsGet(viewType, model, 'sigmamajor',coords); % sigma (in deg)   
        rfParams(6) =  rmCoordsGet(viewType, model, 'sigmatheta',coords); % sigma theta (0 unless we have anisotropic Gaussians)
        rfParams(7) =  rmCoordsGet(viewType, model, 'exponent'  ,coords); % pRF exponent
        rfParams(8) =  rmCoordsGet(viewType, model, 'bcomp1',    coords); % gain ?                      
        rfParams(5) =  rfParams(3) / sqrt(rfParams(7));                   % sigma adjusted by exponent (not for calculations - just for diplay)

    otherwise,
        error('Unknown modelName: %s',modelName{M.modelNum});
end;

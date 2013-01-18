function prediction = rmHrfSearchFit_twoGaussian(model, params, loopSlices, wProcess,varexp,allstimimages)
% rmHrfSearchFit_twoGaussian - make predictions without HRF
%
% prediction = rmHrfSearchFit_twoGaussian(model, params, loopSlices, wProcess)
%
% This model can be used for any twoGaussian model whose Gaussians are
% centered at the same location, because we use all pRF parameters
% including, x,y,sigma,sigma2,beta1 and beta2.
%
% 10/2009: SD & WZ wrote it.


% intiate data stucture for our pRF values
tmp.data = [];
tmp.x    = [];
tmp.y    = [];
tmp.s    = [];
tmp.s2   = [];
tmp.b1   = [];
tmp.b2   = [];
tmp.ve   = [];


% Get the data required to build our pRF
for slice=loopSlices,
    % now we extract only the data from that slice
    s = rmSliceGet(model,slice);
    
    % store
    tmp.x = [tmp.x s{1}.x0(wProcess)];
    tmp.y = [tmp.y s{1}.y0(wProcess)];
    tmp.s = [tmp.s s{1}.s(wProcess)];
    tmp.s2 = [tmp.s2 s{1}.s2(wProcess)];
    tmp.b1 = [tmp.b1 s{1}.b(1,wProcess)];
    tmp.b2 = [tmp.b2 s{1}.b(2,wProcess)];
    tmp.ve = [tmp.ve varexp(wProcess)];
end



% build pRF and make our predictions
n = numel(tmp.x);
s = [[1:ceil(n./1000):n-2] n+1]; %#ok<NBRAK>
prediction = zeros(size(allstimimages,1),n);
fprintf(1,'[%s]:Making predictions without HRF for each voxel (%d):',mfilename,n);
drawnow;tic;
for n=1:numel(s)-1,
    % make rfs
    rf1   = rfGaussian2d(params.analysis.X, params.analysis.Y,...
        tmp.s(s(n):s(n+1)-1), ...
        tmp.s(s(n):s(n+1)-1),...
        zeros(size(tmp.s(s(n):s(n+1)-1))), ...
        tmp.x(s(n):s(n+1)-1), ...
        tmp.y(s(n):s(n+1)-1));
    rf2  = rfGaussian2d(params.analysis.X, params.analysis.Y,...
        tmp.s2(s(n):s(n+1)-1), ...
        tmp.s2(s(n):s(n+1)-1),...
        zeros(size(tmp.s(s(n):s(n+1)-1))), ...
        tmp.x(s(n):s(n+1)-1), ...
        tmp.y(s(n):s(n+1)-1));
    si = size(rf1);
    b1 = repmat(tmp.b1(s(n):s(n+1)-1),si(1),1);
    b2 = repmat(tmp.b2(s(n):s(n+1)-1),si(1),1);
    rf = b1.*rf1 + b2.*rf2;
    
    % convolve with stimulus
    pred = allstimimages*rf;
    
    % store
    prediction(:,s(n):s(n+1)-1) = pred;
    fprintf(1,'.');drawnow;
end;
clear n s rf pred;
fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
drawnow;

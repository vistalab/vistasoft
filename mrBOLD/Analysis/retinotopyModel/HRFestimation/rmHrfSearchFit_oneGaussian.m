function prediction = rmHrfSearchFit_oneGaussian(model, params, loopSlices, wProcess,varexp,allstimimages)
% rmHrfSearchFit_oneGaussian - make predictions without HRF
%
% prediction = rmHrfSearchFit_oneGaussian(model, params, loopSlices, wProcess)
%
% 10/2009: SD & WZ wrote it.


% intiate data stucture for our pRF values
tmp.x    = [];
tmp.y    = [];
tmp.s    = [];
tmp.ve   = [];


% Get the data required to build our pRF
for slice=loopSlices,
    % now we extract only the data from that slice
    s = rmSliceGet(model,slice);
    
    % if we have more than one slice, then check which voxels to process in
    % each slice
    if length(loopSlices) > 1
        wProcessSlice = wProcess{slice};
        varexpSlice  = varexp{slice};
    else
        wProcessSlice = wProcess;
        varexpSlice  = varexp;
    end
    
    % store
    tmp.x = [tmp.x s{1}.x0(wProcessSlice)];
    tmp.y = [tmp.y s{1}.y0(wProcessSlice)];
    tmp.s = [tmp.s s{1}.s(wProcessSlice)];
    tmp.ve = [tmp.ve varexpSlice(wProcessSlice)];
end


% build pRF and make our predictions
n = numel(tmp.x);
s = [[1:ceil(n./1000):n-2] n+1]; %#ok<NBRAK>
prediction = zeros(size(allstimimages,1),n);
fprintf(1,'[%s]:Making predictions without HRF for each voxel (%d):',mfilename,n);
drawnow;tic;
for n=1:numel(s)-1,
    % make rfs
    rf   = rfGaussian2d(params.analysis.X, params.analysis.Y,...
        tmp.s(s(n):s(n+1)-1), ...
        tmp.s(s(n):s(n+1)-1),...
        zeros(size(tmp.s(s(n):s(n+1)-1))), ...
        tmp.x(s(n):s(n+1)-1), ...
        tmp.y(s(n):s(n+1)-1));
    
    % convolve with stimulus
    pred = allstimimages*rf;
    
    % store
    prediction(:,s(n):s(n+1)-1) = pred;
    fprintf(1,'.');drawnow;
end;
clear n s rf pred;
fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
drawnow;

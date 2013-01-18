function model = rmSearchFit_twoGaussianDoGfixed(model, data, params, wProcess, t)
% rmSearchFit_oneGaussianDoGfixed - wrapper for 'fine' one Gaussian fit
%
% model = rmSearchFit_oneGaussianDoGfixed(model, data, params, wProcess, t);
%
% 2009/12 SOD & WZ: split of from rmSearchFit.

% now get original sigmas:
gridSigmas_unique = unique(params.analysis.sigmaMajor);
% add upper and lower limit:
expandRange    = params.analysis.fmins.expandRange;
gridSigmas = [0.001.*ones(expandRange,1); ...
    gridSigmas_unique; ...
    params.analysis.maxRF.*ones(expandRange,1)];
gridSigmas = double(gridSigmas);

% fminsearch options
searchOptions = params.analysis.fmins.options;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);
data = double(data);

% amount of negative fits
nNegFit  = 0;
vethresh = params.analysis.fmins.vethresh;
trends   = t.trends;
t_id     = t.dcid+1;

%-----------------------------------
% Go for each voxel
%-----------------------------------
progress = 0;tic;
for ii = 1:numel(wProcess),

    % progress monitor (10 dots)
    if floor(ii./numel(wProcess)*10)>progress,
        % print out estimated time left
        if progress==0,
            esttime = toc.*10;
            if floor(esttime./3600)>0,
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d hours.\n',...
                    mfilename,numel(wProcess),ceil(esttime./3600));
            else
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d minutes.\n',...
                    mfilename,numel(wProcess),ceil(esttime./60));
            end;
            fprintf(1,'[%s]:Nonlinear optimization (x,y,sigma):',mfilename);
        end;
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    % volume index
    vi = wProcess(ii);
    vData = data(:,ii);

    % raw rss value (non-squared) - faster than sum(data(:,vi).^2)
    rawrss     = norm(vData);

    % reset tolFun: Precision of evaluation function. 
    % We define RMS improvement relative to the initial raw 'no-fit' data
    % RMS. So, 1 means stop if there is less than 1% improvement on the fit:
    searchOptions.TolFun = params.analysis.fmins.options.TolFun.*rawrss;
    
    % start point from grid fit
    startParams = [model.x0(vi); model.y0(vi); model.s(vi)];


    % tight search region [lowerbound upperbound]
    if params.analysis.scaleWithSigmas,
        step = params.analysis.relativeGridStep.*startParams(3);
        minstep = params.analysis.maxXY./2./params.analysis.minimumGridSampling;
        step = min(step,minstep);
        maxstep = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
        step = max(step,maxstep);
    else
        step = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
    end;
    boundary.xy    = startParams(1:2)*[1 1] + [-1 1;-1 1].*step.*expandRange;

    % interpolated sigmas, so we'll look for the closest one.
    [tmp,closestvalue] = sort(abs(gridSigmas_unique-startParams(3)));
    closestvalue       = closestvalue+expandRange;
    % make sure closest value (1) is within valid range
    closestvalue    = max(closestvalue(1),expandRange+1);
    closestvalue    = min(closestvalue,numel(gridSigmas)-(expandRange+1));
    boundary.sigma     = gridSigmas(closestvalue+[-1 1].*expandRange)';
    bndParams          = [boundary.xy;boundary.sigma];

    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_twoGaussianDoGfixed(x,vData,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,trends,...
            params.analysis.sigmaRatioFixedValue,params.analysis.betaRatioAlpha),...
            startParams,[],[],[],[],bndParams(:,1),bndParams(:,2),...
            @(x) distanceCon(x,startParams,step.*expandRange),searchOptions);
    else
        outParams = startParams;
    end
    %[ outParams bndParams(:,1) startParams bndParams(:,2)]

    % make RF, prediction and get rss,b
    Xv = params.analysis.X-outParams(1);
    Yv = params.analysis.Y-outParams(2);
    rf = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(3).^2)) );
    
    
     % test 1 gaussian alone 
    if searchOptions.MaxIter==0
        % without second gaussian
        X = [params.analysis.allstimimages*rf(:,1) trends];
        b = pinv(X)*vData;
        rss2  = norm(vData-X*b).^2;
    end
    
    % make surround
    [tmp eccentricity] = cart2pol(outParams(1), outParams(2));
    s2 = outParams(3).*params.analysis.sigmaRatioFixedValue(1) + ...
        eccentricity.*params.analysis.sigmaRatioFixedValue(2) + ...
        params.analysis.sigmaRatioFixedValue(3);
    %s2 = outParams(3).*params.analysis.sigmaRatioFixedValue;
    RF2 = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(s2.^2)) );
    
    % full pRF
    betaRatio = (outParams(3)./s2).^params.analysis.betaRatioAlpha;
    rf = rf - betaRatio.*RF2;

  
   
    % test with second gaussian
    X = [params.analysis.allstimimages * rf trends];
    b    = pinv(X)*vData;
    rss  = norm(vData-X*b).^2;

    
    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit. We
    % do adjust the rss, so it won't be accidentally counted as a 'good'
    % fit. 
    if b(1)>0,
        model.x0(vi)   = outParams(1);
        model.y0(vi)   = outParams(2);
        model.s(vi)    = outParams(3);
        model.s_major(vi)    = outParams(3);
        model.s_minor(vi)    = outParams(3);
        model.s_theta(vi)    = 0;
        model.rss(vi)  = rss;
        model.b([1 t_id],vi)  = b;
        if searchOptions.MaxIter==0
            model.rss2(vi) = rss2;
        end
    else
        % change the percent variance explained to be just under the
        % current vethresh. So it counts as a 'coarse'-fit but can still be
        % included in later 'fine'-fits
        model.rss(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        nNegFit = nNegFit + 1;
    end;
end

% end time monitor
et  = toc;
if floor(et/3600)>0,
    fprintf(1,'Done [%d hours].\n',ceil(et/3600));
else
    fprintf(1,'Done [%d minutes].\n',ceil(et/60));
end;
fprintf(1,'[%s]:Removed negative fits: %d (%.1f%%).\n',...
    mfilename,nNegFit,nNegFit./numel(wProcess).*100);
return;



%-----------------------------------
% make sure that the pRF can only be moved "step" away from original
% position "startParams" - for the one Gaussian model
function [C, Ceq]=distanceCon(x,startParams,step)
Ceq = [];
dist = x([1 2])-startParams([1 2]);
C = norm(dist) - step;
return;
%-----------------------------------


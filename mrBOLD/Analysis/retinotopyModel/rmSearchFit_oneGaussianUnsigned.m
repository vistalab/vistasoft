function model = rmSearchFit_oneGaussianUnsigned(model,data,params,wProcess,t)
% rmSearchFit_oneGaussianUnsigned - wrapper for 'fine' one Gaussian fit
%
% model = rmSearchFit_oneGaussianUnsigned(model,prediction,data,params);
%
% 2008/01 SOD: split of from rmSearchFit.

% now get original sigmas:
gridSigmas_unique = unique(params.analysis.sigmaMajor);
% add upper and lower limit:
expandRange    = params.analysis.fmins.expandRange;
gridSigmas = [0.001.*ones(expandRange,1); ...
    gridSigmas_unique; ...
    params.analysis.sigmaRatioMaxVal.*ones(expandRange,1)];
gridSigmas = double(gridSigmas);

% fminsearch options
searchOptions = params.analysis.fmins.options;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);

% amount of negative fits
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
    vData = double(data(:,ii));

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
    boundary.sigma     = gridSigmas(closestvalue(1)+[-1 1].*expandRange)';
    bndParams          = [boundary.xy;boundary.sigma];
    
    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_oneGaussianUnsigned(x,vData,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,trends),...
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
    X = [params.analysis.allstimimages * rf trends];
    b    = pinv(X)*vData;
    rss  = norm(vData-X*b).^2;

    model.x0(vi)   = outParams(1);
    model.y0(vi)   = outParams(2);
    model.s(vi)    = outParams(3);
    model.rss(vi)  = rss;
    model.b([1 t_id],vi)  = b;
end

% end time monitor
et  = toc;
if floor(et/3600)>0,
    fprintf(1,'Done [%d hours].\n',ceil(et/3600));
else
    fprintf(1,'Done [%d minutes].\n',ceil(et/60));
end;
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


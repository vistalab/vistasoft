function model = rmSearchFit_twoGaussiansPosOnly(model,data,params,wProcess,t)
% rmSearchFit_twoGaussiansPosOnly - wrapper for 'fine' one Gaussian fit
%
% model = rmSearchFit_twoGaussiansPosOnly(model,prediction,data,params);
%
% 2008/01 SOD: split of from rmSearchFit.

% now get original sigmas:
gridSigmas_unique = double(unique(params.analysis.sigmaMajor));
% add upper and lower limit:
expandRange    = double(params.analysis.fmins.expandRange);
gridSigmas = double([0.001.*ones(expandRange,1); ...
    gridSigmas_unique; ...
    params.analysis.maxRF.*ones(expandRange,1)]);

% fminsearch options
searchOptions         = params.analysis.fmins.options;
vethresh              = params.analysis.fmins.vethresh;

% amount of negative fits
nNegFit  = 0;
trends   = t.trends;
t_id     = t.dcid+2;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);
data = double(data);

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
    
    % reset tolFun: Precision of evaluation function. We define RMS
    % improvement relative to the initial raw 'no-fit' data RMS. So, 1
    % means stop if there is less than 1% improvement on the fit:
    searchOptions.TolFun = params.analysis.fmins.options.TolFun.*rawrss;
    
    % start point from grid fit
    startParams = double([model.x0(vi); model.y0(vi); model.s(vi);...
        model.x02(vi); model.y02(vi); model.s2(vi)]);

    % tight search region [lowerbound upperbound]
    if params.analysis.scaleWithSigmas,
        step = params.analysis.relativeGridStep.*max(startParams([3 6]));
        minstep = params.analysis.maxXY./2./params.analysis.minimumGridSampling;
        step = min(step,minstep);
        maxstep = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
        step = max(step,maxstep);
    else
        step = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
    end;
    boundary.xy    = startParams([1 2 4 5])*[1 1] + ones(4,1)*[-1 1].*(step.*expandRange);

    % interpolated sigmas, so we'll look for the closest one.
    closestvalue = zeros(2,1);
    for n=1:2,
        [tmp,tmp2] = sort(abs(gridSigmas_unique-startParams(3*n)));
        closestvalue(n)       = tmp2(1)+expandRange;
    end
    boundary.sigma     = gridSigmas(closestvalue*[1 1]+[-1 1;-1 1].*expandRange);
    bndParams          = [boundary.xy([1 2],:);boundary.sigma(1,:);...
                          boundary.xy([3 4],:);boundary.sigma(2,:)];
        
    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_twoGaussiansPosOnly(x,vData,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,trends),...
            startParams,[],[],[],[],bndParams(:,1),bndParams(:,2),...
            @(x) distanceCon(x,startParams,step.*expandRange),searchOptions);
    else
        outParams = startParams;
    end
    %[outParams bndParams(:,1) startParams bndParams(:,2)]
    
    
    % make RF, prediction and get rss,b
    Xi = params.analysis.X - outParams(1);   % positive x0 moves center right
    Yi = params.analysis.Y - outParams(2);   % positive y0 moves center up
    rf(:,1) = exp( (Yi.*Yi + Xi.*Xi) ./ (-2.*(outParams(3).^2)) );

    Xi = params.analysis.X - outParams(4);   % positive x0 moves center right
    Yi = params.analysis.Y - outParams(5);   % positive y0 moves center up
    rf(:,2) = exp( (Yi.*Yi + Xi.*Xi) ./ (-2.*(outParams(6).^2)) );

    X = [params.analysis.allstimimages * rf trends];
    b    = pinv(X)*vData;
    rss  = norm(vData-X*b).^2;

    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit.
    if all(b(1:2)>0),
        model.x0(vi)   = outParams(1);
        model.y0(vi)   = outParams(2);
        model.s(vi)    = outParams(3);
        model.x02(vi)  = outParams(4);
        model.y02(vi)  = outParams(5);
        model.s2(vi)   = outParams(6);
        model.rss(vi)  = rss;
        model.b([1 2 t_id],vi)  = b;
    else
        % change the percent variance explained to be just under the
        % current vethresh. So it counts as a 'coarse'-fit but can still be
        % included in later 'fine'-fits
        model.rss(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        nNegFit = nNegFit + 1;
    end
end

% just in case
model.s_major = model.s;
model.s_minor = model.s;

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
dist = x([1 2;4 5])-startParams([1 2;4 5]);
C = sqrt(sum(dist.^2,2)) - step;
return;
%-----------------------------------


function model = rmSearchFit_oneOvalGaussian(model, data, params, wProcess, t)
% rmSearchFit_oneOvalGaussian - wrapper for 'fine' one oval Gaussian fit
%
% model = rmSearchFit_oneOvalGaussian(model, data, params, wProcess, t);
%
% 2008/08 KA incorporated asymmetric gaussian model to rmSearchFit_oneGaussian.

searchOptions = params.analysis.fmins.options;
expandRange   = params.analysis.fmins.expandRange;
 
% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);
data = double(data);

% get starting upper and lower range and reset TolFun 
% (raw rss computation (similar to norm) and TolFun adjustments)
[range TolFun] = rmSearchFit_range(params,model,data);

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
    vData = double(data(:,ii));

        % reset tolFun: Precision of evaluation function. 
    % We define RMS improvement relative to the initial raw 'no-fit' data
    % RMS. So, 1 means stop if there is less than 1% improvement on the fit:
    % searchOptions = optimset(searchOptions,'tolFun',optimget(params.analysis.fmins.options,'tolFun')./100.*rawrss);
    % optimset and optimget are a little slow so:
    searchOptions.TolFun = TolFun(ii);
    
    % actual fitting routine
    if searchOptions.MaxIter>0
        if isfield(params, 'seperateRunBetas') && params.seperateRunBetas && isfield(params.analysis, 'exp')
             outParams = ...
                fmincon(@(x) rmModelSearchFit_oneOvalGaussian_exp_seperateBetas(x,vData,...
                params.analysis.X,...
                params.analysis.Y,...
                params.analysis.allstimimages,trends,...
                length(params.stim)),...
                range.start(:,vi),...
                [0 0 -1 1 0 0],[0],...    % s_major should be larger than s_minor
                [],[],...
                range.lower(:,vi),range.upper(:,vi),...
                @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),searchOptions);
        elseif isfield(params, 'seperateRunBetas') && params.seperateRunBetas
            outParams = ...
                fmincon(@(x) rmModelSearchFit_oneOvalGaussian_seperateBetas(x,vData,...
                params.analysis.X,...
                params.analysis.Y,...
                params.analysis.allstimimages,trends,...
                length(params.stim)),...
                range.start(:,vi),...
                [0 0 -1 1 0],[0],...    % s_major should be larger than s_minor
                [],[],...
                range.lower(:,vi),range.upper(:,vi),...
                @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),searchOptions);
        elseif isfield(params.analysis, 'exp')
           outParams = ...
                fmincon(@(x) rmModelSearchFit_oneOvalGaussian_exp(x,vData,...
                params.analysis.X,...
                params.analysis.Y,...
                params.analysis.allstimimages,...
                trends),...
                range.start(:,vi),...
                [0 0 -1 1 0 0],[0],...    % s_major should be larger than s_minor
                [],[],...
                range.lower(:,vi),range.upper(:,vi),...
                @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),searchOptions);
        else
            outParams = ...
                fmincon(@(x) rmModelSearchFit_oneOvalGaussian(x,vData,...
                params.analysis.X,...
                params.analysis.Y,...
                params.analysis.allstimimages,...
                trends),...
                range.start(:,vi),...
                [0 0 -1 1 0],[0],...    % s_major should be larger than s_minor
                [],[],...
                range.lower(:,vi),range.upper(:,vi),...
                @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),searchOptions);
        end
    else
        outParams = range.start(:,vi);
    end
    %[ outParams bndParams(:,1) startParams bndParams(:,2)]

    % make RF, prediction and get rss,b
    Xv = params.analysis.X-outParams(1);
    Yv = params.analysis.Y-outParams(2);
    
    Xold = Xv;
    Yold = Yv;
    Xv = Xold .* cos(outParams(5)) - Yold .* sin(outParams(5));
    Yv = Xold .* sin(outParams(5)) + Yold .* cos(outParams(5));

    % make gaussian on current grid
    rf = exp( -.5 * ((Yv ./ outParams(3)).^2 + (Xv ./ outParams(4)).^2));
    if isfield(params.analysis, 'exp')
        periods=[0.05:0.05:1 2.1 0.1 0.6 0.9 1 0.15 0.65 0.85 1 0.2 0.7 0.8 1 0.25 0.75 1 0.3 0.7 0.8 1 0.35 0.65 0.85 1 0.4 0.6 0.9 1 0.45 0.55 0.95 1 0.5 1 0.55 1 0.6 1 0.65 1 0.7 1 0.75 1 0.8 1 0.85 1 0.9  1 0.95 1 1 2.1];
        freq=5./periods;
        scale=1./(freq'.^outParams(end));
        scale=scale.*freq';
        rf=rf./scale;
    end
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
        model.s(vi)    = (outParams(3)+outParams(4))/2;
        model.s_major(vi)    = outParams(3);
        model.s_minor(vi)    = outParams(4);
        model.s_theta(vi)    = outParams(5);
        model.rss(vi)  = rss;
        model.b([1 t_id],vi)  = b;
        if isfield(params.analysis, 'exp')
            model.exp(vi) = outParams(end);
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


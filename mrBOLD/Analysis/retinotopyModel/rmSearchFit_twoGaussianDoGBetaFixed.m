function model = rmSearchFit_twoGaussianDoGBetaFixed(model,data,params,wProcess,t)
% rmSearchFit_twoGaussiansDoG - wrapper for 'fine' two DoG Gaussian fit
%
% model = rmSearchFit_twoGaussiansDoG(model,prediction,data,params);
%
% Second gaussian negative only. 
%
% 2008/01 SOD: split of from rmSearchFit.

% now get original sigmas:
gridSigmas_unique = unique(params.analysis.sigmaMajor);
% add upper and lower limit:
expandRange    = params.analysis.fmins.expandRange;
gridSigmas = [0.001.*ones(expandRange,1); ...
    gridSigmas_unique; ...
    params.analysis.maxRF.*ones(expandRange,1)];

% fminsearch options
searchOptions = params.analysis.fmins.options;

vethresh = params.analysis.fmins.vethresh;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);

% amount of negative fits
nNegFit  = 0;
trends   = t.trends;
t_id     = t.dcid+1;

% initialize
if ~isfield(model,'rssPos')
    model.rsspos = zeros(size(model.rss));
end

if ~isfield(model,'rssNeg')
    model.rssneg = zeros(size(model.rss));
end

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
    startParams = [model.x0(vi); ...
        model.y0(vi); ...
        model.s(vi);...
        model.s2(vi)];

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

    % gridSigmas==startParams(3), somehow this fails sometimes so we'll
    % look for the closest one. The min and max make sure the closestvalue
    % stays within the data range.
    [tmp,closestvalue] = sort(abs(gridSigmas-startParams(3)));
    closestvalue    = max(closestvalue(1),expandRange+1);
    closestvalue    = min(closestvalue,numel(gridSigmas)-(expandRange+1));
    boundary.sigma     = gridSigmas(closestvalue+[-1 1].*expandRange)';

    % boundary sigma two depends on boudary of sigma 1
    boundary.sigma2 = [boundary.sigma(1).*params.analysis.minSigmaRatio ...
                       params.analysis.sigmaRatioInfVal];
    
    % combine all boundaries
    bndParams2      = double([boundary.xy;...
        boundary.sigma;...
        boundary.sigma2]);

    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_twoGaussiansDoGBetaFixed(x,vData,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,trends,params.analysis.betaRatioAlpha),...
            startParams,[],[],[],[],bndParams2(:,1),bndParams2(:,2),...
            @(x) distanceCon(x,startParams,step,params.analysis.minSigmaRatio),searchOptions);
    else
        outParams = startParams;
    end
    
    % make predictions
    Xv = params.analysis.X - outParams(1);   % positive x0 moves center right
    Yv = params.analysis.Y - outParams(2);   % positive y0 moves center up
    %betaRatio = params.analysis.betaRatioAlpha.*(outParams(3).^2./outParams(4).^2);
    betaRatio = (outParams(3)./outParams(4)).^params.analysis.betaRatioAlpha;
    rf(:,1) = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(3).^2)) );
    rf(:,2) = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(4).^2)) );
    rfNew = rf(:,1) - betaRatio.*rf(:,2);
    X = [params.analysis.allstimimages*rfNew trends];
    b    = pinv(X)*vData;
    % force positive fit (is a constraint in the
    % rmModelSearchFit_twoGaussianDoGBetaFixed, so it should return here to get the right values)    
    b(1) = abs(b(1));
    
    % test 1 gaussian alone (must be done prior to with second gaussian)
    if searchOptions.MaxIter==0
        % without second gaussian
        % make only the positive and the negative rf
        % for the positive rf put all the negative rf-values to zero, for
        % the negative rf put all the positive rf-values to zero.

        rfBeta = rfNew.*b(1);
        posInd = rfBeta > 0;
        negInd = rfBeta < 0;
        rfPos = rfNew;
        rfNeg = rfNew;
        rfPos(negInd) = 0;
        rfNeg(posInd) = 0;
        XPos = [params.analysis.allstimimages*rfPos trends];
        XNeg = [params.analysis.allstimimages*rfNeg trends];
        rssPos = norm(vData-XPos*b).^2;
        rssNeg = norm(vData-XNeg*b).^2;
%         rfPos = max(rfBeta,0);
%         rfNeg = min(rfBeta,0);
%         XPos = [params.analysis.allstimimages*rfPos trends];
%         XNeg = [params.analysis.allstimimages*rfNeg trends];
%         rssPos = norm(vData-XPos).^2;
%         rssNeg = norm(vData-XNeg).^2;
        

    end
    
    % with second gaussian
    rss  = norm(vData-X*b).^2;
    
    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit.
    if b(1)>0,
        model.x0(vi)   = outParams(1);
        model.y0(vi)   = outParams(2);
        model.s(vi)    = outParams(3);
        model.s_major(vi)    = outParams(3);
        model.s_minor(vi)    = outParams(3);
        model.s_theta(vi)    = 0;
        model.s2(vi)   = outParams(4);
        model.rss(vi)  = rss;
        model.b([1 t_id],vi) = b;
        if searchOptions.MaxIter==0
            model.rsspos(vi) = rssPos;
            model.rssneg(vi) = rssNeg;
        end
    else
        % change the percent variance explained to be just under the
        % current vethresh. So it counts as a 'coarse'-fit but can still be
        % included in later 'fine'-fits
        model.rss(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        nNegFit = nNegFit + 1;
        if searchOptions.MaxIter==0
            model.rsspos(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
            model.rssneg(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        end
    end;
end;

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
% poisiton "startParams"
% For the two Gaussian model we add the additional constraint that the
% second Gaussian is at least twice as large as the first.
function [C, Ceq]=distanceCon(x,startParams,step,minRatio)
Ceq = [];
dist = x([1 2])-startParams([1 2]);
C(1) = sqrt(dist(1).^2+dist(2).^2) - step;
C(2) = minRatio - 0.001 - x(4)./x(3);
return;
%-----------------------------------
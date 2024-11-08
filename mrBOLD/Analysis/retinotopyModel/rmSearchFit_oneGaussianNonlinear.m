function model = rmSearchFit_oneGaussianNonlinear(model, data, params, wProcess, t)
% rmSearchFit_oneGaussianNonlinear - wrapper for 'fine' one Gaussian fit
%
% model = rmSearchFit_oneGaussianNonlinear(model, data, params, wProcess, t);
%
% 2008/01 SOD: split of from rmSearchFit.
% 2010/02 SOD: cleanup.
% 2015/02 JW: branched from rmSearchFit_oneGaussian, now includes
%             non-linear model (see Kay et al, 2013, on Compressive
%             Spatial Summation)
 
% fminsearch options
searchOptions = params.analysis.fmins.options;
expandRange   = params.analysis.fmins.expandRange;
 
% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);

params.analysis.allstimimages_unconvolved = double(params.analysis.allstimimages_unconvolved);
data = double(data);

% get starting upper and lower range and reset TolFun 
% (raw rss computation (similar to norm) and TolFun adjustments)
model.s = model.s_major;
[range, TolFun] = rmSearchFit_range(params,model,data);

% GLU 2021-10-14: not sute if best option, but I am going to restrict here
%                 the exponent
%                 If we are here we know that we are fitting the nonlinear css
if params.analysis.fixcssexp ~= 0
   range.start(4,:) = params.analysis.fixcssexp * ones(size(range.start(4,:)));
   range.lower(4,:) = params.analysis.fixcssexp * ones(size(range.start(4,:)));;
   range.upper(4,:) = params.analysis.fixcssexp * ones(size(range.start(4,:)));;
end

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
            fprintf(1,'[%s]:Nonlinear optimization (x,y,sigma, exponent):',mfilename);
        end;
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    % volume index
    vi = wProcess(ii);
    vData = data(:,ii);
    
    % reset tolFun: Precision of evaluation function. 
    % We define RMS improvement relative to the initial raw 'no-fit' data
    % RMS. So, 1 means stop if there is less than 1% improvement on the fit:
    % searchOptions = optimset(searchOptions,'tolFun',optimget(params.analysis.fmins.options,'tolFun')./100.*rawrss);
    % optimset and optimget are a little slow so:
    searchOptions.TolFun = TolFun(ii);
    
    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_oneGaussianNonlinear(x,vData,...
                                                            params.analysis.X,...
                                                            params.analysis.Y,...
                                                            params.analysis.allstimimages_unconvolved,...
                                                            params.analysis.Hrf,...
                                                            params.analysis.scans,...
                                                            trends),...
                     range.start(:,vi),...  % X0. Vector of 5 [x,y,sigma,exp,?]
                     [],[], ...             % A, B
                     [],[], ...             % Aeq, Beq
                     range.lower(:,vi), ... % LB
                     range.upper(:,vi),...  % UB
                     @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),... % NONLCON
                     searchOptions); % OPTIONS 
    else
        outParams = range.start(:,vi);
    end

    %[ outParams range.lower(:,vi) range.start(:,vi) range.upper(:,vi)]

    % make RF, prediction and get rss,b
    Xv = params.analysis.X-outParams(1);
    Yv = params.analysis.Y-outParams(2);
    n  = outParams(4);
    rf = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(outParams(3).^2)) );
    pred = (params.analysis.allstimimages_unconvolved * rf).^ n;
    for scan = 1:numel(params.stim)
        inds = params.analysis.scans == scan;
        pred(inds) = filter(params.analysis.Hrf{scan}, 1, pred(inds));
    end
        
    X  = [pred trends];
    b    = pinv(X)*vData;
    rss  = norm(vData-X*b).^2;

    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit. We
    % do adjust the rss, so it won't be accidentally counted as a 'good'
    % fit. 
    if b(1)>0,
        model.x0(vi)         = outParams(1);
        model.y0(vi)         = outParams(2);
        model.s(vi)          = outParams(3);
        model.s_major(vi)    = outParams(3);
        model.s_minor(vi)    = outParams(3);
        model.s_theta(vi)    = 0;
        model.exponent(vi)   = outParams(4);
        model.rss(vi)        = rss;
        model.b([1 t_id],vi) = b;
    else
        % change the percent variance explained to be just under the
        % current vethresh. So it counts as a 'coarse'-fit but can still be
        % included in later 'fine'-fits
        model.rss(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        nNegFit = nNegFit + 1;
    end
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


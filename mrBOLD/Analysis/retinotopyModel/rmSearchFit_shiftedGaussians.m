function model = rmSearchFit_shiftedGaussians(model,data,params,wProcess,t,pRFshift)
% rmSearchFit_shiftedGaussians - wrapper for 'fine' one Gaussian fit
%
% model = rmSearchFit_shiftedGaussians(model,prediction,data,params,mirror);
%
% 2010/09

% fminsearch options
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
            fmincon(@(x) rmModelSearchFit_shiftedGaussians(x,vData,...
            params.analysis.X,...
            params.analysis.Y,...
            params.analysis.allstimimages,trends,pRFshift),...
            range.start(:,vi),[],[],[],[],range.lower(:,vi),range.upper(:,vi),...
            @(x) distanceCon(x,range.start(:,vi),range.step(:,vi).*expandRange),searchOptions);
    else
        outParams = range.start(:,vi);
    end
    %[outParams bndParams(:,1) startParams bndParams(:,2)]
    
    % all logic here is relative to the left pRF!! so...
    % If we move our pRF to the right we shift the coordinate system to the
    % left. There fore the logic is "params.analysis.X - outParams(1)", now
    % if we add an additional shift this should also be subtracted. 
    
    % make RF, prediction and get rss,b
    denom = -2.*(outParams(3).^2);
    Xi = params.analysis.X - outParams(1);   % positive x0 moves center right
    Yi = params.analysis.Y - outParams(2);   % positive y0 moves center up
    rf = exp( (Yi.*Yi + Xi.*Xi) ./ denom );

    Xi = params.analysis.X - outParams(1) - pRFshift;   % positive x0 moves center right
    %Yi = params.analysis.Y - outParams(2);   % positive y0 moves center up
    rf = rf + exp( (Yi.*Yi + Xi.*Xi) ./ denom );

    X = [params.analysis.allstimimages * rf trends];
    b    = pinv(X)*vData;
    rss  = norm(vData-X*b).^2;

    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit.
    if b(1)>0,
        model.x0(vi)   = outParams(1);
        model.y0(vi)   = outParams(2);
        model.s(vi)    = outParams(3);
        model.x02(vi)  = outParams(1)+pRFshift;
        model.y02(vi)  = outParams(2);
        model.s2(vi)   = outParams(3);
        model.rss(vi)  = rss;
        model.b([1 t_id],vi)  = b;
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
dist = x([1 2])-startParams([1 2]);
C = hypot(dist(1),dist(2)) - step;
return;
%-----------------------------------


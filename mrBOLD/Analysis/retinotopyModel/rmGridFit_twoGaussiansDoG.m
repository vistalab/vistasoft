function model = rmGridFit_twoGaussiansDoG(model,prediction,data,params,t)
% rmGridFit_twoGaussiansDoG - core of DoG fit
%
% model = rmGridFit_twoGaussiansDoG(model,prediction,data,params);
%
% Second gaussian can go negative only.
%
% 2008/01 SOD: split of from rmGridFit.

% input check
if nargin < 4,
    error('Not enough arguments');
end

% some variables we need
rssinf         = inf(size(data(1,:)),'single');
trends         = t.trends;
t_id           = t.dcid+2;

% stimulus sequence is needed because make second pRF on the fly 
allstimimages = rmDecimate(params.analysis.allstimimages,...
    params.analysis.coarseDecimate);

%-----------------------------------
%--- fit different receptive fields profiles
%--- another loop --- and a slow one too
%-----------------------------------
tic; progress = 0;
for n=1:numel(params.analysis.x0),
    %-----------------------------------
    % progress monitor (10 dots) and time indicator
    %-----------------------------------
    if floor(n./numel(params.analysis.x0).*10)>progress,
        if progress==0,
            % print out estimated time left
            esttime = toc.*10;
            if floor(esttime./3600)>0,
                fprintf(1,'[%s]:Estimated processing time: %d hours.\t(%s)\n',...
                    mfilename, ceil(esttime./3600), datestr(now));
            else
                fprintf(1, '[%s]:Estimated processing time: %d minutes.\t(%s)\n',...
                    mfilename, ceil(esttime./60), datestr(now));
            end;
            fprintf(1,'[%s]:Grid (x,y,sigma) fit:',mfilename);drawnow;
        end;
        % progress monitor
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    
    %-----------------------------------
    %--- first make all second rf profiles
    %-----------------------------------
    sigmaNew = params.analysis.sigmaRatio.*params.analysis.sigmaMajor(n);
    % limit to sigmaRatioMaxVal
    sigmaNew = sigmaNew(sigmaNew<=params.analysis.sigmaRatioMaxVal);
    % add sigmaRatioInfVal which essentially is on/off
    sigmaNew = [sigmaNew; params.analysis.sigmaRatioInfVal]; %#ok<AGROW>

    % Now we make it: slightly different call for speed reasons.
    z = zeros(size(sigmaNew));
    tmprf   = rfGaussian2d(params.analysis.X - params.analysis.x0(n),...
        params.analysis.Y - params.analysis.y0(n),...
        sigmaNew,sigmaNew, ...
        false, z, z);
    prediction2 = allstimimages*tmprf;
    
    %-----------------------------------
    %--- try two rf profiles, yet another loop
    %-----------------------------------
    for sr = 1:numel(sigmaNew),
        %-----------------------------------
        % Now apply GLM, see *_oneGaussian for logic.
        % New rules for this one:
        % 1. first Gaussian has to be positive
        % 2. there should be a positive response in the
        % center at all times. This
        % assumes Gaussians are unscaled (see rfGaussian2d).
        %-----------------------------------
        X     = [prediction(:,n) prediction2(:,sr) trends];
        b     = pinv(X)*data;
        rss   = rssinf;
        keep  = b(1,:)>0 & b(1,:)>-b(2,:) & b(2,:)<=0;
        rss(keep) = sum((data(:,keep)-X*b(:,keep)).^2);
        
        %-----------------------------------
        %--- store data with lower rss
        %-----------------------------------
        minRssIndex = rss < model.rss;

        % now update
        model.x0(minRssIndex)       = params.analysis.x0(n);
        model.y0(minRssIndex)       = params.analysis.y0(n);
        model.s(minRssIndex)        = params.analysis.sigmaMajor(n);
        model.s_major(minRssIndex)        = params.analysis.sigmaMajor(n);
        model.s_minor(minRssIndex)        = params.analysis.sigmaMajor(n);
        model.s_theta(minRssIndex)        = params.analysis.theta(n);
        model.rss(minRssIndex)      = rss(minRssIndex);
        model.b([1:2 t_id],minRssIndex)    = b(:,minRssIndex);
        model.s2(minRssIndex)       = sigmaNew(sr);
    end;
end;

% end time monitor
et  = toc;
if floor(esttime/3600)>0,
    fprintf(1,'Done[%d hours].\t(%s)\n', ceil(et/3600), datestr(now));
else
    fprintf(1,'Done[%d minutes].\t(%s)\n', ceil(et/60), datestr(now));
end;
drawnow;
return;

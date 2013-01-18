function model = rmGridFit_shiftedGaussians(model,pRFshift,data,params,t)
% rmGridFit_shiftedGaussian - core of two Gaussians fit
%
% model = rmGridFit_shiftedGaussians(model,mirror,data,params);
%
% 2010/09

% input check
if nargin < 4,
    error('Not enough arguments');
end

% some variables we need
rssinf         = inf(size(data(1,:)),'single');
trends         = t.trends;
t_id           = t.dcid+1;

%-----------------------------------
%--- remake predictions with two Gaussian shift
%-----------------------------------
% make
n = numel(params.analysis.x0);
s = [[1:ceil(n./1000):n-2] n+1]; %#ok<NBRAK>
allstimimages = rmDecimate(params.analysis.allstimimages,...
    params.analysis.coarseDecimate);
prediction = zeros(size(allstimimages,1),n,'single');
fprintf(1,'[%s]:RE-MAKING %d model samples:',mfilename,n);
drawnow;tic;
for n=1:numel(s)-1,
    % make rfs
    rf   = rfGaussian2d(params.analysis.X, params.analysis.Y,...
        params.analysis.sigmaMajor(s(n):s(n+1)-1), ...
        params.analysis.sigmaMinor(s(n):s(n+1)-1), ...
        params.analysis.theta(s(n):s(n+1)-1), ...
        params.analysis.x0(s(n):s(n+1)-1) - pRFshift./2, ...
        params.analysis.y0(s(n):s(n+1)-1));
    
    % second rf
    rf2  = rfGaussian2d(params.analysis.X, params.analysis.Y,...
        params.analysis.sigmaMajor(s(n):s(n+1)-1), ...
        params.analysis.sigmaMinor(s(n):s(n+1)-1), ...
        params.analysis.theta(s(n):s(n+1)-1), ...
        params.analysis.x0(s(n):s(n+1)-1) + pRFshift./2, ...
        params.analysis.y0(s(n):s(n+1)-1));
    
    % add
    rf = rf + rf2;
    
    % convolve with stimulus
    pred = allstimimages*rf;

    % store
    prediction(:,s(n):s(n+1)-1) = pred;
    fprintf(1,'.');drawnow;
end;
clear n s rf pred;
fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
drawnow;


%-----------------------------------
%--- fit different receptive fields profiles
%--- another loop --- and a slow one too
%-----------------------------------
tic; progress = 0;
for n=1:numel(params.analysis.x0),
    
    %-----------------------------------
    % progress monitor (100 dots) and time indicator
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
    % Now apply GLM, see *_oneGaussian for logic.
    % New rules for this one:
    % 1. both Gaussian have to be positive
    %-----------------------------------
    X     = [prediction(:,n) trends];
    b     = pinv(X)*data;
    rss   = rssinf;
    keep  = b(1,:)>=0;
    rss(keep) = sum((data(:,keep)-X*b(:,keep)).^2);
    
    %-----------------------------------
    %--- store data with lower rss
    %-----------------------------------
    minRssIndex = rss < model.rss;
    
    % now update
    model.x0(minRssIndex)       = params.analysis.x0(n) - pRFshift./2;
    model.y0(minRssIndex)       = params.analysis.y0(n);
    model.s(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.rss(minRssIndex)      = rss(minRssIndex);
    model.b([1 t_id],minRssIndex)    = b(:,minRssIndex);
    model.x02(minRssIndex)      = params.analysis.x0(n) + pRFshift./2;
    model.y02(minRssIndex)      = params.analysis.y0(n);
    model.s2(minRssIndex)       = params.analysis.sigmaMajor(n);
end;

% double but otherwise they'll overwrite each other
model.s_major = model.s;
model.s_minor = model.s;

% end time monitor
et  = toc;
if floor(esttime/3600)>0,
    fprintf(1,'Done[%d hours].\t(%s)\n', ceil(et/3600), datestr(now));
else
    fprintf(1,'Done[%d minutes].\t(%s)\n', ceil(et/60), datestr(now));
end;
drawnow;
return;


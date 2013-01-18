function model = rmGridFit_twoGaussiansPosOnly(model,prediction,data,params,t)
% rmGridFit_twoGaussianPosOnly - core of two Gaussians fit
%
% model = rmGridFit_twoGaussiansPosOnly(model,prediction,data,params);
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

% split up the predictions
if  sign(params.analysis.xlim) < 0
    loop1 = find(params.analysis.x0 < 0);
    loop2 = 1:numel(params.analysis.x0);
elseif sign(params.analysis.xlim) > 0
    loop1 = find(params.analysis.x0 > 0);
    loop2 = 1:numel(params.analysis.x0);
else
    loop1 = find(params.analysis.x0 > 0);
    loop2 = find(params.analysis.x0 < 0);
end

%-----------------------------------
%--- fit different receptive fields profiles
%--- another loop --- and a slow one too
%-----------------------------------
tic; progress = 0;
for n=1:numel(loop1),
    
    %-----------------------------------
    % progress monitor (100 dots) and time indicator
    %-----------------------------------
    if floor(n./numel(loop1).*100)>progress,
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
    
    % remove duplicate tests
    if  sign(params.analysis.xlim) < 0
        loop2 = find(params.analysis.sigmaMajor >= params.analysis.sigmaMajor(n) | ....
            (params.analysis.sigmaMajor < params.analysis.sigmaMajor(n)  &  params.analysis.x0 >= 0));
    elseif sign(params.analysis.xlim) > 0
        loop2 = find(params.analysis.sigmaMajor >= params.analysis.sigmaMajor(n) | ....
            (params.analysis.sigmaMajor < params.analysis.sigmaMajor(n)  &  params.analysis.x0 <= 0));
    end
        
    
    for ii=1:numel(loop2)
        %-----------------------------------
        % Now apply GLM, see *_oneGaussian for logic.
        % New rules for this one:
        % 1. both Gaussian have to be positive
        %-----------------------------------
        X     = [prediction(:,loop1(n)) prediction(:,loop2(ii)) trends];
        b     = pinv(X)*data;
        rss   = rssinf;
        keep  = b(1,:)>=0 & b(2,:)>=0;
        rss(keep) = sum((data(:,keep)-X*b(:,keep)).^2);
        
        %-----------------------------------
        %--- store data with lower rss
        %-----------------------------------
        minRssIndex = rss < model.rss;

        % now update
        model.x0(minRssIndex)       = params.analysis.x0(loop1(n));
        model.y0(minRssIndex)       = params.analysis.y0(loop1(n));
        model.s(minRssIndex)        = params.analysis.sigmaMajor(loop1(n));
        model.rss(minRssIndex)      = rss(minRssIndex);
        model.b([1 2 t_id],minRssIndex)    = b(:,minRssIndex);
        model.x02(minRssIndex)      = params.analysis.x0(loop2(ii));
        model.y02(minRssIndex)      = params.analysis.y0(loop2(ii));
        model.s2(minRssIndex)       = params.analysis.sigmaMajor(loop2(ii));
    end;
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


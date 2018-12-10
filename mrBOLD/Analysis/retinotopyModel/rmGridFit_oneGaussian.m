function model = rmGridFit_oneGaussian(model,prediction,data,params,t)
% rmGridFit_oneGaussian - core of one Gaussian fit
%
% model = rmGridFit_oneGaussian(model,prediction,data,params);
%
% 2008/01 SOD: split of from rmGridFit.

% input check 
if nargin < 4,
    error('Not enough arguments');
end

% some variables we need
%rssinf         = inf(size(data(1,:)),'single');
trends         = t.trends;
t_id           = t.dcid+1;

% we compute mean rss from the sum rss (old convention)
% Some explanation of the divisor would be helpful here.
model.rss = single(model.rss./(size(prediction,1)-(size(trends,2)+1)));  

%-----------------------------------
%--- fit different receptive fields profiles
%--- another loop --- and a slow one too
%-----------------------------------
tic; progress = 0;

%warning('off', 'MATLAB:lscov:RankDefDesignMat')

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
    %--- now apply glm to fit RF
    %-----------------------------------
    % minimum RSS fit
    
    X    = [prediction(:,n) trends];  % Build the model matrix
    
    % This line takes up 30% of the time
    % lscov takes as long as the pinv method but provides the rss as
    % well... Let's put in the ~.  All modern Matlab now uses it, and it
    % will save us memory space.
    [b,ci,rss]    = lscov(X,data); 
    
    % Compute RSS only for positive fits. The basic problem is
    % that if you have two complementary locations, you
    % could fit with a postive beta on the one that drives the signal or a
    % negative beta on the portion of the visual field that never sees the
    % stimulus. This would produce the same prediction. We don't like that
    nkeep   = (b(1,:)<0); % Now we only set the negative fits to inf.
    
    % To save time limit the rss computation to those we care about.
    rss(nkeep) = inf('single');
    
    %-----------------------------------
    %--- store data with lower rss
    %-----------------------------------
    minRssIndex = (rss < model.rss);  % This is where we use model.rss

    % now update model parameters for those cases in which the computed rss
    % is smaller than the input model.rss
    model.x0(minRssIndex)       = params.analysis.x0(n);
    model.y0(minRssIndex)       = params.analysis.y0(n);
    model.s(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_major(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_minor(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_theta(minRssIndex)        = params.analysis.theta(n);
    model.rss(minRssIndex)      = rss(minRssIndex);
    model.b([1 t_id],minRssIndex) = b(:,minRssIndex);
end

%warning('on', 'MATLAB:lscov:RankDefDesignMat')

% Under some conditions, the grid fit never returns an acceptable fit, For
% example for onegaussian fits with data driven DC component, when the DC
% is artificially high. In this case some of the rss values remain Inf,
% which fails to interpolate and compute correct variance explained values.
% So we check it here and reset any Inf (bad fits) to rawrss, so the
% variance explained will be 0.
model.rss(model.rss==Inf) = model.rawrss(model.rss==Inf);

% Correct lscov. It returns the mean rss. To maintain compatibility with
% the sum rss that this function expects, we have to multiply by the
% divisor. See the lscov docs for details.
model.rss = single(model.rss.*(size(prediction,1)-(size(trends,2)+1)));  

% end time monitor
et  = toc;
if floor(esttime/3600)>0,
    fprintf(1,'Done[%d hours].\t(%s)\n', ceil(et/3600), datestr(now));
else
    fprintf(1,'Done[%d minutes].\t(%s)\n', ceil(et/60), datestr(now));
end;
drawnow;

return;



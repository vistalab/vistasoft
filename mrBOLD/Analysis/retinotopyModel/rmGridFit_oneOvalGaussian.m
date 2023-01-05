function model = rmGridFit_oneOvalGaussian(model,prediction,data,params,t)
% rmGridFit_oneOvalGaussian - core of one oval Gaussian fit
%
% model = rmGridFit_oneOvalGaussian(model,prediction,data,params);
%
% 2008/08 KA incorporated asymmetric gaussian model to rmGridFit_oneGaussian.

% input check 
if nargin < 4,
    error('Not enough arguments');
end

% some variables we need
rssinf         = inf(size(data(1,:)),'single');
trends         = t.trends;
t_id           = t.dcid;

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
    %--- now apply glm to fit RF
    %-----------------------------------
    % minimum RSS fit
    X    = [prediction(:,n) trends];
    % This line takes up 30% of the time
    b    = pinv(X)*data;
    % reset RSS
    rss  = rssinf;
    % Compute RSS only for positive fits. The basic problem is
    % that if you have two complementary locations, you
    % could fit with a postive beta on the one that drives the signal or a
    % negative beta on the portion of the visual field that never sees the
    % stimulus. This would produce the same prediction. We don't like that
    keep   = b(1,:)>0;
    % To save time limit the rss computation to those we care about.
    % This line is takes up 60% of the time....
    rss(keep) = sum((data(:,keep)-X*b(:,keep)).^2);
    
    %-----------------------------------
    %--- store data with lower rss
    %-----------------------------------
    minRssIndex = rss < model.rss;
        
    % now update
    model.x0(minRssIndex)       = params.analysis.x0(n);
    model.y0(minRssIndex)       = params.analysis.y0(n);
    model.s(minRssIndex)        = (params.analysis.sigmaMajor(n)+params.analysis.sigmaMinor(n))/2;
    model.s_major(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_minor(minRssIndex)        = params.analysis.sigmaMinor(n);
    model.s_theta(minRssIndex)        = params.analysis.theta(n);
    model.rss(minRssIndex)      = rss(minRssIndex);
    model.b([1 t_id],minRssIndex) = b(:,minRssIndex);
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


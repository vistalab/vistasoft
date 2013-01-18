function view = rmGridFitPosOnly(view,params);
% rmGridFit - fit retinotopic model
%
% view=rmGridFit(view,params[,doPlot]);
%
% Brute force fitting of predictions based upon
%   (a) on/off stimulus sequence (if exists)
%   (b) premade receptive fields (rmDefineParams, x, y, sigma)
%   (c) both a and b.
% Negative fits are discarded for b.
%
% Output is saved in structure model, which should be accessed
% through rmSet and rmGet.
%
%
% 2005/12 SOD: wrote it.
% 2006/12 SOD: converted calculations to single precision. This
% speeds things up considerably and is kinder on memory use.
% 2007/03 SOD: incorporated true coarse to fine search and trimmed code
% considerably.

if notDefined('view'),   error('Need view struct'); end;
if notDefined('params'), error('Need params'); end;

%-----------------------------------
%--- For speed we do our computations in single precision.
%--- But we output in double (for compatibility).
%-----------------------------------
params.analysis.x0         = single(params.analysis.x0);
params.analysis.y0         = single(params.analysis.y0);
params.analysis.sigmaMajor = single(params.analysis.sigmaMajor);
params.analysis.X          = single(params.analysis.X);
params.analysis.Y          = single(params.analysis.Y);
params.analysis.allstimimages    = single(params.analysis.allstimimages);
params.analysis.sigmaRatio       = single(params.analysis.sigmaRatio);
params.analysis.sigmaRatioInfVal = single(params.analysis.sigmaRatioInfVal);
params.analysis.sigmaRatioMaxVal = single(params.analysis.sigmaRatioMaxVal);

%-----------------------------------
%--- make trends to fit with the model (dc, linear and sinewaves)
%-----------------------------------
% not sure we want to do that here.
[trends, ntrends]  = rmMakeTrends(params);
trends = rmDecimate(trends,params.analysis.coarseDecimate);
trends = single(trends);

%-----------------------------------
%--- now loop over slices
%--- but initiate stuff first
%-----------------------------------
switch lower(params.wData),
    case {'fig','roi'},
        loopSlices = 1;
    otherwise,
        % ras 07/07: now uses a separate analysis param, instead of stim
        % param:
        loopSlices = 1:params.analysis.nSlices;
end;
nSlices = length(loopSlices);


%-----------------------------------
%--- make all predictions first
%-----------------------------------
n = numel(params.analysis.x0);
s = [[1:ceil(n./100):n-2] n+1];
prediction = zeros(size(params.analysis.allstimimages,1),n,'single');
allstimimages = rmDecimate(params.analysis.allstimimages,...
    params.analysis.coarseDecimate);
fprintf(1,'[%s]:Making %d model samples:',mfilename,n);
drawnow;tic;
for n=1:numel(s)-1,
    % make rfs
    rf   = rfGaussian2d(params.analysis.X, params.analysis.Y,...
                            params.analysis.sigmaMajor(s(n):s(n+1)-1), ...
                            params.analysis.sigmaMajor(s(n):s(n+1)-1), ...
                            false, ...
                            params.analysis.x0(s(n):s(n+1)-1), ...
                            params.analysis.y0(s(n):s(n+1)-1));
    % convolve with stimulus
    pred = allstimimages*rf;
    
    % store
    prediction(:,s(n):s(n+1)-1) = pred;
    fprintf(1,'.');drawnow;
    if n==1,pack;end;
end;
prediction = rmDecimate(prediction,params.analysis.coarseDecimate);
clear n s rf pred;
fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
drawnow;

% go loop over slices
for slice=loopSlices,
    %-----------------------------------
    % Place datasets behind each other. This is a rather crude way of
    % stimultaneously fitting both. Due to this we cannot
    % prewhiten (we could zeropadd/let the trends deal with this/not care).
    %-----------------------------------
    [data, params] = rmLoadData(view, params, slice,...
                                params.analysis.coarseToFine);
    % for speed convert to single and remove NaNs (should not be
    % there anyway!), TO DO: remove NaN from data and put back
    % later, so computations are even faster.
    data(isnan(data)) = 0;
    data       = rmDecimate(data,params.analysis.coarseDecimate);
    data       = single(data);
    
    % remove trends from data so they do not count in the percent variance
    % explained calculation later.
    trendBetas = pinv(trends)*data;
    data       = data - trends*trendBetas;
    
    % compute rss raw data for variance computation later
    rssdata        = sum(data.^2);
    rssinf         = inf(size(rssdata),'single');
    
    %-----------------------------------
    % initiate stuff on first loop
    %-----------------------------------
    if slice == 1,
        fprintf(1,'[%s]:Number of voxels: %d.\n',mfilename,size(data,2));drawnow;
        model = initiateModel(params, nSlices, size(data,2), ntrends);
        if isfield(params.stim(1),'stimOnOffSeq'),
            % make stim on/off sequence
            stim = [];
            for ii = 1:numel(params.stim),
                stim = [stim; params.stim(ii).stimOnOffSeq];
            end;
        end;
        % This seems double but it is not because modifications to the
        % params struct are not saved but to the model struct are.
        if strcmp(params.wData,'roi');
            for mm = 1:numel(model),
                model{mm} = rmSet(model{mm},'roiCoords',rmGet(params,'roiCoords'));
                model{mm} = rmSet(model{mm},'roiIndex',rmGet(params,'roiIndex'));
                model{mm} = rmSet(model{mm},'roiName',rmGet(params,'roiName'));
            end;
        end;
        % put in number of data points. Right now this is the same as
        % size(data,1), but this will not be the case if we zero-padd!
        for mm = 1:numel(model),
          model{mm} = rmSet(model{mm},'npoints',size(data,1));
         
        end;
    end;

    %-----------------------------------
    % now we extract only the data from that slice and put it in a
    % temporary structure that will be modified throughout.
    %-----------------------------------
    s = extractSlice(model,slice);

    % initiateModel fills the rss-field with Infs. We reset them here
    % to a more data-driven maximum value of sum(data.^2)
    % also make all contrasts here
    for n=1:numel(s),
        findinf           = isnan(s{n}.rss);
        s{n}.rss(findinf) = rssdata(findinf);
        s{n}.rawrss       = double(rssdata);
    end;
    clear findinf;

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
                if slice==1,
                    esttime = toc.*10.*nSlices;
                    if floor(esttime./3600)>0,
                        fprintf(1,'[%s]:Estimated processing time: %d hours.\t(%s)\n',...
                            mfilename, ceil(esttime./3600), datestr(now));
                    else,
                        fprintf(1, '[%s]:Estimated processing time: %d minutes.\t(%s)\n',...
                            mfilename, ceil(esttime./60), datestr(now));
                    end;
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
        X      = [prediction(:,n) trends];
        % This line takes up 30% of the time
        m.b    = pinv(X)*data;
        % reset RSS
        m.rss  = rssinf;
        % Compute RSS only for positive fits. The basic problem is
        % that if you have two complementary locations, you
        % could fit with a postive beta on the one that drives the signal or a
        % negative beta on the portion of the visual field that never sees the
        % stimulus. This would produce the same prediction. We don't like that
        keep   = m.b(1,:)>0;
        % To save time limit the rss computation to those we care about.
        % This line is takes up 60% of the time....
        m.rss(keep) = sum((data(:,keep)-X*m.b(:,keep)).^2);
        % store
        s{1}        = updateModel(m,s{1},...
                                  params.analysis.x0(n),...
                                  params.analysis.y0(n),...
                                  params.analysis.sigmaMajor(n));

        %-----------------------------------
        %--- try two rf profiles, yet another loop
        %-----------------------------------
        if doSecondModel,
            %-----------------------------------
            %--- first make all second rf profiles
            %-----------------------------------
            sigmaNew = params.analysis.sigmaRatio.*params.analysis.sigmaMajor(n);
            % limit to sigmaRatioMaxVal
            sigmaNew = sigmaNew(sigmaNew<=params.analysis.sigmaRatioMaxVal);
            % add sigmaRatioInfVal which essentially is on/off
            sigmaNew = [sigmaNew; params.analysis.sigmaRatioInfVal];

            % Now we make it: slightly different call for speed reasons.
            tmprf   = rfGaussian2d(params.analysis.X - params.analysis.x0(n),...
                                   params.analysis.Y - params.analysis.y0(n),...
                                   sigmaNew,sigmaNew, ...
                                   false, false, false);
            prediction2 = params.analysis.allstimimages*tmprf;

            for sr = 1:numel(sigmaNew),
                %-----------------------------------
                % Now apply GLM, see above for logic. 
                % New rules for this one:
                % 1. first Gaussian has to be positive
                % 2. there should be a positive response in the
                % center at all times. This
                % assumes Gaussians are unscaled (see rfGaussian2d).
                %-----------------------------------
                X2     = [prediction(:,n) prediction2(:,sr) trends];
                m2.b   = pinv(X2)*data;
                m2.rss = rssinf;
                keep   = m2.b(1,:)>0 & m2.b(1,:)>-m2.b(2,:);
                m2.rss(keep) = sum((data(:,keep)-X2*m2.b(:,keep)).^2);
                % store
                s{2}         = updateModel(m2,s{2},...
                                           params.analysis.x0(n),...
                                           params.analysis.y0(n),...
                                           params.analysis.sigmaMajor(n),...
                                           sigmaNew(sr));
            end;
        end;
    end;

    %-----------------------------------
    % now put back the trends to the fits
    %-----------------------------------
    for mm=1:numel(s),
        nB = size(s{mm}.b,1);
        s{mm}.b(nB-ntrends+1:end,:) = s{mm}.b(nB-ntrends+1:end,:)+trendBetas;
    end
    
    %-----------------------------------
    % now we put back the temporary data from that slice
    %-----------------------------------
    model = putSlice(model,s,slice);

    % end time monitor
    et  = toc;
    if floor(esttime/3600)>0,
        fprintf(1,'Done[%d hours].\t(%s)\n', ceil(et/3600), datestr(now));
    else,
        fprintf(1,'Done[%d minutes].\t(%s)\n', ceil(et/60), datestr(now));
    end;
    drawnow;
end;


%-----------------------------------
% recreate complete model if we used coarse sampling
%-----------------------------------
if params.analysis.coarseToFine,
  model = rmInterpolate(view, model, params);
end;

%-----------------------------------
% save and return output (if run interactively)
%-----------------------------------
rmFile = rmSave(view,model,params,1,'gFit');
view = viewSet(view,'rmFile',rmFile);


% that's it
return;
%-----------------------------------

%-----------------------------------
function [model]=updateModel(newmodel,model,x0,y0,s,s2);

minRssIndex = newmodel.rss < model.rss;

% now update
model.x(minRssIndex)        = x0;
model.y(minRssIndex)        = y0;
model.s(minRssIndex)        = s;
model.rss(minRssIndex)      = newmodel.rss(minRssIndex);
model.b(:,minRssIndex)      = newmodel.b(:,minRssIndex);
if nargin == 6,
    model.s2(minRssIndex)   = s2;
end;
return;
%-----------------------------------

%-----------------------------------
function tmp = extractSlice(model,slice);
% some code to extract slice from model struct and place it
% into temporary struct, also convert to single here.

% loop over models
for n=1:numel(model),

    if n==1, % retinotopy
        f = {'x','y','s','rss'};
    else,
        f = {'x','y','s','s2','rss'};
    end;

    % for all models
    tmp{n}.desc = rmGet(model{n},'desc');
    tmp{n}.df   = single(rmGet(model{n},'dfglm'));
    for fn = 1:numel(f),
        val    = rmGet(model{n},f{fn});
        if ~isempty(val),
            tmp{n}.(f{fn}) = single(val(slice,:));
        end;
    end;

    % put all beta values in one matrix
    val      = rmGet(model{n},'b');
    tmp{n}.b = zeros(size(val,3),size(val,2),'single');
    for fn = 1:size(val,3),
        tmp{n}.b(fn,:) = single(val(slice,:,fn));
    end;
end;

return;
%-----------------------------------

%-----------------------------------
function model = putSlice(model,tmp,slice);
% some code to put slice info into model struct
% we convert back to double precision here.

% loop over models
for n=1:numel(model),
    if n==1, % retinotopy only
      ftmp = {'x','y','s','rss','rawrss'};
      model{n} = rmSet(model{n},'dfcorr',double(tmp{n}.df)-3); % for x,y,s
    else, % both
      ftmp = {'x','y','s','s2','rss','rawrss'};
      model{n} = rmSet(model{n},'dfcorr',double(tmp{n}.df)-4); % for x,y,s,s2
    end;
    fput = ftmp;

    % now get values from model and put in new slice values
    for fn = 1:numel(ftmp),
        val             = rmGet(model{n},fput{fn});
        if ~isempty(val),
            val(slice,:)  = double(tmp{n}.(ftmp{fn}));
            model{n}      = rmSet(model{n},fput{fn},val);
        end;
    end;
    model{n}       = rmSet(model{n},'dfglm',double(tmp{n}.df));

    % distribute beta values
    val      = rmGet(model{n},'b');
    for fn = 1:size(val,3),
        val(slice,:,fn) = double(tmp{n}.b(fn,:));
    end;
    model{n} = rmSet(model{n},'b',val);

end;
return;
%-----------------------------------

%-----------------------------------
function model = initiateModel(params,d1,d2,nt);
% make the model struct with rmSet
fillwithzeros       = zeros(d1,d2);
fillwithzerostrends = zeros(d1,d2,nt);
fillwithinfs        = ones(d1,d2).*Inf;

% check how many models are requested
nModels = 1;
if ~isempty(params.analysis.sigmaRatio),
    nModels = 2;
    
end;

% retinotopy
for n=1:nModels,
    model{n} = rmSet;
    model{n} = rmSet(model{n},'x'   ,fillwithzeros);
    model{n} = rmSet(model{n},'y'   ,fillwithzeros);
    model{n} = rmSet(model{n},'s'   ,fillwithzeros);
    model{n} = rmSet(model{n},'rawrss',fillwithzeros);
    model{n} = rmSet(model{n},'rss' ,fillwithinfs);
    model{n} = rmSet(model{n},'df'  ,0);
    model{n} = rmSet(model{n},'ntrends',nt);
    % store hrf too since it is part of the model
    % fix me: we need to store all HRFs for each stimuli.
    % We could just store the entire params.stim struct.
    model{n} = rmSet(model{n},'whrf'     ,params.stim(1).hrfType);
    model{n} = rmSet(model{n},'hrfparams',params.stim(1).hrfParams);
    model{n} = rmSet(model{n},'hrfmax'   ,params.analysis.HrfMaxResponse);
    if n==1,
        model{n} = rmSet(model{n},'b'   ,zeros(d1,d2,nt+1));
    else,
        model{n} = rmSet(model{n},'s2'  ,fillwithzeros);
        model{n} = rmSet(model{n},'b'   ,zeros(d1,d2,nt+2));
    end;
end;
% model names
model{1} = rmSet(model{1},'desc','2D RF (x,y,sigma) fit (positive only)');
if nModels==2,
    model{2} = rmSet(model{2},'desc',...
        'Double 2D RF (x,y,sigma) fit (positive only)');
end;

return;
%-----------------------------------

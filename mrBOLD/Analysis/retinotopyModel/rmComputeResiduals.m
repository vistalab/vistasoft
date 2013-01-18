function [data s] = rmComputeResiduals(view,params,s,slice,coarse)
% rmComputeResiduals - compute residuals after a one Gaussian fit
%
% [data s] = rmComputeResiduals(view,params,s,slice,coarse)
%
% Load's data set and refits the parameters and computer residuals. These
% residuals are then output as 'data'.

% 2008/04 SOD: wrote it.

if ~exist('view','var') || isempty(view),     error('Need view');   end;
if ~exist('params','var') || isempty(params), error('Need params'); end;
if ~exist('s','var') || isempty(s),           error('Need s');      end;
if ~exist('slice','var') || isempty(slice),   slice = 1;            end;
if ~exist('coarse','var') || isempty(coarse), coarse = false(2,1);  end;

% [spatial; temporal] coarse sampling
if numel(coarse)==1, coarse = [coarse;coarse]; end

% get file with models
rmFile = viewGet(view,'rmFile');

% save rmFile so we know which file was used. we do this by growing the
% variable:
params.matFileName = {rmFile params.matFileName{:}};

% Load previous model, but not params since these are allowed to be
% redefined every time. It is the model that is transferable
% between every scan of the same subject but not the exact
% parameters.
tmp = load(rmFile);
model = tmp.model;
modelId = 1;
if numel(model)>1
    for n=1:numel(model),
        switch lower(rmGet(tmp.model{n},'desc'))
            case {'2d prf fit (x,y,sigma, positive only)',...
                    'sequential 2D prf fit (2*(x,y,sigma, positive only))'}
                modelId = n;
                break;
        end
    end
end

% load data without 'coarse' processing
p2 = params; p2.wData = 'all'; 
data = rmLoadData(view,p2,slice,false);

%-----------------------------------
%--- remove make trends
%-----------------------------------
[trends nt dcid] = rmMakeTrends(params);
trendBetas       = pinv(trends)*data;
data             = data - trends*trendBetas;



%-----------------------------------
%--- get data
%-----------------------------------
switch s.desc
    case {'Sequential 2D pRF fit (2*(x,y,sigma, positive only))',...
          'Linked sequential 2D pRF fit (2*(x,y,sigma, positive only))'}
        s.b = zeros(nt+2,size(trendBetas,2));
        s.b(3:2+size(trendBetas,1),:) = trendBetas;
        dcid = dcid + 2;
    otherwise
        s.b = zeros(nt+1,size(trendBetas,2));
        s.b(2:2+size(trendBetas,1),:) = trendBetas;
        dcid = dcid + 1;
end

% swap pRF order: x0->x02 if x02 does not exist in the model (s2)
s2 = rmSliceGet(model,slice,modelId);
if ~any(s.x02) && ~any(s.y02)
    fprintf(1,'[%s]:Transferring estimates.\n',mfilename);
    s.x02   = s2{1}.x0;
    s.y02   = s2{1}.y0;
    s.s2    = s2{1}.s;
    s.rss2  = s2{1}.rss;
    s.rawrss2 = s2{1}.rawrss;

    s.s2(s.s2<=0) = 0.001;
else
    fprintf(1,'[%s]:Using second estimates.\n',mfilename);
end


%-----------------------------------
%--- recompute fit
%-----------------------------------
t = trends(:,dcid);
denom = -2.*(s.s2.^2);
fprintf(1,'[%s]:Recomputing...',mfilename);
drawnow;tic;
for n=1:numel(s.x02),
    % refit
    Xv = params.analysis.X-s.x02(n);
    Yv = params.analysis.Y-s.y02(n);
    rf = exp( (Yv.*Yv + Xv.*Xv) ./ denom(n) );
    X = [params.analysis.allstimimages*rf t];
    b    = pinv(X)*data(:,n);
    b(1) = max(b(1),0);
    
    % replace data with residuals
    data(:,n) = data(:,n)-X*b;
    
    % store
    s.rss2(n)  = norm(data(:,n)).^2;
    s.b([2 dcid],n)  = s.b([2 dcid],n) + b;
end;
fprintf(1, 'Done[%d min].\t(%s)\n', round(toc/60), datestr(now));
drawnow;

%-----------------------------------
%--- preprocessing of residuals
%-----------------------------------
switch lower(params.wData),
    case {'all'}
        if coarse(1),
            % smooth
            data = dhkGraySmooth(view,data,params.analysis.coarseBlurParams(1,:));

            % sparsely sample
            coarseIndex = rmCoarseSamples(viewGet(view,'coords'),params.analysis.coarseSample);
            data = data(:,coarseIndex);
            
            % update b
            s.b = s.b(:,coarseIndex);
        end
            
        if coarse(2)
            % decimate
            data       = rmDecimate(data,params.analysis.coarseDecimate);
            data       = single(data);
        end;

    case {'roi'}
        if coarse(1)
            data = dhkGraySmooth(view,data,params.analysis.coarseBlurParams(1,:));
            coarseIndex = rmCoarseSamples(rmGet(params,'roicoords'),params.analysis.coarseSample);
            roiIndex = rmGet(params,'roiIndex');
            if ~isempty(roiIndex),
                data  = data(:,roiIndex(coarseIndex));
                s.b = s.b(:,roiIndex(coarseIndex));
            end
        else
            roiIndex = rmGet(params,'roiIndex');
            if ~isempty(roiIndex),
                data  = data(:,roiIndex);
                s.b = s.b(:,roiIndex);
            end
        end
        
        if coarse(2)
            data       = rmDecimate(data,params.analysis.coarseDecimate);
            data       = single(data);
        end;
end

% reset rawrss
s.rawrss = sum(data.^2);

return






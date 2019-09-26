function [range TolFun] = rmSearchFit_range(params,model,data)
% rmSearchFit_range - estimate boundaries for fmincon
%  
% boundary = rmSearchFit_boundary(params,startparams)
%
% 2010 SOD: split off from rmSearchFit_oneGaussian

if ~exist('params','var') || isempty(params), error('Need params');  end
if ~exist('model','var')  || isempty(model),  error('Need model');   end

%---general parameters
expandRange = params.analysis.fmins.expandRange;

%--- start point from grid fit
if isfield(model, 's_minor')
    range.start = [model.x0; model.y0; model.s_major; model.s_minor; model.s_theta];
else
    range.start = [model.x0; model.y0; model.s];
end
range.lower = zeros(size(range.start));
range.upper = zeros(size(range.start));
range.step  = zeros(size(range.start(1,:)));

%--- position range (x,y)
if params.analysis.scaleWithSigmas,
    step = params.analysis.relativeGridStep.*range.start(3,:);
    minstep = params.analysis.maxXY./2./params.analysis.minimumGridSampling;
    step = min(step,minstep);
    maxstep = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
    step = max(step,maxstep);
else
    step = (params.analysis.maxXY./2./params.analysis.maximumGridSampling).*ones(size(range.start(1,:)));
end
range.step = step;
step = ones(2,1)*step;
range.upper([1 2],:) = range.start([1 2],:) + step.*expandRange;
range.lower([1 2],:) = range.start([1 2],:) - step.*expandRange;

%--- sigma range (s)
% first get original sigmas from grid fit
gridSigmas_unique = unique(params.analysis.sigmaMajor);

% add min and max limit:
% FIX ME: 0.01 should not be hardcoded here...
gridSigmas = [0.01.*ones(expandRange,1); ...
              gridSigmas_unique; ...
              params.analysis.maxRF.*ones(expandRange,1)];
gridSigmas = double(gridSigmas);

% matrix form
gridSigmas_matrix  = gridSigmas_unique(:)*ones(1,size(range.start,2));
startSigmas_matrix = ones(size(gridSigmas_matrix,1),1)*range.start(3,:);

% interpolated sigmas, so we'll look for the closest one.
[tmp, closestvalue] = sort(abs(gridSigmas_matrix-startSigmas_matrix));

% make sure closest value (1) is within valid range
closestvalue    = closestvalue(1,:)+expandRange;

% set boundary
range.upper(3,:) = gridSigmas(closestvalue+expandRange);
range.lower(3,:) = gridSigmas(closestvalue-expandRange);

% set boundary for second gaussian or minor axis (can't fit both yet)
if isfield(model, 's_minor')
    gridSigmas_unique = unique(params.analysis.sigmaMinor);
    % add min and max limit:
    % FIX ME: 0.01 should not be hardcoded here...
    gridSigmas = [0.001.*ones(expandRange,1); ...
        gridSigmas_unique; ...
        params.analysis.maxRF.*ones(expandRange,1)];
    gridSigmas = double(gridSigmas);
    gridSigmas_matrix  = gridSigmas_unique(:)*ones(1,size(range.start,2));
    startSigmas_matrix = ones(size(gridSigmas_matrix,1),1)*range.start(4,:);
    [tmp, closestvalue] = sort(abs(gridSigmas_matrix-startSigmas_matrix));
    closestvalue    = closestvalue(1,:)+expandRange;
    range.upper(4,:) = gridSigmas(closestvalue+expandRange);
    range.lower(4,:) = gridSigmas(closestvalue-expandRange);
    
    range.upper(5,:)=range.start(4,:)+(0.5*pi);
    range.lower(5,:)=range.start(4,:)-(0.5*pi);
elseif isfield(model,'s2')
    range.start(4,:) = model.s2;
    range.lower(4,:) = range.lower(3,:).*params.analysis.minSigmaRatio;
    range.upper(4,:) = ones(size(range.upper(3,:))).*params.analysis.sigmaRatioInfVal;
end

if isfield(model, 'exp')
    fieldnum=size(range.start, 1)+1;
    range.start(fieldnum,:) = model.exp;
    gridExps_unique=unique(params.analysis.exp);
    gridExps=[min(gridExps_unique).*ones(expandRange,1); gridExps_unique; max(gridExps_unique).*ones(expandRange,1)];
    gridExps=double(gridExps);
    gridExps_matrix  = gridExps_unique(:)*ones(1,size(range.start,2));
    startExps_matrix = ones(size(gridExps_matrix,1),1)*range.start(fieldnum,:);
    [tmp, closestvalue] = sort(abs(gridExps_matrix-startExps_matrix));
    closestvalue    = closestvalue(1,:)+expandRange;

    range.upper(fieldnum,:) = gridExps(closestvalue+2);%expandRange);
    range.lower(fieldnum,:) = gridExps(closestvalue-2);%expandRange);
end

% reset stopping criteria relative to rawrss
if exist('data','var') && ~isempty(data)
    % raw rss computation (similar to norm) and TolFun adjustments
    rawrss = sqrt(sum(data.^2));
    TolFun = params.analysis.fmins.options.TolFun.*rawrss;
end

return

function [range, TolFun] = rmSearchFit_range(params,model,data)
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
range.start = [model.x0; model.y0; model.s];
range.lower = zeros(size(range.start));
range.upper = zeros(size(range.start));
range.step  = zeros(size(range.start(1,:)));

%--- position range (x,y)
if params.analysis.scaleWithSigmas,
    step    = params.analysis.relativeGridStep.*range.start(3,:);
    minstep = params.analysis.maxXY./2./params.analysis.minimumGridSampling;
    step    = min(step,minstep);
    maxstep = params.analysis.maxXY./2./params.analysis.maximumGridSampling;
    step    = max(step,maxstep);
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
[~, closestvalue] = sort(abs(gridSigmas_matrix-startSigmas_matrix));

% make sure closest value (1) is within valid range
closestvalue    = closestvalue(1,:)+expandRange;

% set boundary
range.upper(3,:) = gridSigmas(closestvalue+expandRange);
range.lower(3,:) = gridSigmas(closestvalue-expandRange);

% set boundary for second gaussian
if isfield(model,'s2')
    range.start(4,:) = model.s2;
    range.lower(4,:) = range.lower(3,:).*params.analysis.minSigmaRatio;
    range.upper(4,:) = ones(size(range.upper(3,:))).*params.analysis.sigmaRatioInfVal;
end

% set boundary for exponent
if isfield(params.analysis,'nonlinear') && params.analysis.nonlinear
    range.start(4,:) = model.exponent;
    % limit exponent to [0.01 2]? this should be a parameter in the model definition, not buried all the way in here
    range.lower(4,:) = range.lower(3,:)*0 + 0.01;
    range.upper(4,:) = range.lower(3,:)*0 + 2; 
    
    % sigma also need a big range, because if the exponent is changed by
    % the search, the sigma will need to change too to prevent the pRF size
    % from changing too much
    range.lower(3,:) = range.lower(3,:)*0;
    range.upper(3,:) = range.lower(3,:)*0 + params.analysis.maxRF; 

end


% reset stopping criteria relative to rawrss
if exist('data','var') && ~isempty(data)
    % raw rss computation (similar to norm) and TolFun adjustments
    rawrss = sqrt(sum(data.^2));
    TolFun = params.analysis.fmins.options.TolFun.*rawrss;
end

return

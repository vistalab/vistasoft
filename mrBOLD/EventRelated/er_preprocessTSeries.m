function tSeries = er_preprocessTSeries(tSeries,params,dataRange,varargin);
%
% tSeries = er_preprocessTSeries(tSeries,params,[dataRange],[options]);
%
% Perform preprocessing of a tSeries, given a set
% of event-related analysis params (see er_getParams).
% Return tSeries in units of percent signal change.
%
% This consists of 'standard' things like detrending,
% inhomogeneity correction and temporal normalization, but
% is open to newer analyses, like outlier detection, if
% this becomes desirable.
%
% dataRange: optional 2-vector giving min and max range with
% which to scale data. (see er_voxelData). Default: leave unchanged.
%
% The optional arguments can be used (when I implement it :)
% for inhomogeneity correction. If the params.inhomoCorrect flag
% is set to 2 (divide by null condition), you'll need to pass in
% a trials struct (see er_concatParfiles). If it's set to 3
% (divide by spatial gradient estimate), you'll need to
% pass in 2 arguments: the (4th total) argument should be
% the map for this scan, and the (5th) should be the
% coordinates from which the columns of the tSeries were taken,
% and from which the spatial gradient should be loaded.
% [if this option is actually useful, I'll make it nicer.]
%
% ras 04/05.
if nargin < 2
    help er_preprocessTSeries
    return
end

if notDefined('dataRange')
    dataRange = [min(tSeries(:)) max(tSeries(:))];
end

% ensure tSeries is a double w/ the proper range
if isa(tSeries, 'int16')
    tSeries = normalize(double(tSeries), dataRange(1), dataRange(2));
end

% temporal normalization
if params.temporalNormalization==1
    disp('Temporal normalization to first frame');
    tSeries = doTemporalNormalization(tSeries);
end

% inhomogeneity correction
nFrames = size(tSeries,1);
switch params.inhomoCorrect
    case 0
        % do nothing
    case 1
        % divide by mean separately at each voxel
        dc = mean(tSeries);
        tSeries = tSeries./(ones(nFrames,1)*dc);
    case 2
        % this should be easy w/ a trials struct
        error('Inhomogeneity correction by null condition not yet implemented.');
    case 3
        % divide by spatial gradient estimate
        if isempty(varargin)
            help(mfilename);
            error('No spatial gradient map provided.');
        end
        gradientImg = varargin{1};
        coords = varargin{2};
        ind = sub2ind(size(gradientImg), coords(1,:), coords(2,:), coords(3,:));
        
        % allow for some NaNs indices: this may occur if you're
        % using the preserveCoords option (e.g., to compare data
        % between two data sets, when data isn't available for 
        % some voxels / sessions):
        dc = repmat(NaN, [1 size(tSeries, 2)]);
        
        ok = find(~isnan(ind));
        dc(ok) = gradientImg(ind(ok));
        
        % finally, divide by the DC estimate:
        tSeries = tSeries ./ (ones(nFrames,1) * dc);
        
    otherwise
        msg = sprintf('Invalid option for inhomogeneity correction: %s',...
                       params.inhomoCorrect);
        error(msg);
end

% detrend
tSeries = detrendTSeries(tSeries,params.detrend,params.detrendFrames);

% convert to % signal change
if params.inhomoCorrect ~= 0
    tSeries = tSeries - ones(nFrames,1)*mean(tSeries);
    tSeries = 100*tSeries;
end

return

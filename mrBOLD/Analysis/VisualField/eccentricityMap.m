function [view, mapvol, covol] = eccentricityMap(view, dt, scans, method);
%
% [view, map, co] = eccentricityMap(view, <dt, scans, method);
%
% AUTHOR: rory
% PURPOSE:
% Given corAnal data for an eccentricity-mapping experiment
% (single scan or set of scans), produce a parameter map of preferred
% eccentricity in units of degrees of visual field.
%
% If a single scan is provided as input, this function saves the
% parameter map in the scan's data type, assigning it only for that
% scan.
%
% However, if multiple input scans are provided (see below),
% the code saves the results in a new data type 'Meta_Analysis'.
% corAnal data from each scan are first converted into real-world
% units, then overlapping data are averaged together in a weighted
% average, based on each scan's coherence. (I.e., if one scan's
% co values for a given voxel are much higher than other scans,
% it will dominate the determination of what eccentricity is represented.)
%
% I wrote this code to use in conjunction with my across-session
% tools (createCombinedSession, importTSeries) to run meta-analyses
% on retinotopy data.
%
% ARGUMENTS:
%   INPUT:
%   view: mrVista view. <Defaults to selected gray view>
%   dt: for a single scan, name or number of the data type
%       from which the input data come. If analyzing multiple
%       scans, a cell of length nScans of data type names/numbers.
%       <default: cur data type>
%
%   scans: scan or scans to use as input. <default: cur scan>
%
%   method: which method to use when combining across multiple scans.
%         can be 'average', use weighted average with co field as the
%         weight, or 'wta', winner-take-all: each voxel's eccentricity
%         is determined by the scan with the highest co value.
%         <default: 'average'>
%
%   OUTPUT:
%   view: mrVista view, set to the relevant data type / scan and with
%         the map loaded and set to map mode.
%
%   map: the map volume produced (but not the cell-of-scans set in the
%        view, the numeric matrix).
%
%   co: the maximum coherence at each voxel, across all the input scans.
%       (It may be more sensible to make this the mean, but I'm trying
%       max for now.) Same format as map.
%
%
% ras, 01/10/06.
if notDefined('view'),  view = getSelectedGray;                 end
if notDefined('dt'),    dt = viewGet(view, 'curDataType');      end
if notDefined('scans'), scans = viewGet(view, 'curScan');       end
if notDefined('method'), method = 'average';                    end

params = retinoCheckParams(view, dt, scans);
mapName = 'Eccentricity (degrees)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with single input scan instances separately %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(scans)==1
    % this should be easy: just convert the corAnal values into
    % degrees of eccentricity
    view = selectDataType(view, dt);
    corAnalPath = fullfile(dataDir(view), 'corAnal.mat');
    if ~exist(corAnalPath, 'file')
        error('corAnal not found. Run computeCorAnal first.');
    end
    load(corAnalPath, 'ph', 'co');

    % map from corAnal ph to polar angle
    mapvol = eccentricity(ph{scans}, params); 
    
    % -1 values indicate response during a blank period --
    % zero out the co value for these
    co{scans}(mapvol==-1) =  0;

    % make and set the parameter map
    mapPath = fullfile(dataDir(view), 'Eccentricity_Map.mat');
    if exist(mapPath, 'file')
        load(mapPath, 'map', 'co');
    else
        map = cell(1, numScans(view));
    end

    map{scans} = mapvol;
    
    % let's set the map colormap to be the same as the phase mode
    % colormap, and save this with the map
    if checkfields(view, 'ui', 'phMode')
        view.ui.mapMode.cmap = view.ui.phMode.cmap;
    end

    view = setParameterMap(view, map, mapName);
    saveParameterMap(view, mapPath, 1, 1);
    
    % that should be it!
    if nargout>=3, covol = co{scans}; end
    view = refreshScreen(view);
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if we get here, we have multiple scans: parse the arguments to    %
% be cell arrays, and get set up:                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nScans = length(scans);

if ~iscell(dt)
    mrGlobals;
    % assume a single dt is specified, and all the scans are
    % coming from that data type
    for i = 1:nScans
        if isnumeric(dt), tmp{i} = dataTYPES(dt).name;
        else,             tmp{i} = dt;
        end
    end
    dt = tmp; clear tmp;
else
    for i = 1:nScans
        if isnumeric(dt{i}), dt{i} = dataTYPES(dt{i}).name; end
    end
end

%%%%%Get corAnal volumes for each input scan
srcCo = cell(1, nScans); srcPh = cell(1, nScans);
uniqueDts = unique(dt);
for i = 1:length(uniqueDts)
    corAnalPath = fullfile(viewDir(view), uniqueDts{i}, 'corAnal.mat');
    if ~exist(corAnalPath, 'file')
        error('corAnal not found. Run computeCorAnal first.');
    end
    load(corAnalPath, 'co', 'ph', 'amp')
    
    I = cellfind(dt, uniqueDts{i});
    srcCo(I) = co(scans(I));
    srcPh(I) = ph(scans(I));
    srcAmp(I) = amp(scans(I));
end

%%%%%Set up the target data type for the multi-scan meta-analysis
view = initScan(view, 'Meta_Analysis', [], {dt{1} scans(1)});
view = selectDataType(view, 'Meta_Analysis');
view = setCurScan(view, numScans(view));
view = setAnnotation(view, sprintf('Meta Analysis for %s scans %s', ...
                                dt{1}, num2str(scans)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the Eccentricity Map %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%Set NaNs to zero -- will be ignored
for i = 1:nScans
    srcCo{i}(isnan(srcCo{i})) = 0;
    srcAmp{i}(isnan(srcAmp{i})) = 0;
    srcPh{i}(isnan(srcPh{i})) = 0;
end

%%%%%Convert each phase map into real-word units
for i = 1:nScans
    srcPh{i} = eccentricity(srcPh{i}, params(i));
end

%%%%%Set up the weighted average
% we'll need a volume representing the sum of the coherence
% for each voxel, across input scans. This will serve as the
% denominator of the weight formula for each input scan.
coSum = zeros(size(srcCo{1}));
for i = 1:nScans, coSum = coSum + srcCo{i}; end

%%%%%initialize the map and co volumes
mapvol = zeros(size(srcCo{1}));
covol = zeros(size(srcCo{1}));

%%%%%compute co volume as the max across all input co volumes
for i = 1:nScans, covol = max(covol, srcCo{i}); end

%%%%%Compute the weighted average, iteratively across input scans
for i = 1:nScans
    if isequal(method, 'average')   % weighted average by coherence
        mapvol = mapvol + (srcPh{i} .* srcCo{i} ./ coSum);
    else                            % winner-take-all
        % scan with the
        % highest co value for a given voxel determines the map
        % value at that voxel.
        Imax = find(srcCo{i}==covol);
        mapvol(Imax) = srcPh{i}(Imax);    
    end
end

%%%%%-1 values indicate response during a blank period --
%%%%%zero out the co value for these
covol(mapvol==-1) =  0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output the parameter map %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize the output map and co data fields, loading it if it 
% already exists:
mapPath = fullfile(dataDir(view), 'Eccentricity_Map.mat');
if exist(mapPath, 'file')
    load(mapPath, 'map', 'mapName', 'co');
else
    map = cell(1, numScans(view));
    co = cell(1, numScans(view));
end

% append the map volume for the new scans
map{numScans(view)} = mapvol;
co{numScans(view)} = covol;

% before saving the map, copy the view's phase mode color map
% to the map mode, which will also be saved:
if checkfields(view, 'ui', 'phMode')
    view.ui.mapMode.cmap = view.ui.phMode.cmap;
end

% set the map in the view, and save it
view = setParameterMap(view, map, mapName);
saveParameterMap(view, mapPath, 1, 1);
save(mapPath, 'co', '-append'); % also add the co field
view = refreshScreen(view);

% also set corAnal amp and ph fields, and save a corAnal, so 
% we can view in that mode as well (nice colorbar, can ph-restrict)
% we map the ph back from degrees to radians:
phvol = deg2rad(mapvol);
ampvol = srcAmp{1};
if exist(fullfile(dataDir(view), 'corAnal.mat'), 'file')
    view = loadCorAnal(view);
end
view.ph{numScans(view)} = phvol;
view.amp{numScans(view)} = ampvol;
view.co{numScans(view)} = covol;
view = saveCorAnal(view, 1);

newParams.type = 'eccentricity';      % set new params such that
newParams.startAngle = 0;             % phase mode shows nice range
newParams.endAngle = max(mapvol(:));  % of eccentricity values
newParams.blankPeriod = 'none';        
newParams.dutyCycle = 1;  
newParams.width = 0;  
retinoSetParams(view, 'Meta_Analysis', numScans(view), newParams);

% show a legend if requested
if legend, polarAngleMapLegend(view); end

% ok, think that's it!

return


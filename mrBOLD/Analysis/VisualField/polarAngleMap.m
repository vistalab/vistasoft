function [view, mapvol, covol] = polarAngleMap(view, dt, scans, params, legend, W);
%
% [view, map, co] = polarAngleMap(view, <dt, scans, params>, <legend>, <W>);
%
% AUTHOR: rory
% PURPOSE:
% Given corAnal data for a polar angle ("meridian")-mapping experiment
% (single scan or set of scans), produce a parameter map of preferred
% polar angle in units of degrees of visual field.
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
% it will dominate the determination of what angle is represented.)
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
%   params: struct (or nScans-long struct array) specifying how
%       the stimulus mapped polar angle during each scan. Needs 
%       the following fields:
%       params.startAngle: angle of center of wedge stimulus, measured
%           in degrees clockwise from 12-o-clock, at the start of each
%           cycle;
%       params.width: width of wedge stimulus in degrees.
%       params.direction: 'cw' or 'ccw', direction in which the stimulus
%       proceeded. (cw=clockwise or ccw=counterclockwise).
%       params.visualField: number of degrees the stimulus traversed
%       each cycle (e.g., 360 if it went all the way around).
%       <default: get these params using retinoCheckParams>
%       
%   legend: optional flag which, if set to 1, provides for a separate
%       figure with a legend image to go with the polar angle map.
%       <default 0, don't show this>
%
%   W: optional vector of weights for each input scan, for use when 
%       doing a meta-analysis across scans. The vector should be
%       the same length as the input scans, and should specify the
%       overall weight, on top of the coherence, that that scan's voxels
%       get. Useful for me, when high-res data produces lower co values,
%       but is actually more reliable at identifying meridian
%       representations. <default: all ones.>
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
if notDefined('legend'), legend = 0;                            end
if notDefined('W'),      W = ones(size(scans));                 end
if notDefined('params')
    params = retinoCheckParams(view, dt, scans);
end

mapName = 'Polar Angle (clock position)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal with single input scan instances separately %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(scans)==1
    % this should be easy: just convert the corAnal values into
    % degrees of polar angle
    view = selectDataType(view, dt);
    corAnalPath = fullfile(dataDir(view), 'corAnal.mat');
    if ~exist(corAnalPath, 'file')
        error('corAnal not found. Run computeCorAnal first.');
    end
    load(corAnalPath, 'ph', 'co');
    srcPh = ph{scans}; srcCo = co{scans}; clear ph co;

    % map from corAnal ph to polar angle
    mapvol = polarAngle(srcPh, params) ./ 30; 

    % make and set the parameter map
    mapPath = fullfile(dataDir(view), 'Polar_Angle_Map.mat');
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
        view.ui.mapMode.clipMode = [0 12];        
    end

    view = setParameterMap(view, map, mapName);
    saveParameterMap(view, mapPath, 1, 1);
    
    if legend, polarAngleMapLegend(view); end

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
% Calculate the Polar Angle Map  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%Set NaNs to zero -- will be ignored
for i = 1:nScans
    srcCo{i}(isnan(srcCo{i})) = 0;
    srcAmp{i}(isnan(srcAmp{i})) = 0;
    srcPh{i}(isnan(srcPh{i})) = 0;
end

%%%%%Convert each phase map into real-word units
for i = 1:nScans
    srcPh{i} = polarAngle(srcPh{i}, params(i)) ./ 30;
end


%%%%%because we allow an additional level of user-defined weights
%%%%%(orig. b/c I wanted to weigh high-res scans higher than low-res),
%%%%%adjust the coherence weights accordingly for each scan
for i = 1:nScans, srcCo{i} = srcCo{i} .* W(i); end

%%%%%Set up the weighted average
% we'll need a volume representing the sum of the coherence
% for each voxel, across input scans. This will serve as the
% denominator of the weight formula for each input scan.
coSum = zeros(size(srcCo{1})); coMax = zeros(size(srcCo{1}));
for i = 1:nScans, 
    coSum = coSum + srcCo{i}; 
    coMax = max(coMax, srcCo{i});
end

%%%%%initialize the map and co volumes
mapvol = zeros(size(srcCo{1}));
covol = zeros(size(srcCo{1}));

%%%%%compute co volume as the mean across all input co volumes
for i = 1:nScans, covol = covol + srcCo{i}; end
covol = covol ./ length(srcCo);

%%%%%Compute the weighted average, iteratively across input scans
for i = 1:nScans
    mapvol = mapvol + (srcPh{i} .* srcCo{i} ./ coSum);

%     % alternate attempt: use winner-take-all: scan with the
%     % highest co value for a given voxel determines the map
%     % value at that voxel.
%     Imax = find(srcCo{i}==coMax);
%     mapvol(Imax) = srcPh{i}(Imax);    
end

covol = coMax;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output the parameter map %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize the output map and co data fields, loading it if it 
% already exists:
mapPath = fullfile(dataDir(view), 'Polar_Angle_Map.mat');
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
    view.ui.mapMode.clipMode = [0 12];
end

% set the map in the view, and save it
view = setParameterMap(view, map, mapName);
saveParameterMap(view, mapPath, 1, 1);
save(mapPath, 'co', '-append'); % also add the co field
view.co = co;
refreshScreen(view);

% also set corAnal amp and ph fields, and save a corAnal, so 
% we can view in that mode as well (nice colorbar, can ph-restrict)
% we map the ph back from degrees to radians:
phvol = deg2rad(mapvol.*30);
ampvol = srcAmp{1};
if exist(fullfile(dataDir(view), 'corAnal.mat'), 'file')
    view = loadCorAnal(view);
end
view.co{numScans(view)} = covol;
view.ph{numScans(view)} = phvol;
view.amp{numScans(view)} = ampvol;
view = saveCorAnal(view, 1);

newParams.type = 'polar_angle';     % set retino params such
newParams.startAngle = 0;           % that the default HSV color map
newParams.direction = 'clockwise';  % produces a nice wedge color bar
newParams.visualField = 360;        
newParams.width = 0;  
retinoSetParams(view, 'Meta_Analysis', numScans(view), newParams);

% show a legend if requested
if legend, polarAngleMapLegend(view); end

% ok, think that's it!

return
% /--------------------------------------------------------------------/ %





% /--------------------------------------------------------------------/ %
function A = polarAngleMapLegend(view);
% img = polarAngleMapLegend(view);
% Using the current map mode settings, produce a legend
% for a polar angle parameter map and plot in a separate figure.
% Returns a truecolor image if requested.
mode = view.ui.mapMode;

% generate an angle map A and a radius map R
% A will start at the 12-o-clock and run clockwise back to 12,
% ranging from 1 to the number of colors in the cmap.
[X Y] = meshgrid(1:256, 1:256);
X = X-128; Y = Y-128;
A = atan2(X, Y);
A = fliplr(mod(A-pi, 2*pi));
A = rescale(A, [], [1 mode.numColors]);
R = sqrt(X.^2 + Y.^2);

% take cmap from color part of map mode
cmap = mode.cmap(mode.numGrays+1:end,:);

% convert A to truecolor
A = ind2rgb(A, cmap);

% for each color channel, mask out region outside radius (128 pixels)
[I J] = find(R>128);
for ch = 1:3
    ind = sub2ind(size(A), I, J, repmat(ch, size(I)));
    A(ind) = 1;
end

% put up the image
figure('Color', 'w', 'Name', 'Polar Angle Map Legend');
imshow(A);

return

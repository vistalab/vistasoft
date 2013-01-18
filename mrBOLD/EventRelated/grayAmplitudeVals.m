function mapVals = grayAmplitudeVals(V, ampType, varargin);
% Return event-related amplitudes for a gray view
%
%  mapVals = grayAmplitudeVals(V, ampType, [options]);
%
% ras, 09/30/2009
if notDefined('V'),				V = getSelectedGray;		end
if notDefined('ampType'),       ampType = 'z-score';		end

%% checks
% check that a GLM has been run
if ~isequal(viewGet(V, 'DTName'), 'GLMs')
	error('Need to be in the GLMs data type.')
end

% get scan num, # of non-null conditions
scan = viewGet(V, 'CurScan');
stim = er_concatParfiles(V);
N = length(stim.condNames) - 1;  % omit baseline condition

%% params
% default params
preserveCoords = 0;
saveAmps = 0;

% parse options (these will override the dialog values)
for ii = 1:2:length(varargin)
	val = varargin{ii+1};
	eval( sprintf('%s = val;', varargin{ii}) );
end


%% if the beta maps haven't been xformed from inplanes, do it now
testFile = fullfile( dataDir(V), sprintf('betas-predictor%i.mat', N) );
if ~exist(testFile, 'file')
	hI = initHiddenInplane('GLMs', 1);

	for i = 1:N     % loop across conditions
		mapPath = fullfile(dataDir(hI), 'RawMaps', ...
			sprintf('betas_predictor%i.mat', i));
		hI = loadParameterMap(hI, mapPath);
		V = ip2volParMap(hI, V, 0, 1, 'linear'); % trilinear interpolation

		mapPath = fullfile(dataDir(hI), 'RawMaps', ...
			sprintf('stdDev_predictor%i.mat', i));
		hI = loadParameterMap(hI, mapPath);
		V = ip2volParMap(hI, V, 0, 1, 'linear');
	end

	hI = loadParameterMap(hI, 'Residual Variance.mat');
	V = ip2volParMap(hI, V, 0, 1, 'linear');
end

if notDefined('whichConds'),
	whichConds=1:1:N;
else
	N=length(whichConds);
end

%% get the amplitude estimate for each voxel
switch lower(ampType)
	case 'subtracted-betas'
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);
			mapVals(i,:) = V.map{scan};
		end

		% remove the "cocktail blank" or mean of all conditions for each voxel
		mapVals = mapVals - repmat( nanmean(mapVals), [N 1] );

	case {'raw-betas' 'rawbetas' 'raw betas' 'betas'}
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);

			mapVals(i,:) = V.map{scan};
		end

	case {'z-score' 'z score' 'zscore'}
		% load the betas
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);
			mapVals(i,:) = V.map{scan};
		end

		% load the residual variance map
		V = loadParameterMap(V, 'Residual Variance');
		sigmaVals = V.map{scan};

		% convert from res. var -> std. dev
		% (we need some info from the GLM model: degrees of freedom)
		modelFile = sprintf('Inplane/GLMs/Scan%i/glmSlice1.mat', scan);
		load(modelFile, 'dof');
		sigmaVals = sqrt( sigmaVals .^ 2 ./ dof );

		% remove the "cocktail blank" or DC component for each voxel
		mapVals = mapVals - repmat( nanmean(mapVals), [N 1] );

		% now, normalize by dividing by the estimated residual variance at
		% each voxel
		mapVals = mapVals ./ repmat( sigmaVals, [N 1] );

	otherwise
		error('Invalid amplitude type.')
end

%% return only values in the ROI? (Maybe we don't want to do this)
if isempty(V.ROIs)
    I = 1:size(mapVals, 2);
else
    I = roiIndices(V, V.ROIs(end).coords, preserveCoords);
end
mapVals = mapVals(:,I);

return

function view = rmComputeOverlapMaps(view, rmParams, modelNum);
%
% view = rmComputeOverlapMaps(view, rmParams, modelNum);
%
%
% ras, 11/2007.
if notDefined('view'),		view = getCurView;						end
if notDefined('rmParams'),	rmParams = viewGet(view, 'rmParams');	end
if notDefined('modelNum'),	modelNum = viewGet(view, 'rmModelNum');	end

%% compute the stimulus mask for each condition
[rmParams mask] = rmStimulusMatrix(rmParams);
nStim = size(mask, 3);

%% try to get stimulus names from event-related params
%% failing this, make dummy stimulus names
try 
	trials = er_concatParfiles(view);
catch
	for i = 1:nStim
	trials.condNames{i+1} = sprintf('Stimulus %i', i);
	end
end

%% compute overlap maps
for s = 1:nStim
	tic
	map{scan} = rmOverlapMap( viewGet(view, 'rmmodel', modelNum), ...
							  mask(:,:,s), X, Y );
	toc

	map{scan} = map{scan} .* 100;  % convert from proportion -> percent
						  
	stimName = trials.condNames{s+1}; % ignore baseline condition
	mapName = sprintf('pRF Overlap %s', stimName); 
	mapUnits = '%';
	
	mapPath = fullfile(dataDir(view), mapName);
	
	save(mapPath, 'map', 'mapName', 'mapUnits');
	fprintf('Saved %s.\n', mapPath);
end

return

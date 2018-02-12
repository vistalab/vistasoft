function view = saveGlmMap(view, fieldName, condNum, mapName, scan)
%
% view = saveGlmMap(view, fieldName, condNum, [mapName], [scan]);
%
% Load a GLM model for a mrVista view (saved for the specified scan),
% and save the specifield field name as a parameter map.
%
% To use this, you should have run 'applyGlm' on the view, to save
% the GLM data files.
%
% ras, 1/03/06
if ieNotDefined('view'), view = getSelectedInplane; end
if ieNotDefined('mapName'), mapName = fieldName; end
if ieNotDefined('scan'), scan = getCurScan(view); end

% initialize map as zeros
map = cell(1, numScans(view));
mapSize = dataSize(view);
map{scan} = zeros(mapSize);

h = mrvWaitbar(0, 'Saving GLM Map...');

for slice = 1:numSlices(view)
   % load the results of the GLM
   model = loadGlmSlice(view, slice, scan);

   % find the indices in the map which correspond to this slice
   [X Y Z] = meshgrid(1:mapSize(1), 1:mapSize(2), slice);
   coords = [X(:) Y(:) Z(:)]';
   ind = sub2ind(mapSize, coords(1,:), coords(2,:), coords(3,:));

   % get the data from the appropriate field
   if ~isfield(model, fieldName)
       error('field not found')
   elseif isequal(lower(fieldName), 'residual')
       % take the mean residual from each voxel
       vals = mean(model.(fieldName), 1);
   else
       vals = model.(fieldName)(:, condNum, :);
   end

   % map the values from the specified field to the appropriate
   % place in the map:
   map{scan}(ind) = vals;

   mrvWaitbar(slice/numSlices(view), h);
end

close(h);


% set the absolute value of the parameter as the 'co' field, so
% you can threshold by that as well:
co = cell(1, numScans(view));
co{scan} = abs(map{scan});

% save the map
mapPath = fullfile(dataDir(view), mapName);
save(mapPath, 'map', 'co', 'mapName');

% set as the active map in the view, so you can view the
% results right away:
view = setParameterMap(view, map, mapName);

return
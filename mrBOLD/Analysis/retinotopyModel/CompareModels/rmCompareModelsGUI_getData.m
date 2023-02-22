function M = rmCompareModelsGUI_getData(view, roi, dtList, modelList);
% Create the data structure needed for rmCompareModelsGUI.
%
%   M = rmCompareModelsGUI_getData(view, roi, dtList, modelList);
%
% grab ROI time series data from each of the data types in dtList, and
% grab ROI pRF data for each of the models in model list. Returns a
% structure M that will reside in the GUI figure.
%
% ras, 04/09, broken off from main function to allow 'hidden GUI' analyses.
modelNum = 1;  % default model #, modify if this needs to be set by the user
verbose = prefsVerboseCheck;

% if no model list is provided, use the flag to find default model files.
if notDefined('modelList'),	modelList = -1;			end

%% parse ROI specification
if notDefined('roi'),	roi = view.selectedROI;  end

% make sure the ROI is specified as a structure:
M.roi = tc_roiStruct(view, roi);

% sub-select ROI coords contained in the view coords 
% (I automatically do this, to save substantial time and simplify things -- 
% though this does shuffle the order of the coordinates)
indices = roiIndices(view, M.roi.coords);
if ismember(view.viewType, {'Gray' 'Volume'})
	M.roi.coords = view.coords(:,indices);
else
	M.roi.coords = roiSubCoords(view, M.roi.coords);
end

%% parse model specification
if isequal(modelList, -1)
	modelList = {};
	
	% get default model files
	for ii = 1:length(dtList)
		modelList{ii} = rmDefaultModelFile(view, dtList{ii});
	end
end

% make sure the dtList has data type names -- allow the user to input
% indices, but convert them here.
for ii = 1:length(dtList)
	if isnumeric(dtList{ii})
		mrGlobals;
		dtList{ii} = dataTYPES(dtList{ii}).name;
	end
end

%% load data from each model
if verbose >= 1
	h_wait = mrvWaitbar(0, 'Loading data from each model');
end

for m = 1:length(modelList)
	view = selectDataType(view, dtList{m});
	view = rmSelect(view, 1, modelList{m});
	nScans = viewGet(view, 'numScans');

    M.params{m} = viewGet(view, 'RMParams');
	
	M.tSeries{m} = voxelTSeries(view, M.roi.coords, 1:nScans, 0, 1);
	for f = {'x0' 'y0' 'sigma' 'pol' 'ecc' 'beta' 'varexp'}
		 M.(f{1}){m}  = rmCoordsGet('Gray', view.rm.retinotopyModels{modelNum}, ...
										f{1}, indices);
	end
	
	% gum: first frame still has gradients firing up (artifact)...
	M.tSeries{m}(1,:) = mean(M.tSeries{m}(2:end,:));
	
	if verbose >= 1, mrvWaitbar(m/length(modelList), h_wait);  end
end

if verbose >= 1
	close(h_wait);
end


% record model, data type info
M.modelName = view.rm.retinotopyModels{modelNum}.description;
M.viewType = view.viewType;
M.modelList = modelList;
M.dtList = dtList;
M.nModels = length(modelList);
M.nVoxels = size(M.roi.coords, 2);

return
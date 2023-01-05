function M = rmCompareModelsGUI_sortVoxels(criterion, modelNum, M);
% Sort voxels in rmCompareModelsGUI.
% 
% M = rmCompareModelsGUI_sortVoxels([criterion], [modelNum=dialog], [M=get from cur figure]);
%
% INPUTS:
%	criterion: can be one of 'ecc', 'pol', 'sigma', 'varexp', or 'beta'.
%	Will sort the voxels in ascending order for the specified parameter and
%	model #. 
%	[default: get criterion from dialog]
%
%	modelNum: index of model in the comparison GUI from which to take the
%	voxel data to use for sorting. 
%	[default: get model number from dialog]
%
%	M: comparison GUI struct, created by rmCompareModelsGUI_getData.
%	[default: get from cur figure, assumes you've already opened a
%	comparison GUI.]
%
%
%
% ras, 09/2008.
if notDefined('M'), M = get(gcf, 'UserData'); end
if notDefined('modelNum'),
	modelNum = listdlg('PromptString', 'Sort by Which Model?', ...
						'ListString', M.dtList, 'InitialValue', 1);
end

if notDefined('criterion'),
	cList = {'Variance Explained' 'Eccentricity' 'Polar Angle' ...
			 'x0' 'y0' 'pRF Size (sigma)' 'Scale Factor (beta)'};
	fieldList = {'varexp' 'ecc' 'pol' 'x0' 'y0' 'sigma' 'beta'};
	cNum = listdlg('PromptString', 'Sort by Which Criterion?', ...
						'ListString', cList, 'InitialValue', 1);
	criterion = fieldList{cNum};				
end

% lookup for alternate names for criteria
switch lower(criterion)
	case 'eccentricity', criterion = 'ecc';
	case 'polar angle', criterion = 'pol';
	case 'prf size (sigma)', criterion = 'sigma';
	case 'scale factor (beta)', criterion = 'beta';
end

% get the values for the criterion
vals = M.(criterion){modelNum};

% special case: for beta, we want the first beta value (for the pRF, not
% the trend terms) in the model
if isequal(criterion, 'beta')
	vals = vals(:,1);
end

% sort the values, getting I -- the new voxel order
[sortedVals I] = sort(vals);

% reorder the ROI coordinates and data fields to match this:
M.roi.coords = M.roi.coords(:,I);
for f = {'x0' 'y0' 'sigma' 'pol' 'ecc' 'varexp'}
	for m = 1:M.nModels
		M.(f{1}){m} = M.(f{1}){m}(I);
	end
end

for m = 1:M.nModels
	M.beta{m} = M.beta{m}(I,:);
end


% reoder time series
for m = 1:M.nModels
	M.tSeries{m} = M.tSeries{m}(:,I); 
end

% udpate the GUI
set(gcf, 'UserData', M); 
% rmCompareModelsGUI_update; 
  
return
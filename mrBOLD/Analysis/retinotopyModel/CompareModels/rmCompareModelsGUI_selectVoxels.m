function M = rmCompareModelsGUI_selectVoxels(M, whichVoxels, plotFlag);
% Sub-select voxels in the ROI of rmCompareModelsGUI.
% 
% M = rmCompareModelsGUI_selectVoxels([M=get from cur figure], [whichVoxels=dialog], [plotFlag=2]);
% 
%
% INPUTS:
%	M: rmCompareModelsGUI structure. See rmCompareModelsGUI_getData. Can also be the handle
%	to an rmCompareModelsGUI figure.
%	
%	whichVoxels: index of voxels within M.coords to select.
%	[default: open a dialog allowing the user to select voxels based on
%	basic pRF parameter ranges (e.g., varexp, eccentricity, polar angle,
%	sigma)].
%
%	plotFlag: flag indicating where to show the new analysis on the
%	restricted set of voxels. Values are:
%		0 -- just return the M structure and don't make/update a GUI.
%		1 -- replace the existing GUI with the new data (throw out the
%			 eliminated voxels).
%		2 -- open a new GUI for the restricted subset.
%		[default 2, open a new figure]
%
% Returns a modified version of M.
%
% ras, 04/2009.
if notDefined('M'),			M = get(gcf, 'UserData');		end
if ishandle(M),				M = get(M, 'UserData');			end
if notDefined('plotFlag'),	plotFlag = 2;					end
if notDefined('whichVoxels'),
	whichVoxels = selectVoxelsDialog(M);
end

% is M the proper structure?
if ~checkfields(M, 'modelList') | ~checkfields(M, 'tSeries')
	error('Need an rmCompareModelsGUI structure. See rmCompareModelsGUI.')
end

% are the coordinates empty? If so, warn and do nothing, but don't error.
if isempty(whichVoxels)
	warning('No voxels selected.')
	return
end

% sub-select the voxels
M.roi.coords = M.roi.coords(:,whichVoxels);
for m = 1:M.nModels
	for f = {'tSeries' 'x0' 'y0' 'sigma' 'pol' 'ecc' 'varexp'}
		M.(f{1}){m} = M.(f{1}){m}(:,whichVoxels);
	end
	M.beta{m} = M.beta{m}(whichVoxels,:);
end
M.roi.name = ['Subset of ' M.roi.name];
M.nVoxels = length(whichVoxels);

% update the GUI as desired
switch plotFlag
	case 0, % do nothing
		
	case 1, % replace data in existing GUI
		set(M.fig, 'UserData', M);
		
	case 2,
		M = rmCompareModelsGUI_openFig(M);
		
	otherwise, error('Invalid plot flag.')
end



return
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function whichVoxels = selectVoxelsDialog(M);
%% put up a dialog to get pRF criteria for the voxels to keep, then find
%% the voxels which satisfy these criteria.

% build the dialog
dlg(1).fieldName = 'modelNum';
dlg(end).style = 'popup';
dlg(end).value = 1;
dlg(end).list  = M.dtList;
dlg(end).string = 'Select based on which model''s parameters?';

dlg(end+1).fieldName = 'notes';
dlg(end).style = 'text';
dlg(end).value = '';
dlg(end).string = 'Leave a field empty to omit thresholding:';

dlg(end+1).fieldName = 'varexp';
dlg(end).style = 'number';
dlg(end).value = 0.10;
dlg(end).string = 'Variance explained threshold:';

dlg(end+1).fieldName = 'ecc';
dlg(end).style = 'number';
dlg(end).value = [0 30];
dlg(end).string = 'Eccentricity range (blank for all values):';

dlg(end+1).fieldName = 'pol';
dlg(end).style = 'number';
dlg(end).value = [0 360];
dlg(end).string = 'Polar Angle range (deg CW from up):';

dlg(end+1).fieldName = 'sigma';
dlg(end).style = 'number';
dlg(end).value = [0 30];
dlg(end).string = 'pRF Diameter (major axis) range:';


% put up the dialog
resp = generalDialog(dlg, 'rmCompareModelsGUI: Select Voxels');


% get the model number
m = cellfind(M.dtList, resp.modelNum);
m = m(1); % in case 2 models from the same data type

% find voxels which pass the crtieria
ok = ones(1, size(M.roi.coords, 2));

if ~isempty(resp.varexp)
	ok = ok & (M.varexp{m} >= resp.varexp);
end

if length(resp.pol) > 1
	ok = ok & (M.pol{m} >= resp.pol(1) & M.pol{m} <= resp.pol(2));
end

if length(resp.ecc) > 1
	ok = ok & (M.ecc{m} >= resp.ecc(1) & M.ecc{m} <= resp.ecc(2));
end

if length(resp.sigma) > 1
	ok = ok & (M.sigma{m} >= resp.sigma(1) & M.sigma{m} <= resp.sigma(2));
end

whichVoxels = find(ok);

return
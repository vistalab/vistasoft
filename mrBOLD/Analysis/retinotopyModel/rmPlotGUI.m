function M = rmPlotGUI(vw, roi, allTimePoints, preserveCoords)
% rmPlotGUI - create a GUI for visualizing the results of the retinotopic
% model applied to individual voxels.
%
%    M = rmPlotGUI(vw, [roi=selected ROI], [allTimePoints=1(yes)], [preserveCoords=0]);
%
% INPUTS:
%	vw: mrVista view. Needs to have a retinotopy model loaded.
%
%	roi: ROI specification. can be ROI structure, index into the view's
%	ROIs, or name of an ROI in the view (or a 3xN list of coordinates).
%
%	allTimePoints: flag to plot the whole time course for each file (1) or,
%	where applicable, to average across cycles (0). [Default 1, show all
%	time points].
%
%	preserveCoords: flag to preserve the order of voxels in the ROI.
%	If 1, it may take significantly longer to load, because certain
%	operations have to run as slow loops.
%	[Default: 0, allow voxel order to be shuffled.]
%
% 2006/09 RAS: modified off of rmPlot.

% Programming note: we want the model to be independent of the
% actual scan (parameters).
if notDefined('vw'), vw = getCurView; end

% switch: allow the GUI controls to call this function requesting an update
% hack (SD): if update, the view struct is stored in the roi field so we 
% can pass it on.
if isequal(vw, 'update'), 
    M = rmPlotGUI_update; 
    rmPlotGUI_updateOtherWindows(M);    
    return;          
end;

if ~exist('roi','var') || isempty(roi),
    roi = vw.selectedROI;
    if isequal(roi,0), 
        warndlg('You must load and select an ROI for plotting'); 
        return;
    end
end;

if ~exist('allTimePoints','var') || isempty(allTimePoints), 
    allTimePoints = 1;                  
end;

if notDefined('preserveCoords'), preserveCoords = 0; end


% disambiguate ROI specification: name, ROI index, coords, struct...
% this will return an ROI struct
roi = tc_roiStruct(vw, roi);

%% grab information from the model and ROI into a compact description 
% (the struct variable M). 
% M will be stored as the UserData property of the GUI figure.
M = rmPlotGUI_getModel(vw, roi, allTimePoints, preserveCoords);

%% open the GUI
M = rmPlotGUI_openFig(M);

%% run an initial refresh
rmPlotGUI_update(M);

return;

function rmPlotGUI_updateOtherWindows(M) 
% If reqeusted, update all open rmPlotGUIs in sychrony.  So if we advance
% to a new voxel in one GUI, we will also advance to the same voxel in
% other open GUIs. This is useful in the case that we are looking at
% multiple models for the same data set (e.g., a one gaussian and a
% two-gaussian model), and want to compare model fits.

% Check to see whether updating of all windows is requested. If not, then
% return without action.
if ~isfield(M, 'updateAllWindows') || ~M.updateAllWindows 
    return
end

otherplots = [];
for ii = 1:100;
    try  %#ok<TRYNC>
        x = get(ii, 'UserData'); 
        if checkfields(x, 'ui', 'voxel', 'sliderHandle')
            otherplots = [otherplots ii]; %#ok<AGROW>
        end
    end
end
v = get(M.ui.voxel.sliderHandle, 'Value');
for ii = otherplots
    A = get(ii, 'UserData');
    set(A.ui.voxel.sliderHandle, 'Value', v)
    rmPlotGUI_update(A);
end

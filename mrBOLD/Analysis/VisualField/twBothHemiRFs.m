function [pol ecc] = twBothHemiRFs(view, roi, scans, dt, plotFlag);
% Grab plar angle and eccentricity data separately for both hemispheres of
% an ROI, plotting if desired.
%
% [pol ecc] = twBothHemiRFs([view], [roi], [scans], [dt], [plotFlag=1]);
%
% This function assumes you have a polar angle and eccentricity scan in the
% same data type, in which the retinotopy parameters have been set
% (function: retinoSetParams; menu: Color Map | Set Retinotopy
% Parameters...). You should also have loaded two ROIs, named 'L[roi]' and
% 'R[roi]'. This grabs the raw phase data from the two scans, thresholds by
% the view's current cothresh, and converts the voxels passing threshold
% into polar visual field coordinates, returning them separately for each
% hemisphere in pol and ecc, and plotting the results if plotFlag==1.
%
%
% INPUTS:
%	view: mrVista view. [defaults to getCurView]
%
%	roi: name of ROI. The assumption here is that there are two loaded ROIs
%	in the view, 'L[roi]' and 'R[roi]'. (I can generalize this to different
%	naming conventions if anyone else uses this). [default: guess based on
%	the name of the selected ROI, omitting the first letter.]
%
%	scans: index of [polar angle, eccentricity] mapping scans in the
%	selected data type, from which to get the estimates. [Default: [1 2]]
%
%	dt: data type with the retinotopic mapping data.
%
%	plotFlag: if 1, will plot the RF centers using retinoPlot. [default 1]
%
% OUTPUTS:
%  pol: {2 x 1} cell array containing polar angle measurements for the left
%  and right hemipheres, respectively.
%
%  ecc: {2 x 1} cell array containing eccentricity measurements for the left
%  and right hemipheres, respectively.
%
% ras, 08/2007
if notDefined('view'),		view = getCurView;			end
if notDefined('scans'),		scans = [1 2];				end
if notDefined('dt'),		dt = view.curDataType;		end
if notDefined('plotFlag'),	plotFlag = 1;				end

if notDefined('roi'),		
	roi = view.ROIs( view.selectedROI ).name(2:end);
end

%% find indices of the two ROIs representing L and R hemispheres
names = {view.ROIs.name};
lh = cellfind(names, ['L' roi]);
rh = cellfind(names, ['R' roi]);

if lh==0 | rh==0
	names
	error('Could not find both hemisphere ROIs in view.')
end


%% get corAnal phase, restrict by cothresh
% check if corAnal loaded
if isempty(view.ph) | isempty(view.ph{scans(1)}) | isempty(view.ph{scans(2)})
	view = loadCorAnal(view);
end

% grab phase, coherence vals for all voxels
polPhase{1} = getCurDataROI(view, 'ph', scans(1), lh);
polPhase{2} = getCurDataROI(view, 'ph', scans(1), rh);
eccPhase{1} = getCurDataROI(view, 'ph', scans(2), lh);
eccPhase{2} = getCurDataROI(view, 'ph', scans(2), rh);

polCo{1} = getCurDataROI(view, 'co', scans(1), lh);
polCo{2} = getCurDataROI(view, 'co', scans(1), rh);
eccCo{1} = getCurDataROI(view, 'co', scans(2), lh);
eccCo{2} = getCurDataROI(view, 'co', scans(2), rh);

% restrict by cothresh 
cothresh = viewGet(view, 'cothresh');
ok1 = find( (polCo{1} > cothresh) & (eccCo{1} > cothresh) );
ok2 = find( (polCo{2} > cothresh) & (eccCo{2} > cothresh) );
polPhase{1} = polPhase{1}(ok1);  
polPhase{2} = polPhase{2}(ok2);  
eccPhase{1} = eccPhase{1}(ok1);  
eccPhase{2} = eccPhase{2}(ok2);  


%% convert to visual field units
polParams = retinoGetParams(view, dt, scans(1));
eccParams = retinoGetParams(view, dt, scans(2));

pol = { polarAngle(polPhase{1}, polParams), ...
		polarAngle(polPhase{2}, polParams) };

ecc = { eccentricity(eccPhase{1}, eccParams), ...
		eccentricity(eccPhase{2}, eccParams) };
	

%% plot results if selected
if plotFlag==1
	figure('Color', 'w');
	retinoPlot(pol, ecc);
	title(roi, 'FontSize', 14, 'FontName', 'Helvetica');
	legendPanel({'LH' 'RH'}, {'r' 'b'});
end

return

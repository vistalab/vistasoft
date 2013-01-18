function [view band] = twEccentricityBand(view, eccRange, roi, eccScan, select);
%
% [view band] = twEccentricityBand(view, [eccRange], [roi], [eccScan], [select=1]);
%
% Select a subset of an ROI which corresponds to a particular range of
% visual eccentricities, as determined by a traveling wave analysis. 
% Uses the mapping information provided in retinoSetParams / retinoGetParams. 
%
% INPUTS:
%	view: mrVista view. Defaults to getCurView.
%
%	eccRange: range of eccentricities to include [min max]. If min > max, 
%	will wrap around the max eccentricity. If omitted, will prompt you.
%
%	roi: The larger ROI from which to sub-select the band. Defaults to
%	view's current ROI.
% 
%	eccScan: number of the scan containing the eccentricity data in the
%	current data type. Defaults to view's curScan.
%	
%	select: flag to select the new ROI in the view. Default is 1, select
%	it.
%
% OUTPUTS:
%	view: view with a new ROI corresponding to the eccentricity band
%	attached.
%	
%	band: ROI for the band.
%
% ras, 07/2007.
if notDefined('view'),		view = getCurView;			end
if notDefined('eccRange'),	eccRange = getEccRange;		end
if notDefined('roi'),		roi = view.selectedROI;		end
if notDefined('eccScan'),	eccScan = view.curScan;		end
if notDefined('select'),	select = 1;					end

roi = tc_roiStruct(view, roi);

%% get the traveling wave data: 
%% either there's phase data in the view, or else load it
if ( length(view.ph) > eccScan ) & ( ~isempty(view.ph{eccScan}) )
	ph = view.ph{eccScan};
	co = view.co{eccScan};
else
	corAnalFile = fullfile(dataDir(view), 'corAnal.mat');
	if ~exist(corAnalFile, 'file')
		error('Need to load or compute traveling wave analysis.')
	end
	load(corAnalFile, 'ph', 'co');
	ph = ph{eccScan};
	co = co{eccScan};
	if isempty(co) | isempty(ph)
		error('phase/coherence data not present for eccentricity scan.')
	end
end

%% make sure the eccentricity mapping params are set
params = retinoCheckParams(view, view.curDataType, eccScan);
if ~isequal(params.type, 'eccentricity')
	error('Retinotopy params for this scan don''t specify eccentricity.')
end

%% get TW phase data for the original ROI
I = roiIndices(view, roi.coords);
ph = ph(I);
co = co(I);

%% map to visual eccentricity
% (Also select voxels w/ co > cothresh)
theta = eccentricity(ph, params);
if eccRange(2) > eccRange(1) % max > min
	ok = find(theta > eccRange(1) & theta < eccRange(2) & ...
			  co > getCothresh(view));
else						 % min > max, wrap around
	ok = find( (theta < eccRange(2) | theta > eccRange(1)) & ...
				co > getCothresh(view) );
end
	

%% select the appropriate band
band = roiCreate1;
band.name = sprintf('%s (%s - %s)', roi.name, num2str(eccRange(1)), ...
					num2str(eccRange(2)));
band.coords = roi.coords(:,ok);
band.modified = datestr(now);

% add to view
view = addROI(view, band, select);

return
% /---------------------------------------------------------/ %



% /---------------------------------------------------------/ %
function eccRange = getEccRange;
% Put up a dialog to get the eccentricity range
q = {'[min max] eccentricity'};
def = {'[0 3]'};
eccRange = inputdlg(q, mfilename, 1, def);
eccRange = str2num(eccRange{1});
return

 
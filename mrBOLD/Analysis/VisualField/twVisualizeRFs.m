function h = twVisualizeRFs(view, rois, dt, scans);
%
% h = twVisualizeRFs(view, [rois=all], [dt='Averages'], [scans=1:2];
%
% Visualize the location of RF esimates for each voxel in the
% specified ROIs, from a traveling wave analysis.
%
% scans: 2x1 matrix of [polar angle, eccentricity] scans, from which to
% take estimates. Retinotopic mapping parameters should be set for each of
% these (retinoSetParams; menu ColorMap | Set Retinotopy Parameters...).
%
% ras, 03/2007.
if notDefined('view'),	view = getCurView;			end
if notDefined('rois'),	rois = 1:length(view.ROIs);	end
if notDefined('dt'),	dt = 'Averages';			end
if notDefined('scans'),	scans = [1 2];				end

rois = tc_roiStruct(view, rois);

anal = twEstimateRFs(view, rois, dt, scans);

figure('Color', 'w', 'Name', ' Traveling Wave pRFs');
nrows = ceil(sqrt(length(rois)));
ncols = ceil(length(rois)/nrows);
for r = 1:length(rois)
	subplot(nrows, ncols, r);
	retinoPlot([], []);  % puts up grid
	plot(anal.x0{r}, anal.y0{r}, 'k.', 'MarkerSize', 1);
	grid on, axis([-10 10 -14 14]);
	axis square; axis equal; 
	title(rois(r).name, 'FontSize', 14, 'FontName', 'Helvetica');
end



return

function tc = mv_makeTCUI(mv, openNewFig);
%
% tc = mv_makeTCUI(mv, [openNewFig]);
%
% Create a time course UI from the voxels in 
% a multivoxel UI.
%
% If openNewFig is 1, will open a new figure w/ the UI.
% [default is 1]
%
% ras, 09/2005
if ieNotDefined('mv'), mv = get(gcf,'UserData'); end
if ieNotDefined('openNewFig'), openNewFig = 1;   end


%  Strategy 1: get the ROI coords and re-initialize from a mrVista view
% roi = mv.roi;
% roi.coords = mv.coords;
%
% func = sprintf('initHidden%s', mv.roi.viewType);
% hI = feval(func, mv.params.dataType, mv.params.scans(1));
% 
% tc = tc_init(hI, roi,mv.params.scans, mv.params.dataType);

%  Strategy 2: make the tc directly from the multi-voxel data, 
% so analyses such as temporal smoothing on the voxel TCs will 
% trasmit to the tc struct. This should also be faster.
tSeries = nanmean(mv.tSeries, 2);
tc = er_chopTSeries2(tSeries, mv.trials, mv.params);
tc.trials = mv.trials;
tc.roi = mv.roi;
tc.params = mv.params;
tc.params.legend = 1;
tc.params.showPkBsl = 1;
tc.params.markEachTrial = 1;
tc.params.grid = 0;
tc.TR = tc.params.framePeriod;
tc.plotType = 7;


if openNewFig==1, tc = tc_openFig(tc); timeCourseUI; end

return
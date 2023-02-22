function vw = plotMenu(vw)
% Add plotting-related menu options to a mrVista vw window.
%
% vw = plotMenu(vw)
%
% djh, 4/98
% ras, 06/18/04: added some options to superimpose different
% things (maps, raw tSeries values, etc...) in 'superimpose' submenu
% ras, 06/25/08: tidied up into subfunctions; added some more pRF options
% jw 07/03/08: added another pRF option (rmPlotMap)
% ras 08/08/08: just a preference: all the options in the 'Current Scan'
% submenu are directly available within the menu, rather than being grouped
% into two sub-submenus. It just makes it easier (for me, at least) to
% navigate w/o getting tripped up on sub-menus. Also made the Ctrl-1
% accelerator show the mean time series (it had previously been 'select
% ROI', but that hardly ever seems used, and only works in Inplane views).

h = uimenu('Label', 'Plots', 'Separator', 'on');

% plot options for data from the currently-selected scan
curScanSubmenu(h, vw);

% across-scans plotting options
acrossScansSubmenu(h, vw);

if isequal(vw.viewType, 'Flat')
	curScan_flatOptionsSubmenu(h, vw);
elseif ismember(vw.viewType, {'Volume' 'Gray'})
	curScan_grayOptionsSubmenu(h, vw);
end

% color bar plots
colorbarSubmenu(h, vw);

% Blur tseries plot callback
%  blurTSeriesPlot
callback = 'blurTSeriesPlot';
uimenu(h, 'Label', 'Blur time series plot', 'Separator', 'off', ...
	'CallBack', callback);

% Get plotted data callback
callback = 'getPlottedData';
uimenu(h, 'Label', 'Dump plot data into workspace', 'Separator', 'off', ...
	'CallBack', callback);

% pRF / Retinotopy Model plot options
prfSubmenu(h, vw);

% check for time series artifacts
tSeriesArtifactSubmenu(h, vw);

% superimpose map options
overlaySubmenu(h, vw);

% functionals movie submenu
if isequal(vw.viewType, 'Inplane')
	tSeriesMovieSubmenu(h, vw);
end

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function curScanSubmenu(h, vw)
%% Add plot options for the current scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Current Scan submenu
curScanMenu = uimenu(h, 'Label', 'Current Scan', 'Separator', 'off');


% plotMeanTSeries callback:
%  selectGraphWin;
%  plotMeanTSeries(vw, getCurScan(vw));     
callback = ['plotMeanTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''));getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean Time Series', 'Separator', 'off', ...
	'CallBack', callback, 'Accelerator', '1');

% plotMeanTSeries Raw data (no detrending) callback:
%  selectGraphWin;
%  plotMeanTSeries(vw, getCurScan(vw), [], true);     
callback = ['plotMeanTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''), [], true);getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean Time Series Raw', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleTSeries callback:
%  plotMultipleTSeries(vw, getCurScan(vw));
callback = ['plotMultipleTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''));getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean TSeries of Multiple ROIs - separate subplots', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleTSeries-OnePlot callback:
%  plotMultipleTSeries(vw, getCurScan(vw), [], true);
callback = ['plotMultipleTSeries(', vw.name, ', getCurScan(', vw.name, '), [], true);getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean TSeries of Multiple ROIs - same plot', 'Separator', 'off', ...
	'CallBack', callback);

% plotSingleCycle callback:
%  plotSingleCycleErr(vw);
callback = ['plotSingleCycleErr(', vw.name, ');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Single Cycle', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleSingleCycle callback:
%   plotMultipleSingleCycleErr(vw);
callBackstr=['plotMultipleSingleCycleErr(',vw.name,');getPlottedData;'];
uimenu(curScanMenu,'Label','Single Cycle of Multiple ROIs','Separator','off',...
    'CallBack',callBackstr);

% plotFFTSeries callback:
%  plotFFTSeries(vw, getCurScan(vw));
callback = ['plotFFTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''));getPlottedData;'];
uimenu(curScanMenu, 'Label', 'FFT of Mean TSeries', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleFFTSeries callback:
%  plotMultipleFFTSeries(vw, getCurScan(vw));
callback = ['plotMultipleFFTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''));getPlottedData;'];
uimenu(curScanMenu, 'Label', 'FFT of Multiple ROIs', 'Separator', 'off', ...
	'CallBack', callback);

% plotMeanFFTSeries callback:
%  plotMeanFFTSeries(vw, getCurScan(vw));
callback = ['plotMeanFFTSeries(', vw.name, ', viewGet(', vw.name, ', ''current scan''));getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean FFT', 'Separator', 'off', ...
	'CallBack', callback, 'Accelerator', '`');

%  mrRoistats(vw);
callback = ['mrROIstats(', vw.name, ');'];
uimenu(curScanMenu, 'Label', 'Traveling-Wave Stats Summary', 'Separator', 'on', ...
	'CallBack', callback);

%  mrspMeanPhase(vw);
callback = ['mrspMeanPhase(', vw.name, ');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean Phase vs. Coherence', 'Separator', 'off', ...
	'CallBack', callback);

%  plotMultipleAmps_SingleCondition(['plotMultipleAmps(', vw.name, ');']);
callback = ['plotMultipleAmps_SingleCondition(', vw.name, ');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Mean amplitudes in multiple ROIs', 'Separator', 'off', ...
	'CallBack', callback);

% plotCorVsPhase (cartesian) callback:
%  plotCorVsPhase(vw, 'cartesian');
callback = ['plotCorVsPhase(', vw.name, ', ''cartesian'');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Co vs. Phase (cartesian)', 'Separator', 'off', ...
	'CallBack', callback);

% plotCorVsPhase (polar) callback:
%  plotCorVsPhase(vw, 'polar');
callback = ['plotCorVsPhase(', vw.name, ', ''polar'');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Co vs. Phase (polar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotEccVsPhase (polar) callback:
%  plotEccVsPhase(vw, 'polar');
callback = ['plotEccVsPhase(', vw.name, ');getPlottedData;'];
uimenu(curScanMenu, 'Label', 'Ecc vs. Phase (polar)', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function curScan_grayOptionsSubmenu(curScanMenu, vw)
%% cur scan options specific to VOLUME/GRAY vw types.
lineMenu = uimenu(curScanMenu, 'Label', 'Line ROI Plots', 'Separator', 'off');

% lineROI (no smoothing) callback:
%  plotLineROI(vw, getCurScan(vw), 0);
callback = ['CURLINE = plotLineROI(', vw.name, ', 0);'];
uimenu(lineMenu, 'Label', 'Plot data from line ROI (no smoothing)', 'Separator', 'off', ...
	'CallBack', callback);

% lineROI callback:
%  plotLineROI(vw, getCurScan(vw), smoothing);
callback = ['CURLINE = plotLineROI(', vw.name, ', -1); getPlottedData;'];
uimenu(lineMenu, 'Label', 'Plot data from line ROI', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function curScan_flatOptionsSubmenu(curScanMenu, vw)
%% cur scan options specific to FLAT vw types

lineMenu = uimenu(curScanMenu, 'Label', 'Line ROI Plots', 'Separator', 'off');

% plotCoVsPosition callback
callback = ['plotParamVsPosition(', vw.name, ', ', '''Co''); getPlottedData;'];
uimenu(lineMenu, 'Label', 'Co vs. Position', 'Separator', 'off', ...
	'CallBack', callback);

% plotAmplitudeVsPosition callback
%  plotAmplitudeVsPosition(vw);
% callback = ['plotAmplitudeVsPosition(', vw.name, ', 1);'];
callback = ['plotParamVsPosition(', vw.name, ', ', '''Amplitude''); getPlottedData;'];
uimenu(lineMenu, 'Label', 'Amplitude vs. Position', 'Separator', 'off', ...
	'CallBack', callback);

% plotPhaseVsPosition callback
%  plotPhaseVsPosition(vw);
% plotParamVsPosition( vw, plotParam, scanList );
% by leaving out 'scanList' we get a plot for the current Scan
callback = ['plotParamVsPosition(', vw.name, ', ', '''Phase''); getPlottedData;'];
uimenu(lineMenu, 'Label', 'Phase vs. Position', 'Separator', 'off', ...
	'CallBack', callback);

% plotParamVsDistance callback
%  ROIdata = plotParamsVsDistance(vw, [plotParam], [scanNum], ...
%                [ROIdata], [binSize], [plotFlag]);
% callback = ['ROIdata = plotParamVsDistance(', vw.name, ', 1);'];
callback = ['plotParamVsDistance(', vw.name, '); getPlottedData;'];
uimenu(lineMenu, 'Label', 'Parameter vs. Distance', 'Separator', 'off', ...
	'CallBack', callback);

% plotProjAmpVsPosition callback
% callback = ['plotProjAmpVsPosition(', vw.name, ', 1);'];
callback = ['plotParamVsPosition(', vw.name, ', ', '''Phase''); getPlottedData;'];
uimenu(lineMenu, 'Label', 'NYI: ProjAmp vs. Pos', 'Separator', 'off', ...
	'CallBack', callback);
%-----------------

% publishFigure callback
%  publishFigure(vw);
callback = [vw.name, ' = publishFigure(', vw.name, ');'];
uimenu(curScanMenu, 'Label', 'Publish Figure', 'Separator', 'off', ...
	'CallBack', callback);
callback = [vw.name, ' = publishFigure(', vw.name, ', ''paramPrompt'');'];
uimenu(curScanMenu, 'Label', 'Publish Figure (set params)', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function acrossScansSubmenu(h, vw)
%% plot options for comparing data across scans
acrossScanMenu = uimenu(h, 'Label', 'Across Scans', 'Separator', 'off');

%---------------
% mean t-series
%---------------
% plotMeanTSeries all scans callback:
%  plotMeanTSeries(VOLUME{1},1:viewGet(VOLUME{1}, 'nscans'), false);
%  getPlottedData;
callback = ['plotMeanTSeries(', vw.name, ',1:viewGet(',vw.name,', ''nscans''), false); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Mean Time Series (all scans)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMeanTSeriesRaw all scans callback:
%  plotMeanTSeries(VOLUME{1},1:viewGet(VOLUME{1}, 'nscans'), false, true);
%  getPlottedData;
callback = ['plotMeanTSeries(', vw.name, ',1:viewGet(',vw.name,', ''nscans''), false, true); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Mean Time Series Raw (all scans)', 'Separator', 'off', ...
	'CallBack', callback);


% plotMeanTSeries selected scans all scans callback:
%  plotMeanTSeries(VOLUME{1}, [], true); 
%  getPlottedData;
callback = ['plotMeanTSeries(', vw.name, ', [], true); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Mean Time Series (selected scans)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMeanTSeriesRaw selected scans all scans callback:
%  plotMeanTSeries(VOLUME{1}, [], true, true); 
%  getPlottedData;
callback = ['plotMeanTSeries(', vw.name, ', [], true, true); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Mean Time Series Raw (selected scans)', 'Separator', 'off', ...
	'CallBack', callback);


%---------------
% single cycle
%---------------
% plotSingleCycleErrMultipleScans callback:
%  plotMeanTSeries(VOLUME{1},1:viewGet(VOLUME{1}, 'nscans'));
%  getPlottedData;
callback = ['plotSingleCycleErrMultipleScans(', vw.name, ',1:viewGet(',vw.name,', ''nscans'')); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Single Cycle (all scans)', 'Separator', 'on', ...
	'CallBack', callback);

% plotSingleCycleErrMultipleScans callback:
%  plotMeanTSeries(VOLUME{1});
%  getPlottedData;
callback = ['plotSingleCycleErrMultipleScans(', vw.name, '); getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Single Cycle (selected scans)', 'Separator', 'off', ...
	'CallBack', callback);

%-----------------
% other stuff
%-----------------
% plotVectorMean callback:
%  plotVectorMean(vw);
callback = ['plotVectorMean(', vw.name, ');getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Vector Mean (polar)', 'Separator', 'on', ...
	'CallBack', callback);

% plotCorrelations callback:
%  plotCorrelations(vw);
callback = ['plotCorrelations(', vw.name, ');getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Correlations (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% amplitude menu
ampMenu = uimenu(acrossScanMenu, 'Label', 'Amplitudes', 'Separator', 'off');

% plotAmps callback:
%  plotAmps(vw);
callback = ['plotAmps(', vw.name, ');getPlottedData;'];
uimenu(ampMenu, 'Label', 'Current ROI (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleAmps callback:
%  plotMultipleAmps(vw);
callback = ['plotMultipleAmps(', vw.name, ');getPlottedData;'];
uimenu(ampMenu, 'Label', 'Multiple ROIs (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleAmps_perCondition callback:
%  plotMultipleAmps_perCondition(vw);
callback = ['plotMultipleAmps_perCondition(', vw.name, ');getPlottedData;'];
uimenu(ampMenu, 'Label', 'Multiple ROIs per condition', 'Separator', 'off', ...
	'CallBack', callback);

% relative amplitude menu
relAmpMenu = uimenu(acrossScanMenu, 'Label', 'Relative Amplitudes', 'Separator', 'off');

% plotRelativeAmps callback:
%  plotAmps(vw);
callback = ['plotRelativeAmps(', vw.name, ');getPlottedData;'];
uimenu(relAmpMenu, 'Label', 'Current ROI (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleRelAmps callback:
%  plotMultipleRelAmps(vw);
callback = ['plotMultipleRelAmps(', vw.name, ');getPlottedData;'];
uimenu(relAmpMenu, 'Label', 'Multiple ROIs (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% projected amplitude menu
projAmpMenu = uimenu(acrossScanMenu, 'Label', 'Projected Amplitudes', 'Separator', 'off');

% plotProjectedAmps callback:
%  plotProjectedAmps(vw);
callback = ['plotProjectedAmps(', vw.name, ');getPlottedData;'];
uimenu(projAmpMenu, 'Label', 'Current ROI (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleProjectedAmps callback:
%  plotMultipleProjAmps(vw);
callback = ['plotMultipleProjectedAmps_PerCondition(', vw.name, ');getPlottedData;'];
uimenu(projAmpMenu, 'Label', 'Multiple ROIs (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% relative projected amplitude menu
relProjAmpMenu = uimenu(acrossScanMenu, 'Label', 'Relative Projected Amplitudes', 'Separator', 'off');

% plotRelativeProjectedAmps callback:
%  plotRelativeProjectedAmps(vw);
callback = ['plotRelativeProjectedAmps(', vw.name, ');getPlottedData;'];
uimenu(relProjAmpMenu, 'Label', 'Current ROI (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotMultipleRelativeProjectedAmps callback:
%  plotMultipleRelProjAmps(vw);
callback = ['plotMultipleRelProjAmps(', vw.name, ');getPlottedData;'];
uimenu(relProjAmpMenu, 'Label', 'Multiple ROIs (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% plotParamMap callback:
%  plotParamMap(vw);
callback = ['plotParamMap(', vw.name, ');getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Parameter Map (bar)', 'Separator', 'off', ...
	'CallBack', callback);

% Laminar amplitudes
callback = 'PlotMultipleLaminarProfiles;';
uimenu(acrossScanMenu, 'Label', 'Laminar amplitudes', 'Separator', 'off', ...
	'CallBack', callback);

% In the flat map vw, we may want to create line ROIs and then
% plot a parameter as a function of the line position. So if this is
% a Flat vw, we add the plotParamVsPosition calls.
if strcmp(vw.viewType, 'Flat')
	acrossScans_flatSubmenu(acrossScanMenu, vw);
end

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function acrossScans_flatSubmenu(acrossScanMenu, vw)
%% subset of FLAT-vw specific plotting options, across scans

% plotPhaseVsPosition callback
%  plotPhaseVsPosition(vw);
% plotParamVsPosition( vw, plotParam, scanList ); % option = = 1 is to get to choose scans
callback = ['plotParamVsPosition(', vw.name, ', ', '''Phase'');getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Phase vs. Position (line ROI)', 'Separator', 'off', ...
	'CallBack', callback);

% plotCoVsPosition callback
%  plotCoVsPosition(vw);
% plotParamVsPosition( vw, plotParam, scanList ); % option = = 1 is to get to choose scans
callback = ['plotParamVsPosition(', vw.name, ', ''Co'', 1);getPlottedData;'] ;
uimenu(acrossScanMenu, 'Label', 'Co vs. Position (line ROI)', 'Separator', 'off', ...
	'CallBack', callback);

% plotAmplitudeVsPosition callback
%  plotAmplitudeVsPosition(vw);
% callback = ['plotAmplitudeVsPosition(', vw.name, ', 1);'];
callback = ['plotParamVsPosition(', vw.name, ', ''Amplitude'', 1);getPlottedData;'];
uimenu(acrossScanMenu, 'Label', 'Amplitude vs. Position (line ROI)', 'Separator', 'off', ...
	'CallBack', callback);

% plotProjAmpVsPosition callback
%  plotProjAmpVsPosition(vw);
% callback = ['plotProjAmpVsPosition(', vw.name, ', 1);'];
callback = ['plotParamVsPosition(', vw.name, ', ''ProjAmp'', 1);'];
uimenu(acrossScanMenu, 'Label', 'Projected Amplitude vs. Position (line ROI)', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function prfSubmenu(h, vw)
%% pRF / Retinotopy Model-specific plotting options
rmMenu = uimenu(h, 'Label', 'Retinotopic Model', 'Separator', 'on');

% plot stimulus (ras: moved to top since you can do this before you solve
% the model)
callback = ['rmStimulusMatrix(viewGet(', vw.name, ', ''rmparams''), [], [], 2, false);'];
uimenu(rmMenu, 'Label', 'View stimulus aperture', 'Separator', 'off', ...
	'CallBack', callback);

callback = ['rmStimulusMatrix(viewGet(', vw.name, ', ''rmparams''), [], [], 1, false);'];
uimenu(rmMenu, 'Label', 'View stimulus aperture (movie)', 'Separator', 'off', ...
	'CallBack', callback);

callback = ['rmStimulusMatrix(viewGet(', vw.name, ', ''rmparams''), [], [], 2, true);'];
uimenu(rmMenu, 'Label', 'View stimulus aperture with final images (convolved with hRF)', 'Separator', 'off', ...
	'CallBack', callback);


% visualize the model fit (cycles)
callback = ['rmPlotGUI(', vw.name, ', [], 0);'];
uimenu(rmMenu, 'Label', 'Receptive field and model fit (averaged across repeats)', 'Separator', 'off', ...
	'Separator', 'on', 'CallBack', callback);

% visualize the model fit (all time points)
callback = ['rmPlotGUI(', vw.name, ', [], 1);'];
uimenu(rmMenu, 'Label', 'Receptive field and model fit (all time points)', 'Separator', 'off', ...
	'CallBack', callback);

% visualize pRF distributions
callback = sprintf('plotEccVsPhase(%s, ''dialog''); ', vw.name);
uimenu(rmMenu, 'Label', 'Plot pRF centers (selected ROI)', ...
	'Separator', 'on', 'CallBack', callback);

callback = sprintf('pRF_COV = rmPlotCoverage(%s, ''dialog''); ', vw.name);
uimenu(rmMenu, 'Label', 'Plot pRF coverage (selected ROI)', ...
	'Separator', 'off', 'CallBack', callback);

callback = sprintf('pRF_DATA = rmPlotEccSigma(%s); ', vw.name);
uimenu(rmMenu, 'Label', 'Plot pRF Size vs. Eccentricity (current ROI)', ...
	'Separator', 'on', 'CallBack', callback);

callback = sprintf('pRF_DATA = rmPlotMultiEccSigma(%s); ', vw.name);
uimenu(rmMenu, 'Label', 'Plot pRF Size vs. Eccentricity (selected ROIs)', ...
	'Separator', 'off', 'CallBack', callback);

% % plot pRF size and 1D position variance vs. eccentricity
% callback = ['rmPlotEccSigma(', vw.name, ',[],[],1);'];
% uimenu(rmMenu, 'Label', 'Plot pRF size and 1D pos var vs eccentricity', 'Separator', 'off', ...
% 	'CallBack', callback);
% 
% % plot pRF size and 2D position variance vs. eccentricity
% callback = ['rmPlotEccSigma(', vw.name, ',[],[],2);'];
% uimenu(rmMenu, 'Label', 'Plot pRF size and 2D pos var vs eccentricity', 'Separator', 'off', ...
% 	'CallBack', callback);

callback = sprintf('pRF_DATA = rmPlotTwoParams(%s); ', vw.name);
uimenu(rmMenu, 'Label', 'Plot any two retModel parameters (current ROI)', ...
	'Separator', 'off', 'CallBack', callback);

callback = sprintf('pRF_DATA = rmVisualizeRFs(%s, %s.selectedROI); ', ...
					vw.name, vw.name);
uimenu(rmMenu, 'Label', 'Visualize pRF Distributions (selected ROI)', ...
    'Separator', 'on', 'CallBack', callback);

callback = sprintf('pRF_DATA = rmVisualizeRFs(%s); ', vw.name);
uimenu(rmMenu, 'Label', 'Visualize pRF Distributions (all ROIs)', ...
	'Separator', 'off', 'CallBack', callback);

callback = sprintf('rmPlotMap(%s, ''dialog''); ', vw.name);
uimenu(rmMenu, 'Label', 'pRF Plot Current Map (selected ROI)', ...
	'Separator', 'off', 'CallBack', callback);

callback = sprintf('pRF_MOVIE = rmPlotReconstruction(%s, 1); ', vw.name);
uimenu(rmMenu, 'Label', 'pRF Reconstruction Movie (selected ROI)', ...
	'Separator', 'off', 'CallBack', callback);

% output stats
callback = ['rmRoiStats(', vw.name, ');'];
uimenu(rmMenu, 'Label', 'ROI stats', 'Separator', 'on', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function tSeriesArtifactSubmenu(h, vw)
%% Plot options to aid in checking for tSeries artifacts
tseriesMenu = uimenu(h, 'Label', 'Check for tSeries artifact', 'Separator', 'off');

% Plot rmse callback:
%  plotResidualError(vw, getCurScan(vw))
callback = ['plotResidualError(', vw.name, ', viewGet(', vw.name, ', ''current scan''));'];
uimenu(tseriesMenu, 'Label', 'RMSE with first frame', 'Separator', 'off', ...
	'CallBack', callback);

% Plot max frame difference callback:
%  plotMaxTSErr(vw)
callback = ['plotMaxTSErr(', vw.name, ', viewGet(', vw.name, ', ''current scan''));'];
uimenu(tseriesMenu, 'Label', 'Max frame-to-frame difference', 'Separator', 'off', ...
	'CallBack', callback);

% Plot the rmse as a 3D plot across all scans
callback = ['plotResidualErrorAcrossScans(', vw.name, ');'];
uimenu(tseriesMenu, 'Label', 'Plot error across scans', 'Separator', 'off', ...
	'CallBack', callback);

% Plot the rmse between the first frame of each scan across all slices
callback = ['plotResidualErrorBetweenScans(', vw.name, ');'];
uimenu(tseriesMenu, 'Label', 'Plot RMS error between scans', 'Separator', 'off', ...
	'CallBack', callback);
return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function colorbarSubmenu(h, vw)
%% Color bar plot menu options
cbMenu = uimenu(h, 'Label', 'Color bar plots', 'Separator', 'off');

% Create a figure with the wedge map in it.
cb = sprintf('cmapWedge(%s);', vw.name);
uimenu(cbMenu, 'Label', 'Polar Angle Wedge', 'Separator', 'off', ...
	'CallBack', cb);

% Create a figure with the eccentricity map in it.
cb = sprintf('plotEccRing(%s);', vw.name);
uimenu(cbMenu, 'Label', 'Eccentricity rings', 'Separator', 'off', ...
	'CallBack', cb);


% Get plotted data callback
callback = ['plotColorbar(', vw.name, ')'];
uimenu(cbMenu, 'Label', 'Plot current colorbar', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function overlaySubmenu(h, vw)
%% Superimpose / Overlay stuff submenu
overlayMenu = uimenu(h, 'Label', 'Superimpose', 'Separator', 'off');

% Superimpose mean functional from first and last scans
callback = ['overlayMeanTSeries(', vw.name, ');'];
uimenu(overlayMenu, 'Label', 'Mean tSeries from 1st and last scans', 'Separator', 'off', ...
	'CallBack', callback);

% Superimpose mean functional from two user-chosen scans
callback = ['overlayMeanTSeries(', vw.name, ', 0, 0);'];
uimenu(overlayMenu, 'Label', 'Mean tSeries (choose scans)', 'Separator', 'off', ...
	'CallBack', callback);


% superimpose two maps/fields, same session
callback = ['overlayMapsSameSession(', vw.name, ');'];
uimenu(overlayMenu, 'Label', 'Two maps/corAnal fields, same session', 'Separator', 'off', ...
	'CallBack', callback);

% superimpose two maps, select files
callback = ['overlayMapFiles(', vw.name, ');'];
uimenu(overlayMenu, 'Label', 'Two maps, select files', 'Separator', 'off', ...
	'CallBack', callback);

return
% /---------------------------------------------------------------------/



% /---------------------------------------------------------------------/
function tSeriesMovieSubmenu(h, vw)
%% Show a movie or montage for inplane vw    %
mrGlobals
movieMenu = uimenu(h, 'Label', 'tSeries movie', 'Separator', 'off');

% Movie w/ Java UI (cur slice, cur scan):
%  tSeriesMovie(vw);
cb = sprintf('%s.ui.movie = tSeriesMovie(%s);', vw.name, vw.name);
uimenu(movieMenu, 'Label', 'Movie UI (cur scan)', 'Separator', 'off', ...
	'CallBack', cb);

% Movie w/ Java UI (cur slice, cur scan):
%  tSeriesMovie(vw, 1:numScans(vw));
cb = sprintf('%s.ui.movie = tSeriesMovie(%s, ', vw.name, vw.name);
cb = [cb sprintf('1:numScans(%s));', vw.name)];
uimenu(movieMenu, 'Label', 'Movie UI (all scans)', 'Separator', 'off', ...
	'CallBack', cb);

% Movie w/ Java UI (set params):
%  tSeriesMovie(vw);
cb = sprintf('%s = callTSeriesMovie(%s);', vw.name, vw.name);
uimenu(movieMenu, 'Label', 'Movie UI (set params)', 'Separator', 'off', ...
	'Accelerator', '7', 'CallBack', cb);


% Make a movie without anatomies:
%  vw = makeTSeriesMovie(vw, getCurScan(vw), viewGet(vw, 'Current Slice'), 0);
callback = [vw.name, ' = makeTSeriesMovie(', vw.name, ...
	', getCurScan(', vw.name, '), viewGet(', vw.name, ', ''Current Slice''), 0);'];
uimenu(movieMenu, 'Label', 'Make movie without anatomies', 'Separator', 'off', ...
	'CallBack', callback);

% Make a movie with anatomies:
%  vw = makeTSeriesMovie(vw, getCurScan(vw), viewGet(vw, 'Current Slice'), 1);
callback = [vw.name, ' = makeTSeriesMovie(', vw.name, ...
	', getCurScan(', vw.name, '),  viewGet(', vw.name, ', ''Current Slice''), 1);'];
uimenu(movieMenu, 'Label', 'Make movie with anatomies', 'Separator', 'off', ...
	'CallBack', callback);

% Make a movie without anatomies (all slices):
%  vw = makeTSeriesMovie(vw, getCurScan(vw), viewGet(vw, 'Current Slice'), 0, 0);
callback = [vw.name, ' = makeTSeriesMovie(', vw.name, ...
	', getCurScan(', vw.name, '), 0, 0, 0);'];
uimenu(movieMenu, 'Label', 'Make move w/o anat (all slices)', 'Separator', 'off', ...
	'CallBack', callback);

% Make a movie with anatomies (all slices):
%  vw = makeTSeriesMovie(vw, getCurScan(vw), viewGet(vw, 'Current Slice'), 1, 0);
callback = [vw.name, ' = makeTSeriesMovie(', vw.name, ...
	', getCurScan(', vw.name, '), 0, 1, 0);'];
uimenu(movieMenu, 'Label', 'Make movie w/ anat (all slices)', 'Separator', 'off', ...
	'CallBack', callback);

if strcmp(vw.viewType, 'Inplane')
	% Export t-series movie    (commented out ras 05/06 -- not used?)
	cb = ['saveTSeriesMovie(', vw.name, ');'];
	uimenu(movieMenu, 'Label', 'Export TSeries Movie frames...', ...
		'Separator', 'off', 'Callback', cb);
end

% (Re-)show a movie:
%  showTSeriesMovie(vw);
callback = ['showTSeriesMovie(', vw.name, ');'];
uimenu(movieMenu, 'Label', 'Re-show movie', 'Separator', 'off', ...
	'CallBack', callback);

montageMenu = uimenu(h, 'Label', 'tSeries montage', 'Separator', 'off');

% Show a montage of current scan:
%  tseriesPict(getCurScan(', vw.name, '))
callback = ['tseriesPict(', vw.name, ', viewGet(', vw.name, ', ''current scan''));'];
uimenu(montageMenu, 'Label', 'Current scan', 'Separator', 'off', ...
	'CallBack', callback);
callback = ['tseriesPict(', vw.name, ', getCurScan(', vw.name, '), [], ''', HOMEDIR, ''');'];
uimenu(montageMenu, 'Label', 'Current scan (JPEG save)', 'Separator', 'off', ...
	'CallBack', callback);

% Show a montage of all scans:
%  tseriesPict;
callback = ['tseriesPict(', vw.name, ');'];
uimenu(montageMenu, 'Label', 'All scans', 'Separator', 'off', ...
	'CallBack', callback);
callback = ['tseriesPict(', vw.name, ', [], [], ''', HOMEDIR, ''');'];
uimenu(montageMenu, 'Label', 'All scans (JPEG save)', 'Separator', 'off', ...
	'CallBack', callback);

return

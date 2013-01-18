function vw=analysisMenu(vw)
% vw=analysisMenu(vw)
% 
% Set up the callbacks of the ANALYSIS menu.
% 
% djh, 1/22/98
%
% 7/16/99, djh, added motion compensation, mean map, and resStd map.
% 10/6/99, on,  - activated motion compensation 3D robust.
%               - added plot of residual error between baseFrame
%                 and other frames
% 12/23/99 on, new GUI to motion compensation routines to allow selecting
%               several scans
% 06/06/00 on, - New menu option for BETWEEN SCAN motion compensation
% djh, 2/2010 - use this menu for all viewTypes now that tSeries can be mapped 
%               to the Gray and/or Flat
% ress, 10/05 - Added slice-timing adjustment calculation for Inplane view,
%               and laminar coordinate calculations for volume view.
% $Author: sayres $
% $Date: 2008/08/01 01:20:57 $
% 6/2012 kgs added tSNR map

% Top level Analysis menu
analysismenu = uimenu('Label','Analysis','Separator','on');

% attach submenus:
tSeriesSubmenu(analysismenu, vw);
travelingWaveSubmenu(analysismenu, vw);
retinotopyModelSubmenu(analysismenu, vw);

%eventMenu(vw, analysismenu);

meanMapSubmenu(analysismenu, vw);
tSNRmapSubmenu(analysismenu, vw);
stdDevSubmenu(analysismenu, vw);
snrMapSubmenu(analysismenu, vw);
xScanCorrSubmenu(analysismenu, vw);
corrSubmenu(analysismenu, vw);


% inplane-specific options
if strcmp(vw.viewType,'Inplane')
    % Spatial Gradient map callback:
    %   vw=computeSpatialGradient(vw);
    cb=[vw.name,'=computeSpatialGradient(',vw.name,');'];
    uimenu(analysismenu,'Label',...
        'Compute Spatial Gradient for Inhomogeneity Correction',...
        'Separator','off','CallBack',cb);
    
    motionMenu = motionSubmenu(analysismenu, vw);
%     freqCorrectionMenu = freqCorrectSubmenu(analysismenu, vw);
end

% volume/gray-specific options
if strcmp(vw.viewType,'Volume') || strcmp(vw.viewType,'Gray')
    volumemmenu = volumeSubmenu(analysismenu, vw);
end

return
% /--------------------------------------------------------------------/ %






% /--------------------------------------------------------------------/ %
function tseriesMenu = tSeriesSubmenu(analysismenu, vw)

tseriesMenu = uimenu(analysismenu,'Label','Time series','Separator','off');

% Adjust slice timing callback:
cb = [sprintf('%s = AdjustSliceTiming(%s); ', vw.name, vw.name) ...
	  sprintf('%s = refreshScreen(%s); ', vw.name, vw.name)];
uimenu(tseriesMenu, 'Label', 'Adjust slice timing', 'Separator', 'off', ...
    'CallBack', cb);

% Average tSeries callback:
%   averageTSeries(vw);
cb=['averageTSeries(',vw.name,', ''dialog'');'];
uimenu(tseriesMenu,'Label','Average tSeries','Separator','off',...
    'CallBack',cb);

%   averageTSeriesAllScans(vw);
cb=sprintf('%s = averageTSeriesAllScans(%s);',vw.name, vw.name);
uimenu(tseriesMenu,'Label','Average all tSeries by annoation','Separator','off',...
    'CallBack',cb);

% Average tSeries Across Sessions callback:
%   averageTSeriesAcrossSessions(vw);
cb='averageTSeriesAcrossSessions;';
uimenu(tseriesMenu,'Label','Average tSeries across sessions','Separator','off',...
    'CallBack',cb);

% Flip tSeries callback:
%   flipTSeries(vw);
cb=['flipTSeries(',vw.name,');'];
uimenu(tseriesMenu,'Label','Flip (time-reverse) tSeries','Separator','off',...
    'CallBack',cb);

% Shift tSeries callbacks
%    shiftTSeries(vw,shift)
shiftTseriesMenu = uimenu(tseriesMenu,'Label','Shift tSeries','Separator','off');
cb=['shiftTSeries(',vw.name,',1);'];
uimenu(shiftTseriesMenu,'Label','Advance 1 frame','Separator','off',...
    'CallBack',cb);
cb=['shiftTSeries(',vw.name,',2);'];
uimenu(shiftTseriesMenu,'Label','Advance 2 frames','Separator','off',...
    'CallBack',cb);
cb=['shiftTSeries(',vw.name,',3);'];
uimenu(shiftTseriesMenu,'Label','Advance 3 frames','Separator','off',...
    'CallBack',cb);
cb=['shiftTSeries(',vw.name,',-1);'];
uimenu(shiftTseriesMenu,'Label','Delay 1 frame','Separator','off',...
    'CallBack',cb);
cb=['shiftTSeries(',vw.name,',-2);'];
uimenu(shiftTseriesMenu,'Label','Delay 2 frames','Separator','off',...
    'CallBack',cb);
cb=['shiftTSeries(',vw.name,',-3);'];
uimenu(shiftTseriesMenu,'Label','Delay 3 frames','Separator','off',...
    'CallBack',cb);

% Spatially blur tSeries menu:
cb = sprintf('spatialBlurTSeries(%s, ''dialog''); ', vw.name);
uimenu(tseriesMenu, 'Label', 'Spatially Blur tSeries',...
        'Separator', 'on', 'Callback', cb);

% Clip frames from beginning/end of tSeries
cb = sprintf('tSeriesClipFrames(%s);',vw.name);
uimenu(tseriesMenu,'Label','Clip Frames from tSeries...',...
        'Separator','off','Callback',cb);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function twMenu = travelingWaveSubmenu(analysismenu, vw)
% create a submenu for Traveling Wave Analyses.
twMenu = uimenu(analysismenu, 'Label', 'Traveling Wave Analyses', ...
        'Separator','off');

coranalSubMenu = uimenu(twMenu,'Label','Compute corAnal','Separator','off');

% Correlation analysis (all scans):
%  vw = computeCorAnal(vw,0);
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal(',vw.name,',0); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranalSubMenu,'Label','Compute corAnal (all scans)','Separator','off',...
    'CallBack',cb);

% Correlation analysis (current scan):
%  vw = computeCorAnal(vw,viewGet(vw, 'curScan'));
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranalSubMenu,'Label','Compute corAnal (current scan)','Separator','off',...
    'CallBack',cb);

% Correlation analysis (select scans):
%  vw = computeCorAnal(vw,0);
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal(',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranalSubMenu,'Label','Compute corAnal (select scans)','Separator','off',...
    'CallBack',cb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
coranal2SubMenu = uimenu(twMenu,'Label','Compute corAnal 2 freq.','Separator','off');

% Correlation analysis (all scans):
%  vw = computeCorAnal(vw,0);
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal2Freq(',vw.name,',0); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranal2SubMenu,'Label','Compute corAnal 2 freq. (all scans)','Separator','off',...
    'CallBack',cb);

% Correlation analysis (current scan):
%  vw = computeCorAnal(vw,viewGet(vw, 'curScan'));
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal2Freq(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranal2SubMenu,'Label','Compute corAnal 2 freq. (current scan)','Separator','off',...
    'CallBack',cb);

% Correlation analysis (select scans):
%  vw = computxScanCorrAllSubMenueCorAnal(vw,0);
%  vw = refreshScreen(vw);
cb=[vw.name,'=computeCorAnal2Freq(',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(coranal2SubMenu,'Label','Compute corAnal 2 freq. (select scans)','Separator','off',...
    'CallBack',cb);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % resStdMap submenu

    resStdMenu = uimenu(twMenu,'Label','Residual Std Map','Separator','off');

    % Residual Std map (all scans):
    %   vw=computeResStdMap(vw,0);
    %   vw=setDisplayMode(vw,'map');
    %   vw=refreshScreen(vw);
    cb=[vw.name,'=computeResStdMap(',vw.name,',0); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','Res Std Map (all scans)','Separator','off',...
        'CallBack',cb);

    % Residual Std map (current scan):
    %   vw=computeResStdMap(vw,viewGet(vw, 'curScan'));
    %   vw=setDisplayMode(vw,'map');
    %   vw=refreshScreen(vw);
    cb=[vw.name,'=computeResStdMap(',vw.name,',getCurScan(',vw.name,')); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','Res Std Map (current scan)','Separator','off',...
        'CallBack',cb);

    % Residual Std map (select scans):
    %   vw=computeResStdMap(vw);
    %   vw=setDisplayMode(vw,'map');
    %   vw=refreshScreen(vw);
    cb=[vw.name,'=computeResStdMap(',vw.name,'); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','Res Std Map (select scans)','Separator','off',...
        'CallBack',cb);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % -log10Pmap submenu

    resStdMenu = uimenu(twMenu,'Label','-log10 P map','Separator','off');

    % log10Pmap (all scans):

    cb=[vw.name,'=computeProbMap(',vw.name,',0); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','-log10 P values (all scans)','Separator','off',...
        'CallBack',cb);

    % log10Pmap (current scan):

    cb=[vw.name,'=computeProbMap(',vw.name,',getCurScan(',vw.name,')); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','-log10 P values (current scan)','Separator','off',...
        'CallBack',cb);

    % log10Pmap (select scans):

    cb=[vw.name,'=computeProbMap(',vw.name,'); ',...
            vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
            vw.name,'=refreshScreen(',vw.name,');'];
    uimenu(resStdMenu,'Label','-log10 P values (select scans)','Separator','off',...
        'CallBack',cb);
return
% /--------------------------------------------------------------------/ %





% /--------------------------------------------------------------------/ %
function meanMenu = meanMapSubmenu(analysismenu, vw)
% attach a sub-menu for mean map analysis options.
meanMenu = uimenu(analysismenu,'Label','Mean Map','Separator','off');

% Mean map (all scans):
%   vw=computeMeanMap(vw,0);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeMeanMap(',vw.name,',0); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','Mean Map (all scans)','Separator','off',...
    'CallBack',cb);

% Mean map (current scan):
%   vw=computeMeanMap(vw,viewGet(vw, 'curScan'));
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeMeanMap(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','Mean Map (current scan)','Separator','off',...
    'CallBack',cb);

% Mean map (select scans):
%   vw=computeMeanMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeMeanMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','Mean Map (select scans)','Separator','off',...
    'CallBack',cb);
return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function tSNRMenu = tSNRmapSubmenu(analysismenu, vw)
% attach a sub-menu for mean map analysis options.
tSNRMenu = uimenu(analysismenu,'Label','tSNR Map','Separator','off');

% tSNR (all scans):
%   vw=computeMeanMap(vw,0);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computetSNRMap(',vw.name,',0); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(tSNRMenu,'Label','tSNR Map (all scans)','Separator','off',...
    'CallBack',cb);

% tSNR (current scan):
%   vw=computeMeanMap(vw,getCurScan(vw));
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computetSNRMap(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(tSNRMenu,'Label','tSNR Map (current scan)','Separator','off',...
    'CallBack',cb);

% tSNR map (select scans):
%   vw=computeMMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computetSNRMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(tSNRMenu,'Label','tSNR Map (select scans)','Separator','off',...
    'CallBack',cb);
return
% /--------------------------------------------------------------------/ %


% /--------------------------------------------------------------------/ %
function stdMenu = stdDevSubmenu(analysismenu, vw)
% create a sub-menu for standard-deviation of tSeries analyses
stdMenu = uimenu(analysismenu,'Label','Stddev Map','Separator','off');

% Stddev map (all scans):
%   vw=computeStdMap(vw,0);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeStdMap(',vw.name,',0); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(stdMenu,'Label','Stddev Map (all scans)','Separator','off',...
    'CallBack',cb);

% Stddev map (current scan):
%   vw=computeResStdMap(vw,viewGet(vw, 'curScan'));
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeStdMap(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(stdMenu,'Label','Stddev Map (current scan)','Separator','off',...
    'CallBack',cb);

% Residual Std map (select scans):
%   vw=computeStdMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeStdMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(stdMenu,'Label','Stddev Map (select scans)','Separator','off',...
    'CallBack',cb);

return
% /--------------------------------------------------------------------/ %


% /--------------------------------------------------------------------/ %
function xScanCorrMenu = xScanCorrSubmenu(analysismenu, vw)
% create a sub-menu for cross-scan t-series correlation  analyses
xScanCorrMenu = uimenu(analysismenu,'Label','Cross-Scan Corr Map (slow)','Separator','off');

xScanCorrAllSubMenu = uimenu(xScanCorrMenu,'Label','avg of all scan pairs','Separator','off');


% CrossScanCorr map do Averaging (all scans):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,',0); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrAllSubMenu,'Label','Cross Scan Corr Map(all scans)','Separator','off',...
    'CallBack',cb);

% CrossScanCorr map do Averaging (selected scans):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrAllSubMenu,'Label','Cross Scan Corr Map (select scans)','Separator','off',...
    'CallBack',cb);

% CrossScanCorr map do Averaging (by annotation):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,', ''group''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrAllSubMenu,'Label','Cross Scan Corr Map (by annotation)','Separator','off',...
    'CallBack',cb);

xScanCorrEachSubMenu = uimenu(xScanCorrMenu,'Label','each scan vs avg of other scans','Separator','off');

% CrossScanCorr map (all scans):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,',0,[],false); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrEachSubMenu,'Label','Cross Scan Corr Map (all scans)','Separator','off',...
    'CallBack',cb);

% CrossScanCorr map (selected scans):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,',[],[],false); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrEachSubMenu,'Label','Cross Scan Corr Map (select scans)','Separator','off',...
    'CallBack',cb);

% CrossScanCorr map (by annotation):
cb=[vw.name,'=computeCrossScanCorrelationMap(',vw.name,', ''group'',[],false); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(xScanCorrEachSubMenu,'Label','Cross Scan Corr Map (by annotation)','Separator','off',...
    'CallBack',cb);


return
% /--------------------------------------------------------------------/ %

% /--------------------------------------------------------------------/ %
function meanMenu = snrMapSubmenu(analysismenu, vw)
% attach a sub-menu for SNR map analysis options.
meanMenu = uimenu(analysismenu,'Label','SNR Map (mean/std)','Separator','off');

% SNR map (all scans):
%   vw=computeSnrMap(vw,0);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeSnrMap(',vw.name,',0); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','Snr Map (all scans)','Separator','off',...
    'CallBack',cb);

% SNR map (current scan):
%   vw=computeSnrMap(vw,viewGet(vw, 'curScan'));
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeSnrMap(',vw.name,',getCurScan(',vw.name,')); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','SNR Map (current scan)','Separator','off',...
    'CallBack',cb);

% SNR map (select scans):
%   vw=computeSnrMap(vw);
%   vw=setDisplayMode(vw,'map');
%   vw=refreshScreen(vw);
cb=[vw.name,'=computeSnrMap(',vw.name,'); ',...
        vw.name,'=setDisplayMode(',vw.name,',''map''); ',...
        vw.name,'=refreshScreen(',vw.name,');'];
uimenu(meanMenu,'Label','SNR Map (select scans)','Separator','off',...
    'CallBack',cb);
return
% /--------------------------------------------------------------------/ %


% /--------------------------------------------------------------------/ %
function motionMenu = motionSubmenu(analysismenu, vw)
% attach a submenu with motion compensation options.
motionMenu = uimenu(analysismenu,'Label','Motion compensation','Separator','off');

% ras 04/2006: turned off inplane compensation, seems unnecessary nowadays,
% don't think anyone uses it; turned off revert tSeries, seems like it's
% obsolete since the motion options create new data types; added option
% to do within + between scans at once.
% % Motion compensation callback:
% %    vw = inplaneMotionComp(vw)
% cb=[vw.name,'=inplaneMotionCompSelScan(',vw.name,');'];
% uimenu(motionMenu,'Label','Rigid Body: Inplane motion compensation', ...
%     'Separator', 'off', 'CallBack',cb);

% 3d motion compensation callback:
%    vw = motionCompSelScan(vw)
cb=[vw.name,'=motionCompSelScan(',vw.name,');'];
uimenu(motionMenu,'Label','Rigid Body: Within-Scans compensation', ...
        'Separator', 'off', 'CallBack', cb);

% Between Scans motion compensation
%    vw = betweenScanMotCompSelScan(vw)
cb=[vw.name,'=betweenScanMotCompSelScan(',vw.name,');'];
uimenu(motionMenu,'Label','Rigid Body: Between Scans compensation', ...
        'Separator', 'off', 'CallBack',cb);
    
% Within and Between Scans Motion Compensation
cb = sprintf('%s = motionCompNestaresFull(%s); ', vw.name, vw.name);
uimenu(motionMenu, 'Label', 'Rigid Body: Both Between + Within Scans', ...
        'Separator', 'off', 'CallBack',cb);

% % Revert motion compensation callback:
% %    vw = revertMotionComp(vw)
% % [Is this still needed if motion compensation creates a new data
% % type?]
% cb=[vw.name,'=revertMotionCompSelScan(',vw.name,');'];
% uimenu(motionMenu, 'Label', 'Revert motion compensation', ...
%     'Separator', 'off', 'CallBack', cb);

% Motion compensation by Mutual Information MI callback:
%    vw = motionCompMutualInfMeanInit(vw)
cb=[vw.name,'=motionCompSetArgs(',vw.name,');'];
uimenu(motionMenu,'Label','Motion Compensation (MI)', ...
    'Separator','off', 'CallBack', cb);


% also create a submenu for plotting consecutive frame difference
% (put this here, might put it back if people want it)
cfdMenu = uimenu(analysismenu, 'Label', 'Consecutive frame difference', ...
                    'Separator','off');

% MSE callback:
%    motionCompPlotMSE(vw)
cb=['motionCompPlotMSE(',vw.name,',''selected'');'];
uimenu(cfdMenu, 'Label','MSE (current ROI)','Separator','off',...
    'CallBack', cb);

% MI callback:
%    motionCompPlotMI(vw)
cb=['motionCompPlotMI(',vw.name,',''selected'');'];
uimenu(cfdMenu, 'Label','MI (current ROI)','Separator','off',...
    'CallBack', cb);

% Compare data types callback:
%    motionCompCompareDataTypes(vw)
cb=['motionCompCompareDataTypes(',vw.name,');'];
uimenu(cfdMenu, 'Label', 'Compare data types','Separator','off',...
    'CallBack', cb);
return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function freqCorrectionMenu = freqCorrectSubmenu(analysismenu, vw)
% attach a submenu with options for correction off-resonance frequency 
% artifacts.
freqCorrectionMenu = uimenu(analysismenu,'Label','Frequency Correction','Separator','off');
    
% Step1 callback:
%    reconFreq_step1
cb=['reconFreqSetArgs_step1(',vw.name,');'];
uimenu(freqCorrectionMenu,'Label','Step 1','Separator','off',...
    'CallBack',cb);  

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function rmMenu = retinotopyModelSubmenu(analysismenu, vw)
% Submenu for the retinotopy model.

rmMenu = uimenu(analysismenu,'Label','Retinotopic Model','Separator','off');

% set stimulus parameters:
% There are two versions of the GUI to set stimulus parameters. 
% A newer version (by JW/BW 12/08) works well, but seg faults on MATLAB
% versions before r2007a (ras, checked 6/2009);
if verLessThan('matlab', '7.4')
    % fall back to the older, more stable version
    cb = ['rmEditStimulusParameters(' vw.name ');'];
else
    % use the newer, nicer GUI. 
    cb = ['rmEditStimParams(' vw.name ');'];
end

uimenu(rmMenu, 'Label', 'Set Parameters', 'Separator', 'off', ...
    'CallBack', cb);

% set analysis/stimulus parameters:
cb=[vw.name,'=rmLoadParameters(',vw.name,');',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','Load Parameters','Separator','off',...
       'CallBack',cb);
% - separator

%Run model
cb=[vw.name,'=rmMain(',vw.name,',[],3); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','Run (pRF)','Separator','on',...
    'CallBack',cb);

%Run model
cb=[vw.name,'=rmMain(',vw.name,',[],5); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','Run (pRF + HRF)','Separator','off',...
    'CallBack',cb);

%Run model in background on unix
cb=['rmSpawn(',vw.name,',[],1);'];
uimenu(rmMenu,'Label','Run in background (Unix)','Separator','off',...
    'CallBack',cb);
   
%Run oval gaussian model
%cb=[vw.name,'=rmMain(',vw.name,',[],3,''model'',{''one oval gaussian''});',...
%    vw.name,'=refreshScreen(',vw.name,');'];
%uimenu(rmMenu,'Label','Run (oval gaussian)','Separator','on',...
%    'CallBack',cb);

%Run oval gaussian model without theta
%cb=[vw.name,'=rmMain(',vw.name,',[],3,''model'',{''one oval gaussian without theta''});',...
%    vw.name,'=refreshScreen(',vw.name,');'];
%uimenu(rmMenu,'Label','Run (oval gaussian without theta)','Separator','off',...
%    'CallBack',cb);
%Run oval gaussian model
%cb=[vw.name,'=rmMain(',vw.name,',[],3,''model'',{''difference of gaussians''});',...
%    vw.name,'=refreshScreen(',vw.name,');'];
%uimenu(rmMenu,'Label','Run (difference of gaussian)','Separator','off',...
%    'CallBack',cb);

% - separator

% save predictions as a new data type
cb = [  'rmInfo;'... 
        'rmStimInfo;'...
    sprintf('%s = rmCalculatePredictions(%s, 1); ', vw.name, vw.name)];
uimenu(rmMenu, 'Label', 'Calculate pRF Predictions', ...
		'Separator', 'on', 'CallBack', cb);

	
% - separator

% coarse (grid) search only
cb=[vw.name,'=rmMain(',vw.name,',[],1); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','Coarse (grid) minimization','Separator','on',...
       'CallBack',cb);

% fmin only
cb=[vw.name,'=rmMain(',vw.name,',[],2); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','Fine (nonlinear) minimization',...
       'Separator','off','CallBack',cb);
   
% hrf min only
cb=[vw.name,'=rmMain(',vw.name,',[],6); ',...
    vw.name,'=refreshScreen(',vw.name,');'];
uimenu(rmMenu,'Label','HRF (grid + nonlinear) minimization',...
       'Separator','off','CallBack',cb);

% - separator
   
% position correction
cb=[vw.name,'=rmModelPositionCorrectionGUI(',vw.name,');'];
uimenu(rmMenu,'Label','Position correction','Separator','on',...
       'CallBack',cb);
  
return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function volumemenu = volumeSubmenu(analysismenu, vw)
% attach a menu with volume/gray - specific options.
volumemenu = uimenu(analysismenu,'Label','Volume view analyses','Separator','off');

% Blur phase in the gray matter callback:
%   vw = blurDialog(vw);
cb=[vw.name,'=blurDialog(',vw.name,');'];    
uimenu(volumemenu,'Label','Blur phase','Separator','off',...
    'CallBack',cb);

% Cortical Magnification analysis based on current ROIs
%   
% if exist('CORTMAG','var') 
%  CORTMAG = mrLVolumeCortMag(CORTMAG)
% else
% CORTMAG = mrLVolumeCortMag;
% end    
cb=['if exist(''CORTMAG'',''var'')',...
        ' CORTMAG = mrLVolumeCortMag(CORTMAG); else CORTMAG = mrLVolumeCortMag; end'];     
uimenu(volumemenu,'Label','Cortical Magnification','Separator','off',...
    'CallBack',cb);

% Laminar distance calculation
cb = [vw.name, '= ComputeLaminarDistance(', vw.name, ');'];
uimenu(volumemenu, 'Label', 'Laminar distance', 'Separator', 'on', ...
  'CallBack', cb);

% Laminar coordinates calculation
cb = 'MapLaminarIndices;';
uimenu(volumemenu, 'Label', 'Laminar coordinates', 'Separator', 'on', ...
  'CallBack', cb);
return

% /--------------------------------------------------------------------/ %
function corrMenu =corrSubmenu(analysismenu, vw)
% attach a sub-menu for mean map analysis options.
corrMenu = uimenu(analysismenu,'Label','Correlation to ROI tseries','Separator','off');

cb=sprintf('%s=computeCorrelation2ROIMap(%s)',vw.name,vw.name) ; 

uimenu(corrMenu,'Label','Correlation Map (select scans)','Separator','off',...
    'CallBack',cb);

return
% /--------------------------------------------------------------------/ %



function GUI = sessionGUI_analysisMenu(GUI);
% Attach an Analysis Menu to the session GUI figure, including
% callbacks for all analysis-related operations,l including
% preprocessing (motion compensation, time-slice correction), 
% traveling wave annalyses, and general linear models.
%
% GUI = sessionGUI_analysisMenu(GUI);
%
%
% ras, 07/06.
GUI.menus.analysis = uimenu('Label', 'Analysis', 'Separator', 'on');

% Attach submenus
submenu_preprocessing(GUI.menus.analysis);
submenu_tSeries(GUI.menus.analysis);
submenu_anatomy(GUI.menus.analysis);
submenu_travelingWave(GUI.menus.analysis);
submenu_retinotopyModel(GUI.menus.analysis);
submenu_eventRelated(GUI.menus.analysis);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_preprocessing(parent);
% attach a submenu for Preprocessing-related operations.
h = uimenu(parent, 'Label', 'Preprocessing', 'Separator', 'off');
    
%%%%% sub-submenu: Nestares Motion Compensation
h_nest = uimenu(h, 'Label', 'Motion Compensation (Nestares)', 'Separator', 'off');

uimenu(h_nest, 'Label', 'Within Scans', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = motionCompSelScan(INPLANE{1}); ');
      
uimenu(h_nest, 'Label', 'Between Scans', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = betweenScanMotCompSelScan(INPLANE{1}); ');

uimenu(h_nest, 'Label', 'Both Within and Between Scans', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = motionCompNestaresFull(INPLANE{1}); ');      

%%%%% SPM motion comp          
uimenu(h, 'Label', 'Motion Compensation (SPM)', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = motionCompSetArgs(INPLANE{1}); ');
      
%%%%% sub-submenu: evaluate motion          
h_eval = uimenu(h, 'Label', 'Evaluate Motion', 'Separator', 'off');

uimenu(h_eval, 'Label', 'Mean-Squared Error (frame difference)', ...
       'Separator', 'off', 'Callback', 'motionCompPlotMSE(INPLANE{1}); ');
      
uimenu(h_eval, 'Label', 'Mutual Information (frame difference)', ...
       'Separator', 'off', 'Callback', 'motionCompPlotMI(INPLANE{1}); ');

uimenu(h_eval, 'Label', 'Both Within and Between Scans', ...
       'Separator', 'off', 'Callback', 'motionCompCompareDataTypes(INPLANE{1}); ');
      
%%%%% resonance frequency correction
uimenu(h, 'Label', 'Correct Off-Resonance (step 1)', 'Separator', 'on', ...
          'Callback', 'reconFreqSetArgs_step1(INPLANE{1}); ');
       
%%%%% slice-timing adjustment
uimenu(h, 'Label', 'Adjust Slice Timing', 'Separator', 'on', ...
          'Callback', 'AdjustSliceTiming(guiGet(''scans'')); ');
          
          
          
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_tSeries(parent);
% attach a submenu for Time Series-related operations.
h = uimenu(parent, 'Label', 'Time Series', 'Separator', 'off');

cb = ['INPLANE{1} = computeMeanMap(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Compute Mean Map (selected scans)', 'Separator', 'off', ...
          'Callback', cb);

cb = ['INPLANE{1} = computeMeanMap(INPLANE{1}, 0); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Compute Mean Map (all scans)', 'Separator', 'off', ...
          'Callback', cb);      

cb = ['INPLANE{1} = computeStdMap(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Compute Standard Dev. Map (selected scans)', ...
          'Separator', 'off', 'Callback', cb);      

cb = ['INPLANE{1} = computeStdMap(INPLANE{1}, 0); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Compute Standard Dev. Map (all scans)', 'Separator', 'off', ...
          'Callback', cb);      

cb = ['INPLANE{1} = computeSpatialGradient(INPLANE{1}); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Compute Spatial Gradient for Inhomogeneity Correction', ...
          'Separator', 'off', 'Callback', cb);      


      
uimenu(h, 'Label', 'Average Scans Together', 'Separator', 'on', ...
          'Callback', 'INPLANE{1}=averageTSeries(INPLANE{1}, guiGet(''scans'')); ');

uimenu(h, 'Label', 'Flip Time Series', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=flipTSeries(INPLANE{1}, guiGet(''scans'')); ');

      
h_shift = uimenu(h, 'Label', 'Circular Shift Time Series', 'Separator', 'on');

uimenu(h_shift, 'Label', 'Advance 1 frame', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, 1); ');
      
uimenu(h_shift, 'Label', 'Advance 2 frame', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, 2); ');
      
uimenu(h_shift, 'Label', 'Advance 3 frames', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, 3); ');
      
uimenu(h_shift, 'Label', 'Delay 1 frame', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, -1); ');
      
uimenu(h_shift, 'Label', 'Delay 2 frames', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, -2); ');
      
uimenu(h_shift, 'Label', 'Delay 3 frames', 'Separator', 'off', ...
          'Callback', 'INPLANE{1}=shiftTSeries(INPLANE{1}, -3); ');
      
          
uimenu(h, 'Label', 'Spatial Blur', 'Separator', 'off', ...
          'Callback', 'spatialBlurTSeries(INPLANE{1}, guiGet(''scans'')); ');

uimenu(h, 'Label', 'Clip Frames from Start/End', 'Separator', 'off', ...
          'Callback', 'tSeriesClipFrames(INPLANE{1}, guiGet(''scans'')); ');
      
      
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_anatomy(parent);
% attach a submenu for Anatomical-related operations.
h = uimenu(parent, 'Label', 'Anatomy', 'Separator', 'off');

uimenu(h, 'Label', 'Compute Laminar Distance', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = ComputeLaminarDistance(INPLANE{1}); ');

uimenu(h, 'Label', 'Map Laminar Indices', 'Separator', 'off', ...
          'Callback', 'MapLaminarIndices ');

cb = ['VOLUME{1}.ROIS = mrViewGet([], ''roi''); ' ...
      'showROISlices(VOLUME{1}); '];      
uimenu(h, 'Label', 'Show ROI Slice Montage', 'Separator', 'off', ...
          'Callback', cb);
          
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_travelingWave(parent);
% attach a submenu for traveling-wave (phase-encoding) analyses.
h = uimenu(parent, 'Label', 'Traveling Wave', 'Separator', 'off');
      
cb = ['INPLANE{1} = computeCorAnal(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];      
uimenu(h, 'Label', 'Apply Traveling Wave Analysis (corAnal)', ...
          'Separator', 'off', 'Callback', cb);

cb = ['INPLANE{1} = computeCorAnal2Freq(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];      
uimenu(h, 'Label', '2-Frequency corAnal', 'Separator', 'off', ...
          'Callback', cb);

cb = ['INPLANE{1} = computeResStdMap(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Residual Std. Dev. Map', 'Separator', 'on', ...
          'Callback', cb);

cb = ['INPLANE{1} = computeProbMap(INPLANE{1}, guiGet(''scans'')); ' ...
      'sessionGUI_selectDataType; '];
uimenu(h, 'Label', 'Significance of Model Fit Map (-log10(p))', ...
          'Separator', 'off', 'Callback', cb);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_retinotopyModel(parent);
% attach a submenu for Retinotopic Model analyses.
h = uimenu(parent, 'Label', 'Retinotopy Model', 'Separator', 'off');
      
uimenu(h, 'Label', 'ROI Analysis (grid search)', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = rmMain(INPLANE{1}, ''roi''); ');

uimenu(h, 'Label', 'ROI Analysis (Nelder-Mead simplex search)', ...
          'Callback', 'INPLANE{1} = rmMain(INPLANE{1}, ''roi''); ');

uimenu(h, 'Label', 'Analyze All (careful)', 'Separator', 'off', ...
          'Callback', 'INPLANE{1} = rmMain(INPLANE{1}, ''all''); ');     
          
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_eventRelated(parent);
% attach a submenu for Event-Related analyses.
h = uimenu(parent, 'Label', 'Event-Related', 'Separator', 'off');

% uimenu(h, 'Label', 'Apply GLM (old code) (selected scans)', 'Separator', 'off', ...
%           'Callback', 'er_runSelxavgBlock(INPLANE{1}, guiGet(''scans'')); ');
% 
% uimenu(h, 'Label', 'Apply GLM (old code) (scan group)', 'Separator', 'off', ...
%           'Callback', 'er_runSelxavgBlock(INPLANE{1}, -1); ');
% 
% uimenu(h, 'Label', 'Contrast Map (old code)', 'Separator', 'off', ...
%           'Accelerator', '5', 'Callback', 'er_mkcontrast(INPLANE{1}, -1); ');

uimenu(h, 'Label', 'Apply GLM (selected scans)', 'Separator', 'on', ...
          'Callback', 'applyGlm(INPLANE{1}, guiGet(''scans'')); ');

uimenu(h, 'Label', 'Apply GLM (scan group)', 'Separator', 'off', ...
          'Callback', 'applyGlm(INPLANE{1}, er_getScanGroup(INPLANE{1})); ');
      
uimenu(h, 'Label', 'Contrast Map (scan group)', 'Separator', 'off', ...
          'Accelerator', '4', 'Callback', 'contrastGUI(INPLANE{1}); ');

uimenu(h, 'Label', 'Many contrast Map (scan group)', 'Separator', 'off', ...
          'Callback', 'contrastBatchGUI(INPLANE{1}); ');
	  
% uimenu(h, 'Label', 'Selectivity Map (Cur ROI)', 'Separator', 'on', ...
%           'Callback', 'INPLANE{1} = er_selectivityMap(INPLANE{1}); ');
% 
% uimenu(h, 'Label', 'Selectivity Map (Gray Matter)', 'Separator', 'off', ...
%           'Callback', 'INPLANE{1} = er_selectivityMap(INPLANE{1}, ''gray''); ');
%       
% uimenu(h, 'Label', 'Reliability Map (Cur ROI)', 'Separator', 'off', ...
%           'Callback', 'INPLANE{1} = er_voxRMap(INPLANE{1}); ');
% 
% uimenu(h, 'Label', 'Reliability Map (Gray Matter)', 'Separator', 'off', ...
%           'Callback', 'INPLANE{1} = er_voxRMap(INPLANE{1}, ''gray''); ');            

return


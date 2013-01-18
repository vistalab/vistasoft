function tc = tc_addMenus(tc,hfig);
% tc = tc_addMenus(tc,[hfig]): add menus to time course UI figure.
%
% tc: the analysis struct used by the UI.
%
% hfig: handle to the figure (default is gcf).
%
% 07/04 ras.
% 09/05 ras: made each top-level menu a sub-function, to 
% make 'em easier to get at.
if ~exist('hfig')   hfig = gcf;     end

tc.ui.fig = hfig;

% turn off standard menus for now:
set(hfig,'Menubar','none');

% add each top-level menu individually
tc.ui = tc_plotMenu(tc, tc.ui);
tc.ui = tc_viewMenu(tc, tc.ui);
tc.ui = tc_analMenu(tc, tc.ui);
tc.ui = tc_settingsMenu(tc, tc.ui);
tc.ui = tc_condMenu(tc, tc.ui);
tc.ui = tc_exportMenu(tc, tc.ui);
tc.ui = tc_helpMenu(tc, tc.ui);

% add standard MATLAB menus
tc.ui.spacerMenu = uimenu('Label',' ');
% eval(get(tc.ui.figMenuToggle,'Callback'));

return
% /---------------------------------------------------------------/ %




% /---------------------------------------------------------------/ %
function h = tc_plotMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (1): Plotting options for time course
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.plotMenu = uimenu('ForegroundColor',[0 0 0],'Label','Plot','Separator','on');

% callback for all plotting options: 
%   TMP = get(gcf, 'UserData');
%   TMP_H = get(gcbo, 'UserData');
%   set(TMP_H, 'Checked', 'off');
%   set(gcbo, 'Checked', 'on');
%   TMP.plotType = find(TMP_H==gcbo);
%   set(gcf, 'UserData', TMP);
%   timeCourseUI;
%   clear TMP_H TMP;
cb=['TMP_H = get(gcbo, ''UserData''); ' ...
    'TMP = get(gcf, ''UserData''); ' ...
    'set(TMP_H, ''Checked'', ''off''); ' ... 
    'set(gcbo, ''Checked'', ''on''); ' ...
    'TMP.plotType = find(TMP_H==gcbo); ' ...
    'set(gcf, ''UserData'', TMP); ' ...
    'timeCourseUI; clear TMP_H TMP; ' ];

h.plotWholeTc = uimenu(h.plotMenu,'Label','Plot Whole Time Course','Separator','off',...
    'Accelerator','K','Callback',cb);

h.sparklineWholeTc = uimenu(h.plotMenu, 'Label', 'Plot Whole Time Course (sparkline)',...
                        'Callback',cb);

h.plotMeanTrials = uimenu(h.plotMenu,'Label','Plot Mean Time Course','Separator','off',...
    'Checked','off','Accelerator','M','Callback',cb);           

h.meanSubplots = uimenu(h.plotMenu,'Label','Mean Time Course Subplots','Separator','off',...
    'Checked','off','Accelerator','B','Callback',cb);           

h.plotAllTrials = uimenu(h.plotMenu,'Label','Plot All Trials','Separator','off',...
    'Accelerator','I','Callback',cb);         

h.plotRelAmps = uimenu(h.plotMenu,'Label','Plot Relative Amplitudes','Separator','on',...
    'Accelerator','J','Callback',cb);           

h.plotMeanAmps = uimenu(h.plotMenu,'Label','Plot Mean Amplitudes','Separator','off',...
    'Accelerator','U','Callback',cb);           

h.plotSummary = uimenu(h.plotMenu,'Label','Mean Time Course Plus Amplitudes','Separator','on',...
    'Checked','on','Accelerator','D','Callback',cb);  

h.plotFFT = uimenu(h.plotMenu,'Label','FFT of mean tSeries','Separator','on',...
    'Checked','off','Accelerator','F','Callback',cb);           

h.plotGlm = uimenu(h.plotMenu,'Label','Visualize GLM Results','Separator','on',...
    'Checked','off','Accelerator','G','Callback',cb);           

h.plotCorAnal = uimenu(h.plotMenu,'Label','Visualize Cor Anal','Separator','off',...
    'Checked','off','Accelerator','T','Callback',cb);           

% this code allows the UI to exclusively check the selected
% plot option, and deselect the others:
handlesArray = [h.plotWholeTc h.plotAllTrials h.plotMeanTrials ...
                h.plotRelAmps h.plotMeanAmps h.meanSubplots ...
                h.plotSummary h.plotFFT h.plotGlm h.plotCorAnal ...
                h.sparklineWholeTc];
set(h.plotWholeTc,'UserData',handlesArray);
set(h.plotAllTrials,'UserData',handlesArray);
set(h.plotMeanTrials,'UserData',handlesArray);
set(h.plotRelAmps,'UserData',handlesArray);
set(h.plotMeanAmps,'UserData',handlesArray);
set(h.meanSubplots,'UserData',handlesArray);
set(h.plotSummary,'UserData',handlesArray);
set(h.plotFFT,'UserData',handlesArray);
set(h.plotGlm,'UserData',handlesArray);
set(h.plotCorAnal,'UserData',handlesArray);
set(h.sparklineWholeTc,'UserData',handlesArray);

return
% /---------------------------------------------------------------/ %




% /---------------------------------------------------------------/ %
function h = tc_viewMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (2): View options for time course
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.viewMenu = uimenu('ForegroundColor',[0 0 0],'Label','View','Separator','on');

% spawn new UI callback:
% tc_openFig(get(gcf,'UserData'));
h.newTCUI = uimenu(h.viewMenu,'Label','New UI Window','Separator','off',...
    'Callback',' tc_openFig(get(gcf,''UserData'')); timeCourseUI;');

% view/edit parfiles callback:
% tc = get(gcf, 'UserData');
% for p = tc.trials.parfiles, edit(p{1}); end
cb = 'tc = get(gcf, ''UserData''); ';
cb = [cb 'for p = tc.trials.parfiles, edit(p{1}); end '];
h.editParfiles = uimenu(h.viewMenu, 'Label', 'View/Edit Parfiles', ...
    'Separator', 'on', 'Callback', cb);


% mark individual trials in All Trials plot:
%   umtoggle(gcbo);
%   TMP = get(gcf,'UserData');
%   TMP.params.markEachTrial = isequal(get(gcbo,'Checked'),'on');
%   set(gcf,'UserData',TMP);
%   timeCourseUI;
%   clear TMP
cb = ['umtoggle(gcbo); '...
       'TMP = get(gcf,''UserData''); '...
       'TMP.params.markEachTrial = isequal(get(gcbo,''Checked''),''on''); '...
       'set(gcf, ''UserData'', TMP); '...
       'timeCourseUI; clear TMP;'];
h.markEachTrial = uimenu(h.viewMenu,'Label','Color Single Trials (All Trials Plot)', ....
                'Separator','on', 'Checked', 'on', 'Callback', cb);

% show grid:
%   umtoggle(gcbo);
%   TMP = get(gcf,'UserData');
%   TMP.params.grid = isequal(get(gcbo,'Checked'),'on');
%   set(gcf,'UserData',TMP);
%   timeCourseUI;
%   clear TMP
cb = ['umtoggle(gcbo); '...
       'TMP = get(gcf,''UserData''); '...
       'TMP.params.grid = isequal(get(gcbo,''Checked''),''on''); '...
       'set(gcf, ''UserData'', TMP); '...
       'timeCourseUI; clear TMP;'];
h.grid = uimenu(h.viewMenu, 'Label', 'Grid',  'Separator', 'off', ...
                'Checked', 'off', 'Callback', cb);

            
% show peak and baseline periods callback:
%   umtoggle(gcbo);
%   TMP = get(gcf,'UserData');
%   TMP.params.showPkBsl = isequal(get(gcbo,'Checked'),'on');
%   set(gcf,'UserData',TMP);
%   timeCourseUI;
%   clear TMP
cb = ['umtoggle(gcbo); '...
       'TMP = get(gcf,''UserData''); '...
       'TMP.params.showPkBsl = isequal(get(gcbo,''Checked''),''on''); '...
       'set(gcf, ''UserData'', TMP); '...
       'timeCourseUI; clear TMP;'];
h.showPkBsl = uimenu(h.viewMenu,'Label','Show Peak/Baseline Periods', ....
                'Separator','off', 'Checked', 'on', 'Callback', cb);

% legend callback:
% TMP = get(gcf, 'UserData');
% TMP.params.legend = mrvPanelToggle(TMP.ui.legend, gcbo); 
% set(gcf, 'UserData', TMP); 
% clear TMP
cb = ['TMP = get(gcf, ''UserData''); ' ...
      'TMP.params.legend = mrvPanelToggle(TMP.ui.legend, gcbo); ' ...
      'set(gcf, ''UserData'', TMP); ' ...
      'clear TMP; '];
h.showLegend = uimenu(h.viewMenu, 'Label', 'Show Legend', ...
    'Separator', 'off', 'Checked', 'on', 'Accelerator', 'L', ...
    'Callback', cb);

h.figMenuToggle = addFigMenuToggle(h.viewMenu);

return
% /---------------------------------------------------------------/ %




% /---------------------------------------------------------------/ %
function h = tc_analMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (3): Analysis options for time course
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.analMenu = uimenu('ForegroundColor',[0 0 0],'Label','Analysis','Separator','on');

% calc SNR (peak v bsl)
cb = 'tc = get(gcf,''UserData''); ';
cb = [cb 'title(sprintf(''SNR Peak Vs Baseline: %2.2f (%2.2f dB)'',tc.SNR,tc.SNRdb),''FontSize'',14);'];
h.calcSNR = uimenu(h.analMenu,'Label','Calculate SNR (peak vs bsl)','Separator','off','Callback',cb);

% blur time course
cb = 'tc_blurTimeCourse;';
h.blurTc = uimenu(h.analMenu,'Label','Blur Time Course','Separator','off','Callback',cb);

% detrend time course
cb = 'tc_detrendTimeCourse;';
h.blurTc = uimenu(h.analMenu,'Label','Detrend Time Course','Separator','off','Callback',cb);


% remove outlier data points
cb = 'tc_removeOutliers;';
h.blurTc = uimenu(h.analMenu,'Label','Remove Outlier Time Points',...
    'Separator','on','Callback',cb);

% apply corAnal
cb = 'tc_applyCorAnal; tc_visualizeCorAnal; ';
h.applyCorAnal = uimenu(h.analMenu, 'Label', 'Apply Cor Anal',...
    'Separator', 'on', 'Callback', cb);

% apply GLM
cb = 'tc_applyGlm; tc_visualizeGlm; ';
h.applyGLM = uimenu(h.analMenu, 'Label', 'Apply GLM',...
    'Separator', 'off', 'Callback', cb);

% Apply statistical contrast callback:
% tc_contrast;
h.contrast = uimenu(h.analMenu,'Label', 'Apply Statistical Contrast',...
    'Separator', 'on', 'Callback', ' tc_contrast;');

% % for a certain design type, with alternating null periods b/w active
% % conditions, allow the user to automatically merge each null condition
% % with the previous trial, (maybe) saving a parfile along the way
%  if all(tc.trials.cond(1:2:end)==0) | all(tc.trials.cond(2:2:end)==0)
%     uimenu(h.analMenu,'Label','Remove Null Conditions...','Separator','on',...
%                      'Callback','tc_mergeNullTrials;');
%  end


% save HRF callback:
% tc_saveHrf;
h.saveHrf = uimenu(h.analMenu,'Label','Save HRF','Separator','on',...
    'Callback',' tc_saveHrf; timeCourseUI;');

% dump data to workspace callback:
% tc_dumpDataToWorkspace;
h.dumpToWs = uimenu(h.analMenu,'Label','Dump Data to Workspace','Separator','on',...
    'Callback','tc_dumpDataToWorkspace;');

return
% /---------------------------------------------------------------/ %




% /---------------------------------------------------------------/ %
function h = tc_settingsMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (3): Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.settingsMenu = uimenu('ForegroundColor',[0 0 0],'Label','Settings','Separator','on');

% recompute tc callback:
% tc = get(gcf,'UserData');
% tc_recomputeTc(tc);
cb = sprintf('tc = get(gcf,''UserData'');\n');
cb = [cb sprintf('tc = tc_recomputeTc(tc);')];
h.recompute = uimenu(h.settingsMenu,'Label','Change chopTSeries params...','Separator','off','Callback',cb);

% set zero %signal submenu
h.zeroSubMenu = uimenu(h.settingsMenu,'Label','Set Zero % Value...',...
                        'Separator','on');

% set mean of data to 0% callback:
% tc_setZeroPt(1);
h.setMean2Null = uimenu(h.zeroSubMenu,'Label','Set Mean of All Data as Zero',...
                    'Separator','off','Callback','tc_setZeroPt([],-1);');

% set null to 0% callback:
% tc_setZeroPt(1);
h.setZero2Null = uimenu(h.zeroSubMenu,'Label','Set Null Condition as Zero',...
                    'Separator','off','Callback','tc_setZeroPt([],-2);');

% set other condition as 0% callback:
% val = input('What condition should be set as the 0% signal condition? ');
% tc_setZeroPt(val);
h.setOther2Null = uimenu(h.zeroSubMenu,'Label','Set Other Condition as Zero',...
                    'Separator','off','Callback','tc_setZeroPt([],-3);');

% set null to 0% callback:
% tc_setZeroPt(1);
h.setGLMNull = uimenu(h.zeroSubMenu, 'Label', 'Estimate Null from GLM',...
                    'Separator', 'off', 'Callback', 'tc_setZeroPt([],-4);');

                
                
% set axis bounds submenu
h.axisSubmenu = uimenu(h.settingsMenu,'Label','Axis Bounds...','Separator','on');
         
% manually reset                 
uimenu(h.axisSubmenu,'Label','Set Manually','Separator','off',...
                     'Callback','tc_setAxisBounds;');
% reset to nice value
cb = 'tc_setAxisBounds([],''auto'');';
uimenu(h.axisSubmenu,'Label','Reset to nice values','Separator','off',...
                     'Callback',cb);
                 

% add also a way to change the assigned colors for each condition
uimenu(h.settingsMenu,'Label','Assign Condition Colors...',...
                     'Separator','off','Callback','tc_assignColors;');

% add also a way to change the assigned names for each condition
uimenu(h.settingsMenu,'Label','Assign Condition Names...','Separator','off',...
                     'Callback','tc_assignNames;');

% allow reordering of condition #s
uimenu(h.settingsMenu,'Label','Reorder Condition #s...','Separator','on',...
                     'Callback','tc_reorderCondNums;');
          
% group several conditions together 
uimenu(h.settingsMenu,'Label','Group Conditions...','Separator','off',...
                     'Callback','tc_groupConditions([], ''dialog'');');
				 
% % allow saving of the parfile info (will soon add color info, not yet)
% uimenu(h.settingsMenu,'Label','Save parfiles...','Separator','on',...
%                      'Callback','tc = get(gcf,''UserData''); tc_saveParfiles(tc);');
return
% /---------------------------------------------------------------/ %



% /---------------------------------------------------------------/ %
function h = tc_condMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (4): condition menu w/ conditions toggle buttons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback for all menu items:
% umtoggle(gcbo);
% tc_legend(get(gcf, 'UserData'));
% timeCourseUI; 
h.condMenu = uimenu('ForegroundColor',[0 0 0],'Label','Conditions','Separator','on');
accelChars = '0123456789-=|';
cb = ['umtoggle(gcbo); tc_legend(get(gcf,''UserData'')); timeCourseUI; '];
for i = 1:length(tc.trials.condNames)
    if i < length(accelChars)
        accel = accelChars(i);
    else
        accel = '';
    end
    
    if isempty(tc.trials.condNames{i})
        tc.trials.condNames{i} = num2str(i);
    end
    
    hc(i) = uimenu(h.condMenu, 'Label', tc.trials.condNames{i}, ...
                 'Separator', 'off', 'Checked', 'on', ...
                 'Accelerator', accel, ...
                 'Tag', tc.trials.condNames{i}, ...
                 'UserData', tc.trials.condNums(i), ...
                 'Callback', cb);
end

% unselect the null condition if there is one
if any(tc.trials.condNums==0)
    null = find(tc.trials.condNums==0);
    set(hc(null), 'Checked', 'off');
end
h.condMenuHandles = hc;             

return
% /---------------------------------------------------------------/ %


% /---------------------------------------------------------------/ %
function h = tc_exportMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (6): export options menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.exportMenu = uimenu('Label', 'Export', 'Separator', 'on');

h.exportOptions = uimenu(h.exportMenu, 'Label', 'Export Options', ...
							'Callback', 'exportsetupdlg;');

% dump data to workspace:
% (replicated from analysis menu, will disable it once people get used to
% this new menu)
h.dumpToWs = uimenu(h.exportMenu, 'Label', 'Dump Data to Workspace', ...
					'Callback', 'tc_dumpDataToWorkspace;');
				
% export parfile info (moved over from analysis menu)
uimenu(h.exportMenu, 'Label', 'Save parfiles as...', ...
		 'Callback', 'tc_saveParfiles(get(gcf,''UserData''));');



return
% /---------------------------------------------------------------/ %





% /---------------------------------------------------------------/ %
function h = tc_helpMenu(tc,h);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (6): help menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.helpMenu = uimenu('ForegroundColor',[.6 .2 0],'Label','Help','Separator','on');

% web page callback:
% web http://white.stanford.edu/newlm/index.php/Time_Course_UI
cb = 'web http://white.stanford.edu/newlm/index.php/Time_Course_UI';
h.webHelp = uimenu(h.helpMenu,'Label','Time Course UI page','Separator','off',...
    'Callback',cb);

% web page (external browser) callback:
% web http://white.stanford.edu/newlm/index.php/Time_Course_UI -browser
cb = 'web http://white.stanford.edu/newlm/index.php/Time_Course_UI -browser';
cb = 'web http://white/newlm/index.php/Main_Page -browser';
h.webHelp2 = uimenu(h.helpMenu,'Label','Time Course UI page (external browser)','Separator','off',...
    'Callback',cb);


% mrVista web page callback:
% web web http://white.stanford.edu/newlm/index.php/Main_Page
cb = 'web http://white.stanford.edu/newlm/index.php/Main_Page';
h.webWiki = uimenu(h.helpMenu, 'Label', 'mrVista wiki', ...
    'Separator', 'off', 'Callback', cb);

% mrVista web page (external browser) callback:
% web web http://white.stanford.edu/newlm/index.php/Main_Page
% -browser
h.webWiki2 = uimenu(h.helpMenu, 'Label', 'mrVista wiki (external browser)', ...
    'Separator', 'off', 'Callback', cb);

% identify callback for menu item
cb = 'helpFindCallback; ';
uimenu(h.helpMenu, 'Label', 'Identify Callback for a menu item', ...
        'Separator', 'on', 'Callback', cb);

% add handles to tc struct
fields = fieldnames(h);
for i = 1:length(fields)
    tc.ui.(fields{i}) = h.(fields{i});
end

return

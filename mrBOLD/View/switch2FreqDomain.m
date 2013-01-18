function view = switch2FreqDomain(view)
%
% Switches analysis mode to frequency domain

if ~strcmp(view.viewType,'generalGray')
  myErrorDlg('This function only works in the ''general gray'' gray view');
end


% Only do this for VOLUME, not for hiddenVolume
if findstr(view.name, 'VOLUME')
  % Set view.ui.grayVolButtons
  selectButton(view.ui.analysisDomainButtons, 2);
  % Load user preferences
  view=initDataValsSlider(view);
  
  
  % Changed domain so recompute maps
  
    
  % Changed domain so recompute maps
  view=viewSet(view,'dataValIndex',1);
  view=recomputeEMMap(view);
  
  view=UpdateMapWindow(view);
  
end

return;

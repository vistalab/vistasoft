function view = switch2TimeDomain(view)
%
% Switches analysis mode to time domain

if ~strcmp(view.viewType,'generalGray')
  myErrorDlg('This function only works in the ''general gray'' gray view');
end


% Only do this for VOLUME, not for hiddenVolume
if findstr(view.name, 'VOLUME')
  % Set view.ui.grayVolButtons
  selectButton(view.ui.analysisDomainButtons, 1);
  
  % Load user preferences
  view=initDataValsSlider(view);
  
  % Changed domain so recompute maps
  view=viewSet(view,'dataValIndex',1);
  
  view=recomputeEMMap(view);
  
  view=UpdateMapWindow(view);
  
end

return;

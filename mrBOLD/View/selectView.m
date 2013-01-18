function selectView(view)
%selectView(view)
% set the global selectedINPLANE variable
% to reflect the specified view.
global selectedINPLANE selectedVOLUME selectedFLAT
% Set global variable to select this view in case more than one
% view of this viewType is open.
switch view.viewType
  case 'Inplane'
    selectedINPLANE = viewIndex(view);
  case {'Volume','Gray'}
    selectedVOLUME = viewIndex(view);
  case 'Flat'
    selectedFLAT = viewIndex(view);
end

return

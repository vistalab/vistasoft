function h = rxViewMenu(parent);
%
% h = rxViewMenu(parent);
%
% Make a menu for mrRx view commands,
% attached to parent object.
%
% ras 02/05.
if nargin<1
    parent = gcf;
end

h = uimenu(parent,'Label', 'View');

% Refresh
uimenu(h,'Label', 'Refresh', ...
       'Separator', 'on', ...
       'Callback', 'rxRefresh;'); 
   
% Visualize Prescription
uimenu(h,'Label', 'Visualize Rx', ...
       'Separator', 'on', ...
       'Callback', 'rxVisualizeRx;'); 

% Visualize Prescription (set axi, cor, sag)
cb = ['tmp = inputdlg({''Enter [Axi Cor Sag] slices to show''}); ' ...
       'rxVisualizeRx([], tmp{1}); clear tmp '];
uimenu(h,'Label', 'Visualize Rx (Set [axi cor sag] slices)', ...
       'Separator', 'off', 'Callback', cb); 

   
% tSeries Movie 
uimenu(h,'Label', 'tSeries Movie', ...
       'Separator', 'off', ...
       'Callback', 'rxMovie;');   
   
% allow user to toggle std. figure menus:     
addFigMenuToggle(h);     
   
return
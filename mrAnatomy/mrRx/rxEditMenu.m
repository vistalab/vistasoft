function h = rxEditMenu(parent);
%
% h = rxEditMenu(parent);
%
% Make a menu for mrRx file commands, 
% attached to parent object.
%
% ras 02/05.
if nargin<1
    parent = gcf;
end

h = uimenu(parent, 'Label', 'Edit');

% undo menu
cb = ['rx = get(gcf,  ''UserData''); ' ...
      'tmp = rx.xform; rxSetXform(rx,  rx.prevXform); ' ...
      'rx.prevXform = tmp; set(gcf,  ''UserData'',  rx);'];
uimenu(h,  'Label',  'Undo',  'Accelerator',  'Z', ...
       'Separator', 'off',  'Callback',  cb);

% mid-sagittal alignment
uimenu(h,  'Label',  'Prescribe Mid-Sagittal', ...
       'Separator',  'off',  'Callback',  'rxMidSagRx;');

% mid-coronal
uimenu(h,  'Label',  'Prescribe Mid-Coronal',  'Separator',  'off',  ...
    'Callback', 'rxMidCorRx;');


% mid-coronal
uimenu(h,  'Label',  'Prescribe Oblique (~Perpendicular to Calcarine)',  ...
    'Separator',  'off',   'Callback',  'rxObliqueRx;');

% % Compare Images submenu
% rxComparePrefsMenu(h);

% flip slice order 
uimenu(h,  'Label',  'Flip Slice Order',  'Separator',  'off',  ...
    'Callback',  'rxFlipSliceOrder;');
   
%%%%%%%%%%%%%%%%%%%%
% Points submenu   %
%%%%%%%%%%%%%%%%%%%%
hpoints = uimenu(h, 'Label', 'Points', 'Separator', 'on');

% add points
uimenu(hpoints, 'Label', 'Add Points', ...
       'Accelerator', 'P', 'Callback', 'rxAddPoints;');

% remove points
uimenu(hpoints, 'Label', 'Delete Points', ...
       'Accelerator', 'D', 'Callback', 'rxRemovePoints;');   

% toggle show/hide points
uimenu(hpoints, 'Label', 'Show Points', 'Checked', 'on', ...
       'Tag', 'showPointsMenu', ...
       'Accelerator', 'S', 'Callback', 'umtoggle(gcbo); rxRefresh;');
  
%%%%%%%%%%%%%%%%%%%%
% ROI submenu      %
%%%%%%%%%%%%%%%%%%%%
hroi = uimenu(h, 'Label', 'ROIs', 'Separator', 'on');
   
   
% delete all ROIs
cb = 'rx = get(gcf, ''UserData''); rx.rois = rx.rois([]); rxRefresh(rx); ';
uimenu(hroi,'Label', 'Delete All ROIs', 'Accelerator', 'K', 'Callback', cb);
   
% show/hide ROIs
uimenu(hroi,'Label', 'Show ROIs', 'Checked', 'on', ...
       'Tag', 'rxShowROIsMenu', ...
       'Accelerator', 'H', 'Callback', 'umtoggle(gcbo); rxRefresh;');
   
% find center of cur ROI
cb = 'rxCenterOnROI; ';
uimenu(hroi, 'Label', 'Find Center of Current ROI', 'Callback', cb);
      
%%%%%%%%%%%%%%%%%%%%
% Edit Size Params %
%%%%%%%%%%%%%%%%%%%%
cb = 'rxEditSize; ';
uimenu(h, 'Label', 'Rx Size / Resolution', 'Separator', 'on', 'Callback', cb);

return
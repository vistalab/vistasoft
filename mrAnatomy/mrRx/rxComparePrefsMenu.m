function h = rxComparePrefsMenu(parent);
%
% h = rxComparePrefsMenu(parent);
%
% Make a menu for setting view preferences
% for the compare images figure,
% attached to parent object.
%
% ras 03/05.
if ieNotDefined('parent')
    parent = gcf;
end

h = uimenu(parent,'Label','Comparison Prefs',...
                  'ForegroundColor','b','Separator','on');

% mrAlign intensity correct toggle:
cb = 'umtoggle(gcbo); rxRefresh;';
uimenu(h,'Label','Use mrAlign Intensity Correction',...
         'Tag','corrrectIntensityMenu',...
         'Checked','off','Callback',cb);
     
% quantitative comparison report toggle:
cb = 'val=umtoggle(gcbo); rxShowStats([],val);';
uimenu(h,'Label','Show Comparison Stats',...
         'Tag','quantifyMenu','Separator','off',...
         'Checked','on','Callback',cb);
     
% call overlay volume GUI:
uimenu(h,'Label','Compare all slices (separate GUI)',...
         'Tag','overlayVolMenu','Separator','on',...
         'Checked','off','Callback','rxOverlayCompare;');
     
% allow user to toggle std. figure menus:     
addFigMenuToggle(h);     
     
return

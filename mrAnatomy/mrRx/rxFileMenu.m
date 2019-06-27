function h = rxFileMenu(parent);
%
% h = rxFileMenu(parent);
%
% Make a menu for mrRx file commands,
% attached to parent object.
%
% ras 02/05.
if ieNotDefined('parent')
    parent = gcf;
end

h = uimenu(parent,'Label','File');

%%%%%%%%%%%%%%%%%
% load submenu: %
%%%%%%%%%%%%%%%%%
hload = uimenu(h,'Label','Load...','Separator','on');

% load Rx:
uimenu(hload,'Label','Xform Settings','Separator','on',...
             'Callback','rxLoadSettings;');
         
% load mrVista alignment:
uimenu(hload,'Label','mrVista alignment','Separator','on',...
             'Callback','rxLoadMrVistaAlignment;');

% load mrAlign bestrotvol file:
uimenu(hload,'Label','mrAlign bestrotvol','Separator','on',...
             'Callback','rxLoadBestrotvol;');
         
% load ROI:
uimenu(hload,'Label','mrVista ROI','Separator','on',...
             'Callback','rxLoadROI;');
         
 % load Volume:
uimenu(hload,'Label','New Xform Volume','Separator','on',...
             'Callback','rxLoadVolume([],[],''vol'');');
         
% load Reference:
uimenu(hload,'Label','New Reference Volume','Separator','on',...
             'Callback','rxLoadVolume([],[],''ref'');');         

% load tSeries:
uimenu(hload,'Label','mrVista tSeries','Separator','on',...
             'Callback','rxLoadTSeries;');

% load Screen Save:
uimenu(hload,'Label','Screen Save Image','Separator','on',...
             'Callback','rxLoadScreenSave;');
         
% load full Rx file:
uimenu(hload,'Label','Full Data Set','Separator','on',...
             'Callback','rxLoad;');

% load FSL transform: Mark Hymers, 2019 YNiC
uimenu(hload,'Label','FSL Transform','Separator','on',...
             'Callback','rxLoadFSLTransform;');


         
%%%%%%%%%%%%%%%%%
% save submenu: %
%%%%%%%%%%%%%%%%%
hsave = uimenu(h,'Label','Save...','Separator','on');

% save Rx:
uimenu(hsave,'Label','Xform Settings','Separator','on',...
             'Callback','rxSaveSettings;');

% save mrVista alignment:
uimenu(hsave,'Label','mrVista alignment','Separator','on',...
             'Callback','rxSaveMrVistaAlignment;');

% save mrAlign bestrotvol file:
uimenu(hsave,'Label','mrAlign bestrotvol','Separator','on',...
             'Callback','rxSaveBestrotvol;');         
         
% save Xformed Volume:
uimenu(hsave,'Label','Xformed Volume','Separator','on',...
             'Callback','rxSaveVolume;');

% save Rx:
uimenu(hsave,'Label','Full Data Set','Separator','on',...
             'Callback','rxSave;');

%%%%%%%%%%%%%%%%%
% exit option:  %
%%%%%%%%%%%%%%%%%
uimenu(h,'Label','Exit','Separator','on','Callback','rxClose');

         
return

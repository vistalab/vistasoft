function view = makePopup(view,name,options,position,callbackStr)
% 
% view = makePopup(view,name,options,position,callbackStr)
%
% Make a popu menu ui control and attach its callback.  
% the structure holds:
%  popupHandle: handle to the popup menu itself
%  name: text string
%  label: handle to the label positioned below the popup.
%
% Inputs:
%   view: view (e.g., INPLANE)
%   name: name of popup menu (e.g., 'ROI')
%   options: list of options (cell array)
%   position: position of popup menu [left,bottom,width,height]
%
% To modify a menu's choice, use functions like selectROI.  
% These functions call setPopup that updates the menu 
% appropriately.
%
% gmb, 4/24/98
% djh, 2/21/2001
% - added callbackStr argument
% ras, 11/24/04 - made uicontrol instead of subplot;
%               - also, label now above the popup instead of below

% temporarily disable java figures
v = version;
mVersion = str2double(v(1:3));
mMinorVersion = str2double(v(3:end));
if (mVersion >= 7 && mMinorVersion < 4) % Problems in versions 7.0 - 7.3 
    javaFig = feature('javafigures');
    feature('javafigures', 0);
end
labelOffset = [0 .025 0 0];

% Make label
labelPos = position + labelOffset;
labelPos(2) = labelPos(2) - position(4);
labelStr = sprintf('%s:',name);
label = uicontrol('Style','text',...
                     'Units','Normalized',...
                     'Position',labelPos,...
                     'FontName','Helvetica',...
                     'FontSize',10,...
                     'FontWeight','normal',...
                     'HorizontalAlignment','left',...
                     'BackgroundColor',get(gcf,'Color'),...
                     'String',labelStr);
                 
% shift so label above, not below
position(2) = position(2) - position(4);
                 
% Make popup menu
popupHandle = ...
    uicontrol('Style','popupmenu',...
    'Units','Normalized',...
    'Position',position,...
    'String',options,...
    'Callback',callbackStr);

% Set fields of popup structure
eval(['view.ui.',name,'.popupHandle = popupHandle;']);
eval(['view.ui.',name,'.name = name;']);
eval(['view.ui.',name,'.labelHandle = label;']);

% restore the previous java figures setting
if (mVersion >= 7 && mMinorVersion < 4) % Problems in versions 7.0 - 7.3 
    feature('javafigures', javaFig); 
end

return

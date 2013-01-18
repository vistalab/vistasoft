function view = xformInplaneMenu(view)
%
% view = xformInplaneMenu(view)
% 
% Set up the callbacks for the xformView menu in the volume view
% 
% djh, 1/9/98
% rmk, 1/15/99
xformMenu = uimenu('Label','Xform from Vol','separator','on');

% Xform ROI callback:
%   volume = checkSelectedVolume;
%   view=vol2ipCurROI(volume,view);
%   view=refreshScreen(view,0);
callBackstr=['volume=checkSelectedVolume; ',...
    view.name,'=vol2ipCurROI(volume,',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0); ' ...
	'clear volume '];
uimenu(xformMenu,'Label','ROI - selected','Separator','off',...
    'CallBack',callBackstr);

% Xform All ROIs callback:
%   volume = checkSelectedVolume;
%   view=vol2ipAllROIs(VOLUME,view);
%   view=refreshScreen(view,0);
callBackstr=['volume=checkSelectedVolume; ',...
    view.name,'=vol2ipAllROIs(volume,',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0); ' ...
	'clear volume '];
uimenu(xformMenu,'Label','ROIs - all','Separator','on',...
    'CallBack',callBackstr);

return

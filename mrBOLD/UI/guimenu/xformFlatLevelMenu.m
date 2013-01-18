function view=xformFlatLevelMenu(view)
%
% view = xformFlatLevelMenu(view)
% 
% Set up the callbacks for the xformView menu in the Flat Level view
% 
% djh, 1/9/98
% rmk, 1/10/99 added xformParMap
% rmk, 1/15/99 added xformAllROIs
% ras, 10/04 created xformFlatLevelMenu

mrGlobals;

xformMenu = uimenu('Label','Xform','separator','on');

% Xform ROI callback:
%   gray=checkSelectedGray;
%   view=vol2flatCurROILevels(gray,view);
%   view=refreshScreen(view,0);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCurROILevels(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(xformMenu,'Label','ROI (selected)','Separator','off',...
    'CallBack',callBackstr);

% Xform AllROIs callback:
%   gray=checkSelectedGray;
%   view=vol2flatAllROIsLevels(gray,view);
%   view=refreshScreen(view,0);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatAllROIsLevels(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(xformMenu,'Label','ROIs (all)','Separator','on',...
    'CallBack',callBackstr);

% Xform CorAnal all scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnalLevels(gray,view,0);
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnalLevels(gray,',view.name,',0); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (all scans)','Separator','on',...
    'CallBack',callBackstr);

% Xform CorAnal current scan callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnalLevels(gray,view,getCurScan(view));
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnalLevels(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (current scan)','Separator','on',...
    'CallBack',callBackstr);

% Xform CorAnal select scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnalLevels(gray,view);
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnalLevels(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (select scans)','Separator','on',...
    'CallBack',callBackstr);

% Xform ParMap all scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMapLevels(gray,view,0);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMapLevels(gray,',view.name,',0); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (all scans)','Separator','on',...
    'CallBack',callBackstr);

% Xform ParMap current scan callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMapLevels(gray,view,getCurScan(view));
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMapLevels(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (current scan)','Separator','on',...
    'CallBack',callBackstr);

% Xform ParMap select scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMapLevels(gray,view);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMapLevels(gray,',view.name,'); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (select scans)','Separator','on',...
    'CallBack',callBackstr);

% Xform tSeries all scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatTSeriesLevels(gray,view,0);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatTSeriesLevels(gray,',view.name,',0); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','tSeries (all scans)','Separator','on',...
    'CallBack',callBackstr);

% Xform tSeries current scan callback:
%   gray=checkSelectedGray;
%   view=vol2flatTSeriesLevels(gray,view,getCurScan(view));
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatTSeriesLevels(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','tSeries (current scan)','Separator','on',...
    'CallBack',callBackstr);

% Xform tSeries select scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatTSeriesLevels(gray,view);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatTSeriesLevels(gray,',view.name,'); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','tSeries (select scans)','Separator','on',...
    'CallBack',callBackstr);


return


function view=xformFlatMenu(view)
%
% view = xformFlatMenu(view)
% 
% Set up the callbacks for the xformView menu in the Flat view
% 
% djh, 1/9/98
% rmk, 1/10/99 added xformParMap
% rmk, 1/15/99 added xformAllROIs

mrGlobals;

xformMenu = uimenu('Label','Xform','separator','on');

% Xform ROI callback:
%   gray=checkSelectedGray;
%   view=vol2flatCurROI(gray,view);
%   view=refreshScreen(view,0);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCurROI(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(xformMenu,'Label','ROI (selected)','Separator','off',...
    'CallBack',callBackstr);

% Xform AllROIs callback:
%   gray=checkSelectedGray;
%   view=vol2flatAllROIs(gray,view);
%   view=refreshScreen(view,0);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatAllROIs(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(xformMenu,'Label','ROIs (all)','Separator','off',...
    'CallBack',callBackstr);

% Xform CorAnal all scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnal(gray,view,0);
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnal(gray,',view.name,',0); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (all scans)','Separator','off',...
    'CallBack',callBackstr);

% Xform CorAnal current scan callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnal(gray,view,getCurScan(view));
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnal(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (current scan)','Separator','off',...
    'CallBack',callBackstr);

% Xform CorAnal select scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatCorAnal(gray,view);
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatCorAnal(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','CorAnal (select scans)','Separator','off',...
    'CallBack',callBackstr);

% Xform ParMap all scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMap(gray,view,0);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMap(gray,',view.name,',0); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (all scans)','Separator','off',...
    'CallBack',callBackstr);

% Xform ParMap current scan callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMap(gray,view,getCurScan(view));
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMap(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (current scan)','Separator','off',...
    'CallBack',callBackstr);

% Xform ParMap select scans callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMap(gray,view);
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMap(gray,',view.name,'); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (select scans)','Separator','off',...
    'CallBack',callBackstr);

% Xform ParMap current scan, nearest-neighbor callback:
%   gray=checkSelectedGray;
%   view=vol2flatParMap2(gray,view,getCurScan(view));
%   view=setDisplayMode(view,'map');
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=vol2flatParMap2(gray,',view.name,',getCurScan(',view.name,')); ',...
        view.name,'=setDisplayMode(',view.name,',''map''); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Parameter Map (nearest-neighbor)','Separator','off',...
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
uimenu(xformMenu,'Label','Parameter Map (separate gray levels)','Separator','off',...
    'CallBack',callBackstr);


% Xform retModel:
%   gray=checkSelectedGray;
%   view=rmVol2flat(gray,view);
%   view=refreshScreen(view,1);
callBackstr=['gray=checkSelectedGray; ',...
        view.name,'=rmVol2flat(gray,',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',1);'];
uimenu(xformMenu,'Label','Retinotopic Model','Separator','off',...
    'CallBack',callBackstr);

return;


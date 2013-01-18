function view3d(arg,arg2)


% view3d  Interactively rotate, zoom and pan the view of a 3-D plot
% --------------------------------------------------------------------
%
% VIEW3D ROT turns on mouse-based 3-D rotation
% VIEW3D ZOOM turns on mouse-based 3-D zoom and pan
% VIEW3D OFF turns it off
%
% VIEW3D(FIG,...) works on the figure FIG
%
% Double click to restore the original view
%
% hit "z" key over the figure to switch from ROT to ZOOM
% hit "r" key over the figure to switch from ZOOM to ROT
%
% in ROT mode:
% press and hold left mouse button to rotate about screen xy axis
% press and hold middle mouse button to rotate about screen z axis
% in ZOOM mode:
% press and hold left mouse button to zoom in and out
% press and hold middle mouse button to move the plot
%
% --------------------------------------------------------------------
% inspired from rotate3d by The MathWorks, Inc.
%
% Torsten Vogel 09.04.1999 
% tv.volke@bmw.de
% tested under Matlab 5.2
% --------------------------------------------------------------------


% ---------------------------------------------- inputs --------------
if nargin == 0
   error('not enough inputs')
elseif nargin == 1
   if ishandle(arg)
      error('not enough inputs')
      return
   else
      switch(lower(arg))
      case 'rot'
         viewact(gcf,'rot')
      case 'zoom'
         viewact(gcf,'zoom')
      case 'off'
         viewact(gcf,'off')
      case 'down'
         view3dDownFcn
      case 'up'
         view3dUpFcn
      case 'keypress'
         view3dkeypressFcn
      case 'view_xy' % rotate via screen xy axis
         view3dxyFcn
      case 'view_z'  % rotate via screen z axis
         view3dzFcn
      case 'view_zoom' % zoom in and out
         view3dzoomFcn
      case 'view_pan'  % move the plot 
         view3dpanFcn
      otherwise
         error('misspelled command argument')
      end
   end
elseif nargin==2
   if ~ishandle(arg)
      error('bad figure handle')
   end
   switch(lower(arg2))
   case 'rot'
      viewact(arg,'rot')
   case 'zoom'
      viewact(arg,'zoom')
   case 'off'
      viewact(arg,'off')
   otherwise
      error('misspelled command argument')
   end
end


% ---------------------------------------------- activation ----------
function viewact(fig,what)


% de-/activates view3d for the given figure


view3dObj = findobj(allchild(fig),'Tag','view3dObj');


if strcmp(what,'rot')
   if isempty(view3dObj)
      view3dObj = makeview3dObj(fig); %the small text box at the lower left corner
   end
   vdata = get(view3dObj,'UserData');
   vdata.what = 'rot';
   set(view3dObj,'UserData',vdata);
elseif strcmp(what,'zoom')
   if isempty(view3dObj)
      view3dObj = makeview3dObj(fig); %the small text box at the lower left corner
   end
   vdata = get(view3dObj,'UserData');
   vdata.what = 'zoom';
   set(view3dObj,'UserData',vdata);
elseif strcmp(what,'off')
   if isempty(view3dObj)
      return
   end
   vdata = get(view3dObj,'UserData');
   uirestore(vdata.uistate);
   set(fig,'KeyPressFcn',vdata.oldkeypressfcn)
   delete(view3dObj);
end


% ---------------------------------------------- view3dDownFcn -------
function view3dDownFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
mouseclick = get(gcf,'SelectionType');
if isempty(view3dObj)
   return
end 
vdata = get(view3dObj,'UserData');
vdata.oldunits = get(gcf,'Units');
set(gcf,'Units','pixels');
vdata.old_pt = get(0,'PointerLocation');
%  ----------------- store or restore previous view
ViewData = get(get(gca,'zlabel'),'UserData'); 
if isempty(ViewData)
   ViewData = manageViewData('get_from_axes');
   set(get(gca,'zlabel'),'UserData',ViewData)
end
if strcmp(mouseclick,'open')
   manageViewData('set_axes',ViewData);
   set(gcf,'Units',vdata.oldunits)
   return
end
%  ----------------- display text box
fig_color = get(gcf,'Color');
c = sum([.3 .6 .1].*fig_color);
set(vdata.textbox,'BackgroundColor',fig_color);
if(c > .5)
   set(vdata.textbox,'ForegroundColor',[0 0 0]);
else
   set(vdata.textbox,'ForegroundColor',[1 1 1]);
end
%  ----------------- what to do?
if strcmp(vdata.what,'rot')
   if strcmp(mouseclick,'normal')
      set(vdata.textbox,'string','Screen XY Rotation');
      set(gcf,'WindowButtonMotionFcn','view3d(''view_xy'')');
      set(gcf,'Pointer','custom','pointershapecdata',pointershapes('rot'));
   elseif strcmp(mouseclick,'extend')
      set(vdata.textbox,'string','Screen Z Rotation');
      set(gcf,'WindowButtonMotionFcn','view3d(''view_z'')');
      set(gcf,'Pointer','custom','pointershapecdata',pointershapes('rot'));
   end
else
   if strcmp(mouseclick,'normal')
      set(vdata.textbox,'string','Zoom');
      set(gcf,'WindowButtonMotionFcn','view3d(''view_zoom'')');
      set(gcf,'Pointer','custom','pointershapecdata',pointershapes('zoom'));
   elseif strcmp(mouseclick,'extend')
      set(vdata.textbox,'string','Pan');
      set(gcf,'WindowButtonMotionFcn','view3d(''view_pan'')');
      set(gcf,'Pointer','custom','pointershapecdata',pointershapes('pan'));
   end
end
set(view3dObj,'UserData',vdata)
set(vdata.textbox,'visi','on')


% ---------------------------------------------- view3dUpFcn ---------
function view3dUpFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
if isempty(view3dObj)
   return
end
vdata = get(view3dObj,'UserData');
set(gcf,'WindowButtonMotionFcn','','Units',vdata.oldunits,'pointer','arrow')
set(view3dObj,'visi','off')


% ---------------------------------------------- view3dkeypressFcn ---
function view3dkeypressFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
if isempty(view3dObj)
   return
end
vdata = get(view3dObj,'UserData');
currchar = lower(get(gcf,'currentchar'));
if strcmp(currchar,'r')
   vdata.what = 'rot';
elseif strcmp(currchar,'z')
   vdata.what = 'zoom';
end
set(view3dObj,'UserData',vdata)


% ---------------------------------------------- view3dxyFcn ---------
function view3dxyFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
vdata = get(view3dObj,'UserData');
new_pt = get(0,'PointerLocation');
old_pt = vdata.old_pt;
dx = (new_pt(1) - old_pt(1))*.5;
dy = (new_pt(2) - old_pt(2))*.5;
direction = [0 0 1];
coordsys  = 'camera';
pos  = get(gca,'cameraposition' );
targ = get(gca,'cameratarget'   );
dar  = get(gca,'dataaspectratio');
up   = get(gca,'cameraupvector' );
[newPos newUp] = camrotate(pos,targ,dar,up,-dx,-dy,coordsys,direction);
set(gca,'cameraposition', newPos, 'cameraupvector', newUp);
vdata.old_pt = new_pt;
set(view3dObj,'UserData',vdata)


% ---------------------------------------------- view3dzFcn ----------
function view3dzFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
vdata = get(view3dObj,'UserData');
new_pt = get(0,'PointerLocation');
old_pt = vdata.old_pt;
dy = (new_pt(2) - old_pt(2))*.5;
camroll(gca,-dy)
vdata.old_pt = new_pt;
set(view3dObj,'UserData',vdata)


% ---------------------------------------------- view3dzoomFcn -------
function view3dzoomFcn
view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
vdata = get(view3dObj,'UserData');
new_pt = get(0,'PointerLocation');
old_pt = vdata.old_pt;
dy = (new_pt(2) - old_pt(2))/abs(old_pt(2));
camzoom(gca,1-dy)
vdata.old_pt = new_pt;
set(view3dObj,'UserData',vdata)


% ---------------------------------------------- view3dpanFcn --------
function view3dpanFcn


view3dObj  = findobj(allchild(gcf),'Tag','view3dObj');
vdata = get(view3dObj,'UserData');
new_pt = get(0,'PointerLocation');
old_pt = vdata.old_pt;
dx = (new_pt(1) - old_pt(1))/old_pt(1)*4;
dy = (new_pt(2) - old_pt(2))/old_pt(2)*4;
campan(gca,-dx,-dy,'camera')
vdata.old_pt = new_pt;
set(view3dObj,'UserData',vdata)


% ---------------------------------------------- make view3dObj ------
function view3dObj = makeview3dObj(fig)


% save the previous state of the figure window
vdata.uistate  = uisuspend(fig);
% the data structure
vdata.what     = [];
vdata.olp_pt   = [];
vdata.textbox  = [];
vdata.oldunits = [];
vdata.oldkeypressfcn = get(fig,'KeyPressFcn');
% view3dObj
view3dObj = uicontrol('style','text','parent',fig,'Units','Pixels',... 
                      'Position',[2 2 130 20],'Visible','off', ...
                      'HandleVisibility','off','tag','view3dObj');
vdata.textbox  = view3dObj;
% store current view
ViewData = manageViewData('get_from_axes');
set(get(gca,'zlabel'),'UserData',ViewData);
% functions
set(fig,'WindowButtonDownFcn','view3d(''down'')');
set(fig,'WindowButtonUpFcn','view3d(''up'')');
set(fig,'WindowButtonMotionFcn','');
set(fig,'ButtonDownFcn','');
set(fig,'KeyPressFcn','view3d(''keypress'')');


set(view3dObj,'UserData',vdata);
% ---------------------------------------------- manage ViewData -----
function ViewData = manageViewData(how,data)


if nargin == 1 ; data = [];end
props = {
   'DataAspectRatio'
   'DataAspectRatioMode'
   'CameraPosition'
   'CameraPositionMode'
   'CameraTarget'
   'CameraTargetMode'
   'CameraUpVector'
   'CameraUpVectorMode'
   'CameraViewAngle'
   'CameraViewAngleMode'
   'PlotBoxAspectRatio'
   'PlotBoxAspectRatioMode'
   'Units'
   'Position'
   'View'
   'Projection'
};
if strcmp(how,'get_from_axes')
   ViewData = get(gca,props);
elseif strcmp(how,'get_stored')
   ViewData = get(get(gca,'zlabel'),'UserData');
elseif strcmp(how,'set_axes')
   set(gca,props,data)
   ViewData = [];
end
% -------------------------------------------------------------------------
% get some pointer shapes
function shape = pointershapes(arg)


if strcmp(arg,'zoom')
% -- zoom
shape=[ 2   2   2   2   2   2   2   2   2   2 NaN NaN NaN NaN NaN NaN  ;
        2   1   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN  ;
        2   1   2   2   2   2   2   2   2   2 NaN NaN NaN NaN NaN NaN  ;
        2   1   2   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN  ;
        2   1   2   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN  ;
        2   1   2   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN  ;
        2   1   2   1   1   1   1   1   2 NaN NaN NaN   2   2   2   2  ;
        2   1   2   1   1   2   1   1   1   2 NaN   2   1   2   1   2  ;
        2   1   2   1   2 NaN   2   1   1   1   2   1   1   2   1   2  ;
        2   2   2   2 NaN NaN NaN   2   1   1   1   1   1   2   1   2  ;
      NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   1   1   2   1   2  ;
      NaN NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   2   1   2  ;
      NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   1   2   1   2  ;
      NaN NaN NaN NaN NaN NaN   2   2   2   2   2   2   2   2   1   2  ;
      NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   1   1   1   2  ;
      NaN NaN NaN NaN NaN NaN   2   2   2   2   2   2   2   2   2   2  ];
elseif strcmp(arg,'pan')
% -- pan
shape=[ NaN NaN NaN NaN NaN NaN NaN   2   2 NaN NaN NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN   2   1   1   1   1   2 NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN   1   1   1   1   1   1 NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
        NaN NaN   2   1 NaN NaN   2   1   1   2 NaN NaN   1   2 NaN NaN ;
        NaN   2   1   1   2   2   2   1   1   2   2   2   1   1   2 NaN ;
          2   1   1   1   1   1   1   1   1   1   1   1   1   1   1   2 ;
          2   1   1   1   1   1   1   1   1   1   1   1   1   1   1   2 ;
        NaN   2   1   1   2   2   2   1   1   2   2   2   1   1   2 NaN ;
        NaN NaN   2   1 NaN NaN   2   1   1   2 NaN NaN   1   2 NaN NaN ;
        NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN   1   1   1   1   1   1 NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN   2   1   1   1   1   2 NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
        NaN NaN NaN NaN NaN NaN NaN   2   2 NaN NaN NaN NaN NaN NaN NaN ];
elseif strcmp(arg,'rot')
% -- rot
shape=[ NaN NaN NaN   2   2   2   2   2 NaN   2   2 NaN NaN NaN NaN NaN ;
        NaN NaN NaN   1   1   1   1   1   2   1   1   2 NaN NaN NaN NaN ;
        NaN NaN NaN   2   1   1   1   1   2   1   1   1   2 NaN NaN NaN ;
        NaN NaN   2   1   1   1   1   1   2   2   1   1   1   2 NaN NaN ;
        NaN   2   1   1   1   2   1   1   2 NaN NaN   2   1   1   2 NaN ;
        NaN   2   1   1   2 NaN   2   1   2 NaN NaN   2   1   1   2 NaN ;
          2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
          2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
          2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
          2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
        NaN   2   1   1   2 NaN NaN   2   1   2 NaN   2   1   1   2 NaN ;
        NaN   2   1   1   2 NaN NaN   2   1   1   2   1   1   1   2 NaN ;
        NaN NaN   2   1   1   1   2   2   1   1   1   1   1   2 NaN NaN ;
        NaN NaN NaN   2   1   1   1   2   1   1   1   1   2 NaN NaN NaN ;
        NaN NaN NaN NaN   2   1   1   2   1   1   1   1   1 NaN NaN NaN ;
        NaN NaN NaN NaN NaN   2   2 NaN   2   2   2   2   2 NaN NaN NaN ];


end

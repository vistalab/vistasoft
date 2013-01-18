function varargout = open3DWindow(varargin)
% 
%   OPEN3DWINDOW (M-file for open3DWindow.fig)
%
%      Control 3D volume representations by mrMesh from a Matlab
%      user-interface. This window is opened by a VOLUME window in mrVista.
%      The VOLUME{n} data attached to that window are used to create and
%      manipulate mesh data.
%
%      OPEN3DWINDOW, by itself, creates a new OPEN3DWINDOW or raises the
%      existing singleton*.
%
%      H = OPEN3DWINDOW returns the handle to a new OPEN3DWINDOW or the
%      handle to the existing singleton*.
%
%      OPEN3DWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPEN3DWINDOW.M with the given input arguments.
%
%      OPEN3DWINDOW('Property','Value',...) creates a new OPEN3DWINDOW or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before open3DWindow_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to open3DWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help open3DWindow

% Last Modified by GUIDE v2.5 07-Aug-2007 16:12:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @open3DWindow_OpeningFcn, ...
    'gui_OutputFcn',  @open3DWindow_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before open3DWindow is made visible.
function open3DWindow_OpeningFcn(hObject, eventdata, handles, varargin)

mrGlobals;  

% Choose default command line output for open3DWindow
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Place the window just to the right of the VOLUME window

global VOLUME;
selectedVOLUME = viewSelected('volume'); 

if isempty(selectedVOLUME), errordlg('3D Window requires an open Gray window.'); return; end

% Calculate the window positions in normalized units.
% [lowerLeftCornerX,lowerLeftCornerY,width (X-dim),height (Y-dim)]
vHndl = viewGet(VOLUME{selectedVOLUME},'windowhandle'); 
vHndlUnits = get(vHndl,'Units');
set(vHndl,'Units','normalized');      vPos  = get(vHndl,'Position'); 
set(vHndl,'Units',vHndlUnits);
set(hObject,'units','normalized');    o3Pos = get(hObject,'Position'); 

if (1 - (vPos(1) + vPos(3))) > (o3Pos(3)*1.05)
    % If the right side of the volume window leaves enough space, put the o3
    % window to its right, and set the updown so that the top positions
    % match
    set(hObject,'Position',[ (vPos(1) + vPos(3))*1.02, (vPos(2) + vPos(4) - o3Pos(4)), o3Pos(3), o3Pos(4)]);
else
    % Otherwise, put the o3 window to its left
    set(hObject,'Position',[ (vPos(1) - 1.05*o3Pos(3)), (vPos(2) + vPos(4) - o3Pos(4)), o3Pos(3), o3Pos(4)]);
end
figOffscreenCheck(hObject);

% Put the units back
set(hObject,'units','pixels');
o3refresh(handles);

return;

% --- Outputs from this function are returned to the command line.
function varargout = open3DWindow_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);

% Get default command line output from handles structure
varargout{1} = handles.output;

return;

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)

return;

% --------------------------------------------------------------------
function OK = menuLoad_Callback(hObject, eventdata, handles)
% File | Load (Anatdir)
global VOLUME
global selectedVOLUME  % These are probably not needed any more.

selectedVOLUME = viewSelected('volume'); 

% Loads the mesh and selects it.
[VOLUME{selectedVOLUME},OK] = meshLoad(VOLUME{selectedVOLUME});
if ~OK, return; end

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

o3refresh(handles);

return;
% --------------------------------------------------------------------
function menuLoadCurDir_Callback(hObject, eventdata, handles)
% File | Load (Curdir)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 
    
% mshFileName = uigetfile('*.mat','Choose mesh file');

% Loads the mesh and selects it.
[VOLUME{selectedVOLUME},OK] = meshLoad(VOLUME{selectedVOLUME},pwd);
if ~OK, return; end

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

% refresh happens there
menuDisplay_Callback(hObject, eventdata, handles)
return;


% --------------------------------------------------------------------
function menuLoadDisplay_Callback(hObject, eventdata, handles)
%
OK = menuLoad_Callback(hObject, eventdata, handles);

if OK
    menuDisplay_Callback(hObject, eventdata, handles);
end

return;
% --------------------------------------------------------------------
function menuSave_Callback(hObject, eventdata, handles)
% File | Save (Session dir)

% Set up the popup handles listing the mesh names.
global VOLUME
global selectedVOLUME
persistent savePath

% Since the file is probably a representation of the data, we often save it
% in the data directory rather than in the anatomy directory.
selectedVOLUME = viewSelected('volume'); 
if isempty(savePath), savePath = viewGet(VOLUME{selectedVOLUME},'sessiondirectory'); end
if ~exist(savePath,'dir'), error('Problem identifying session directory'); end

% if exist(viewGet(VOLUME{selectedVOLUME}, 'MeshDir'))
%     savePath = viewGet(VOLUME{selectedVOLUME}, 'MeshDir');
% end

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

% When we save the data, we get the color overlay, too, and we use that to
% write out the mesh.  Normally, we just paint the color overlay onto the
% image without changing the mesh data or data file.
coloroverlay = mrmGet(msh,'colors');
msh = meshSet(msh,'colors',coloroverlay);


mrmWriteMeshFile(msh,savePath);

return;

% --------------------------------------------------------------------
function menuSaveAnatdir_Callback(hObject, eventdata, handles)
% File | Save (Anatdir)
% ras 11/07: removed the persistent saveDir: the point of using the anatDir
% option is that the save directory is not peristent, but depends on the
% state of the view.
global VOLUME


selectedVOLUME = viewSelected('volume');

% for the 'Save Anat Dir' option, we save in the view's mesh directory.  
savePath = viewGet(VOLUME{selectedVOLUME}, 'meshdir'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), fprintf('No mesh to save in VOLUME{%.0f}',selectedVolume); return; end

fullName = mrvSelectFile('w','mat',[],'Save Mesh',savePath);
if isempty(fullName), return;
else savePath = fileparts(fullName);      % Remember this path
end

mrmWriteMeshFile(msh,fullName);

o3refresh(handles);
return;

% --------------------------------------------------------------------
function menuExitNoClose_Callback(hObject, eventdata, handles)
% File | Exit No Close
% This leaves the Mesh windows active

closereq;

return;

% --------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)
% File | Exit and Close
%
% Set up the popup handles listing the mesh names.
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Sometimes the Gray window is closed before we get here.  Then we don't
% want to do this because we can't access the UI.  
if ~isempty(selectedVOLUME) & selectedVOLUME > 0
    allMesh = viewGet(VOLUME{selectedVOLUME},'allmeshes');
    if ~isempty(allMesh)
        allMesh = mrmSet(allMesh,'closeall');
        VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'allmeshes',allMesh);
    end
end

closereq;

return;

% --------------------------------------------------------------------
function menuRefresh_Callback(hObject, eventdata, handles)
o3refresh(handles);
return;

% --------------------------------------------------------------------
function menuEdit_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuEditGetCameraRotation_Callback(hObject, eventdata, handles)
% 
% Dump this into the work space and store it in the window handle space.

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Get the current mesh, window id, and so forth
msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

% if camera rotation is not set, use the one in the mesh as a default
cRot = mrmGet(msh,'camerarotation');
fprintf('Current camera rotation:\n------------------\n');
cRot

% Store the camera rotation in the window data
handles.cameraRotation = cRot;
guidata(handles.figure1,handles);

return;

% --------------------------------------------------------------------
function menuEditCameraRotation_Callback(hObject, eventdata, handles)
%
% Set the camera rotation so we can put the mesh in a canonical view.
%

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Get the current mesh, window id, and so forth
msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

% if camera rotation is stored, use it.  Otherwise use the one in the
% window at this moment.
if checkfields(handles,'cameraRotation'), cRot = handles.cameraRotation; 
else cRot = mrmGet(msh,'camerarotation'); end

% Read the one the user wants.  Might be a better way to enter?
cRot = ieReadMatrix(cRot);

% Set it in the display
mrmSet(msh,'camerarotation',cRot);

% nothing to refresh, right?
% o3refresh(handles);

return;


% --------------------------------------------------------------------
function menuEditSetBackWhite_Callback(hObject, eventdata, handles)
%
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), warndlg('No current mesh.'); return; end

msh = mrmSet(msh,'background',[1 1 1]);
o3refresh(handles);
return;

% --------------------------------------------------------------------
function menuEditSetBackGray_Callback(hObject, eventdata, handles)
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), warndlg('No current mesh.'); return; end

msh = mrmSet(msh,'background',[.3 .3 .3]);
o3refresh(handles);

return;


% --------------------------------------------------------------------
function menuCurvatureContrast_Callback(hObject, eventdata, handles)
% Edit | Curvature Contrast
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Get the current mesh, window id, and so forth
msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
newMsh = meshChangeColor(msh);
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmesh',newMsh);

btnUpdate_Callback(hObject, eventdata, handles);

return;

% --------------------------------------------------------------------
function menuEditLightingColor_Callback(hObject, eventdata, handles)
% Edit | Lighting Color
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
lights = meshGet(msh,'lights');

%% put up a dialog for editing lighting levels --
% for this function, we set the coefficients for all
% lights to be the same. Build up an 'L' light struct
% which will eventually be handed to mrMesh:
if iscell(lights)
	L.diffuse = lights{1}.diffuse;
	L.ambient = lights{1}.ambient;
else
	L.diffuse = lights(1).diffuse;
	L.ambient = lights(1).ambient;
end

% create the dialog
dlg(1).fieldName = 'ambient';
dlg(1).style	 = 'edit';
dlg(1).string	 = 'Ambient Light Level';
dlg(1).value	 = num2str(L.ambient);

dlg(2).fieldName = 'diffuse';
dlg(2).style	 = 'edit';
dlg(2).string	 = 'Light Diffusion Coeffcient';
dlg(2).value	 = num2str(L.diffuse);

dlg(3).fieldName = 'distance';
dlg(3).style	 = 'edit';
dlg(3).string	 = ['Move lights closer (<1) or further (>1) ' ...
					'from current distance?'];
dlg(3).value	 = '1';


% get the response
resp = generalDialog(dlg, 'Set Mesh Lighting');
if isempty(resp), return; end

% parse the response
L.diffuse = str2num(resp.diffuse);
L.ambient = str2num(resp.ambient);
distance  = str2num(resp.distance); 

% apply the user settings to each light
host = meshGet(msh, 'host');
windowID = meshGet(msh, 'windowID');
for n = 1:length(lights)
	if iscell(lights)
		L.actor = lights{n}.actor;
		L.origin = distance .* lights{n}.origin;	
		
		lights{n} = mergeStructures(lights{n}, L);
	else
		L.actor = lights(n).actor;
		L.origin = distance .* lights(n).origin;
		
		lights(n) = mergeStructures(lights(n), L);
	end
     mrMesh(host, windowID, 'set', L);
end

% update mesh, lights in view
msh = meshSet(msh, 'lights', lights);
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME}, 'mesh', msh);

return;

% --------------------------------------------------------------------
function menuEditWindowSize_Callback(hObject, eventdata, handles)
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Get the current mesh, window id, and so forth
msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

prompt={'Enter window size'}; def={num2str([512,512])}; dlgTitle='Set Window Size'; lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer), return; 
else sz = str2num(answer{1}); end

mrmSet(msh,'windowSize',sz(1),sz(2));
return;

% --------------------------------------------------------------------
function menuEditWindowTitle_Callback(hObject, eventdata, handles)
% hObject    handle to menuEditWindowTitle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Get the current mesh, window id, and so forth
msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
mshName = meshGet(msh,'name');
prompt={'Enter title'}; def={mshName}; dlgTitle='Set Window Title'; lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer), return; end

mrmSet(msh,'windowTitle',answer{1});

return;


% --------------------------------------------------------------------
function menuPrint_Callback(hObject, eventdata, handles)
%
% Useful for examining mesh parameters.  
% We should probably make this return as a variable in the global
% workspace without the global.  There is some way ....

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

global printedMesh

fprintf('Current mesh parameters\n-------------------------\n');
printedMesh = viewGet(VOLUME{selectedVOLUME},'currentmesh')

fprintf('Current mesh data structure\n-------------------------\n');
printedMesh.data

return;


% --------------------------------------------------------------------
function menuBuild_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuBuildLeft_Callback(hObject, eventdata, handles)
menuBuild(handles,'left')
return;

% --------------------------------------------------------------------
function menuBuildRight_Callback(hObject, eventdata, handles)
menuBuild(handles,'right')
return;

% --------------------------------------------------------------------
function menuBuildBoth_Callback(hObject, eventdata, handles)
menuBuild(handles,'both')
return;

%--------------Called by all the menuBuildLeft/Right/Both routines.
function menuBuild(handles,hemisphere)
%
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

% Main callback for building the mesh. The VOLUME{} data is adjusted in that
% the mesh is attached.
[VOLUME{selectedVOLUME},meshN] = meshBuild(VOLUME{selectedVOLUME},hemisphere);

if ~isempty(meshN)
    VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmeshn',meshN);
end

o3refresh(handles);
return;

% --------------------------------------------------------------------
function menuDisplay_Callback(hObject, eventdata, handles)
%
%  Show the mesh, without any color overlay.

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME}, 'currentmesh');
if meshGet(msh,'windowid') < 0,
	% ras 07/07: we need to look for all meshes displayed 
	% in all volume views, not just the selected one: otherwise
	% you can't have two volume views with two meshes showing, 
	% which is needed:
	
	% first, check if the server is started
	serverStarted = mrmCheckServer(msh.host);
	if ~serverStarted
		id = mrmStart(-1, msh.host);  % make a new mesh window and start server
	end
	
	% now, get a new window ID (should return positive integer
	% corresponding to the mrMesh window)
	id = mrMesh(msh.host, -1, 'get'); 	% start a new window
	
    % We could reuse numbers.
    msh = meshSet(msh, 'windowid', id);
    msh = mrmInitMesh(msh);
else 
    meshVisualize(msh);
end


% Perhaps, I should write a replaceMesh routine because we use it so often?
if ~isempty(msh)
    VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmesh',msh); 
end

o3refresh(handles);

return;

% --------------------------------------------------------------------
function menuMeshDispMshSetWin_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME}, 'currentmesh');

% We need to get the mesh server to tell us how many windows are open and
% what their numbers are.  Until then, we do this annoying thing
wNumber = ieReadNumber('Enter mesh window number');
msh = meshSet(msh,'windowid',wNumber);
msh = mrmInitMesh(msh);

% Perhaps, I should write a replaceMesh routine because we use it so often?
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmesh',msh);

o3refresh(handles);

return;

% --- Executes on button press in btnDisplay.
function btnDisplay_Callback(hObject, eventdata, handles)

menuDisplay_Callback(hObject,eventdata,handles);

return;

% --- Executes on button press in btnTimeSeries.
function btnTimeSeries_Callback(hObject, eventdata, handles)

menuTimeSeries_Callback(hObject, eventdata, handles);

return;

% --------------------------------------------------------------------
function menuRename_Callback(hObject, eventdata, handles)

%  Rename the current mesh.  The renamed mesh can be saved.  

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume');  

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
meshName = meshGet(msh,'name');
if isempty(msh), warndlg('No current mesh.'); return; end

prompt={'Enter name'}; def={meshName}; dlgTitle='Rename object'; lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer), return; end

msh = meshSet(msh,'name',answer{1});
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'mesh',msh);

o3refresh(handles);

return;


% --------------------------------------------------------------------
function menuDelete_Callback(hObject, eventdata, handles)

% Deletes the currently selected mesh from the VOLUME{} structure (not its
% file). Closes the associated window.

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
meshNum = viewGet(VOLUME{selectedVOLUME},'currentmeshn');

if isempty(msh), warndlg('No current mesh.'); return; end

% Close the associated window
if meshGet(msh,'windowID') >= 0
    msh = mrmSet(msh,'close');
end

% Delete the mesh itself from the list.
VOLUME{selectedVOLUME} = meshDelete(VOLUME{selectedVOLUME}, meshNum);

o3refresh(handles);

return;


% --------------------------------------------------------------------
function menuMesh_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuSmooth_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
currentSmooth = meshGet(msh,'smooth_relaxation');
msh = meshSet(msh,'smooth_relaxation',min(1.5,currentSmooth+0.2));

% Rather than use visualize mesh, we leave the mesh in place and just
% change the vertices.  This helps the user see the smoothing.
msh = meshSmooth(msh);
mrmSet(msh,'vertices');

% We could put up the smoothing parameters here and let the user choose how
% much the smoothing will be.
% msh = mrmSet(msh,'smooth');
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'mesh',msh);

o3refresh(handles);

return;


% --------------------------------------------------------------------
function menuMeshSmoothLarge_Callback(hObject, eventdata, handles)
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

msh = meshSmooth(msh,1);
% msh = meshSet(msh,'id',2);
% mrmSet(msh,'vertices');

% We could put up the smoothing parameters here and let the user choose how
% much the smoothing will be.
% msh = mrmSet(msh,'smooth');
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'mesh',msh);

o3refresh(handles);
return;

% --------------------------------------------------------------------
function menuMeshInitVertices_Callback(hObject, eventdata, handles)
%
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');

msh = meshSet(msh,'vertices',meshGet(msh,'initialVertices'));
msh = meshSet(msh,'smooth_relaxation',0);   % 
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmesh',msh);

% Because we changed the vertices, we use this call.  This does not change 
% the color overlay.
mrmSet(msh,'vertices');

o3refresh(handles);

return;

% --------------------------------------------------------------------
function menuCursorOps_Callback(hObject, eventdata, handles)
% Empty
return;

% --------------------------------------------------------------------
function menuCursor_Callback(hObject, eventdata, handles,action)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume');  

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
windowID = meshGet(msh,'windowid');

if windowID >= 0
    switch lower(action)
        case {'read','get'}
            % Return the cursor position.  This should get a coordinate
            % frame description (i.e., left/right, inferior/superior,
            % anterior/posterior.  But I am not sure if this should be
            % w.r.t vAnatomy or Talairach or what.
            if windowID >= 0
                curpos = round(mrmGet(msh,'cursor'));
                mrMessage(sprintf('Cursor position\n\n Axial (Sup/Inf)   %.0f\nCoronal (Ant/Post)   %.0f\nSagittal (Left/Right)   %.0f\n',curpos(1),curpos(2),curpos(3)));
            end
        case {'set','write'}
            % Set the cursor position manually
            prompt={'Enter cursor coordinates:'};
            curpos = round(mrmGet(msh,'cursor'));
            def={num2str(curpos)};
            dlgTitle='Input cursor position';
            lineNo=1;
            answer=inputdlg(prompt,dlgTitle,lineNo,def);
            if isempty(answer), return;
            else pos = str2num(answer{1}); end
            mrmSet(msh,'cursorposition',pos);
            mrMessage(sprintf('Cursor:\t[%.0f, %.0f, %.0f]\n',pos(1),pos(2),pos(3)));
        case {'click'}

            % Click on the VOLUME view to set the cursor position
            
            figure(viewGet(VOLUME{selectedVOLUME},'fignum'))
            [VOLUME{selectedVOLUME},selectedPosition] = selectSliceCoords(VOLUME{selectedVOLUME});

            % The selected position is returned as: axial, coronal, sagittal
            mrmSet(msh,'cursor',selectedPosition([1,2,3]))
        otherwise
            error('Unknown Cursor option')
    end
else
    warndlg('No open window.');
end

return;

% --------------------------------------------------------------------
function menuAnatROI_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

VOLUME{selectedVOLUME} = setDisplayMode(VOLUME{selectedVOLUME},'anat');
VOLUME{selectedVOLUME} = refreshScreen(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = meshColorOverlay(VOLUME{selectedVOLUME});

return;


% --------------------------------------------------------------------
function menuCoherence_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

VOLUME{selectedVOLUME} = setDisplayMode(VOLUME{selectedVOLUME},'co');
VOLUME{selectedVOLUME} = refreshScreen(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = meshColorOverlay(VOLUME{selectedVOLUME});

return;

% --------------------------------------------------------------------
function menuPhase_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

VOLUME{selectedVOLUME} = setDisplayMode(VOLUME{selectedVOLUME},'ph');
VOLUME{selectedVOLUME} = refreshScreen(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = meshColorOverlay(VOLUME{selectedVOLUME});

return;

% --------------------------------------------------------------------
function menuAmp_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

VOLUME{selectedVOLUME} = setDisplayMode(VOLUME{selectedVOLUME},'amp');
VOLUME{selectedVOLUME} = refreshScreen(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = meshColorOverlay(VOLUME{selectedVOLUME});

return;

% --- Executes on button press in btnUpdate.
function btnUpdate_Callback(hObject, eventdata, handles)

% Change nothing.  Just update whatever was adjusted in the VOLUME window. 
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 
VOLUME{selectedVOLUME} = meshColorOverlay(VOLUME{selectedVOLUME});

return;

% --------------------------------------------------------------------
function menuROI_Callback(hObject, eventdata, handles)
return;


% --------------------------------------------------------------------
function menuROIinVOL_Callback(hObject, eventdata, handles)
%
global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 
pos = meshCursor2Volume(VOLUME{selectedVOLUME});
roiName = sprintf('mrm-%.0f-%.0f-%.0f',pos(1),pos(2),pos(3));
roiRadius = str2double(get(handles.editROISize,'String'));

VOLUME{selectedVOLUME} = makeROIdiskGray(VOLUME{selectedVOLUME},roiRadius,roiName,[],[],pos);
VOLUME{selectedVOLUME} = selectCurROISlice(VOLUME{selectedVOLUME});
VOLUME{selectedVOLUME} = refreshScreen(VOLUME{selectedVOLUME},1);

o3refresh(handles);

return;

% --------------------------------------------------------------------
function menuROI_mesh2vol_Callback(hObject, eventdata, handles)
meshROI2Volume(handles,2);
return;

% --------------------------------------------------------------------
function menuROI_mesh2volAllLayers_Callback(hObject, eventdata, handles)
meshROI2Volume(handles,3);
return;


% --- Executes during object creation, after setting all properties.
function editROISize_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%---------------------------

function editROISize_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of editROISize as text
%        str2double(get(hObject,'String')) returns contents of editROISize as a double

% We use roiDiameter = str2double(get(handles.editROISize,'String'))
% When we compute the VOLUME ROI
% We don't do anything on this call back

return;

% --------------------------------------------------------------------
function menuMeshROIRadius_Callback(hObject, eventdata, handles)

roiDiameter = str2double(get(handles.editROISize,'String'))

roiDiameter = ieReadNumber('Enter ROI radius (mm)',roiDiameter);
if isempty(roiDiameter), return;
else set(handles.editROISize,'String',num2str(roiDiameter));
end
return;


% --------------------------------------------------------------------
function menuROIinINP_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

global INPLANE
global selectedINPLANE
selectedINPLANE = viewSelected('inplane'); ; 

[selectedINPLANE,selectedVOLUME,nROI] = meshROIdiskInplane(handles);

return;


% --------------------------------------------------------------------
function menROIinFLAT_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

global FLAT
global selectedFLAT
selectedFLAT = viewSelected('flat'); ; 

pos = meshCursor2Volume(volView);
roiName = sprintf('mrm-%.0f-%.0f-%.0f',pos(1),pos(2),pos(3));
[VOLUME{selectedVOLUME},volROI] = makeROIdiskGray(VOLUME{selectedVOLUME},5,roiName,[],[],pos);

flatROI = vol2flatROI(volROI,VOLUME{selectedVOLUME},FLAT{selectedFLAT});
FLAT{selectedFLAT} = addROI(FLAT{selectedFLAT},flatROI);
FLAT{selectedFLAT} = refreshScreen(FLAT{selectedFLAT},1);

return;

% --- Executes on button press in btnOverlay.
function btnOverlay_Callback(hObject, eventdata, handles)
%
menuOverlay_Callback(hObject, eventdata, handles);
return;

% --- Executes on button press in btnClose.
function btnClose_Callback(hObject, eventdata, handles)

% Close a single window displaying a mesh.  Does not delete the mesh from
% the VOLUME structure.

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), warndlg('No current mesh.'); return; end

msh = mrmSet(msh,'close');

% Make sure we save the fact that the mesh is closed.
VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentmesh',msh);

o3refresh(handles);

return;

% --------------------------------------------------------------------
function menuPlot_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
% function menuTS_Callback(hObject, eventdata, handles)
% return;

% --------------------------------------------------------------------
function menuTimeSeries_Callback(hObject, eventdata, handles)

global INPLANE;

[sINP,curScan,nROI] = meshVOL2INP(handles);

%selectGraphWin;
plotMeanTSeries(INPLANE{sINP},curScan);

% Clean up.  Do we always want to eliminate the ROI?  Maybe.
if strcmp(viewGet(INPLANE{sINP},'name'),'hidden'), INPLANE = [];
else INPLANE{sINP} = deleteROI(INPLANE{sINP},nROI);
end

return;

% --------------------------------------------------------------------
function menuPlotMeanMultipleTS_Callback(hObject, eventdata, handles)
%
%  There is no way to define multiple open3dWindow ROIs at the moment.
%  Perhaps we should have an ROI list in the open3dWindow.
%  At present, this simply calls the multiple ROI plot for the INPLANE
%  window.  Not perfect.  Perhaps useful.

global INPLANE;
[sINP,curScan,nROI] = meshVOL2INP(handles);

% sINP = viewSelected('inplane'); 

%selectGraphWin;
plotMultipleTSeries(INPLANE{sINP},curScan);

return;

% --------------------------------------------------------------------
function menuPlotBlurTSeries_Callback(hObject, eventdata, handles)
blurTSeriesPlot;
return;

% --------------------------------------------------------------------
function menuSingleCycle_Callback(hObject, eventdata, handles)

global INPLANE;

[sINP,curScan,nROI] = meshVOL2INP(handles);

%selectGraphWin;
plotSingleCycleErr(INPLANE{sINP},curScan);

% Clean up
if strcmp(viewGet(INPLANE{sINP},'name'),'hidden'), INPLANE = [];
else INPLANE{sINP} = deleteROI(INPLANE{sINP},nROI);
end

return;


% --------------------------------------------------------------------
function menuFFTofMean_Callback(hObject, eventdata, handles)

global INPLANE;

[sINP,curScan,nROI] = meshVOL2INP(handles);

%selectGraphWin;
plotFFTSeries(INPLANE{sINP},curScan);

% Clean up
if strcmp(viewGet(INPLANE{sINP},'name'),'hidden'), INPLANE = [];
else INPLANE{sINP} = deleteROI(INPLANE{sINP},nROI);
end

return;


% --------------------------------------------------------------------
function menuMeanFFT_Callback(hObject, eventdata, handles)
%
global INPLANE;

[sINP,curScan,nROI] = meshVOL2INP(handles);

%selectGraphWin;
plotMeanFFTSeries(INPLANE{sINP},curScan);

if strcmp(viewGet(INPLANE{sINP},'name'),'hidden'), INPLANE = [];
else INPLANE{sINP} = deleteROI(INPLANE{sINP},nROI);
end

return;


% --------------------------------------------------------------------
function menuCovsPhasepolar_Callback(hObject, eventdata, handles)
disp('Not yet implemented')
return;


% --------------------------------------------------------------------
function menuSummary_Callback(hObject, eventdata, handles)
%
return;

function menuStats_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME

selectedVOLUME = viewSelected('volume');  

% Build an ROI in the VOLUME
menuROIinVOL_Callback(hObject, eventdata, handles);

mrRoistats(VOLUME{selectedVOLUME});

% Delete the ROI
VOLUME{selectedVOLUME} = deleteROI(VOLUME{selectedVOLUME});
return;

% --- Executes during object creation, after setting all properties.
function popObject_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;

% --- Executes on selection change in popObject.
function popObject_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns popObject contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popObject

% Selects this mesh.  This takes no action in terms of displaying the mesh.
meshNum = get(hObject,'Value');

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'setcurrentmeshn',meshNum);

o3refresh(handles);

return;

% --- Executes during object creation, after setting all properties.
function editBackground_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;

% --------------------------------------------------------------------
function menuBackground_Callback(hObject, eventdata, handles)
%

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), warndlg('No current mesh.'); return; end

bColor = [1,1,1];
prompt={'Enter [r,g,b] background color (0-1)'};
def={num2str(bColor)};
dlgTitle='Set Background Color';
lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer) 
    return;
else
    msh = mrmSet(msh,'background',str2num(answer{1}));
    o3refresh(handles);
end

return;

% --- Executes on button press in btnScreenShot.
function btnScreenShot_Callback(hObject, eventdata, handles,fname)
%
global VOLUME
global selectedVOLUME

selectedVOLUME = viewSelected('volume'); 

persistent pathname;
% if user cancelled before pathname is set to 0
if ~exist('pathname','var') | isempty(pathname) | ~ischar(pathname), pathname = pwd; end

if ~exist('fname','var') | isempty(fname)
    fileFilter = fullfile(pathname,'*.png');
    [filename, pathname] = uiputfile(fileFilter, 'Pick a file name.');
    if ~filename, return;
    else fname = fullfile(pathname,filename);
    end
end

[p,n,e] = fileparts(fname);
if ~strcmp(e,'.png'), e = '.png'; end
fname = fullfile(p,[n,e]);

% if ~exist('fname','var') | isempty(fname)
%     % When no fname is sent in, we keep track of the images and number them.
%     persistent curImgNum curSeriesNum;
%     if(isempty(curSeriesNum)) curSeriesNum = 1; end
%     if(isempty(curImgNum)) curImgNum = 1; end
%     mkdir(tempdir, 'mrMeshSS');
%     fname = fullfile(tempdir, 'mrMeshSS', ['mrMeshSS_' num2str(curSeriesNum,'%0.2d') '_' num2str(curImgNum,'%0.4d') '.png']);
%     while(exist(fname, 'file'))
%         curSeriesNum = curSeriesNum+1;
%         fname = fullfile(tempdir, 'mrMeshSS', ['mrMeshSS_' num2str(curSeriesNum,'%0.2d') '_' num2str(curImgNum,'%0.4d') '.png']);
%     end
%     curImgNum = curImgNum + 1;
% end

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if isempty(msh), warndlg('No current mesh.'); return; end

udata.rgb = mrmGet(msh,'screenshot')/255;
imwrite(udata.rgb, fname);
disp(['Screenshot saved to ' fname '.']);

% figure; 
% image(udata.rgb); 
% axis image
set(gcf,'userdata',udata);

return;

% --- Executes on button press in btnMovie.
function btnMovie_Callback(hObject, eventdata, handles)
%
% Creates an AVI file showing the fundamental time course in a region near
% the cursor with a diameter selected by the user.
% This appears to be obsolete. -ras, 07/08 (updated syntax anyway)
meshMovie([], [], 'Scratch', 10, 1);

return;

% --- Executes on button press in btnHideCursor.
function btnHideCursor_Callback(hObject, eventdata, handles)

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

msh = viewGet(VOLUME{selectedVOLUME},'currentmesh');
if(~isempty(strmatch('Hide', get(handles.btnHideCursor,'String'))))
    mrmSet(msh, 'cursoroff');
    set(handles.btnHideCursor, 'String', 'Show Cursor');
else
    mrmSet(msh, 'cursoron');
    set(handles.btnHideCursor, 'String', 'Hide Cursor');
    set(handles.btnHideCursor, 'String', 'Hide Cursor');
end
return;

%-----------------------
function menuHideCursor_Callback(hObject, eventdata, handles)
%

if(~isempty(strmatch('Hide', get(hObject,'Label'))))
    set(hObject, 'Label', 'Show Cursor');
else
    set(hObject, 'Label', 'Hide Cursor');
end
btnHideCursor_Callback(handles.btnHideCursor, eventdata, handles);
return;


%--------------------------------------------
function o3refresh(handles);

% Set up the popup handles listing the mesh names.
global VOLUME
selectedVOLUME = viewSelected('volume'); 

% Regulate the popup contents
o3PopObjectName(VOLUME{selectedVOLUME},handles);

% Should we reset the origin and background color from the currently
% selected mesh? 

% Create the text description information for the upper right.
txt = o3Description(VOLUME{selectedVOLUME});
set(handles.txtDescription,'String',txt);

return;

%-------------------------------
function txt = o3Description(v)
%

msh  = viewGet(v,'currentmesh');
if isempty(msh), 
    txt = sprintf('Win\nN/A'); 
    return; 
end

windowID = meshGet(msh,'id');
if windowID < 0, txt = sprintf('Win\nN/A');
else       txt = sprintf('Win\n%.0f',windowID);
end

return;

%-----------------------------------
function o3PopObjectName(v,handles)
%
%   o3PopObjectName(v,handles)
%

meshNames = viewGet(v, 'meshnames');

if isempty(meshNames), 
    set(handles.popObject,'Visible','off');
else 
    % Make the popup button point to the right mesh name.
    selectedMesh = viewGet(v,'currentmeshn');
    set(handles.popObject, 'String', meshNames);
    set(handles.popObject, 'Value', selectedMesh);
    set(handles.popObject,'Visible','on'); 
end

return;


% --------------------------------------------------------------------
function menuImages_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menImagesScreen_Callback(hObject, eventdata, handles)
btnScreenShot_Callback(hObject, eventdata, handles);
return;

% --------------------------------------------------------------------
function menuFileScreenAnatomy_Callback(hObject, eventdata, handles)

% Normally we store the output directory here persistently.
persistent pathname;

if ~exist('pathname','var') | isempty(pathname) | ~ischar(pathname), pathname = pwd; end

fileFilter = fullfile(pathname,'*.png');
[filename, pathname] = uiputfile(fileFilter, 'Pick a png file name.');
if ~filename, return; 
else fName = fullfile(pathname,filename);
end
[p,n,e] = fileparts(fName);
if ~strcmp(e,'.png'),
    disp('Forcing extension to .png');
    e = '.png'
end
btnScreenShot_Callback(hObject, eventdata, handles,fName);

menuAnatROI_Callback(hObject, eventdata, handles);
n = sprintf('%s_Anat',n);
anatName = fullfile(p,[n,e]);
btnScreenShot_Callback(hObject, eventdata, handles,anatName);

% It would be best to put things back as we found them.

return;

% --------------------------------------------------------------------
function menuImageMovie_Callback(hObject, eventdata, handles)
global VOLUME selectedVOLUME
roiRadius = str2double(get(handles.editROISize, 'String'));
meshMovie(VOLUME{selectedVOLUME}, roiRadius, 'dialog');
return;


% --------------------------------------------------------------------
function menuPrefs_Callback(hObject, eventdata, handles)
mrmPreferences;
return;


% --------------------------------------------------------------------
function menuEditSaveCameraRotation_Callback(hObject, eventdata, handles)
meshAngle('save');
return;

% --------------------------------------------------------------------
function menuEditLoadCameraAngle_Callback(hObject, eventdata, handles)
meshAngle('load');
return;


% --------------------------------------------------------------------
function menuEditFontSize_Callback(hObject, eventdata, handles)

dSize = ieReadNumber('Font change relative to base: [-4 4]',2);
if isempty(dSize), disp('User canceled'); return; end

% Changes relative to the base for your platform.
fontChangeSize(gcbf,dSize);

return;

% --------------------------------------------------------------------
function menuTCUI_mesh_Callback(hObject, eventdata, handles)
% Opens a Time Course UI for the current scan group, for data from
% the mesh ROI (i.e., the ROI drawn using the mrMesh 'draw' tools).
% ROI is auto-projected back to a hidden inplane.
mrGlobals;
s = viewSelected('gray'); 
dataType = viewGet(VOLUME{s}, 'curDataType');
scan = viewGet(VOLUME{s}, 'curScan');

% initialize hidden inplane view; prefer this to checking INPLANE
inplane = initHiddenInplane(dataType, scan);

% xform from mesh to volume view to hiddent inplane
meshROI2Volume(handles, 2); % 3=all gray layers -- sometimes flakey?
inplane = vol2ipCurROI(VOLUME{s}, inplane);
VOLUME{s} = deleteROI(VOLUME{s}); % may want to save? not for now...

% open a TCUI
tc_plotScans(inplane, 1); % 1=use scan group

% clean up
clear inplane s dataType scan

return;

% --------------------------------------------------------------------
function menuTCUI_disc_Callback(hObject, eventdata, handles)
% Opens a Time Course UI for the current scan gruop, for data from
% a disc ROI surrounding the current cursor location (radius set by
% set disc radius).
% ROI is auto-projected back to a hidden inplane.
global INPLANE;

[s curScan nROI] = meshVOL2INP(handles);

% open a TCUI
tc_plotScans(INPLANE{s}, 1); % 1=use scan group

% Clean up.  Do we always want to eliminate the ROI?  Maybe.
if strcmp(viewGet(INPLANE{s}, 'name'), 'hidden'), INPLANE = [];
else INPLANE{s} = deleteROI(INPLANE{s}, nROI);
end

return;


% --------------------------------------------------------------------
function menuSettingsPanel_Callback(hObject, eventdata, handles)
% hObject    handle to menuSettingsPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
test = get(hObject, 'UserData');

% if we created the panel already, test will be non-empty and should be
% toggled on/off. if it's empty, we should create it.
if isempty(test)
    test = meshSettingsPanel(gcf);
    set(hObject, 'UserData', test, 'Checked', 'on');
else
    % ensure all the uicontrols belong to the toggled panel
    set(test.zoom, 'Parent', test.panel);
    set(test.store, 'Parent', test.panel);
    set(test.retrieve, 'Parent', test.panel);
    set(test.rename, 'Parent', test.panel);
    set(test.delete, 'Parent', test.panel);
    mrvPanelToggle(test.panel, hObject);
end

return;


% --------------------------------------------------------------------
function recomputeV2G_Callback(hObject, eventdata, handles)
% hObject    handle to recomputeV2G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% This function recomputes the vertex to gray map in the current mesh.
mrGlobals;
s = viewSelected('gray'); 

msh = viewGet(VOLUME{s}, 'curmesh');

vertexGrayMap = mrmMapVerticesToGray( meshGet(msh, 'initialvertices'),...
					viewGet(VOLUME{s}, 'nodes'), ...
					viewGet(VOLUME{s}, 'mmPerVox'),...
					viewGet(VOLUME{s}, 'edges') );

msh = meshSet(msh, 'vertexgraymap', vertexGrayMap);

VOLUME{s} = viewSet(VOLUME{s}, 'curmesh', msh);

return;

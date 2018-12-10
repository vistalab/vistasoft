function varargout = dtiFiberUI(varargin)
%Create the dtiFiberUI window; contains all the opening and callbacks.
%
% Application M-file for dtiFiberUI.fig
%
%    fig = dtiFiberUI, or
%    fig = dtiFiberUI(dt6FileName), or
%    dtiFiberUI('callback_name', ...) invoke the named callback.
%
% Philosophy is to attach all of the data to the window.  This allows us to
% have multiple instances of this program running on independent data
% without having to manage the data.
%
% The callback functions contained within should be listed here:
%
% TODO:
%   * This routine has useful functions in it.  They should be extracted.
%   * This routine is more tan 4000 lines long.  It should be much shorter.
%   * The commenting should be improved.
%   * There has been no updating of the code as Matlab evolved.  We will
%   lose functionality if we don't worry about deprecation of strmatch and
%   perhaps other functions
%   * We don't use dtiSet/Get much in here. We should.
%
%   Fix: 
%   * menuFile_AlignAddNiftiImage_Callback
%   * spm calls for interpolation should not be replicated, but they
%        should all go through one interpolation function.  See
%        dtiLoadNormalizedMap for another example.  There are some in here
%        I think.
%   * cut_click functions should be integrated and pulled out of here
%   * menuAnalyze_adjustAcPcAlign_Callback
%   * menuAnalyze_adjustDTIAlign_Callback
%   * menuRois_buildFromCurImage_Callback
%   * menuRois_buildFromCurImage_Callback
%   * menuXform_computeSpatialNormalization_Callback
%   * menuView_sliceMontage_Callback
%   * menuView_quench_pushPaths_Callback
%
% HISTORY:
%   2003.05.15 RFD (bob@white.stanford.edu) wrote it.
%   2004.06    BW  (wandell@stanford.edu)   many changes
%   Many years of changes and additions
%   2012.09    BW looked at it again for neatening.
%
% (c) Stanford VISTA Team
%
% Last Modified by GUIDE v2.5 04-Nov-2009 18:56:50


%% The callbacks begin here
% This code was written in the early days of GUIDE. It still runs with the
% modern Matlab.  But there have been advances that we don't take advantage
% of.  And Bob was still figuring out how to use Matlab callbacks when this
% was first written.  So there are lots of things that could be better.
%
% For example, in modern usage, the code below would be the opening
% function created by GUIDE. This was written long enough ago so that we
% don't have such a function.
if(nargin <= 1)  % LAUNCH GUI
    %clear all; clear global all;
    
    fig = openfig(mfilename,'new');
    
    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    
    if ~isnumeric(fig)
        % In Matlab 2014b and up the figure handle is defined as an object.
        % This new definition is not compatible with older versions of
        % Matlab that treat the handle as a number.
        fig = fig.Number;
    end
    
    % initialize variables
    
    % We should use the dtiGet/dtiSet more,using the form
    %
    %   handles = dtiSet(handles,'fiberGroups',val)
    %
    % to manage the large set of data attached to the handles structure.
    
    % Two figures are created by default.  The main dtiFiberUI figure and a
    % 2nd one (rarely used) for showing Matlab 3D renderings.
    handles.fig = fig;
  
    handles.fig3d = figure;
    handles.title = sprintf('mrdMain%d',fig);
     handles.type  = sprintf('mrdWindow');
    set(fig,'Name',handles.title);
    
    
    % Fiber group initialization
    handles.fiberGroups = [];
    handles.curFiberGroup = 0;
    handles.fiberGroupShowMode = 2;
    set(handles.popupFiberShow,'Value',handles.fiberGroupShowMode);
    handles = popupCurrentFiberGroup_Refresh(handles);
    
    handles.interpType = 'n';
    
    % Region of interest initialization
    handles.rois = [];
    handles.curRoi = 0;
    handles.roiShowMode = 2; set(handles.popROIShow,'Value',handles.roiShowMode);
    handles = popupCurrentRoi_Refresh(handles);
    
    % 3D Matlab figure initialization
    set(handles.fig3d, 'NumberTitle', 'off');
    n = sprintf('mrd3D%d',fig);
    set(handles.fig3d, 'Name', n);
    set(handles.fig3d,  'Visible','off');
    
    % 3D visualization initialization
    set(handles.rbAxial,'Value',1);
    set(handles.rbCoronal,'Value',0);
    set(handles.rbSagittal,'Value',1);
    handles.mrMesh = dtiMrMeshInit(174);
    
    handles.versionNum = 1.0;
    
    % You can put a figure handle for other dtiFiberUI figs here:
    handles.yokeTo = [];
    
    % A default file location
    % If mrVista is running, we'll try to set the default dir from the
    % anatomy path.
    global mrSESSION;
    if(isfield(mrSESSION, 'subject'))
        handles.defaultPath = getAnatomyPath(mrSESSION.subject);
        if(exist(fullfile(handles.defaultPath,'dti'),'dir'))
            handles.defaultPath = fullfile(handles.defaultPath,'dti');
        end
    else
        handles.defaultPath = pwd;
    end
    handles.defaultPath = [handles.defaultPath filesep];
    
    % Creates a large set of default colormaps used in overlays
    handles = dtiCmapInit(handles);

    set(handles.popupOverlayCmap, 'String', {handles.cmaps(:).name}');
    set(handles.popupOverlayCmap, 'Value', 1);
    
    % This is impsortant and needs some comment.
    handles.bb = dtiGet(0,'defaultBoundingBox');
    
    % Replace the current figure handle with the new set of handles
    % containing the additional data
    guidata(fig, handles);
    
    % If there is an argument, it should be the name of a dt6 file, I think.
    if(nargin==1)
        handles = dtiLoadDt6Gui(handles, varargin{1});
        handles.defaultPath = [handles.defaultPath filesep];
        handles = dtiRefreshFigure(handles,0);
        handles = updateStandardSpaceValue(handles);
        guidata(fig, handles);
    end
    
    % If there is a return, it gets the main figure that was created.
    if nargout > 0
        varargout{1} = fig;
    end
    
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    % In this case, there were more than 1 input argument.
    % We check that the first one is a string, and then we invoke that
    % string as a function with parameters varargin{:}
    try
        if (nargout)
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        else
            feval(varargin{:}); % FEVAL switchyard
        end
    catch ME
        disp('An error occurred in mrDiffusion:')
        disp(ME.message)
        disp('Thrown in:')
        disp([ME.stack(1).file, sprintf(' line %i', ME.stack(1).line)])
    end
    
end

return

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
%   % Work-around for Matlab's lack of support for LaTex in UIControls. We
%   % want LaTex in our image value unit string. So, we build it using a text
%   % object.
%   p = get(handles.textImgVal,'Position');
%   handles.textImgValStr = text(p(1), p(2), '                 \mum^2/msec');
%   set(gca, 'vis', 'off');
return;



%% Checkbox ROI Edit Mode
function cbRoiEditMode_Callback(hObject, eventdata, handles)
return;

function cbRoiEditMode_CreateFcn(hObject, eventdata, handles)
return;

%% Maybe the following cut_click functions can be integrated 
function z_cut_click_Callback(hObject, eventdata, handles)
% Used by dtiRefreshFigure to establish the image callbacks. Called there
% for each image in the window.  Doesn't seem to be called elsewhere.
%
% See SelectionType property to see if a special key was held down.
% 'Normal' = left mouse button (LMB)
% 'extend' = shift-LMB or middle MB
% 'alt'    = control-LMB or right MB
% 'open'   = double-click any MB

selType = get(handles.fig,'SelectionType');

coord = get(hObject,'CurrentPoint');
coord = coord(1,1:2);
curPosition = str2num(get(handles.editPosition, 'String')); %#ok<*ST2NM>
newPosition = round([coord(1) coord(2) curPosition(3)]);
penStyleInd = get(handles.popup_roiEditPen,'Value');

if(strncmpi(selType,'nor',3))
    setPositionAcPc(handles, newPosition);
elseif(strncmpi(selType,'alt',3)&&get(handles.cbRoiEditMode,'Value'))
    if(isempty(handles.rois)) handles = dtiAddROI(dtiNewRoi,handles,1); end
    handles.rois(handles.curRoi) = ...
        dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'add', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
elseif(strncmpi(selType,'ext',3) & ...
        get(handles.cbRoiEditMode,'Value') & ...
        ~isempty(handles.rois))
    handles.rois(handles.curRoi) = ...
        dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'remove', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end

return;

% --------------------------------------------------------------------
function y_cut_click_Callback(hObject, eventdata, handles)
% See above
selType = get(handles.fig,'SelectionType');
coord = get(hObject,'CurrentPoint');
coord = coord(1,1:2);
curPosition = str2num(get(handles.editPosition, 'String'));
newPosition = round([coord(1) curPosition(2) coord(2)]);
penStyleInd = get(handles.popup_roiEditPen,'Value');
if(strncmpi(selType,'nor',3))
    setPositionAcPc(handles, newPosition);
elseif(strncmpi(selType,'alt',3)&&get(handles.cbRoiEditMode,'Value'))
    if(isempty(handles.rois)) handles = dtiAddROI(dtiNewRoi,handles,1); end
    handles.rois(handles.curRoi) = dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'add', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
elseif(strncmpi(selType,'ext',3)&get(handles.cbRoiEditMode,'Value')&~isempty(handles.rois))
    handles.rois(handles.curRoi) = dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'remove', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end
return;

% --------------------------------------------------------------------
function x_cut_click_Callback(hObject, eventdata, handles)
% See above above
selType = get(handles.fig,'SelectionType');
coord = get(hObject,'CurrentPoint');
coord = coord(1,1:2);
curPosition = str2num(get(handles.editPosition, 'String'));
newPosition = round([curPosition(1) coord(1) coord(2)]);
penStyleInd = get(handles.popup_roiEditPen,'Value');
if(strncmpi(selType,'nor',3))
    setPositionAcPc(handles, newPosition);
elseif(strncmpi(selType,'alt',3) & ...
        get(handles.cbRoiEditMode,'Value'))
    if(isempty(handles.rois)) handles = dtiAddROI(dtiNewRoi,handles,1); end
    handles.rois(handles.curRoi) = ...
        dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'add', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
elseif(strncmpi(selType,'ext',3) & ...
        get(handles.cbRoiEditMode,'Value') & ...
        ~isempty(handles.rois))
    handles.rois(handles.curRoi) = dtiRoiModifyCoords(handles.rois(handles.curRoi), newPosition, 'remove', penStyleInd);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end

return;


% --- Executes on button press in pbZPlus.
function pbZPlus_Callback(hObject, eventdata, handles)
% Push button plus sign for z image.  Similar callbacks follow for
% decrements and other slices. The dtiIncrementImagePlane function is below
% here in this file.
dtiIncrementImagePlane(hObject,handles,'+z');
return;

% --- Executes on button press in pbZMinus.
function pbZMinus_Callback(hObject, eventdata, handles)
dtiIncrementImagePlane(hObject,handles,'-z');
return;

% --- Executes on button press in pbYPlus.
function pbYPlus_Callback(hObject, eventdata, handles)
dtiIncrementImagePlane(hObject,handles,'+y');
return;

% --- Executes on button press in pbYMinus.
function pbYMinus_Callback(hObject, eventdata, handles)
dtiIncrementImagePlane(hObject,handles,'-y');
return;

% --- Executes on button press in pbXplus.
function pbXplus_Callback(hObject, eventdata, handles)
dtiIncrementImagePlane(hObject,handles,'+x');
return;

% --- Executes on button press in pbXMinus.
function pbXMinus_Callback(hObject, eventdata, handles)
dtiIncrementImagePlane(hObject,handles,'-x');
return;

%------------------------------------------
function dtiIncrementImagePlane(hObject,handles,whichPlane)
% Adjust view plane up or down by one.
% whichPlane is +x,-x,+y,-y,+z,-z
%
curPosition = str2num(get(handles.editPosition, 'String'));
mm = dtiGet(handles,'curMm');
switch lower(whichPlane)
    case '+x', curPosition(1) = round(curPosition(1) + mm(1));
    case '+y', curPosition(2) = round(curPosition(2) + mm(2));
    case '+z', curPosition(3) = round(curPosition(3) + mm(3));
    case '-x', curPosition(1) = round(curPosition(1) - mm(1));
    case '-y', curPosition(2) = round(curPosition(2) - mm(2));
    case '-z', curPosition(3) = round(curPosition(3) - mm(3));
    otherwise
end
set(handles.editPosition, 'String', sprintf('%.1f, %.1f, %.1f',curPosition));
editPosition_Callback(handles.editPosition, [], handles);
return;

% --- Executes on selection change in popup_roiEditPen.
function popup_roiEditPen_Callback(hObject, eventdata, handles)
return;

% --- Executes during object creation, after setting all properties.
function popup_roiEditPen_CreateFcn(hObject, eventdata, handles)
set(hObject,'String', dtiRoiEditGetPen);
return;

% --- Executes on button press in toggle_zoom.
function toggle_zoom_Callback(hObject, eventdata, handles)
if(get(hObject,'Value'))
    zoom on;
    set(hObject,'String','Zoom on');
else
    zoom off;
    set(hObject,'String','Zoom off');
end
return;

% --- Executes on button press in pb_zoomReset.
function pb_zoomReset_Callback(hObject, eventdata, handles)
zoom off;
set(handles.toggle_zoom,'Value',0);
set(handles.toggle_zoom,'String','Zoom off');
axis(handles.x_cut,'auto'); zoom reset;
axis(handles.y_cut,'auto'); zoom reset;
axis(handles.z_cut,'auto'); zoom reset;
return;

%-----------------------------------------
% UPDATE PLOTS BUTTON
function varargout = plotbutton_Callback(h, eventdata, handles, varargin)
handles = dtiRefreshFigure(handles, 1);
guidata(h, handles);
return;

%-----------------------------------------
% GLASS BRAIN CHECKBOX (cb)
function varargout = cbGlassBrain_Callback(h, eventdata, handles, varargin)
return;

%-----------------------------------------
% SHOW FIBERS CHECKBOX
function cbShowFibers_Callback(hObject, eventdata, handles)
return;

% SHOW 3D CHECKBOX
function cbShowMatlab3d_Callback(hObject, eventdata, handles)
% Matlab 3D check box
return;

% USE MRMESH CHECKBOX
function cbUseMrMesh_CreateFcn(hObject, eventdata, handles)
% set(hObject, 'Enable', 'off');
return;

function cbUseMrMesh_Callback(hObject, eventdata, handles)
return;

% SHOW CUR POS MARKER CHECKBOX
function cbShowCurPosMarker_Callback(hObject, eventdata, handles)
return;

function cbShowCurPosMarker_CreateFcn(hObject, eventdata, handles)
set(hObject, 'Value', 1);
return;


% These three radio buttons (rb) store which planes we show in the mrMesh
% view. 
function rbAxial_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of rbAxial
return;

% --- Executes on button press in rbCoronal.
function rbCoronal_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of rbCoronal
return;

% --- Executes on button press in rbSagittal.
function rbSagittal_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of rbSagittal
return;

% Current value display box
function editCurVal_Callback(hObject, eventdata, handles)
return;

% --- Executes during object creation, after setting all properties.
function editCurVal_CreateFcn(hObject, eventdata, handles)
return;

% Edit Overlay Threshold
function editOverlayThresh_Callback(hObject, eventdata, handles)
val = str2double(get(handles.editOverlayThresh,'String'));
handles = dtiSet(handles,'curoverlaythreshslider',val);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

function editOverlayThresh_CreateFcn(hObject, eventdata, handles)
set(hObject, 'String', '0.0');
return;

% Edit Overlay Alpha
function editOverlayAlpha_Callback(hObject, eventdata, handles)
% Value is stored in the edit box.  It is used by the refresh.
handles = dtiRefreshFigure(handles, 0);
return;

function editOverlayAlpha_CreateFcn(hObject, eventdata, handles)
% Initialize alpha to 0
set(hObject, 'String', '0.0');
return;

% Edit Position Callback
function editPosition_CreateFcn(hObject, eventdata, handles)
% Initialize current position to (0,0,0)
set(hObject, 'String', '0,0,0');
return;

function editPosition_Callback(hObject, eventdata, handles)
curPosAcpc = str2num(get(hObject, 'String'));
setPositionAcPc(handles, curPosAcpc);
return;

function setPositionAcPc(handles, acpcCoord)
% Specify current position in acpc coordinates

% Fill the string
set(handles.editPosition, 'String', sprintf('%.1f, %.1f, %.1f', acpcCoord));

% Get the standard space popup value and set this appropriately.
handles = updateStandardSpaceValue(handles, acpcCoord);

% Redraw
handles = dtiRefreshFigure(handles, 0);
guidata(handles.editPosition, handles);
return;

% Edit Position (Standardized space) Callback
%
%-----------------------------------------
function editPositionTal_CreateFcn(hObject, eventdata, handles)
set(hObject, 'String', '0,0,0');
return;

function editPositionTal_Callback(hObject, eventdata, handles)
ssCoords = str2num(get(hObject, 'String'));
ssVals = get(handles.popupStandardSpace,'String');
curSs = ssVals{get(handles.popupStandardSpace,'Value')};
curPosAcpc = '';
if(strcmpi(curSs,'Image'))
    T = handles.bg(get(handles.popupBackground,'Value')).mat;
    curPosAcpc = mrAnatXformCoords(T, ssCoords);
elseif(strcmpi(curSs,'Talairach'))
    curPosAcpc = mrAnatTal2Acpc(handles.talairachScale, ssCoords);
else
    % Check for other standard spaces
    if(isfield(handles,'t1NormParams')&&~isempty(handles.t1NormParams))
        normSs = strmatch(curSs,{handles.t1NormParams(:).name});
        if(~isempty(normSs))
            sn = handles.t1NormParams(normSs).sn;
            sn.outMat = eye(4);
            curPosAcpc = mrAnatXformCoords(sn, ssCoords);
        end
    end
    if(isempty(curPosAcpc)&&isfield(handles,'labels')&&~isempty(handles.labels))
        disp('not implemented yet.');
        return;
    end
end
if(~isempty(curPosAcpc))
    set(handles.editPosition, 'String', sprintf('%.0f, %.0f, %.0f', round(curPosAcpc)));
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end
return;

%----------------------------------------
% Standard Space popupup
%
function popupStandardSpace_CreateFcn(hObject, eventdata, handles)
set(hObject,'String', {'Image'});
return;

%-----------------------------------------
function popupStandardSpace_Callback(hObject, eventdata, handles)
acpcCoord = str2num(get(handles.editPosition, 'String'));
handles = updateStandardSpaceValue(handles, acpcCoord);
guidata(hObject, handles);
return;

%----------------------------------------
% Background Image popupup
%
function popupBackground_CreateFcn(hObject, eventdata, handles)
set(hObject,'String', {'No Data loaded'});
return;

%-----------------------------------------
function popupBackground_Callback(hObject, eventdata, handles)
handles = dtiRefreshFigure(handles, 0);
handles = updateStandardSpaceValue(handles);
guidata(hObject, handles);
return;

%----------------------------------------
% Overlay Image and colormap popupStandardSpace-ups
%
function popupOverlay_Callback(hObject, eventdata, handles)
handles = updateOverlayThresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

function popupOverlay_CreateFcn(hObject, eventdata, handles)
return;

function popupOverlayCmap_Callback(hObject, eventdata, handles)
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

function popupOverlayCmap_CreateFcn(hObject, eventdata, handles)
return;

function pbEditCurBackground_Callback(hObject, eventdata, handles)
% Push button?  Edit current background
bgNum = dtiGet(handles,'curBgNum');
dispRange = handles.bg(bgNum).displayValueRange;
clipRange = [handles.bg(bgNum).minVal handles.bg(bgNum).maxVal];
dispRange(1:2) = dispRange(1:2) .* (clipRange(2)-clipRange(1)) + clipRange(1);
ans = inputdlg({'Name:','Display Range:','Unit String:'},...
    'Background Image Properties',1,...
    {handles.bg(bgNum).name, num2str(dispRange), handles.bg(bgNum).unitStr});
if(~isempty(ans))
    handles.bg(bgNum).name = ans{1};
    dispRange = str2num(ans{2});
    dispRange(1:2) = (dispRange(1:2) - clipRange(1)) ./ (clipRange(2)-clipRange(1));
    handles.bg(bgNum).displayValueRange = dispRange;
    handles.bg(bgNum).unitStr = ans{3};
    % Update the GUI (in case the name changed)
    set(handles.popupBackground, 'String', {handles.bg(:).name}');
    set(handles.popupOverlay, 'String', {handles.bg(:).name}');
    % update the figure (in case the display range changed)
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end
return;


%----------------------------------------
% Overlay threshold slider
%
function handles = updateOverlayThresh(handles)
handles = dtiSet(handles,'curOverlayThresh',get(handles.slider_overlayThresh,'Value'));
return;

% --- Executes on slider movement.
function slider_overlayThresh_Callback(hObject, eventdata, handles)
handles = dtiSet(handles,'curOverlayThresh',get(hObject,'Value'));
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

function slider_overlayThresh_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'min',0,'max',1);
return


%-----------------------------------------
% Current ROI popup
function popupCurrentRoi_CreateFcn(hObject, eventdata, handles)
return;

%-----------------------------------------
function popupCurrentRoi_Callback(hObject, eventdata, handles)
%
handles.curRoi = get(handles.popupCurrentRoi,'Value');

% If Current show mode, adjust the visibility
if (handles.roiShowMode == 2)
    for ii=1:length(handles.rois), handles.rois(ii).visible = 0; end
    handles.rois(handles.curRoi).visible = 1;
    handles = dtiRefreshFigure(handles, 0);
end

guidata(hObject, handles);

return;

%-----------------------------------------
function handles = popupCurrentRoi_Refresh(handles)
% Refresh the Current ROI popup

if isempty(handles.rois), roiStr = {''};
else
    % Place all of the names in the popup string
    roiStr = {handles.rois.name};
end
set(handles.popupCurrentRoi,'String', roiStr);

% Set the display string
if(handles.curRoi < 1 || (handles.curRoi > length(roiStr)))
    handles.curRoi = 1;
end
set(handles.popupCurrentRoi,'Value', handles.curRoi);

return;

% ********************************************************************
% MENU: FILE
% ********************************************************************

%% Main file
function menuFile_Callback(hObject, eventdata, handles)
return;

%% File | Open tensor (dt6) file
function menuFile_OpenTensor_Callback(hObject, eventdata, handles)
handles = dtiLoadDt6Gui(handles,handles.defaultPath);
handles = dtiRefreshFigure(handles,0);
handles = updateStandardSpaceValue(handles);
guidata(hObject, handles);
return;

%% File | Load labeled atlas
function menuFile_LoadLabels_Callback(hObject, eventdata, handles)

% 
[handles, mapData, mapName, mmPerVox, xformImgToAcpc, labels] = dtiLoadNormalizedMap(handles);
if(~isempty(mapData))
    newLabel.name = mapName;
    newLabel.map = round(mapData);
    % FIX ME: Assumes AAL label text file format
    newLabel.labelText([labels{:,1}]) = labels(:,2);
    newLabel.xformAcpcToImg = inv(xformImgToAcpc);
    if(~isfield(handles,'labels'))
        handles.labels = newLabel;
    else
        handles.labels(end+1) = newLabel;
    end
    handles = dtiSet(handles, 'addStandardSpace', newLabel.name);
    handles = updateStandardSpaceValue(handles);
    guidata(hObject, handles);
end
return;

%% File |  Add deformation
function menuFile_AddDeformation_Callback(hObject, eventdata, handles)

% Comments, sigh.
[f,p] = uigetfile({'*.mat'}, 'Select a deformation file...', handles.defaultPath);
if(isnumeric(f)) error('Canceled.'); end
basename = fullfile(p,f);
d = load(basename);
name = 'deform dist';
img = d.absDeform;
if(isfield(d,'xform'))
    mat = d.xform;
else
    % We assume that the xform for the deformation is the same as that for
    % the vectors- probably a safe assumption.
    mat = handles.xformToAcpc;
end
mmPerVoxel = handles.mmPerVoxel;
handles = dtiAddBackgroundImage(handles, img, name, mmPerVoxel, mat, [], 0, 'mm');
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Add NIFTI/Analyze image 
function menuFile_AddAnalyzeImage_Callback(hObject, eventdata, handles)

[f, p] = uigetfile({'*.nii;*.nii.gz','NIFTI';'*.hdr','Analyze'}, 'Select image file...', handles.defaultPath);
if(~isnumeric(f))
    if(strcmpi(f(end-2:end),'hdr'))
        [img, mmPerVox, hdr] = loadAnalyze(fullfile(p,f));
        img = img.*hdr.pinfo(1);
        xform = hdr.mat;
        unitStr = '';
    else
        ni = niftiRead(fullfile(p,f));
        % we need the xform that brings us inline with the anatomy image. We
        % assume that the NIFTI/Analyze xform brings us to ac-pc space, so we want
        % the difference between the two ac-pc xforms.
        xform = ni.qto_xyz;
        img = double(ni.data);
        mmPerVox = ni.pixdim;
        %unitStr = ni.??;
        unitStr = '';
    end
    % *** NOTE: should we scale image values by ni.cal_max/cal_min?
    % We should clip the image to the default bb to avoid keeping
    % unnecessary voxels in memory.
    handles = dtiAddBackgroundImage(handles, img, f, mmPerVox, xform, [], 0, unitStr);
    % Messing around for muscle data
    %handles = dtiAddBackgroundImage(handles, img, f, mmPerVox, xform, [0.5 1.2], 0, unitStr);
    handles = dtiRefreshFigure(handles);
    guidata(hObject, handles);
else
    disp('Add Image canceled.');
end
return;

%% File | Align and add NIFTI image file
function menuFile_AlignAddNiftiImage_Callback(hObject, eventdata, handles)

% This should be a separate function and the callback should be shorter.
% dtiAlignAddNIFTI()
% Much of this function relies on SPM
[f, p] = uigetfile({'*.nii;*.nii.gz','NIFTI'}, 'Select image file...', handles.defaultPath);
if(isnumeric(f))
    disp('User canceled.');
    return;
end

spm_defaults; global defaults;
defaults.analyze.flip = 0;
ni = niftiRead(fullfile(p,f));
% We assume that the NIFTI/Analyze xform brings us to ac-pc space.
% Perhaps call mrAnatSetNiftiXform to let the user set this manually?
xform = ni.qto_xyz;
mmPerVox = ni.pixdim;
if(any(abs(xform(1:3,4)')<10))
    % try to fix ill-formed xforms (or at least make them sane)
    imgOrigin = (size(ni.data)+1)./2;
    xform = [[diag(mmPerVox), [imgOrigin.*-mmPerVox]']; [0 0 0 1]];
end
img = double(ni.data);
% *** We should prompt the user for some parameters here, like default clip
% values, type of registration, etc.
img = mrAnatHistogramClip(img,0.4,0.99);
VF.uint8 = uint8(round(img.*255));
%origin = (size(img)+1)./2;VF.mat = [[diag(ip.mmPerVox), [ip.origin.*-ip.mmPerVox]']; [0 0 0 1]];
VF.mat = xform;

% Retrieve key anatomical parameters
curBgImg   = dtiGet(handles,'bg image',n);
curBgXform = dtiGet(handles,'bg img2acpc xform',n);
% curBgMm    = dtiGet(handles,'bg mmpervox',n);
% curBgName  = dtiGet(handles,'bg name',n);
% [curBgImg, curBgMm, curBgXform, curBgName] = dtiGetCurAnat(handles);
VG.uint8 = uint8(round(curBgImg.*255));
VG.mat = curBgXform;
rotTrans = spm_coreg(VF,VG);

% This composite xform will convert the image voxel space to image
% physical (VF.mat) and then image physical to curBg physical (the
% rigid-body rotTrans that we just computed). Since the curBg physical
% space is ac-pc space, that is where we want to be.
xform = spm_matrix(rotTrans(:)')*VF.mat;
%VF.mat = xform; dtiShowAlignFigure(figure,VF,VG);

% Go back to the unclipped data (clipping is done just for alignment)
img = double(ni.data);
resp = questdlg('Save new transform in NIFTI file or resample?','Confirm','Save transform','Apply transform','Neither (just load image)','Save transform');
if(strcmpi(resp,'Save transform'))
    ni.qform_code = 2;
    ni.qto_xyz = xform;
    %ni.sto_xyz = zeros(4,4);
    %ni.sto_ijk = zeros(4,4);
    writeFileNifti(ni);
elseif(strcmpi(resp,'Apply transform'))
    newMmPerVox = [1 1 1];
    prompt = sprintf('New mmPerVoxel (current = [%0.1f %0.1f %0.1f]):',mmPerVox);
    ans = inputdlg(prompt,'Resample mmPerVox',1,{num2str(newMmPerVox)});
    if(~isempty(ans))
        newMmPerVox = str2num(ans{1});
        [img,xform] = mrAnatResliceSpm(img,inv(xform),dtiGet(handles,'defaultBB'),newMmPerVox);
        mmPerVox = newMmPerVox;
        [f2, p2] = uiputfile('*.nii.gz','Save resampled image...', fullfile(p,'reampled.nii.gz'));
        if(~isnumeric(f2))
            dtiWriteNiftiWrapper(single(img), xform, fullfile(p2,f2));
        end
    end
end
handles = dtiAddBackgroundImage(handles, img, f, mmPerVox, xform, [], 0, '');
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Add Normalized map
function menuFile_addNormalizedMap_Callback(hObject, eventdata, handles)
% A comment would be nice
[handles, mapData, mapName, mmPerVox, xform, labels] = dtiLoadNormalizedMap(handles);
if(~isempty(mapData))
    handles = dtiAddBackgroundImage(handles, mapData, mapName, mmPerVox, xform, [], 0, '');
    handles = dtiRefreshFigure(handles);
    guidata(hObject, handles);
end
return;

%%  File | Remove current image
function menuFile_removeCurImage_Callback(hObject, eventdata, handles)
% Eliminates the data in the current background image

bn = questdlg('Are you sure?','Confirm removal','Yes','No','Yes');
if(strcmp(bn,'No')), return; end

handles = dtiRemoveBackground(handles);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);

return;

%% File | Compute new map
function menuFile_computeNewMap_Callback(hObject, eventdata, handles)
return;

%% File | Compute new maps | Tensor shapes
function menuFile_computeTensorShapes_Callback(hObject, eventdata, handles)
[cl, cp, cs] = dtiComputeWestinShapes(handles.dt6);
handles = dtiAddBackgroundImage(handles, cp, 'Planarity', handles.mmPerVoxel, handles.xformToAcpc, [0 1]);
handles = dtiAddBackgroundImage(handles, cs, 'Sphericity', handles.mmPerVoxel, handles.xformToAcpc, [0 1]);
[handles,bgNum] = dtiAddBackgroundImage(handles, cl, 'Linearity', handles.mmPerVoxel, handles.xformToAcpc, [0 1]);
handles = dtiSet(handles,'curBackgroundNum',bgNum);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Compute new map | Mean diffusivity
function menuFile_computeMeanDiffusivity_Callback(hObject, eventdata, handles)
%[eigVec, eigVal] = dtiSplitTensor(handles.dt6);
%clear eigVec;
%img = sum(eigVal,4)./3;
% More efficient to just sum the diagonal elements to compute trace:
img = sum(handles.dt6(:,:,:,1:3), 4)./3;
rng = [0 max(img(:))];
[handles,bgNum] = dtiAddBackgroundImage(handles, img, 'mean diffusivity', handles.mmPerVoxel, handles.xformToAcpc, rng, 0, handles.adcUnits);
handles = dtiSet(handles,'curBackgroundNum',bgNum);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Compute new map | Fractional Anisotropy
function menuFile_computeFA_Callback(hObject, eventdata, handles)
img = dtiComputeFA(handles.dt6);
img(img<0) = 0; img(img>1) = 1;
rng = [0 1];
[handles,bgNum] = dtiAddBackgroundImage(handles, img, 'FA', handles.mmPerVoxel, handles.xformToAcpc, rng, 0, 'ratio');
handles = dtiSet(handles,'curBackgroundNum',bgNum);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Compute new map | Axial and Radial diffusivity
function menuFile_computeAxialRadialDiffusivity_Callback(hObject, eventdata, handles)
[eigVec, eigVal] = dtiSplitTensor(handles.dt6);
clear eigVec;
ltz = find(eigVal<0);
if(~isempty(ltz))
    warning(sprintf('%d negative eigenvalues! Fixing them to zero.',sum(ltz(:))));
    eigVal(ltz) = 0;
end
ad = eigVal(:,:,:,1);
rd = sum(eigVal(:,:,:,2:3),4)./2;
handles = dtiAddBackgroundImage(handles, ad, 'Axial Diffusivity', handles.mmPerVoxel, handles.xformToAcpc, [], 0, handles.adcUnits);
[handles,bgNum] = dtiAddBackgroundImage(handles, rd, 'Radial Diffusivity', handles.mmPerVoxel, handles.xformToAcpc, [], 0, handles.adcUnits);
handles = dtiSet(handles,'curBackgroundNum',bgNum);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% File | Compute new map | White matter probability
function menuFile_computeWmProb_Callback(hObject, eventdata, handles)
b0 = handles.bg(1).img*handles.bg(1).maxVal + handles.bg(1).minVal;
wmProb = dtiFindWhiteMatter(handles.dt6,b0,handles.xformToAcpc,true);
[handles,bgNum] = dtiAddBackgroundImage(handles, wmProb, 'White Matter Prob', handles.mmPerVoxel, handles.xformToAcpc);
handles = dtiSet(handles,'curBackgroundNum',bgNum);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% Main ROI callback should be moved here
% Not sure where it is


%% File | ROIs | Save current ROI
function menuFileSaveCurrentROI_Callback(hObject, eventdata, handles)
% File -> Save Current ROI
dtiRoiSave(handles, 'current');
return;

%% File | ROIs | Save ROI
function menuFile_saveROI_Callback(hObject, eventdata, handles)
% File -> Save ROIs ...  (Some)
dtiRoiSave(handles, 'selected');
return;

%% File | ROIs | Save All ROIs
function menuSaveAllROIs_Callback(hObject, eventdata, handles)
dtiRoiSave(handles, 'all');
return;

%% File | ROIs | Export normalized ROI
function menuFile_saveNormRoi_Callback(hObject, eventdata, handles)
handles = dtiRoiSave(handles, 'current', 'normalized');
guidata(hObject, handles);
return;

%-------------------------------------------
function menuFile_LoadROI_Callback(hObject, eventdata, handles)
% File -> Load ROI
dtiLoadROI(hObject,handles);
return;

%% File | ROIs | Load ROIs from NIFTI
function menuFile_LoadROIsfromNifti_Callback(hObject, eventdata, handles)
dtiLoadROIsfromNifti(hObject,handles);
return;

%% File | ROIs | Load ROIs from MNI Nifti
function menuFile_LoadROIsfromMniNifti_Callback(hObject, eventdata, handles)
dtiLoadROIsfromMniNifti(hObject,handles);
return;

% --------------------------------------------------------------------
function menuFile_LoadManyROIs_Callback(hObject, eventdata, handles)
dtiLoadManyROIs(hObject,handles);
return;

%% Fiber call backs from FILE menu
% Find the create function and put it here

%% File | fibers | Save Current Fibers
function menuFileSaveCurrentFibers_Callback(hObject, eventdata, handles)
% File -> Save Current Fibers
dtiFiberSave(handles, 'current');
return;


%% File | fibers | Save All Fibers
function menuFileSaveAllFibers_Callback(hObject, eventdata, handles)
dtiFiberSave(handles, 'all');
return;

%% File | fibers | Save fibers ...
function menuFile_SaveFibers_Callback(hObject, eventdata, handles)
% File->Save Fibers ... (selected)
dtiFiberSave(handles, 'selected');
return;

%% File | fibers | Load Fibers ...
function menuFile_LoadFibers_Callback(hObject, eventdata, handles)
dtiLoadFibers(hObject,handles);
return;


%% File | fibers | Load many fibers
function menuFile_LoadManyFibers_Callback(hObject, eventdata, handles)
dtiLoadManyFiberGroups(hObject,handles);
return;

%% File | fibers | Export Normalized fibers
function menuFile_saveNormFibers_Callback(hObject, eventdata, handles)
dtiFiberSave(handles, 'current', 'normalized');
return;

%% File | fibers | Export Fibers as BV (Tal)
function menuFile_SaveBvTal_Callback(hObject, eventdata, handles)
disp('Saving fibers in Talairach coordinates for Brain Voyager...');
filename = dtiWriteBrainVoyagerFibers(handles.fiberGroups, '', 'TAL');
fprintf('Fibers saved in %s',filename);
return;

%% File | fibers | Import
function menuFibers_Import_Callback(hObject, eventdata, handles)
handles = dtiImportFibers(handles,handles.defaultPath,handles.xformToAcpc);
guidata(hObject, handles);
return;

%% File | filbers | Export current fibers
function menuFibers_Export_Current_Callback(hObject, eventdata, handles)
% Anyone want to guess what it exports to?  Must be a Sherbondy around
% here.  And a pdb format.
dtiExportFibers(handles, 'current');
return;

%% File | Save Inplane Images
function menuFileSaveInplaneImages_Callback(hObject, eventdata, handles)
%Saves Anat + ROI + Fibers.  The View menu contains more options
menuViewSSFibersROI_Callback(hObject, eventdata, handles);
return;

%% File | Save Mesh
function menuFileSaveMesh_Callback(hObject, eventdata, handles)
dtiMrMeshSave(handles)
return;

%% File | Print mrMesh
function menuFilePrintMrMesh_Callback(hObject, eventdata, handles)
global printedMesh
printedMesh = handles.mrMesh;

if checkfields(handles,'mrMesh')
    fprintf('Mesh structure used by mrMesh\n-------------------\n');
    printedMesh
else
    fprintf('mrMesh data structure not created yet.');
end

return;

%% File | Quit
function menuFile_Quit_Callback(hObject, eventdata, handles)
% *** SHOULD CHECK FOR UNSAVED STUFF!
try
    close(handles.fig3d);
catch
end
close(handles.fig);
% Should we close mrMesh, too?  Nah.
return;



%% MENU: VIEW
% This used to be called menuEdit.  Most routines in this menu have an old
% legacy name.
function menuView_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuViewROIandFGList_Callback(hObject, eventdata, handles)
% Move into a popup window
nROIs = length(handles.rois);
fprintf('\n-----------ROIs---------------\n');
for ii=1:nROIs, fprintf('%.0f\t%s\n',ii,handles.rois(ii).name); end
fprintf('\n\n-----------FGs---------------\n');
nFGs = length(handles.fiberGroups);
for ii=1:nFGs, fprintf('%.0f\t%s\n',ii,handles.fiberGroups(ii).name); end
return;

% --------------------------------------------------------------------
function menuViewScreenShots_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuViewSSCurrent_Callback(hObject, eventdata, handles)
%  Write out the mrMesh current screen shot.
dtiMrMeshScreenShot(handles,[]);
return;

% --------------------------------------------------------------------
function menuViewSSInplane_Callback(hObject, eventdata, handles)
% Inplane file writes
return;

% --------------------------------------------------------------------
function menuViewSSAnatomy_Callback(hObject, eventdata, handles)
dtiSaveImageSlicesOverlays(handles,[],[]);
return;

% --------------------------------------------------------------------
function menuViewSSROI_Callback(hObject, eventdata, handles)
showTheseROIs = dtiROIShowList(handles);
dtiSaveImageSlicesOverlays(handles, [], handles.rois(showTheseROIs));
return;

% --------------------------------------------------------------------
function menuViewSSFibers_Callback(hObject, eventdata, handles)
showTheseFgs = dtiFGShowList(handles);
dtiSaveImageSlicesOverlays(handles, handles.fiberGroups(showTheseFgs), []);
return;


% --------------------------------------------------------------------
function menuViewSSFibersROI_Callback(hObject, eventdata, handles)
showTheseROIs = dtiROIShowList(handles);
showTheseFgs = dtiFGShowList(handles);
dtiSaveImageSlicesOverlays(handles, handles.fiberGroups(showTheseFgs), handles.rois(showTheseROIs));
return;

% --------------------------------------------------------------------
function menuView_sliceMontage_Callback(hObject, eventdata, handles)
% Too long and weird.  Fix it.

persistent resp;
if(isempty(resp))
    resp{1} = 'axial';
    resp{2} = '[-35:5:60]';
    resp{3} = '0';
    resp{4} = 'true';
    resp{5} = '';
    resp{6} = '0';
    resp{7} = '[]';
end
resp = inputdlg({'Plane (axial,coronal,sagittal):','Slice numbers (ac-pc coords):','Upsample factor:','Slice labels:','Num Columns:','Cluster threshold:','Overlay FGs:'},...
    'Select montage slices',1,resp);
if(isempty(resp)) disp('User canceled.'); return; end
if(isempty(resp{1})) plane = 'a';
else plane = strmatch(lower(resp{1}(1)),{'s','c','a'}); end
acpcSlices = str2num(resp{2});
upsamp = str2double(resp{3});
labelSlices = strcmpi(resp{4},'true')|strcmpi(resp{4},'yes');
if(isempty(resp{5})) numCols = [];
else numCols = str2double(resp{5}); end
clusterThresh = str2double(resp{6});
overlayFGs = str2num(resp{7});

overlayThresh = dtiGet(handles, 'curOverlayThresh');
overlayAlpha = dtiGet(handles, 'curOverlayAlpha');
anatNum = dtiGet(handles,'curbgnum');

if(isempty(overlayFGs))
    % Use the current GUI overlay
    overlayNum = dtiGet(handles,'curoverlaynum');
    overlay = handles.bg(overlayNum);
    % put image and threshold back into real image units
    overlayImg = overlay.img .* (overlay.maxVal-overlay.minVal) + overlay.minVal;
    overlayThresh = overlayThresh .* (overlay.maxVal-overlay.minVal) + overlay.minVal;
    if(size(overlayImg,4)==3)
        cmap = [];
    else
        cmap = dtiGet(handles,'curOverlayCmap');
    end
    clipRange = [overlayThresh overlay.maxVal];
    overlayXform = handles.bg(overlayNum).mat;
else
    % Generate an overlay from the FGs
    cmap = [];
    clipRange = [0 1];
    overlayAlpha = 1;
    overlayXform = handles.bg(anatNum).mat;
    sz = size(handles.bg(anatNum).img);
    overlayImg = zeros([sz(1:3) 3]);
    for(ii=overlayFGs)
        coords = round(mrAnatXformCoords(inv(overlayXform), horzcat(handles.fiberGroups(ii).fibers{:})));
        coords = sub2ind(sz(1:3),coords(:,1),coords(:,2),coords(:,3));
        for(jj=1:3)
            tmp = overlayImg(:,:,:,jj);
            tmp(coords) = handles.fiberGroups(ii).colorRgb(jj)/255;
            overlayImg(:,:,:,jj) = tmp;
        end
    end
end
mrAnatOverlayMontage(overlayImg, overlayXform, ...
    handles.bg(anatNum).img, handles.bg(anatNum).mat, cmap, clipRange, ...
    acpcSlices,[],plane,overlayAlpha,labelSlices,upsamp,numCols,clusterThresh);
return;


% --------------------------------------------------------------------
%  3D SURFACE SUBMENU
% --------------------------------------------------------------------
function menuView_3dSurfaces_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuViewOpen3dSurfaceWindow_Callback(hObject, eventdata, handles)
[f, p] = uigetfile({'*.mat','Mesh file (*.mat)'}, 'Select mrVista mesh file...', handles.defaultPath);
if(isnumeric(f))
    error('Open mrVista mesh canceled.');
end
msh = mrmReadMeshFile(fullfile(p,f));
% remove extension
[junk,mshName] = fileparts(f);
mshName = [handles.subName(1:findstr(handles.subName,'_')-1) '-' mshName];
% We want to be able to run without a mrVista view. Should we fake the
% following? Or is it OK to leave the msh struct with no mapping?
% vertexGrayMap = mrmMapVerticesToGray(meshGet(msh,'initialvertices'), viewGet(view,'nodes'), viewGet(view,'mmPerVox'));
% msh = meshSet(msh,'vertexgraymap',vertexGrayMap);
if(~isfield(msh, 'fibers'))
    msh = meshSet(msh,'fibers',[]);
end
if(~isfield(handles, 'mrVistaMesh') || isempty(handles.mrVistaMesh) || isempty(handles.mrVistaMesh.meshes))
    idList = [];
    handles.mrVistaMesh.meshes = msh;
    handles.mrVistaMesh.curMesh = 1;
else
    idList = [handles.mrVistaMesh.meshes(:).id];
    handles.mrVistaMesh.curMesh = length(handles.mrVistaMesh.meshes)+1;
end
if meshGet(msh,'windowid') < 0,
    if isempty(idList), id = 100; else id = max(idList)+1; end
    % We could reuse numbers.
    msh = meshSet(msh,'windowid',id);
    msh = mrmInitMesh(msh);
else
    mrmSet(msh,'refresh');
end
mrmSet(msh,'windowTitle',[num2str(msh.id) ': ' mshName]);
handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = msh;
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_select3dSurf_Callback(hObject, eventdata, handles)
% 
if(~isfield(handles, 'mrVistaMesh') || isempty(handles.mrVistaMesh) || ...
        isempty(handles.mrVistaMesh.meshes))
    error('No meshes.');
end

newMeshNum = menu('Select a mesh:',{handles.mrVistaMesh.meshes(:).id});
if(newMeshNum>0)
    handles.mrVistaMesh.curMesh = newMeshNum;
else
    disp('Select mesh cancelled.');
end
id = meshGet(handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh), 'windowid');
disp(['Current mesh window id: ' num2str(id)]);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_deleteCur3dSurf_Callback(hObject, eventdata, handles)
if(~isfield(handles, 'mrVistaMesh') || isempty(handles.mrVistaMesh) || isempty(handles.mrVistaMesh.meshes))
    error('No current mesh.');
end
msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
% Close the associated window
if meshGet(msh,'windowID') >= 0
    msh = mrmSet(msh,'close');
end
handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = [];
% Set cur mesh to 1 less than the one we deleted, but not less than 1.
handles.mrVistaMesh.curMesh = max(1,handles.mrVistaMesh.curMesh-1);
if(isempty(handles.mrVistaMesh.meshes))
    handles.mrVistaMesh.curMesh = 0;
end
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_set3dSurfTransparency_Callback(hObject, eventdata, handles)
if(isfield(handles, 'mrVistaMesh') && ~isempty(handles.mrVistaMesh) && ~isempty(handles.mrVistaMesh.meshes))
    msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
    mrv = 0;
else
    volView = getSelectedVolume;
    if(~isempty(volView))
        msh = viewGet(volView,'mesh');
        mrv = 1;
    else
        error('No current mesh.');
    end
end
trans = double(msh.data.colors(4,1))./255;
trans = round(trans*100)./100;
resp = inputdlg('Transparency (0=transparent, 1=opaque):','Set Surface Transparency', 1, {num2str(trans)});
if(isempty(resp)) error('user canceled.'); end
trans = str2double(resp);
trans = max(trans,0); trans = min(trans,1);
msh = mrmSet(msh, 'alpha', trans);
msh = mrmSet(msh, 'transparency', trans~=1);
if(mrv)
    volView = viewSet(volView,'mesh',msh);
    mrGlobals;
    eval([volView.name '=volView;']);
else
    handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = msh;
end
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_overlay3dColormap_Callback(hObject, eventdata, handles)
%
% This routine needs to come out of here

msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
overlayThresh = get(handles.slider_overlayThresh, 'Value');

% Retrieve key anatomical parameters
n          = dtiGet(handles,'bg num');
img       = dtiGet(handles,'bg image',n);
% mm = dtiGet(handles,'bg mmpervox',n);
xform      = dtiGet(handles,'bg img2acpc xform',n);
valRange   = dtiGet(handles,'bg range',n);
name       = dtiGet(handles,'bg name',n);
% dispRange  = dtiGet(handles,'display range',n);
% unitStr    = dtiGet(handles,'unit string',n);
% [img, mm, xform, name, valRange, dispRange, unitStr] = dtiGetCurAnat(handles,true);

overlayRange = [overlayThresh.*diff(valRange)+valRange(1), valRange(2)];
overlayAlpha = str2double(get(handles.editOverlayAlpha, 'String'));
distThresh = 3;
keepCurOverlay = 0;
prompt = {'Distance threshold (mm):',...
    sprintf('%s threshold (%d - %d):',name,valRange(1),valRange(2)),...
    'Overlay transparency (0-1):','Merge with current overlay (0|1):'};
defAns = {num2str(distThresh),num2str(overlayRange),num2str(overlayAlpha),num2str(keepCurOverlay)};
resp = inputdlg(prompt, '3d Surface Overlay Parameters', 1, defAns);
if(isempty(resp)) disp('user canceled.'); return; end
distThresh = str2double(resp{1});
overlayRange = str2num(resp{2});
overlayAlpha = str2double(resp{3});
keepCurOverlay = str2double(resp{4})==1;

overlayRange = (overlayRange-valRange(1))./diff(valRange);

gd = dtiGet(handles, 'curAcpcGrid', true);
curImgCoords = [gd.X(:) gd.Y(:) gd.Z(:)];
clear gd;
% We need to get the T1-space image coords from the current anatomy image.
% OK-the following needs some explaining. mrMesh vertices are essentially
% mrVista vAnat coords scaled to isotropic voxels, with X and Y swapped
% (why not?). Reading from right-to-left (since it's a pre-multiply xform),
% inv(handles.xformVAnatToAcpc) converts mrDiffusion ac-pc coords to vAnat coords
% The diag([msh.mmPerVox([2,1,3]) 1]) thing
% removes the vAnat scale factor. And finally, we need to do an x-y swap.
swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
acpc2vertex = swapXY*diag([msh.mmPerVox([2,1,3]) 1])*inv(handles.xformVAnatToAcpc);
t1ImgCoords = mrAnatXformCoords(acpc2vertex, curImgCoords);
% t1ImgCoords essentially maps the current image (the indices into imgCoords)
% to the T1 image space (the values in imgCoords). We need to do this
% because the mesh vertices are in T1 space.
%
% Remove the below-threshold values.
goodVal = img>=overlayRange(1);
t1ImgCoords = t1ImgCoords(goodVal,:)';
%t1ImgCoords = t1ImgCoords([2,3,1],:);
% Do the same to the current img coords, but they also need to be converted
% from acpc space to the native image space.
curImgCoords = mrAnatXformCoords(inv(xform), curImgCoords(goodVal,:));
% Now do the mapping:
[v2iMap, sqDist] = nearpoints(msh.initVertices+1, t1ImgCoords);
vertInds = sqDist <= distThresh^2;
imgInds = sub2ind(size(img), curImgCoords(v2iMap,1), curImgCoords(v2iMap,2), curImgCoords(v2iMap,3));

% Keep the old colors (which should be the sulcal pattern).
if(keepCurOverlay)
    oldColors = mrmGet(msh,'colors');
else
    oldColors = meshGet(msh,'colors');
end

% Convert image values to colormap values.
img(img>overlayRange(2)) = overlayRange(2);
img = round(img./overlayRange(2).*255)+1;
%cmap = [linspace(192,255,256)', linspace(0,255,256)', repmat(0,256,1)];
%cmap([0:round(cmapThresh*255)]+1,:) = NaN;
cmap = handles.cmaps(get(handles.popupOverlayCmap,'Value')).rgb;
cmap = cmap.*255;
newColors = repmat(NaN, size(oldColors(1:3,:)));
newColors(:,vertInds) = cmap(img(imgInds(vertInds)),:)';
% Mask out vertices who don't have an above-threshold value within
% threshDist are below threshold (they are marked with NaNs).
dataMask = ~isnan(newColors(1,:));
if(overlayAlpha<1)
    newColors(:,dataMask) = overlayAlpha*newColors(:,dataMask) ...
        + (1-overlayAlpha)*double(oldColors(1:3,dataMask));
end
newColors(:,~dataMask) = oldColors(1:3,~dataMask);
newColors(newColors>255) = 255;
newColors(newColors<0) = 0;
mrmSet(msh,'colors',uint8(round(newColors')));
return;

% --------------------------------------------------------------------
function menuView_build3dSurfaceFromImage_Callback(hObject, eventdata, handles)

% Get anatomical parameters from current background
n          = dtiGet(handles,'bg num');
anat       = dtiGet(handles,'bg image',n);
mmPerVoxel = dtiGet(handles,'bg mmpervox',n);
xform      = dtiGet(handles,'bg img2acpc xform',n);
name       = dtiGet(handles,'bg name',n);
valRange   = dtiGet(handles,'bg range',n);
% [anat, mmPerVoxel, xform, name, valRange] = dtiGetCurAnat(handles);

meshName = [name ' Surface'];
thresh = 0.5*valRange(2);
smoothKernel = 3;
alpha = 200;
relaxIterations = 0.6;
prompt = {'Mesh Name:',...
    'Threshold:',...
    'Image smooth kernel (0-10):',...
    'Default alpha (0-255):',...
    'Inflation (0=none, 1=lots):'};
defAns = {meshName,...
    num2str(thresh),...
    num2str(smoothKernel),...
    num2str(alpha),...
    num2str(relaxIterations)};
resp = inputdlg(prompt, '3d Surface Parameters', 1, defAns);
if(isempty(resp)) disp('user canceled.'); return; end
meshName = resp{1};
thresh = str2num(resp{2});
smoothKernel = str2num(resp{3});
alpha = str2num(resp{4});
relaxIterations = round(str2num(resp{5})*160);  % Arbitrary choice, scales iters [0,160]
disp('Cleaning image mask...');
voxels = dtiCleanImageMask(anat>(thresh-valRange(1))/(valRange(2)-valRange(1)), smoothKernel);
disp('Building mesh...');
[msh, lights, tenseMesh] = ...
    mrmBuildMesh(uint8(voxels), mmPerVoxel, 'localhost', -1, ...
    'RelaxIterations', relaxIterations, ...
    'MeshName',meshName, ...
    'QueryFlag',1,...
    'SaveTenseMesh');

msh = meshSet(msh,'name',meshName);
msh = meshSet(msh,'nGrayLayers',0);
msh = meshSet(msh,'lights',lights);
msh = meshSet(msh,'fibers', []);
msh = meshSet(msh,'unsmoothedvertices',tenseMesh.data.vertices);
clear tenseMesh voxels anat;

% vertexGrayMap = mrmMapVerticesToGray(meshGet(msh,'initialvertices'), viewGet(view,'nodes'), viewGet(view,'mmPerVox'));
% msh = meshSet(msh,'vertexgraymap',vertexGrayMap);
if(~isfield(handles, 'mrVistaMesh') || isempty(handles.mrVistaMesh) || isempty(handles.mrVistaMesh.meshes))
    idList = [];
    handles.mrVistaMesh.meshes = msh;
    handles.mrVistaMesh.curMesh = 1;
else
    idList = [handles.mrVistaMesh.meshes(:).id];
    handles.mrVistaMesh.curMesh = length(handles.mrVistaMesh.meshes)+1;
end

if meshGet(msh,'windowid') < 0,
    if isempty(idList), id = 100; else id = max(idList)+1; end
    % We could reuse numbers.
    msh = meshSet(msh,'windowid',id);
    msh = mrmInitMesh(msh);
else
    mrmSet(msh,'refresh');
end
mrmSet(msh,'windowTitle',[num2str(msh.id) ': ' meshName]);
handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = msh;
% Subsequent code assumes an X/Y swap, so we'll comply.
% XXX TONY below two lines are a hack to get fibers to line up with mesh
handles.xformVAnatToAcpc=[0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
handles.xformVAnatToAcpc(:,4) = xform(:,4);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_3dGetMrMeshRoi_Callback(hObject, eventdata, handles)
msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
mrmRoi = mrmGet(msh,'curRoi');
if(~isfield(mrmRoi,'vertices')) error('No ROI in current surface!'); end
swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
vertex2acpc = handles.xformVAnatToAcpc*swapXY*diag([1./msh.mmPerVox([2,1,3]) 1]);
coords = mrAnatXformCoords(vertex2acpc, msh.initVertices(:,mrmRoi.vertices));
coords = unique(round(coords),'rows');
roi = dtiNewRoi('surf ROI',[],coords);
handles = dtiAddROI(roi,handles);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuView_3dSaveScreenShot_Callback(hObject, eventdata, handles)
persistent pathname;
if isempty(pathname) | isnumeric(pathname), pathname = pwd; end
[filename, p] = uiputfile(fullfile(pathname,'*.png'), 'Pick a file name.');
if(isnumeric(filename)), return; end
pathname = p;
fname = fullfile(pathname,filename);
[p,n,e] = fileparts(fname);
if ~strcmp(e,'.png'), e = '.png'; end
fname = fullfile(p,[n,e]);
rgb = mrmGet(handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh),'screenshot');
imwrite(uint8(rgb), fname);
disp(['Screenshot saved to ' fname '.']);
return;

% --------------------------------------------------------------------
function menu_InterpTypeMenu_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuInterpNearest_Callback(hObject, eventdata, handles)
guidata(hObject, setInterpType(handles,'n'));
return;

% --------------------------------------------------------------------
function menuInterpLinear_Callback(hObject, eventdata, handles)
guidata(hObject, setInterpType(handles,'l'));
return;

% --------------------------------------------------------------------
function menuInterpCubic_Callback(hObject, eventdata, handles)
guidata(hObject, setInterpType(handles,'c'));
return;

% --------------------------------------------------------------------
function menuInterpSpline_Callback(hObject, eventdata, handles)
guidata(hObject, setInterpType(handles,'s'));
return;

function handles = setInterpType(handles, newType)
if(newType=='n') val{1} = 'on'; else val{1} = 'off'; end
if(newType=='l') val{2} = 'on'; else val{2} = 'off'; end
if(newType=='c') val{3} = 'on'; else val{3} = 'off'; end
if(newType=='s') val{4} = 'on'; else val{4} = 'off'; end
set(handles.menuInterpNearest,'checked',val{1});
set(handles.menuInterpLinear,'checked',val{2});
set(handles.menuInterpCubic,'checked',val{3});
set(handles.menuInterpSpline,'checked',val{4});
handles.interpType = newType;
handles = dtiRefreshFigure(handles,0);
return;



%-------------------------------------------
% MENU:  ANALYXE 
%-------------------------------------------
function menuAnalyze_Callback(hObject, eventdata, handles)
return;

%% Analyze | Fibers
function menuAnalyzeFibers_Callback(hObject, eventdata, handles)
return;

%% Analyze | Fibers | Summary
function menuAnalyzeFiberSummary_Callback(hObject, eventdata, handles)
txt = dtiFiberSummary(handles);
disp(txt)
return;

%% Analyze | Fibers | Diffusion properties along the trajectory
function menuComputeDiffusionPropertiesAlongFG_Callback(hObject, eventdata, handles)
% Pull this out of here into a separate function.

sList = dtiSelectROIs(handles);

if ~isempty(sList)
    roiArray=handles.rois(sList);
else
    disp('Load ROIs ... canceled.');
    return;
end
if length(roiArray)~=2
    disp('Need to choose 2 ROIs ... canceled');
    return;
end

prompt = {'Number of steps along the trajectory'};
def = {num2str(30)};
numberOfNodes = inputdlg(prompt, 'Number of steps', 1, def);
if(isempty(numberOfNodes))
    return;
else numberOfNodes=str2num(numberOfNodes{1});
end
fg = dtiGet(handles, 'currentFg');
[fa, md, rd, ad, cl, SuperFibersGroup, fgClipped, cp, cs]=dtiComputeDiffusionPropertiesAlongFG(fg, handles, roiArray(1), roiArray(2), numberOfNodes);
fgClipped.name=[fg.name '_clippedTo_' roiArray(1).name '_' roiArray(2).name];
SuperFiberCore=dtiNewFiberGroup([fgClipped.name '_core'], [], 2);
SuperFiberCore.fibers=SuperFibersGroup.fibers;

for nodeI=1:numberOfNodes
    [determinant, varcovmatrix] =detLowTriMxVectorized(SuperFibersGroup.fibervarcovs{1}(:, nodeI));
    genvar(nodeI)=sqrt(trace(diag(eig(varcovmatrix)))./3);
    
end
fprintf(1, 'Generalized variance (volume) across %d nodes \n %6.2f \n', numberOfNodes, genvar');

handles = dtiAddFG(SuperFiberCore, handles);
handles = dtiAddFG(fgClipped, handles);

properties={'fa', 'md','rd',  'ad','cl'};
for pID=1:length(properties)
    propertyofinterest=properties{pID};
    dtiVisualizeSuperFibersGroup(SuperFibersGroup, eval(propertyofinterest), [propertyofinterest '--weighted average']);
end

guidata(hObject, handles);

return;


%% Analyze | ROI
function menuAnalyzeROI_Callback(hObject, eventdata, handles)
return;

%% Analyze | ROI | Spatial Interpolation method
function menuAnalyzeROIInterptype(hObject, eventdata,handles)
disp('We should set the interp type here.  Figure out options')
return

%% Analyze | ROI | Stats
function menuAnalyze_showRoiStats_Callback(hObject, eventdata, handles)
%
if(isempty(handles.rois)), disp('No ROIs.'); return; end
[statsStruct, statsStr] = dtiGetRoiStats(handles, handles.curRoi, false);
fprintf(statsStr);
handles.roiStats = statsStruct;
guidata(hObject, handles);
return;

%% Analyze | ROI | ROI Stats (verbose)
function menuAnalyze_showRoiTensorStats_Callback(hObject, eventdata, handles)
[statsStruct, statsStr] = dtiGetRoiStats(handles, handles.curRoi, true);
fprintf(statsStr);
handles.roiStats = statsStruct;
guidata(hObject, handles);
return;

%% Analyze | Fibers | Compute fiber density
function menuAnalyze_computeDensity_Callback(hObject, eventdata, handles)
handles = dtiComputeFiberDensity(handles, [], false, false);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return

%% Analyze | Fibers | Compute fiber endpoint density
function menuAnalyze_computeEndptDensity_Callback(hObject, eventdata, handles)
handles = dtiComputeFiberDensity(handles, [], true);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return

%% Analyze | Fibers | Compute fiber group count 
function menuAnalyze_computeFgCount_Callback(hObject, eventdata, handles)
handles = dtiComputeFiberDensity(handles, [], false, true);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;


%% Analyze | Current position | Summary
function menuAnalyze_CurPos_Callback(hObject, eventdata, handles)
[statsStruct, statsStr] = dtiGetRoiStats(handles, 0, true);
fprintf(statsStr);
handles.roiStats = statsStruct;
guidata(hObject, handles);
return;

%% Analyze | Segment tissue...
function menuAnalyze_segmentTissue_Callback(hObject, eventdata, handles)
spmDir = fileparts(which('spm_segment'));
d = dir(fullfile(spmDir, 'templates', 'T1.*'));
t1Template = fullfile(spmDir,'templates',d(1).name);
[t1, mmPerVoxel, xform] = dtiGetNamedImage(handles.bg, 't1');
disp('Segmenting T1 image using SPM segmentation routine...');
[t1Wm,t1Gm,t1Csf] = mrAnatSpmSegment(t1, xform, t1Template);
handles = dtiAddBackgroundImage(handles, double(t1Wm)./255, 'White Matter', mmPerVoxel, xform);
handles = dtiAddBackgroundImage(handles, double(t1Gm)./255, 'Gray Matter', mmPerVoxel, xform);
handles = dtiAddBackgroundImage(handles, double(t1Csf)./255, 'CSF', mmPerVoxel, xform);
handles = dtiRefreshFigure(handles);
guidata(hObject, handles);
return;

%% Analyze | Adjust DTI alignment
function menuAnalyze_adjustDtiAlign_Callback(hObject, eventdata, handles)
% *** TODO: Fix this! It currently only adjusts the global 'xformToAcPc',
% but it needs to also adjust the xform in all relevent background images.

warning('Callback needs to be improved')

x = handles.xformToAcpc;
newX = x;
oldX = x;
done = false;
cancel = false;
while(~done && ~cancel)
    [t,r,s,k] = affineDecompose(newX);
    resp = inputdlg({'Translation (mm):','Rotation (rad):','Scale (mm):','Skew (rad):'},...
        'Modify DTI-to-AcPc alignment...',1,...
        {num2str(t), num2str(r), num2str(s), num2str(k)});
    if(isempty(resp))
        disp('User canceled- resetting values.');
        cancel = true;
    else
        t = str2num(resp{1});
        r = str2num(resp{2});
        s = str2num(resp{3});
        k = str2num(resp{4});
        if(length(t)~=3 || length(r)~=3 || length(s)~=3 || length(k)~=3)
            disp('Invalid transform matrix.');
        else
            t = str2num(resp{1});
            r = str2num(resp{2});
            s = str2num(resp{3});
            k = str2num(resp{4});
            
            newX = affineBuild(t,r,s,k);
            % Keep it clean- we can't use more precision than this anyway
            newX = round(newX*100)/100;
            handles.xformToAcpc = newX;
            for(ii=1:length(handles.bg))
                if(all(handles.bg(ii).mat(:)==x(:))), handles.bg(ii).mat = newX; end
            end
            guidata(hObject, handles);
            handles = dtiRefreshFigure(handles, 0);
            pause(0.1);
        end
        if(all(newX==oldX)) done = true; end
        oldX = newX;
    end
end
if(cancel)
    handles.xformToAcpc = x;
    for(ii=1:length(h.bg))
        if(all(handles.bg(ii).mat(:)==newX(:))), handles.bg(ii).mat = x; end
    end
    guidata(hObject, handles);
    dtiRefreshFigure(handles, 0);
else
    [f,p] = uigetfile({'*.mat'}, 'Save new transform in dt6 file...',handles.dataFile);
    if(isnumeric(f)) error('Save canceled.'); end
    xformToAcPc = newX;
    save(fullfile(p,f), 'xformToAcPc', '-APPEND');
end
return;


%% Analyze | Adjust ACPC alignment
function menuAnalyze_adjustAcPcAlign_Callback(hObject, eventdata, handles)

% Pull this out.  Comment.  Does it have the same problem as above

x = dtiGet(handles, 'acpcXform');
x = round(x*100)/100;
newX = x;
oldX = x;
done = false;
cancel = false;
while(~done && ~cancel)
    [t,r,s,k] = affineDecompose(newX);
    resp = inputdlg({'Translation (mm):','Rotation (rad):','Scale (mm):','Skew (rad):'},...
        'Modify AC-PC alignment...',1,...
        {num2str(t), num2str(r), num2str(s), num2str(k)});
    if(isempty(resp))
        disp('User canceled- resetting values.');
        cancel = true;
    else
        t = str2num(resp{1});
        r = str2num(resp{2});
        s = str2num(resp{3});
        k = str2num(resp{4});
        if(length(t)~=3 || length(r)~=3 || length(s)~=3 || length(k)~=3)
            disp('Invalid transform matrix.');
        else
            t = (str2num(resp{1})*10)/10;
            r = (str2num(resp{2})*100)/100;
            s = (str2num(resp{3})*10)/10;
            k = (str2num(resp{4})*100)/100;
            
            newX = affineBuild(t,r,s,k);
            % Keep it clean- we can't use more precision than this anyway
            newX = round(newX*100)/100;
            handles = dtiSet(handles,'acpcXform',newX);
            guidata(hObject, handles);
            handles = dtiRefreshFigure(handles, 0);
            pause(0.1);
        end
        if(all(newX==oldX)) done = true; end
        oldX = newX;
    end
end
if(cancel)
    handles = dtiSet(handles,'acpcXform',x);
    guidata(hObject, handles);
    dtiRefreshFigure(handles, 0);
else
    [f,p] = uigetfile({'*.mat'}, 'Save new transform in dt6 file...',handles.dataFile);
    if(isnumeric(f)) error('Save canceled.'); end
    anat.xformToAcPc = newX;
    xformToAcPc = handles.acpcXform*dtiGet(handles, 'dtiToAnatXform');
    save(fullfile(p,f), 'xformToAcPc', 'anat.xformToAcPc', '-APPEND');
end
return;

%% Analyze | Compute Brain Mask
function menuAnalyze_computeBrainMask_Callback(hObject, eventdata, handles)

% Pull this out.  Comment

bgNum = dtiGet(handles,'curbgnum');

betLevel = 0.5;
resp = inputdlg('BET FIT (0-1; smaller=more brain):', 'Brain Extraction Params', 1, {num2str(betLevel)});
if(isempty(resp)), disp('Canceled.'); return; end
betLevel = str2double(resp{1});

[brainMask,checkSlices] = ...
    mrAnatExtractBrain(handles.bg(bgNum).img, handles.bg(bgNum).mmPerVoxel, betLevel);

figure;image(checkSlices); axis image;
if(~isfield(handles,'brainMask') || isempty(handles.brainMask))
    handles.brainMask = brainMask;
else
    bn = questdlg('BrainMask exists:', 'Brain Mask exists', ...
        'Replace it','Cancel','Replace it');
    if(strcmp(bn, 'Cancel'))
        return;
    end
end
guidata(hObject, handles);
[f,p] = uigetfile({'*.mat'}, 'Save brain mask in dt6 file...',handles.dataFile);
if(isnumeric(f)) error('Canceled.'); end
% there's no way to simply append a sub-field
dt = load(fullfile(p,f), 'anat');
anat = dt.anat;
anat.brainMask = brainMask;
save(fullfile(p,f), 'anat', '-APPEND');

return

%%% ****************************************************
%% MENU: ROIs
%%% ****************************************************

% TODO:  There should be an dtiRoiCreate() function.
% All of the specialized code in here should be in the function.

function menuRois_Callback(hObject, eventdata, handles)
return;

%% ROIs | New (sphere)
function menuRois_buildSphere_Callback(hObject, eventdata, handles)
%  Create s sphere-ROI at the current position.

center = str2num(get(handles.editPosition,'String'));
answer = inputdlg('Radius:','Build Sphere ROI',1,{'5'});
if(isempty(answer)), disp('Sphere ROI canceled'); return; end

radius = str2double(answer);
roiNum = length(handles.rois)+1;
roi = dtiNewRoi(['sphere_' num2str(radius, '%02d')]);
roi.coords = dtiBuildSphereCoords(center, radius);

handles = dtiAddROI(roi,handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;


%% ROIs | New (rectangular)
function menuRois_buildRectangle_Callback(hObject, eventdata, handles)
%  Create s rectangle-ROI at the current position.

center = round(str2num(get(handles.editPosition,'String')));
x = sprintf('[%d  %d]',center(1)-10, center(1)+10);
y = sprintf('[%d  %d]',center(2)-10, center(2)+10);
z = sprintf('[%d  %d]',center(3)-10, center(3)+10);
answer = inputdlg({'X coords:','Y coords:','Z coords:'},'Build Rectangle ROI',1,{x,y,z});
if(isempty(answer)) disp('Rectangle ROI canceled'); return; end

x = str2num(answer{1});
y = str2num(answer{2});
z = str2num(answer{3});
roiNum = length(handles.rois)+1;
roi = dtiNewRoi(['rect' num2str(round(center), '_%02d')]);
[X,Y,Z] = meshgrid([x(1):x(2)],[y(1):y(2)],[z(1):z(2)]);
roi.coords = [X(:), Y(:), Z(:)];
handles = dtiAddROI(roi,handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%% ROIs | New (polygon)
function menuRois_buildPoly_Callback(hObject, eventdata, handles)
return;

%% ROIs | New (polygon) | X Image
function menuROInewPolyX_Callback(hObject, eventdata, handles)
dtiNewPolyRoi(hObject,handles,'x');
return;

%% ROIs | New (polygon) | Y Image
function menuROInewPolyY_Callback(hObject, eventdata, handles)
dtiNewPolyRoi(hObject,handles,'y');
return;

%% ROIs | New (polygon) | Z Image
function menuROInewPolyZ_Callback(hObject, eventdata, handles)
dtiNewPolyRoi(hObject,handles,'z');
return;

%% Function used for previous calls.  Could be pulled out.
function dtiNewPolyRoi(hObject,handles,whichPlane)
%  Create a new Polygonal ROI in one of the 3 image planes.

% Create a new (empty) ROI
newRoiNum = length(handles.rois)+1;
roi = dtiNewRoi(['Poly (',num2str(newRoiNum),')']);
handles = dtiAddROI(roi,handles);

% Call the Add Polygon routine.  These also refresh and attach to the
% figure.
switch lower(whichPlane)
    case 'x', menuROIAddPx_Callback(hObject, [], handles);
    case 'y', menuROIAddPy_Callback(hObject, [], handles);
    case 'z', menuROIAddPz_Callback(hObject, [], handles);
    otherwise, error('Unknown plane');
end

return;

%% ROIs | Edit Name and Color
function menuRois_modify_Callback(hObject, eventdata, handles)
[newRoi, ok] = dtiModifyRoi(handles.rois(handles.curRoi));
if(ok)
    handles.rois(handles.curRoi) = newRoi;
    handles = popupCurrentRoi_Refresh(handles);
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
end
return;

% --- Executes on button press in pbModifyROI.
function pbModifyROI_Callback(hObject, eventdata, handles)
menuRois_modify_Callback(hObject, eventdata, handles)
return;

%% ROIs | Merge
function menuRoisMerge_Callback(hObject, eventdata, handles)

% We could merge several here.
sList = dtiSelectROIs(handles,'Choose ROIs to merge');
if(isempty(sList) || length(sList) < 2), disp('Merge ROIs canceled'); return; end

% Warning:  Don't use newRoi because, sadly, this is the name of a
% mrLoadRet function.
mergedROI = dtiMergeROIs(handles.rois(sList(1)),handles.rois(sList(2)));
if length(sList) > 2
    for ii=3:length(sList)
        mergedROI = dtiMergeROIs(mergedROI,handles.rois(sList(ii)));
    end
end

handles = dtiAddROI(mergedROI,handles,1);
handles = dtiRefreshFigure(handles, 0);

guidata(gcf,handles);

return;

%% ROIs | Intersect
function menuRoisIntersect_Callback(hObject, eventdata, handles)
% We can intersect several ROIs
sList = dtiSelectROIs(handles,'Choose ROIs to intersect');
if(isempty(sList) || length(sList) < 2), disp('Intersect ROIs canceled'); return; end

% Warning:  Don't use newRoi because, sadly, this is the name of a
% mrLoadRet function.
intersectedROI = dtiIntersectROIs(handles.rois(sList(1)),handles.rois(sList(2)));
if length(sList) > 2
    for ii=3:length(sList)
        intersectedROI = dtiIntersectROIs(intersectedROI,handles.rois(sList(ii)));
    end
end

handles = dtiAddROI(intersectedROI,handles,1);
handles = dtiRefreshFigure(handles, 0);

guidata(gcf,handles);

return;

%-------------------------------------------
function menuRois_deleteSome_Callback(hObject, eventdata, handles)

sList = dtiSelectROIs(handles,'Delete some ROIs');
if(isempty(sList)), disp('Delete some ROIs canceled'); return; end

% Always delete from highest to lowest to avoid numbering problem
sList = fliplr(sList);
for ii=sList
    handles = dtiDeleteROI(ii,handles);
end

% Shouldn't all of these calls really be part of dtiRefreshFigure?
handles = popupCurrentRoi_Refresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%% ROIs | Find Current ROI
function menuRois_findCurRoi_Callback(hObject, eventdata, handles)
centerOfMass = round(mean(handles.rois(handles.curRoi).coords,1)*10)/10;
set(handles.editPosition, 'String', sprintf('%.1f, %.1f, %.1f',centerOfMass));
editPosition_Callback(handles.editPosition, [], handles);
return;

%% ROIs | New Other
function menuRois_build_Callback(hObject, eventdata, handles)
return;

%% ROIs | New Other | ROI from image mask
function menuRois_buildFromCurImage_Callback(hObject, eventdata, handles)
% Sure could use a comment and a pointer to where this is called in the
% GUI.
curImNum = dtiGet(handles, 'bgnum');

imName   = handles.bg(curImNum).name;
thresh   = [0.25 inf];
smoothKernel = 3;
removeSatellites = 1;
baseName = imName;
resp = inputdlg({'Im val range to keep (eg. [0 0.25)):','smoothing kernel (0 for none):',...
    'remove satellites (0|1):','ROI name:'}, ...
    ['Generate ROI from ' handles.bg(curImNum).name], 1, {num2str(thresh), num2str(smoothKernel), ...
    num2str(removeSatellites), baseName});
if(isempty(resp)), disp('user cancelled.'); return; end
thresh = str2num(resp{1});
smoothKernel = str2num(resp{2});
removeSatellites = str2num(resp{3});
baseName = resp{4};
if(length(thresh)==1), thresh = [thresh inf]; end
[im,mm,mat,valRange] = dtiGetNamedImage(handles.bg, imName);
colors = 'gcbmry';
flags = {'fillHoles'};
if(removeSatellites), flags{end+1} = 'removeSatellites'; end
if(any(thresh<0))
    thresh = (abs(thresh)-valRange(1))./diff(valRange);
    fprintf('actual thresh: %0.3f (valRange = [%0.2f,%0.2f])', thresh(1), valRange(1), valRange(2));
end
for(ii=2:length(thresh))
    if(length(thresh)>2)
        newRoi = dtiNewRoi([baseName '_' num2str(round(thresh(ii-1)*100),'%03d')], colors(mod(ii-2,length(colors))+1));
    else
        newRoi = dtiNewRoi(baseName);
    end
    if(~all(mm==1))
        [im,mat] = mrAnatResliceSpm(double(im), inv(mat), [], [1 1 1], [1 1 1 0 0 0], 0);
    end
    mask = im>=thresh(ii-1) & im<thresh(ii);
    mask = dtiCleanImageMask(mask, smoothKernel, flags);
    [x,y,z] = ind2sub(size(mask), find(mask));
    newRoi.coords = mrAnatXformCoords(mat, [x,y,z]);
    handles = dtiAddROI(newRoi,handles);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%% ROIs | New Other | ROI from Fibers 
function menuRois_buildFromFibers_Callback(hObject, eventdata, handles)
% Sure could use a comment and a pointer to where this is called in the
% GUI.
fg = dtiGet(handles,'curFiberGroup');
newRoi = dtiNewRoi(fg.name, fg.colorRgb./255, round(horzcat(fg.fibers{:}))');
handles = dtiAddROI(newRoi,handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%% ROIs | New Other | Create Callosal ROI
function menuRois_createCallosalRoi_Callback(hObject, eventdata, handles)
% NOTE: handles.bg(1) should always be the b0!
ccCoords = dtiFindCallosum(handles.dt6,handles.bg(1).img,handles.xformToAcpc,0.5);
roi = dtiNewRoi('CC','c',ccCoords);
handles = dtiAddROI(roi,handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%% ROIs | New Other | ROI from Fiber Endpoints
function menuRois_buildFromFiberEndpts_Callback(hObject, eventdata, handles)
% Sure could use a comment and a pointer to where this is called in the
% GUI.
fg = dtiGet(handles,'curFiberGroup');
nfibers = length(fg.fibers);
fc = zeros(nfibers*2, 3);
for(jj=1:nfibers)
    fc((jj-1)*2+1,:) = [fg.fibers{jj}(:,1)'];
    fc((jj-1)*2+2,:) = [fg.fibers{jj}(:,end)'];
end
newRoi = dtiNewRoi([fg.name '_endpts'], fg.colorRgb./255, fc);
handles = dtiAddROI(newRoi,handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuRois_cleanCurShape_Callback(hObject, eventdata, handles)
roi = dtiGet(handles, 'currentROI');
newRoi = dtiRoiClean(roi);
if(isempty(newRoi.name))
    roi.coords = newRoi.coords;
    handles = dtiSet(handles, 'curRoi', roi);
else
    handles = dtiAddROI(newRoi, handles, 1);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

function menuRois_edit_Callback(hObject, eventdata, handles)
return;


% --------------------------------------------------------------------
function menuRois_clipCur_Callback(hObject, eventdata, handles)
roi = dtiGet(handles,'currentROI');
[roiClip, roiNot] = dtiRoiClip(roi);
if(isempty(roiClip.name))
    roi.coords = roiClip.coords;
else
    handles = dtiAddROI(roiNot,handles);
    handles = dtiAddROI(roiClip,handles);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

%% 3d flood-fill
function menuRois_growFromPos_Callback(hObject, eventdata, handles)
if(isempty(handles.rois))
    handles = dtiAddROI(dtiNewRoi('floodFill'), handles, 1);
end
radius = 20; % in mm
tol = .15;
sigma = 0;
curAnat = dtiGet(handles,'curanatdata');
curXform = dtiGet(handles,'curimg2acpcxform');
curPosAcpc = round(dtiGet(handles, 'curPos'));
curPos = round(mrAnatXformCoords(inv(curXform), curPosAcpc));
sz = size(curAnat);
distIm = zeros(sz(1:3));
distIm(curPos(1), curPos(2), curPos(3)) = 1;
distIm = bwdist(distIm);
if(ndims(curAnat)==4)
    % For the PDD maps, we use the log-tensor similarity metric
    clear curAnat;
    [eigVec,eigVal] = dtiEig(handles.dt6);
    badVals = eigVal<1e-4;
    distIm(any(badVals,4)) = 1e12;
    eigVal(badVals) = 1e-4;
    curAnat = dtiEigComp(eigVec, log(eigVal));
    curAnat(curAnat>5) = 5;
    curAnat = curAnat./5;
    sz = size(curAnat);
    tol = 0.01;
end
oldCoords = dtiGet(handles, 'curRoiCoords');
oldTol = tol;
oldRadius = radius;
oldSigma = sigma;
done = false;
cancel = false;
while(~done && ~cancel)
    if(sigma>0)
        % Don't bother recomputing it if sigma hasn't changed.
        if(sigma~=oldSigma)
            curAnatTmp = dtiSmooth3(curAnat, sigma);
        end
    else
        curAnatTmp = curAnat;
    end
    seedVal = squeeze(curAnatTmp(curPos(1), curPos(2), curPos(3), :));
    radiusVox = max(radius./handles.mmPerVoxel);
    % Compute the similarity image
    if(numel(sz)>3)
        img = zeros(sz(1:3));
        for(jj=1:sz(4))
            img = img+(curAnatTmp(:,:,:,jj)-seedVal(jj)).^2;
        end
        img(img>1) = 1;
    else
        img = abs(curAnat-seedVal);
    end
    % error image is smoothed.
    if(sigma<0)
        img = dtiSmooth3(img, abs(sigma));
    end
    % Voxels outside the search radius get max error
    img(bwdist(distIm)>radiusVox) = 1;
    % binarize and floodfill with bwlabeln
    img = img<=tol;
    % Default connectivity is 6- may try 18 or 26.
    [l,n] = bwlabeln(img, 6);
    if(n>0&&l(curPos(1),curPos(2),curPos(3))>0)
        roiIm = l==l(curPos(1), curPos(2), curPos(3));
        % Resample to 1mm grid to make a nice ROI
        bb = [curPosAcpc-radius-1; curPosAcpc+radius+1];
        [roiIm,roiXform] = mrAnatResliceSpm(double(roiIm), inv(handles.xformToAcpc), bb, [1 1 1],[1 1 1 0 0 0],0);
        roiIm(isnan(roiIm)) = 0;
        roiIm = roiIm>=0.5;
        [x,y,z] = ind2sub(size(roiIm), find(roiIm(:)));
        coordsAcpc = mrAnatXformCoords(roiXform,[x(:) y(:) z(:)]');
    else
        coordsAcpc = [];
    end
    handles.rois(handles.curRoi).coords = [oldCoords; coordsAcpc];
    handles.rois(handles.curRoi).coords = unique(handles.rois(handles.curRoi).coords, 'rows');
    handles = dtiRefreshFigure(handles, 0);
    resp = inputdlg({'tolerance:','sigma (smoothing kernel):','max radius (in voxels):'}, 'Floodfill 3d...', 1, ...
        {num2str(tol),num2str(sigma),num2str(radius)});
    if(isempty(resp)) disp('User canceled.'); cancel = true;
    else
        tol = str2double(resp{1});
        sigma = str2double(resp{2});
        radius = str2double(resp{3});
    end
    if(tol<0 || (tol==oldTol && sigma==oldSigma && radius==oldRadius)) done = true; end
    oldTol = tol;
    oldSigma = sigma;
    oldRadius = radius;
end
if(cancel)
    handles.rois(handles.curRoi).coords = oldCoords;
    handles = dtiRefreshFigure(handles, 0);
end
guidata(hObject, handles);
return;

%-------------------------------------------
function menuRois_grow2d_parent_Callback(hObject, eventdata, handles)
return;

%-------------------------------------------
function menuRois_grow2d_Callback(hObject, eventdata, handles, whichAxis)
%
% Flood-fill a 2d region starting with the current position.
%
if(isempty(handles.rois))
    handles = dtiAddROI(dtiNewRoi('floodFill'), handles, 1);
end
curPosAcpc = str2num(get(handles.editPosition, 'String'));
tol = .15;
thick = 2;
if(whichAxis=='x') ax = 1;
elseif(whichAxis=='y') ax = 2;
else ax = 3;
end

% Get anatomical parameters from current background
n      = dtiGet(handles,'bg num');
anat   = dtiGet(handles,'bg image',n);
xform  = dtiGet(handles,'bg img2acpc xform',n);
% mmPerVoxel = dtiGet(handles,'bg mmpervox',n);
% [anat, mmPerVoxel, xform] = dtiGetCurAnat(handles);

% If this is a RGB PDD map, we'll need to swap it out with the dt6 data for
% the growing code.
if(ndims(anat)==4)
    anat = handles.dt6;
end
% Initialize the 2d-growing
[coords, data] = dtiRoiGrow2d(anat, xform, curPosAcpc, ax, tol, thick);

% iterate, displaying the results, until the user is satisfied
oldCoords = handles.rois(handles.curRoi).coords;
oldTol = tol;
oldThick = thick;
done = false;
cancel = false;
while(~done && ~cancel)
    % To avoid recomputing the iamge pre-processing, we pass in the data
    % struct rather than a raw image volume.
    coords = dtiRoiGrow2d(data, xform, curPosAcpc, ax, tol, thick);
    % Update the current ROI
    handles.rois(handles.curRoi).coords = [oldCoords; coords];
    handles.rois(handles.curRoi).coords = unique(handles.rois(handles.curRoi).coords, 'rows');
    handles = dtiRefreshFigure(handles, 0);
    ans = inputdlg({'tolerance:','thickness:'}, 'Select similar...', 1, {num2str(tol),num2str(thick)});
    if(isempty(ans)) cancel = true;
    else
        tol = str2double(ans{1});
        thick = round(str2double(ans{2}));
    end
    if(tol<0 || (tol==oldTol && thick==oldThick)) done = true; end
    oldTol = tol;
    oldThick = thick;
end
if(cancel)
    handles.rois(handles.curRoi).coords = oldCoords;
    handles = dtiRefreshFigure(handles, 0);
end
guidata(hObject, handles);
return;


%-------------------------------------------
function menuRois_addSphere_Callback(hObject, eventdata, handles)
% Add a sphere to the current ROI
center = str2num(get(handles.editPosition,'String'));
answer = inputdlg('Radius:','Add Sphere ROI', 1, {'5'});
if(isempty(answer)) return; end
radius = str2double(answer);
coords = dtiBuildSphereCoords(center, radius);
coords = [handles.rois(handles.curRoi).coords; coords];
coords = unique(coords, 'rows');
handles.rois(handles.curRoi).coords = coords;
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;



%-------------------------------------------
function menuRois_removeSphere_Callback(hObject, eventdata, handles)
% Delete a sphere from the current ROIs
center = str2num(get(handles.editPosition,'String'));
answer = inputdlg('Radius:','Remove Sphere ROI', 1, {'5'});
if(isempty(answer)) return; end
radius = str2double(answer);
coords = handles.rois(handles.curRoi).coords;
dSq = (coords(:,1)-center(1)).^2 + (coords(:,2)-center(2)).^2 + (coords(:,3)-center(3)).^2;
coords(dSq<=radius.^2,:) = [];
handles.rois(handles.curRoi).coords = coords;
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-----------------------------------------
function [r,c] = getPolyRoiPoints(axisHandle, axisLim)
% AxisLim should be [column, row]
axes(axisHandle);
%set(handles.y_cut_img,'HitTest','on');
oldbdf = get(axisHandle,'ButtonDownFcn');
set(axisHandle,'ButtonDownFcn','');
bw = roipoly;
set(axisHandle,'ButtonDownFcn',oldbdf);
[c,r] = ind2sub(size(bw),find(bw));
r = floor(r+axisLim(1)-1);
c = floor(c+axisLim(2)-1);
return;

%-------------------------------------------
function menuROIAddP_Callback(hObject, eventdata, handles)
return;

%-------------------------------------------
function menuROIAddPz_Callback(hObject, eventdata, handles)
% Add a polygon in the Z-image window
% handles = checkCurRoi(handles);
thick = 2;
curPosition = str2num(get(handles.editPosition, 'String'));
curSlice = round(curPosition(3));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.z_cut, [bb(1,1) bb(1,2)]);
coords = [r, c, repmat(curSlice, length(r), 1)];
for(ii=[1:thick-1,-1:-1:-(thick-1)])
    newLayer = coords;
    newLayer(:,3) = newLayer(:,3)+ii;
    coords = [coords; newLayer];
end
handles.rois(handles.curRoi).coords = [handles.rois(handles.curRoi).coords; coords];
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuROIAddPy_Callback(hObject, eventdata, handles)
%  = checkCurRoi(handles);
thick = 2;
curPosition = str2num(get(handles.editPosition, 'String'));
curSlice = round(curPosition(2));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.y_cut, [bb(1,1) bb(1,3)]);
coords = [r, repmat(curSlice, length(r), 1), c];
for(ii=[1:thick-1,-1:-1:-(thick-1)])
    newLayer = coords;
    newLayer(:,2) = newLayer(:,2)+ii;
    coords = [coords; newLayer];
end
handles.rois(handles.curRoi).coords = [handles.rois(handles.curRoi).coords; coords];
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuROIAddPx_Callback(hObject, eventdata, handles)
% handles = checkCurRoi(handles);
thick = 2;
curPosition = str2num(get(handles.editPosition, 'String'));
curSlice = round(curPosition(1));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.x_cut, [bb(1,2) bb(1,3)]);
numCoordsPerLayer = length(r);
layers = [-thick+1:thick-1];
coords = zeros(numCoordsPerLayer*length(layers),3);
zeroLayer = [repmat(curSlice, length(r), 1), r, c];
for(ii=[1:length(layers)])
    curLayerInd = (ii-1)*numCoordsPerLayer+1;
    curLayer = zeroLayer;
    curLayer(:,1) = curLayer(:,1)+layers(ii);
    coords(curLayerInd:curLayerInd+numCoordsPerLayer-1,:) = curLayer;
end
handles.rois(handles.curRoi).coords = [handles.rois(handles.curRoi).coords; coords];
handles.rois(handles.curRoi).coords = unique(handles.rois(handles.curRoi).coords,'rows');
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuROIDeleteP_Callback(hObject, eventdata, handles)
return;

%-------------------------------------------
function menuROIDeleteX_Callback(hObject, eventdata, handles)
thick = 2;
curPos = str2num(get(handles.editPosition, 'String'));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.x_cut, [bb(1,2) bb(1,3)]);
coords = handles.rois(handles.curRoi).coords;
% We handle slice separately since we need to deal with the slice thickness.
sliceMatch = coords(:,1)>=curPos(1)-thick & coords(:,1)<=curPos(1)+thick;
removeThese = ismember(round(coords(:,[2,3])), [r, c], 'rows');
removeThese = removeThese & sliceMatch;
handles.rois(handles.curRoi).coords = handles.rois(handles.curRoi).coords(~removeThese,:);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuROIDeleteY_Callback(hObject, eventdata, handles)
thick = 2;
curPos = str2num(get(handles.editPosition, 'String'));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.y_cut, [bb(1,1) bb(1,3)]);
% sliceSlop = [2 2 2];
coords = handles.rois(handles.curRoi).coords;

% We handle slice separately since we need to deal with the slice thickness.
sliceMatch = coords(:,2)>=curPos(2)-thick & coords(:,2)<=curPos(2)+thick;
removeThese = ismember(round(coords(:,[1,3])), [r, c], 'rows');
removeThese = removeThese&sliceMatch;
handles.rois(handles.curRoi).coords = ...
    handles.rois(handles.curRoi).coords(~removeThese,:);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuROIDeleteZ_Callback(hObject, eventdata, handles)
thick = 2;
curPos = str2num(get(handles.editPosition, 'String'));
bb = dtiGet(handles,'defaultBoundingBox');
[r,c] = getPolyRoiPoints(handles.z_cut, [bb(1,1) bb(1,2)]);
coords = handles.rois(handles.curRoi).coords;
% Handle slice separately since we need to deal with the slice thickness.
sliceMatch = coords(:,3)>=curPos(3)-thick & coords(:,3)<=curPos(3)+thick;
% *** FIX THIS: we aren't quite doing this right. We do (basically) the
% right thing for the slice by using the mmPerVox of the real sampling grid
% to select our points. But here, we just use a crude 'round' and ismember.
% What we should really do is write a variant of 'ismember' that can find
% near matches as well.
removeThese = ismember(round(coords(:,[1:2])), [r, c], 'rows');
removeThese = removeThese&sliceMatch;
handles.rois(handles.curRoi).coords = ...
    handles.rois(handles.curRoi).coords(~removeThese,:);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

%-------------------------------------------
function menuRois_restrictToImgVal_Callback(hObject, eventdata, handles)
handles = dtiRestrictToImageValueRange(handles);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuRois_xformCoords_Callback(hObject, eventdata, handles)
roi = dtiGet(handles,'currentROI');
resp = inputdlg({'Translate (X,Y,Z; in mm):','New ROI name (blank to xform in place):'}, ...
    'Transform ROI coords...', 1, {num2str([0 0 0]),[roi.name '_xformed']});
if(isempty(resp)) disp('User canceled.'); return; end
t = str2num(resp{1}); t = t(:);
if(length(t)~=3) error('Incorrect translation!'); end
newName = resp{2};
for(ii=1:3) roi.coords(:,ii) = roi.coords(:,ii) + t(ii); end
if(isempty(newName))
    handles = dtiSet(handles, 'curRoi', roi);
else
    roi.name = newName;
    handles = dtiAddROI(roi,handles);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

% --------------------------------------------------------------------
function menuRois_importMrMesh_Callback(hObject, eventdata, handles)
if(~isfield(handles, 'mrVistaMesh') || isempty(handles.mrVistaMesh) || isempty(handles.mrVistaMesh.meshes))
    error('No current mesh.');
end
msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
mrMeshRoi = mrmGet(msh,'curRoi');
if(~isfield(mrMeshRoi,'vertices'))
    error('Couldn''t get ROI- maybe there are none defined?');
end
coords = msh.initVertices(:,mrMeshRoi.vertices);
% See menuView_overlay3dColormap_Callback for an explanation of the
% following transform.
swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
acpc2vertex = swapXY*diag([msh.mmPerVox([2,1,3]) 1])*inv(handles.xformVAnatToAcpc);
coords = mrAnatXformCoords(inv(acpc2vertex), coords');
roi = dtiNewRoi('mrMesh ROI',[],coords);
handles = dtiAddROI(roi, handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;


% ******************************************
% MENU: FIBERS
% ******************************************
function menuFibers_Callback(hObject, eventdata, handles)
return;

%% Fibers | Delete some Groups
function menuFibers_deleteSomeGroups_Callback(hObject, eventdata, handles)
if(isempty(handles.fiberGroups)), disp('No Fiber groups to delete!'); return; end
sList = dtiSelectFGs(handles);
if isempty(sList), disp('Delete Fiber Groups ... canceled'); end
% We need to make sure we delete the highest numbers first, or the
% following loop will crash (for obvious reasons).
for ii=fliplr(sort(sList(:)'))
    handles = dtiDeleteFG(ii,handles);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

%% Fibers -> Modify group (and (*) button
function menuFibers_modifyGroup_Callback(hObject, eventdata, handles)
[newFg, ok] = dtiModifyFiberGroup(handles.fiberGroups(handles.curFiberGroup));
if ~ok, disp('Modify Group canceled.'), return; end
handles.fiberGroups(handles.curFiberGroup) = newFg;
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

% --- Executes on button press in pbModifyFG.
function pbModifyFG_Callback(hObject, eventdata, handles)
menuFibers_modifyGroup_Callback(hObject, eventdata, handles);
return;

%-------------------------------------------
function menuFibers_trackFromCurRoi_Callback(hObject, eventdata, handles)
seeds = handles.rois(handles.curRoi).coords;
fgName = [dtiGet(handles,'curRoiName'),'FG'];
[fg,opts] = dtiFiberTrack(handles.dt6, seeds, handles.mmPerVoxel, handles.xformToAcpc, fgName);
handles = dtiAddFG(fg,handles);
handles = dtiRefreshFigure(handles,0);
guidata(hObject, handles);
return;


% MENU FIBERS: AND
function menuFibers_pruneCurRoi_Callback(hObject, eventdata, handles)
% Deprecated?  See below???
menuFibers_andCurRoi_Callback(hObject, eventdata, handles);
return;

%% Fibers | AND with current roi
function menuFibers_andCurRoi_Callback(hObject, eventdata, handles)
%
%   We create a new fiber group that includes only fibers that pass through
%   the current ROI. (Fibers AND currentROI)
%
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'AND'});
handles = dtiAddFG(fg, handles);
guidata(hObject, handles);
return;


%% NOT current ROI
function menuFibersNOTcurROI_Callback(hObject, eventdata, handles)
%
%   We create a new fiber group that excludes any fibers that pass through
%   the current ROI. (Fibers NOT currentROI)
%
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'NOT'});
handles = dtiAddFG(fg, handles);
guidata(hObject, handles);
return;

%% SPLIT
function menuFibersSplitCurRoi_Callback(hObject, eventdata, handles)
% Create two sets of fibers.  Those that are AND with the current ROI and
% those that are NOT with the current ROI.
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'SPLIT'});
handles = dtiAddFG(fg(1), handles);
handles = dtiAddFG(fg(2), handles);
guidata(hObject, handles);
return;

%% SPLIT (ONLY LOOK AT FIBER ENDPOINTS)
function menuFiber_splitCurRoiEndpoints_Callback(hObject, eventdata, handles)
% Create two sets of fibers.  Those that are AND with the current ROI and
% those that are NOT with the current ROI.
%
% AND
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'SPLIT','endPoints'}, 2.0);
handles = dtiAddFG(fg(1), handles);
handles = dtiAddFG(fg(2), handles);
guidata(hObject, handles);
return;

% AND (ONLY LOOK AT FIBER ENDPOINTS)
function menuFiber_andCurRoiEndpoints_Callback(hObject, eventdata, handles)
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'AND','endPoints'}, 2.0);
handles = dtiAddFG(fg, handles);
guidata(hObject, handles);
return;

%% AND (LOOK at BOTH FIBER ENDPOINTS)
function menuFiber_andCurRoiBothEndpoints_Callback(hObject, eventdata, handles)
if(dtiGet(guidata(gcf),'mrMeshCheckbox'))
    handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles);
end
fg = dtiIntersectFibersWithRoi(handles, {'AND','both_endpoints'}, 2.0);
handles = dtiAddFG(fg, handles);
guidata(hObject, handles);
return;

%% SPLIT by Multiple ROIs (ONLY LOOK AT FIBER ENDPOINTS)
function menuFiber_splitMultiRoiEndpoints_Callback(hObject, eventdata, handles)
% User selects 2 or more ROIs. Split the current fiber group (by endpoint)
% using these ROIs.
minDist = 2;
fg = dtiGet(handles, 'currentFg');
roiNames = {handles.rois.name};
[selectedRoiNums,ok] = listdlg('Name', ['Split ' fg.name ' by multiple ROIs...'],...
    'PromptString','Select ROIs',...
    'SelectionMode', 'multiple',...
    'ListString', roiNames, ...
    'ListSize', [300 300]);
if ~ok || isempty(selectedRoiNums)
    disp('SPLIT by multiple ROIs canceled.');
    return;
end
rois = handles.rois(selectedRoiNums);
[newFgs,numContentious] = dtiIntersectFibersWithRoi(handles, {'DIVIDE','endPoints'}, minDist, rois, fg);
percentContentious = sum(numContentious)/length(fg.fibers)*100;
disp([num2str(percentContentious) '% of the fibers were within ' num2str(minDist) 'mm of >1 ROI.']);
for(ii=1:length(newFgs))
    [handles, fgNum] = dtiAddFG(newFgs(ii), handles);
end
guidata(hObject, handles);
return;

%% SPLIT by Multiple ROIs
function menuFiber_splitMultiRoi_Callback(hObject, eventdata, handles)
% User selects 2 or more ROIs. Split the current fiber group using these ROIs.
minDist = 2;
fg = dtiGet(handles, 'currentFg');
roiNames = {handles.rois.name};
[selectedRoiNums,ok] = listdlg('Name', ['Split ' fg.name ' by multiple ROIs...'],...
    'PromptString','Select ROIs',...
    'SelectionMode', 'multiple',...
    'ListString', roiNames, ...
    'ListSize', [300 300]);
if ~ok || isempty(selectedRoiNums)
    disp('SPLIT by multiple ROIs canceled.');
    return;
end
rois = handles.rois(selectedRoiNums);
[newFgs,numContentious] = dtiIntersectFibersWithRoi(handles, {'DIVIDE'}, minDist, rois, fg);
percentContentious = sum(numContentious)/length(fg.fibers)*100;
disp([num2str(percentContentious) '% of the fibers were within ' num2str(minDist) 'mm of >1 ROI.']);
for(ii=1:length(newFgs))
    [handles, fgNum] = dtiAddFG(newFgs(ii), handles);
end
guidata(hObject, handles);
return;


%% FIBERS->MERGE
function menuFibers_mergeSomeFiberGroups_Callback(hObject, eventdata, handles)
if(isempty(handles.fiberGroups) | length(handles.fiberGroups)==1)
    disp('Not enough Fiber groups to merge!');
    return;
end
sList = dtiSelectFGs(handles);
if isempty(sList) | (length(sList) == 1), disp('Merge Fiber Groups canceled'); return; end
mergedFG = dtiMergeFiberGroups(handles.fiberGroups(sList(1)),handles.fiberGroups(sList(2)));
if length(sList) > 2
    for ii=3:length(sList)
        mergedFG = dtiMergeFiberGroups(mergedFG,handles.fiberGroups(sList(ii)));
    end
end
handles = dtiAddFG(mergedFG,handles,1);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);
return;

%% FIBERS->CLIP
function menuFibers_clipCur_Callback(hObject, eventdata, handles)
fg = dtiGet(handles,'currentfg');
newName = [fg.name '_clip'];
prompt = {'Left (-80) Right (+80) clip (blank for none):',...
    'Posterior (-120) Anterior (+80) clip (blank for none):',...
    'Inferior (-50) Superior (+90) clip (blank for none):',...
    'New fiber group name:'};
defAns = {'','','',newName};
resp = inputdlg(prompt,'Clip Current FG',1,defAns);
if(isempty(resp))
    disp('User cancelled clip.');
    return;
end
rlClip = str2num(resp{1});
apClip = str2num(resp{2});
siClip = str2num(resp{3});
newName = resp{4};
empty = zeros(size(fg.fibers));
for ii=1:length(fg.fibers)
    keep = ones(size(fg.fibers{ii}(1,:)));
    if(~isempty(rlClip))
        keep = keep & (fg.fibers{ii}(1,:)<rlClip(1) | fg.fibers{ii}(1,:)>rlClip(2));
    end
    if(~isempty(apClip))
        keep = keep & (fg.fibers{ii}(2,:)<apClip(1) | fg.fibers{ii}(2,:)>apClip(2));
    end
    if(~isempty(siClip))
        keep = keep & (fg.fibers{ii}(3,:)<siClip(1) | fg.fibers{ii}(3,:)>siClip(2));
    end
    fg.fibers{ii} = fg.fibers{ii}(:,keep);
    empty(ii) = isempty(fg.fibers{ii})|size(fg.fibers{ii},2)==1;
end
fg.fibers = fg.fibers(~empty);
fg.name = newName;
handles = dtiAddFG(fg,handles);
guidata(hObject,handles);
return;

%% Fibers | Clean
function menuFibers_cleanCur_Callback(hObject, eventdata, handles)
fg = dtiGet(handles,'currentfg');
newName = [fg.name '_clean'];
prompt = {'NOT planes (remove fibers that intersect these planes; [L-R,A-P,S-I]):',...
    'Max fiber length (NaN for no max):',...
    'New fiber group name (blank to clean in place):'};
defAns = {'[NaN NaN NaN]','300',newName};
resp = inputdlg(prompt,'Clean Current FG',1,defAns);
if(isempty(resp)), disp('User cancelled.'); return; end
notPlanes = str2num(resp{1});
maxLen = str2num(resp{2});
newName = resp{3};
fg = dtiCleanFibers(fg, notPlanes, maxLen);
if(isempty(newName))
    handles = dtiSet(handles, 'curFg', fg);
else
    fg.name = newName;
    handles = dtiAddFG(fg,handles);
end
guidata(hObject,handles);
return;

%% Fibers | Warp to White matter 
function menuFibers_warpToWhiteMatter_Callback(hObject, eventdata, handles)
xform = inv(handles.xformToAcpc);
% curPosTal = str2num(get(handles.editPosition, 'String'));
% p = round(mrAnatXformCoords(xform, curPosTal));
% figure(99);
% w = permute(handles.wmWarp,[2,1,3,4]);
% subplot(1,3,1); quiver(squeeze(w(p(1)-8:p(1)+8,p(2)-8:p(2)+8,p(3),1)), squeeze(w(p(1)-8:p(1)+8,p(2)-8:p(2)+8,p(3),2)));
% subplot(1,3,1); quiver(squeeze(w(:,:,p(3),1)), squeeze(w(:,:,p(3),2)));
% subplot(1,3,2); quiver(squeeze(handles.wmWarp(:,curPos(2),:,1)), squeeze(handles.wmWarp(:,curPos(2),:,3)));
% subplot(1,3,3); quiver(squeeze(handles.wmWarp(curPos(1),:,:,2)), squeeze(handles.wmWarp(curPos(1),:,:,3)));
fg = handles.fiberGroups(handles.curFiberGroup);
h = mrvWaitbar(0,'Warping fibers...');
%fcAll = mrAnatXformCoords(xform,horzcat(fg.fibers{:})');

for(ii=1:length(fg.fibers))
    fc = mrAnatXformCoords(xform, fg.fibers{ii}');
    % We do nearest-neighbor for now
    fcInt = round(fc);
    for(jj=1:size(fc,1))
        vec = squeeze(handles.wmWarp(fcInt(jj,1), fcInt(jj,2), fcInt(jj,3), :));
        %vec = vec*2;
        % *** FIX ME: We should ensure that we get the mmPerVox order
        % correct.
        %vec = vec([2,1,3]);
        % vec = vec.*handles.vec.mmPerVoxel';
        fg.fibers{ii}(:,jj) = mrAnatXformCoords(inv(xform), fc(jj,:) + vec')';
    end
    mrvWaitbar(ii/length(fg.fibers),h);
end
mrvWaitbar(1.0,h);
close(h);
fg.visible = 1;
fg.seeds = [];
fg.colorRgb = 255-fg.colorRgb;
%fg.fibers = fg.fibers(keep);
fg.name = [fg.name '_warped'];
newGroupNum = length(handles.fiberGroups) + 1;
handles.curFiberGroup = newGroupNum;
handles.fiberGroups(newGroupNum) = fg;
handles = popupCurrentFiberGroup_Refresh(handles);
guidata(hObject, handles);


%% Fibers |  Connect multiple ROIS
function menuFibers_connectMultipleRois_Callback(hObject, eventdata, handles)
fgArray=dtiConnectMultipleROIs(handles);

for ii=1:length(fgArray)
    for jj=ii+1:length(fgArray) %Not interested in connections with itself?
        if ~isempty(fgArray(ii, jj).fibers)
            handles = dtiAddFG(fgArray(ii, jj), handles);
        end
    end
end

guidata(hObject, handles);

return

%-------------------------------------------
% MENU: XFORM
%-------------------------------------------
function menuXform_Callback(hObject, eventdata, handles)
return;

%-------------------------------------------
function menuXform_computeMrVista_Callback(hObject, eventdata, handles)
global mrSESSION;
if(~isempty(mrSESSION) && isfield(mrSESSION,'subject'))
    vAnatFile = fullfile(getAnatomyPath(lower(mrSESSION.subject)),'vAnatomy.dat');
else
    vAnatFile = '';
end
if(isempty(vAnatFile) || ~exist(vAnatFile, 'file'))
    [f,p] = uigetfile({'*.dat','vAnatomy files (*.dat)'; '*.*','All Files (*.*)'},'Select vAnatomy file for this subject');
    if(isnumeric(f)) error('user canceled.'); end
    vAnatFile = fullfile(p,f);
end
if strcmp(vAnatFile(end-6:end),'ii.gz')
    vAnatomy=niftiRead(vAnatFile);
    xformVAnatToAcpc = vAnatomy.qto_xyz;
else
    [vAnatomy,vAnatMm] = readVolAnat(vAnatFile);
    %[p,f,e] = fileparts(vAnatFile);
    %talFile = fullfile(p,[f '_talairach.mat']);
    %vAnatTal = loadTalairachXform('', talFile);
    [dtiT1, mmPerVoxel, dtiAcpcXform] = dtiGetNamedImage(handles.bg, 't1');
    if(isempty(dtiT1)), error('No T1 found! Please load a t1 image via the File menu.'); end
    xformVAnatToAcpc = dtiXformVanatCompute(dtiT1, dtiAcpcXform, vAnatomy, vAnatMm);
end

handles.xformVAnatToAcpc = xformVAnatToAcpc;
guidata(hObject, handles);
[f,p] = uigetfile({'*.mat'}, 'Save xform in dt6 file...',handles.dataFile);
if(isnumeric(f)) error('Canceled.'); end
save(fullfile(p,f), 'xformVAnatToAcpc', '-APPEND');
return;


% --------------------------------------------------------------------
function menuXform_computeWarpToMrVistaWM_Callback(hObject, eventdata, handles)
if(isempty(strmatch(lower('white matter'), lower({handles.bg.name}))))
    disp('Segmenting white matter from DTI...');
    menuAnalyze_segmentTissue_Callback(hObject, eventdata, handles);
end
global mrSESSION;
volView = getSelectedVolume;
handles.wmWarp = dtiComputeWhiteMatterWarp(handles, volView);
guidata(hObject, handles);
[f,p] = uigetfile({'*.mat'}, 'Save deformation in dt6 file...',handles.dataFile);
if(isnumeric(f)) error('Canceled.'); end
wmWarp = handles.wmWarp;
save(fullfile(p,f), 'wmWarp', '-APPEND');
return;


%-------------------------------------------
function menuXform_importMrVistaCurVolROI_Callback(hObject, eventdata, handles)
% *** call to mrVista function
view = getSelectedVolume;
mrVistaRoi = view.ROIs(view.selectedROI);
handles = dtiXformVanatRoi(handles, mrVistaRoi);
handles.curRoi = length(handles.rois);
handles = popupCurrentRoi_Refresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuXform_importMrVistaCurFlatROI_Callback(hObject, eventdata, handles)
% *** call to mrVista function
volView = getSelectedVolume;
if(isempty(volView)) volView = initHiddenVolume; end
flatView = getSelectedFlat;
if(isempty(flatView)) error('No selected FLAT! If a Flat window is open, click in it then try again.'); end
mrVistaRoi = flat2volROI(flatView.ROIs(flatView.selectedROI),flatView,volView);
handles = dtiXformVanatRoi(handles, mrVistaRoi);
handles.curRoi = length(handles.rois);
handles = popupCurrentRoi_Refresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuXform_importMrVistaAllFlatROI_Callback(hObject, eventdata, handles)
% *** call to mrVista function
volView = getSelectedVolume;
if(isempty(volView)) volView = initHiddenVolume; end
flatView = getSelectedFlat;
if(isempty(flatView)) error('No selected FLAT! If a Flat window is open, click in it then try again.'); end
for(ii=1:length(flatView.ROIs))
    mrVistaRoi = flat2volROI(flatView.ROIs(ii),flatView,volView);
    handles = dtiXformVanatRoi(handles, mrVistaRoi);
end
handles.curRoi = length(handles.rois);
handles = popupCurrentRoi_Refresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuXform_importMrVistaAllVolROI_Callback(hObject, eventdata, handles)
% *** call to mrVista function
view = getSelectedVolume;
for(ii=1:length(view.ROIs))
    mrVistaRoi = view.ROIs(ii);
    handles = dtiXformVanatRoi(handles, mrVistaRoi);
end
handles.curRoi = length(handles.rois);
handles = popupCurrentRoi_Refresh(handles);
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);
return;


%-------------------------------------------
function menuXform_xformSelectedRoiToMrVistaVol_Callback(hObject, eventdata, handles)
dtiXformRoiToMrVistaVolume(handles);
return;

%-------------------------------------------
function menuXform_xformSelectedFibersToMrVistaVol_Callback(hObject, eventdata, handles)
dtiXformFibersToMrVistaVolume(handles);
return;

%-------------------------------------------
function menuXform_xformSelectedFibersToMrVistaGray_Callback(hObject, eventdata, handles)
view = getSelectedGray;
view = dtiXformFibersToMrVistaGray(handles, view);
% Is there a better way to do this?
mrGlobals;
eval([view.name '=view;']);
return;

%-------------------------------------------
function menuXform_addFibersToMrVistaCurMesh_Callback(hObject, eventdata, handles)
if(~isfield(handles,'xformVAnatToAcpc'))
    error('You must compute the mrVista xform. See ''Xform'' menu.');
end
if(isfield(handles, 'mrVistaMesh') && ~isempty(handles.mrVistaMesh) && ~isempty(handles.mrVistaMesh.meshes))
    msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
    mrmSet(msh,'refresh');
    msh = dtiAddFibersToMrVistaMesh(handles, msh);
    handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = msh;
    guidata(hObject, handles);
    return;
else
    volView = getSelectedVolume;
    if(~isempty(volView))
        mrvMesh = viewGet(volView,'mesh');
        mrvMesh = dtiAddFibersToMrVistaMesh(handles, mrvMesh);
        volView = viewSet(volView,'mesh',mrvMesh);
        mrGlobals;
        eval([volView.name '=volView;']);
        return;
    end
end
error('No surface meshes available.');
return;


%-------------------------------------------
function menuXform_intersectFibersWithMrVistaCurMesh_Callback(hObject, eventdata, handles)
if(~isfield(handles,'xformVAnatToAcpc'))
    error('You must compute the mrVista xform. See ''Xform'' menu.');
end
if(isfield(handles, 'mrVistaMesh') && ~isempty(handles.mrVistaMesh) && ~isempty(handles.mrVistaMesh.meshes))
    msh = handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh);
    mrmSet(msh,'refresh');
    msh = dtiAddFibersToMrVistaMesh(handles, msh, 2);
    handles.mrVistaMesh.meshes(handles.mrVistaMesh.curMesh) = msh;
    guidata(hObject, handles);
    return;
else
    volView = getSelectedVolume;
    if(~isempty(volView))
        mrvMesh = viewGet(volView,'mesh');
        mrvMesh = dtiAddFibersToMrVistaMesh(handles, mrvMesh, 2);
        volView = viewSet(volView,'mesh',mrvMesh);
        mrGlobals;
        eval([volView.name '=volView;']);
        return;
    end
end
error('No surface meshes available.');

return;

% --------------------------------------------------------------------
function menuXform_stainByFunctional_Callback(hObject, eventdata, handles)
grayView = getSelectedVolume;
newFGs = dtiSplitByFunctional(handles, grayView);
for(ii=1:length(newFGs))
    if(~isempty(newFGs(ii).fibers))
        handles = dtiAddFG(newFGs(ii),handles);
    end
end
guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuXform_computeSpatialNormalization_Callback(hObject, eventdata, handles)
% Also has SPM stuff in it that should be coordinated with other SPM calls.

curBgImgNum = dtiGet(handles,'curBgNum');
curBgImgName = handles.bg(curBgImgNum).name;
if(~isfield(handles,'t1NormParams'))
    handles.t1NormParams = [];
end
if(~isempty(handles.t1NormParams))
    bn = questdlg('Normalization exists- what do you want to do?', 'Normalization exists', ...
        'Replace existing transform(s)','Add a new transform','Cancel','Add a new transform');
    if(strcmp(bn, 'Cancel'))
        return;
    elseif(strcmp(bn, 'Replace existing transform(s)'))
        handles.t1NormParams = [];
    else
        if(~isfield(handles.t1NormParams(1),'name'))
            if(length(handles.t1NormParams)>1)
                error('The t1NormParam field is non-standard. You will need to replace it.');
            end
            % fix old t1Norm that was missing a 'name' field
            tmp.name = 'MNI';
            tmp.sn = handles.t1NormParams(1).sn;
            handles.t1NormParams = tmp;
        end
    end
end
spm_defaults;
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
d = dir(fullfile(tdir,'*T1.*'));
[p,f,e1] = fileparts(d(1).name);
[p,f,e2] = fileparts(f);
tsuffix = [e2 e1];
if(strcmpi(curBgImgName, 't1'))
    template = fullfile(tdir, ['MNI_T1' tsuffix]);
elseif(strcmpi(curBgImgName, 'b0'))
    template = fullfile(tdir, ['MNI_EPI' tsuffix]);
elseif(strcmpi(curBgImgName, 'fa'))
    template = fullfile(tdir, ['MNI_FA' tsuffix]);
elseif(strcmpi(curBgImgName, 'vectorRGB'))
    error('Use tensor-based normalization!');
else
    template = fullfile(tdir, ['MNI_T1' tsuffix]);
end
[f,p] = uigetfile({'*.nii;*.nii.gz','NIFTI';'*.img','analyze';'*.mnc','MNC';'*.*','all files'}, 'Load a template', template);
if(isnumeric(f)) disp('User cancelled.'); return; end
template = fullfile(p,f);
us = strfind(f,'_');
if(~isempty(us))
    newXform.name = f(1:us(1)-1);
else
    newXform.name = f;
end
newXform.name = inputdlg('Template name (eg. MNI, SIRL54, etc.):','template name',1,{newXform.name});
if(isempty(newXform.name)) disp('User cancelled.'); return; end
newXform.name = newXform.name{1};
[srcImg, mmPerVoxel, mat] = dtiGetNamedImage(handles.bg, curBgImgName);
if(~isempty(strfind(f,'brain')) && isfield(handles,'brainMask') && ~isempty(handles.brainMask) ...
        && all(size(handles.brainMask)==size(srcImg)))
    disp('Applying brain mask.');
    srcImg(~handles.brainMask) = 0;
end
disp('Normalizing...');
[newXform.sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(srcImg, mat, template);

curSs = strrep(newXform.name,' ','_');
lutFile = fullfile(handles.dataDir,[curSs, '_coordLUT.nii.gz']);
newXform.coordLUT = invDef.coordLUT;
newXform.inMat = invDef.inMat;
intentCode = 1006; % NIFTI_INTENT_DISPVECT=1006
intentName = ['To' curSs];
% NIFTI format requires 4th dim to be time, so we put the deformation vector [x,y,z] in the 5th dim.
tmp = reshape(newXform.coordLUT,[size(newXform.coordLUT(:,:,:,1)) 1 3]);
try
    dtiWriteNiftiWrapper(tmp,inv(newXform.inMat),lutFile,1,'',intentName,intentCode);
    dtiSetFilenameInDT6(handles.dataFile,'lutMNI',lutFile);
catch
    disp('Could not save LUT transform- check permissions.');
end
if(isempty(handles.t1NormParams))
    handles.t1NormParams = newXform;
else
    handles.t1NormParams(end+1) = newXform;
end
handles = dtiSet(handles, 'addStandardSpace', handles.t1NormParams(end).name);
if(strncmp('MNI',handles.t1NormParams(end).name,3))
    labels = dtiGetBrainLabel;
    for(ii=1:length(labels))
        handles = dtiSet(handles, 'addStandardSpace', labels{ii});
    end
end
guidata(hObject, handles);
% WORK HERE: save the norm params in with the t1
[f,p] = uigetfile({'*.mat'}, 'Save normalization params...',handles.dataFile);
if(isnumeric(f)) error('Canceled.'); end
t1NormParams = handles.t1NormParams;
save(fullfile(p,f), 't1NormParams', '-APPEND');
return;

%-------------------------------------------
% Current Fiber Group popup
%
function popupCurrentFiberGroup_CreateFcn(hObject, eventdata, handles)
set(hObject, 'String', {'No Fiber Groups'});
return;

%-------------------------------------------
function popupCurrentFiberGroup_Callback(hObject, eventdata, handles)
% Set current fiber group

% set(hObject,'String',dtiGet(handles,'fgnames'))
handles.curFiberGroup = get(hObject,'Value');

% If Current show mode, adjust the visibility
if (handles.fiberGroupShowMode == 2)
    for ii=1:length(handles.fiberGroups), handles.fiberGroups(ii).visible = 0; end
    handles.fiberGroups(handles.curFiberGroup).visible = 1;
    handles = dtiRefreshFigure(handles, 0);
end

% If we are in All, None, or Choose mode, there is no reason to redisplay.
% Though perhaps we should alert the user in these modes?

guidata(hObject, handles);

return;

%-------------------------------------------
function handles = popupCurrentFiberGroup_Refresh(handles)

if(isempty(handles.fiberGroups)), fgStr = {''};
else    fgStr = {handles.fiberGroups.name};
end
set(handles.popupCurrentFiberGroup,'String', fgStr);

if(handles.curFiberGroup < 1 | handles.curFiberGroup>length(fgStr))
    handles.curFiberGroup = 1;
end
set(handles.popupCurrentFiberGroup,'Value', handles.curFiberGroup);

return;

% --- Executes during object creation, after setting all properties.
function popupFiberShow_CreateFcn(hObject, eventdata, handles)
return;

% --- Executes on selection change in popupFiberShow.
function popupFiberShow_Callback(hObject, eventdata, handles)
% Show:  Fiber Groups, None/Current/All/Choose

% Set all fiber groups to invisible
for ii=1:length(handles.fiberGroups), handles.fiberGroups(ii).visible = 0; end
% Vectorized form:
% [handles.fiberGroups(:).visible] = deal(zeros(size(handles.fiberGroups)));

handles.fiberGroupShowMode = get(hObject,'Value');
if     (handles.fiberGroupShowMode == 4) sList = dtiSelectFGs(handles);
elseif (handles.fiberGroupShowMode == 3) sList = 1:length(handles.fiberGroups);
elseif (handles.fiberGroupShowMode == 2) sList = handles.curFiberGroup;
elseif (handles.fiberGroupShowMode == 1) sList = [];
else
    error('Bad fiber show mode');
end

for ii=sList, handles.fiberGroups(ii).visible = 1; end

handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);

return;

% --- Executes during object creation, after setting all properties.
function popROIShow_CreateFcn(hObject, eventdata, handles)
return;

% --- Executes on selection change in popROIShow.
function popROIShow_Callback(hObject, eventdata, handles)
% Setting None/Current/All/Choose

% Turn them all off
nRois = dtiGet(handles,'numberofrois');
for ii=1:nRois, handles.rois(ii).visible = 0; end

handles.roiShowMode = get(hObject,'Value');
if     (handles.roiShowMode == 4),  sList = dtiSelectROIs(handles);
elseif (handles.roiShowMode == 3),  sList = 1:length(handles.rois);
elseif (handles.roiShowMode == 2),  sList = handles.curRoi;
elseif (handles.roiShowMode == 1),  sList = [];
else   error('Bad select ROI mode');
end

for ii=sList, handles.rois(ii).visible = 1; end

handles = dtiRefreshFigure(handles, 0);
guidata(hObject,handles);

return;

%% Seems obsolete
function [x,y,z] = getFrames(handles)

axes(handles.x_cut);
%truesize;
f = getframe(handles.x_cut);
x = f.cdata;

axes(handles.y_cut);
%truesize;
f = getframe(handles.y_cut);
y = f.cdata;

axes(handles.z_cut);
%truesize;
f = getframe(handles.z_cut);
z = f.cdata;
return;

%% View | mrMesh Settings
function menuMrMesh_Callback(hObject, eventdata, handles)
return;

%% View | mrMesh Settings | Close Window
function menuMrMeshCloseWindow_Callback(hObject, eventdata, handles)
imageMesh = handles.mrMesh;
[tmp,foo,val] = mrMesh(imageMesh.host,imageMesh.id,'close');
return;

%% View | mrMesh Settings | Window Size
function menuMrMeshWindowSize_Callback(hObject, eventdata, handles)
% Get the current mesh, window id, and so forth
msh = handles.mrMesh;

prompt={'Enter window size'}; def={num2str([512,512])}; dlgTitle='Set Window Size'; lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);
if isempty(answer), return;
else sz = str2num(answer{1}); end

mrmSet(msh,'windowSize',sz(1),sz(2));

return;

% --------------------------------------------------------------------
function menuMrMeshHideCursor_Callback(hObject, eventdata, handles)
% Turn off (or on) the cursor display

currentState = get(handles.menuMrMeshHideCursor,'Checked');

switch (lower(currentState))
    case 'on'
        set(handles.menuMrMeshHideCursor,'Checked','off');
        curon = 1;
    case 'off'
        set(handles.menuMrMeshHideCursor,'Checked','on');
        curon = 0;
    otherwise
        error('Bad check state');
end

if(curon==1) mrmSet(handles.mrMesh, 'cursoron');
else mrmSet(handles.mrMesh, 'cursoroff'); end

if(isfield(handles, 'mrVistaMesh') && ~isempty(handles.mrVistaMesh))
    for(ii=1:length(handles.mrVistaMesh.meshes))
        if(curon==1)
            mrmSet(handles.mrVistaMesh.meshes(ii), 'cursoron');
        else
            mrmSet(handles.mrVistaMesh.meshes(ii), 'cursoroff');
        end
    end
end

guidata(hObject,handles);
return;

% --------------------------------------------------------------------
function menuMrMeshGetCamPos_Callback(hObject, eventdata, handles)
msh = handles.mrMesh;
cRot = mrmGet(msh,'camerarotation');
fprintf('Current camera rotation:\n------------------\n');
cRot

% Store the camera rotation in the window data
handles.cameraRotation = cRot;
guidata(hObject,handles);

return;

% --------------------------------------------------------------------
function menuMrMeshSetCamPos_Callback(hObject, eventdata, handles)
% Set the camera rotation

msh = handles.mrMesh;

% if camera rotation is stored, use it.  Otherwise use the one in the
% window at this moment.
if checkfields(handles,'cameraRotation'), cRot = handles.cameraRotation;
else cRot = mrmGet(msh,'camerarotation'); end

% Read the one the user wants.  Might be a better way to enter?
cRot = ieReadMatrix(cRot);

% Set it in the display
mrmSet(msh,'camerarotation',cRot);

return;

% --------------------------------------------------------------------
function handles = menuRois_syncCurWithMrMesh_Callback(hObject, eventdata, handles)
% ROIs | Sync current ROI with Mesh
if(~isfield(handles.rois(handles.curRoi), 'mesh') | isempty(handles.rois(handles.curRoi).mesh) )
    warning('Current ROI has no mesh.');
    return;
end

p.actor = handles.rois(handles.curRoi).mesh.actor;
p.get_origin = 1;
[id,s,r] = mrMesh(handles.mrMesh.host, handles.mrMesh.id, 'get', p);
coordOffset = handles.rois(handles.curRoi).mesh.origin - r.origin;
handles.rois(handles.curRoi).mesh.origin = r.origin;
for(ii=1:3)
    handles.rois(handles.curRoi).coords(:,ii) = handles.rois(handles.curRoi).coords(:,ii) - coordOffset(ii);
end
handles = dtiRefreshFigure(handles, 0);
guidata(hObject, handles);

return;


% --------------------------------------------------------------------
function mrMeshInit_Callback(hObject, eventdata, handles)
% View | mrMesh Settings | Window Initialize
if checkfields(handles,'mrMesh')
    handles.mrMesh = dtiInitMrMeshWindow(handles.mrMesh);
else
    warndlg('No mesh structure created.');
end
guidata(hObject,handles);
return;


% --------------------------------------------------------------------
function menuMrMeshTubesLines_Callback(hObject, eventdata, handles)

% We set a flag to indicate whether to render with Tubes or polylines.
% We could do this for each individual fiber tract.  But for now,
% let's just set one global flag.

nGroups = length(handles.fiberGroups);
if nGroups == 0, disp('No fiber groups'); return; end

currentState = get(handles.menuMrMeshTubesLines,'Checked');
switch (lower(currentState))
    case 'on'
        set(handles.menuMrMeshTubesLines,'Checked','off');
        thickSign = -1;
    case 'off'
        set(handles.menuMrMeshTubesLines,'Checked','on');
        thickSign = 1;
        
    otherwise
        error('Bad check state');
end

% Set the sign of all fiber groups appropriately
for ii=1:nGroups
    handles.fiberGroups(ii).thickness = ...
        thickSign*abs(handles.fiberGroups(ii).thickness);
end
guidata(hObject,handles); return;

return;

% --------------------------------------------------------------------
function menuMrMeshWindowID_Callback(hObject, eventdata, handles)
% View | mrMesh Settings | Window ID
if checkfields(handles,'mrMesh')
    v = ieReadNumber('Enter mrMesh window ID');
    if isempty(v), disp('Set window canceled.'); return;
    else handles.mrMesh = meshSet(handles.mrMesh,'windowID',v);
    end
end
guidata(hObject,handles);
return;

% --------------------------------------------------------------------
function mrMeshAddLights_Callback(hObject, eventdata, handles)
if checkfields(handles,'mrMesh')
    handles.mrMesh = dtiAddLights(handles.mrMesh);
else
    warndlg('No mesh structure created.');
end
guidata(hObject,handles);
return;


% --------------------------------------------------------------------
function menuEditTransparency_Callback(hObject, eventdata, handles)
% mrMesh transparency parameter for the image planes.

if checkfields(handles,'mrMesh','transparency'), d = handles.mrMesh.transparency;
else d = 1; end

t = ieReadNumber('Enter image transparency',d);
if isempty(t), disp('Set image transparency canceled.'); return;
else handles.mrMesh.transparency = t; end

guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuEditInitMesh_Callback(hObject, eventdata, handles)
handles.mrMesh = dtiMrMeshInit(174);
guidata(hObject, handles);
return;

% --------------------------------------------------------------------
function menuMrMeshBackColor_Callback(hObject, eventdata, handles)

msh = handles.mrMesh;

c = ieReadMatrix('[.3,.3,.4]');
if isempty(c), disp('Set Background Color Canceled.'); return;
else mrmSet(msh,'background',c); end

return;

% --------------------------------------------------------------------
function menuEditReadCursor_Callback(hObject, eventdata, handles)
p.actor = 1;
[id,stat,res] = mrMesh(handles.mrMesh.host, handles.mrMesh.id, 'get_selection', p);
acpcCoord = res.position;
setPositionAcPc(handles,acpcCoord);
return;

%------------------------------------------------
% function showTheseRois = selectROIs(handles);
% disp('selectROIs for visibility not yet implemented.');
% return;


function figure1_CloseRequestFcn(hObject, eventdata, handles)
try
    if(isempty(handles.rois) & isempty(handles.fiberGroups))
        delete(hObject);
        return;
    end
    r = questdlg('Are you sure you want to close? Unsaved ROIs and fibers will be lost!',...
        'Confirm Close', 'Yes','No','Yes');
    if(strcmp(r,'Yes'))
        delete(hObject);
    else
        disp('Close canceled.');
    end
catch
    % Hint: delete(hObject) closes the figure
    delete(hObject);
end
return;


% --------------------------------------------------------------------
function menuView_dtiQuery_Callback(hObject, eventdata, handles)
return;

function [acpcTranslation] = getACPCTranslation (handles)
xform = inv(dtiGet(handles, 'dt6toacpcxform'));
acpcTranslation = [xform(1,4)/xform(1,1) xform(2,4)/xform(2,2) xform(3,4)/xform(3,3)];
return;

% --------------------------------------------------------------------
function menuView_dtiQuery_syncRoi_Callback(hObject, eventdata, handles)

[id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'get_roi_ids');

ids = r.roi_id_array;

for roi_id = 1:length(ids)
    p.roi_id = roi_id;
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'sync_roi', p);
    % r.offset_array: offset of corner of bounding box
    % r.image_array: image representing the ROI
    [i, j, k] = ind2sub (size(r.image_array), find(r.image_array));
    roi_coords = [i j k];
    roi_coords = roi_coords+repmat (r.offset_array, [size(roi_coords,1) 1]);
    roi_coords = roi_coords';
    % now need to transform the coords by the AC-PC offset:
    
    roi_coords = roi_coords - repmat((getACPCTranslation(handles)+1)', 1, size(roi_coords,2));
    % two cases: ROI already exists, or ROI is new
    if (isempty(handles.rois) == false & find([handles.rois.query_id] == roi_id))
        % already exists
        handles.rois(find([handles.rois.query_id] == roi_id)).coords = roi_coords';
    else
        % new ROI to mrDiffusion
        newRoi = dtiNewRoi (sprintf('DTI-Query ROI #%d',roi_id), [], roi_coords');
        newRoi.query_id = roi_id;
        handles = dtiAddROI (newRoi,handles);
    end;
end;

handles = dtiRefreshFigure(handles,0);
guidata(hObject, handles);
return;

% r holds the roi offset. we compare the roi offset to the current bounding
% box to figure out how to move the roi? this assumes that the roi is one
% we created using mrDiffusion - what if we created the ROI in DTI-Query?
% then we will actually need to send an image over... is this kind of thing
% done elsewhere in mrDiffusion? can i just return a 3-D array of values?
% i would have to be able to compute this array for any ROI i created... which
% means being able to tell what parts are inside and which parts are outside.
% i can do this for cubes and spheres... but not for arbitrarily scaled
% versions of things that mrDiffusion has created.

% r.offset: offset of ROI
% r.image: image for ROI - 1's where inside, 0's outside

function queryID = dtiQuerySendRoi (roi, handles, hObject)

% first translate our ROI to "anatomical" coordinates used by DTI-Query
% the units are still millimeters, but (0,0,0) corresponds to the voxel
% origin (1,1,1) in matlab

%anatSpaceCoords = roi.coords + repmat(getACPCTranslation(handles)-1, size(roi.coords,1), 1);
anatSpaceCoords = roi.coords - repmat([1 1 1], size(roi.coords,1), 1);

% Remove any duplicate coordinates:
anatSpaceCoords = unique (round(anatSpaceCoords), 'rows');

% We will send the ROI as an image positioned at the min-corner
% of its bounding box:
p.roi_origin = min(anatSpaceCoords(:,:));

% subtract off origin to get coords relative to origin:
anatSpaceCoords = anatSpaceCoords - repmat (p.roi_origin, [rows(anatSpaceCoords) 1])+1;

% Calculate the bounding box of the ROI, overestimating a little to be safe:
bb = [repmat(0,[3 1]) max(anatSpaceCoords(:,:))'+5]; % xxx dla voxel dimensions

% Now initialize an image covering the bounding box:
p.voxels = zeros([diff(bb')+1]);
inds = sub2ind(size(p.voxels), ...
    anatSpaceCoords(:,1), ...
    anatSpaceCoords(:,2), ...
    anatSpaceCoords(:,3));

% And fill it in with 1's wherever we are inside the ROI:
p.voxels(inds) = 1;
p.roi_origin = p.roi_origin';
if (roi.query_id >= 0)
    p.query_id = roi.query_id; % the query_id field uniquely identifies an ROI in DTI-Query
end

% Make sure these are column vectors
if roi.color == 'y'
    p.color=[1 1 0]'; p.opacity = 0.75;
else if roi.color == 'k'
        p.color=[0 0 0]'; p.opacity = 0.75;
    else if roi.color == 'w'
            p.color=[1 1 1]'; p.opacity = 0.75;
        else if roi.color == 'b'
                p.color=[0 0 1]'; p.opacity = 0.75;
            else if roi.color == 'g'
                    p.color=[0 1 0]'; p.opacity = 0.75;
                else if roi.color == 'r'
                        p.color=[1 0 0]'; p.opacity = 0.75;
                    else if roi.color == 'c'
                            p.color=[0 1 1]'; p.opacity = 0.75;
                        else if roi.color == 'm'
                                p.color=[1 0 1]'; p.opacity = 0.75;
                            else if(length(roi.color)==3)
                                    p.color=roi.color(1:3); p.color = p.color(:); p.opacity=0.75;
                                else
                                    p.color = roi.color(1:3); p.color = p.color(:); p.opacity = roi.color(4);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


% Smoothing parameters
p.do_smooth_pre = 1;
p.do_deimate = 0;
p.do_smooth = 0;
p.name = roi.name;

% Use mrMesh function to send the ROI coordinates to DTI-Query:
[id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'push_roi', p);

% update the query_id field to reflect the id in DTI-Query:
queryID = r.query_id;

return;

% Sends all ROIs to Quench...
function queryID = quenchSendRoi (roi, handles, hObject)

% ROI coordinates are already in anatomical space.
anatSpaceCoords = roi.coords;

% Remove any duplicate coordinates:
anatSpaceCoords = unique (round(anatSpaceCoords), 'rows');

% We will send the ROI as an image positioned at the min-corner
% of its bounding box:
p.roi_origin = min(anatSpaceCoords(:,:));

% subtract off origin to get coords relative to origin:
anatSpaceCoords = anatSpaceCoords - repmat (p.roi_origin, [rows(anatSpaceCoords) 1])+1;

% Calculate the bounding box of the ROI, overestimating a little to be safe:
bb = [repmat(0,[3 1]) max(anatSpaceCoords(:,:))'+5]; % xxx dla voxel dimensions

% Now initialize an image covering the bounding box:
p.voxels = zeros([diff(bb')+1]);
inds = sub2ind(size(p.voxels), ...
    anatSpaceCoords(:,1), ...
    anatSpaceCoords(:,2), ...
    anatSpaceCoords(:,3));

% And fill it in with 1's wherever we are inside the ROI:
p.voxels(inds) = 1;
p.roi_origin = p.roi_origin';
if (roi.query_id >= 0)
    p.query_id = roi.query_id; % the query_id field uniquely identifies an ROI in Quench
end

% Make sure these are column vectors
if roi.color == 'y'
    p.color=[1 1 0]'; p.opacity = 0.75;
else if roi.color == 'k'
        p.color=[0 0 0]'; p.opacity = 0.75;
    else if roi.color == 'w'
            p.color=[1 1 1]'; p.opacity = 0.75;
        else if roi.color == 'b'
                p.color=[0 0 1]'; p.opacity = 0.75;
            else if roi.color == 'g'
                    p.color=[0 1 0]'; p.opacity = 0.75;
                else if roi.color == 'r'
                        p.color=[1 0 0]'; p.opacity = 0.75;
                    else if roi.color == 'c'
                            p.color=[0 1 1]'; p.opacity = 0.75;
                        else if roi.color == 'm'
                                p.color=[1 0 1]'; p.opacity = 0.75;
                            else if(length(roi.color)==3)
                                    p.color=roi.color(1:3); p.color = p.color(:); p.opacity=0.75;
                                else
                                    p.color = roi.color(1:3); p.color = p.color(:); p.opacity = roi.color(4);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


% Smoothing parameters
p.do_smooth_pre = 1;
p.do_deimate = 0;
p.do_smooth = 0;
p.name = roi.name;

% Use mrMesh function to send the ROI coordinates to Quench:
[id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'push_roi', p);

% Quench returns the "ID" of the ROI. We use this to determine whether to
% add a new ROI, or update an existing one (the next time a push is
% requested).
qidStruct = typecast( uint8(r),'single');

% update the query_id field to reflect the id in Quench:
queryID = qidStruct(1);

return;

% --------------------------------------------------------------------
function menuView_dtiQuery_pushRois_Callback(hObject, eventdata, handles)
%roi = handles.rois(handles.curRoi);
for roiNum = 1:length(handles.rois)
    %roi = handles.rois(roiNum);
    handles.rois(roiNum).query_id = dtiQuerySendRoi (handles.rois(roiNum), handles, hObject);
    guidata(hObject, handles);
end;
return;


% --------------------------------------------------------------------
function menuView_quench_pushRois_Callback(hObject, eventdata, handles)
%roi = handles.rois(handles.curRoi);
for roiNum = 1:length(handles.rois)
    %roi = handles.rois(roiNum);
    handles.rois(roiNum).query_id = quenchSendRoi (handles.rois(roiNum), handles, hObject);
    guidata(hObject, handles);
end;
return;
% ----------------------------------
function addMissingParamFields(p)
if ~isfield(p,'ile')
    p.ile = 0;
end
if ~isfield(p,'icpp')
    p.icpp = 0;
end
if ~isfield(p,'ivs')
    p.ivs = 0;
end
if ~isfield(p,'stat')
    p.stat = [];
end
return;

%--------------------------------------------
function pinfo=addDummyPathwayInfo(fgm, numfibers,numstats)
if ~isfield(fgm,'pathwayInfo') || size(fgm.pathwayInfo,1) == 0
    fgm.pathwayInfo = struct('algo_type', zeros(numfibers,1), ...
        'seed_point_index', ones(numfibers,1), 'pathStat',zeros(numfibers,1),'point_stat_array',zeros(numfibers,1));
end
if ~isfield(fgm.pathwayInfo(1),'pathStat')
    [fgm.pathwayInfo(:).pathStat]=deal(0);
    %[fgm.pathwayInfo(:).pathStat]=0;
end
if ~isfield(fgm.pathwayInfo(1),'point_stat_array')
    for i = 1:numfibers
        fgm.pathwayInfo(i).point_stat_array=zeros(numstats,length(fgm.fibers{i}));
    end
    %[fgm.pathwayInfo(:).point_stat_array]=deal(zeros(numstats,100));%assuming a maximum of 100 fibers per element
end
pinfo=fgm.pathwayInfo;
return;

% --------------------------------------------------------------------
function menuView_CINCH_pushPaths_Callback(hObject, eventdata, handles)
if (length(handles.fiberGroups) == 0)
    warndlg('No fiber groups to push.');
    return;
end;


if (~cinchCheckServer())
    r = questdlg ('CINCH is not running. Would you like to start it?');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    cinchStart();
    pause(1);
    p = struct();
    p.datapath = [handles.dataDir filesep 'bin'];
    if ~cinchGenerateData (handles.dataFile, p.datapath)
        disp ('Canceled.');
        return;
    end;
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'set_datapath', p);
    % Set the data directory
else
    r = questdlg('Are you sure you want to push fibers? All fibers will be overwritten in CINCH!',...
        'Confirm Push', 'Yes','No','Yes');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    % CINCH is already running
    p = struct();
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'get_datapath', p);
    CINCH_datapath = r.datapath;
    if (~strcmp (CINCH_datapath, [handles.dataDir filesep 'bin']) || strcmp (CINCH_datapath, '[none]'))
        disp ('Refreshing CINCH data...');
        p.datapath = [handles.dataDir filesep 'bin'];
        if ~cinchGenerateData (handles.dataFile, p.datapath)
            disp ('Canceled.');
            return;
        end;
        [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'set_datapath', p);
    end;
end;

pathIndices = [];
pathCoords = [];
for fgNum = 1:length(handles.fiberGroups)
    fg = handles.fiberGroups(fgNum);
    %p.pathIndices = fg.fibers
    for pathNum = 1:length(fg.fibers)
        pathIndices = [pathIndices length(fg.fibers{pathNum})];
        %pathCoords = [pathCoords fg.fibers{pathNum}];
    end;
    pathCoords = [pathCoords horzcat(fg.fibers{:})];
end;
p.pathIndices = pathIndices';
p.pathCoords = pathCoords';
% first send whole paths database
[id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'push_paths', p);
pathCount = 0;

for fgNum = 1:length(handles.fiberGroups)
    fg = handles.fiberGroups(fgNum);
    numPaths = length(handles.fiberGroups(fgNum).fibers);
    p = struct();
    p.assignment_min = pathCount;
    p.assignment_max = pathCount+numPaths;
    p.visible = fg.visible;
    p.color = fg.colorRgb';
    p.name = fg.name;
    if (~isfield(fg, 'query_id'))
        fg.query_id = -1;
    end;
    if (fg.query_id ~= -1)
        p.query_id = fg.query_id;
    end;
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'push_fg_info', p);
    handles.fiberGroups(fgNum).query_id = r.query_id;
    pathCount = pathCount + numPaths;
end;
guidata(hObject, handles);

return;

% --------------------------------------------------------------------
function menuView_CINCH_getPaths_Callback(hObject, eventdata, handles)
% handles.fiberGroups(handles.curFiberGroup).fibers
if (~cinchCheckServer())
    warndlg ('CINCH is not running. Cannot get pathways.');
    return;
end;
r = questdlg('Are you sure you want to pull fibers? Fiber groups may be overwritten!',...
    'Confirm Pull', 'Yes','No','Yes');
if(~strcmp(r,'Yes'))
    disp('Get paths canceled.');
    return;
end;

[id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'get_fg_ids');

ids = r.fg_id_array;
if (~isempty(handles.fiberGroups))
    known_group_ids = find ([handles.fiberGroups.query_id] ~= -1);
    known_query_ids = [];
    for groupNum = 1:length(known_group_ids)
        known_query_ids(groupNum) = handles.fiberGroups(known_group_ids(groupNum)).query_id;
    end;
    toDelete = sort(known_group_ids(~ismember (known_query_ids, ids)), 2, 'descend');
    for deleteIndex = 1:length(toDelete)
        fprintf ('Deleting fg %d\n', toDelete(deleteIndex));
        handles = dtiDeleteFG(toDelete(deleteIndex), handles);
    end;
end;
for fg_index = 1:length(ids)
    p.fg_id = ids(fg_index);
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'get_fg', p);
    
    %[id, s, r] = mrMesh([handles.mrMesh.host, ':4000'], handles.mrMesh.id, 'get_paths');
    
    % "r" holds the paths
    % r.color 1D array: [r, g, b]
    % r.visible - 1 if visible, 0 otherwise.
    % r.points - 2D array: point #, vert #
    % r.pathIndices - 1D array: for each path, # of verts
    % will need to transform into path structure, and make a new fiber
    % group.
    if (isempty(handles.fiberGroups) == false & find([handles.fiberGroups.query_id] == p.fg_id))
        % seen this one before
        fGroup = handles.fiberGroups(find([handles.fiberGroups.query_id] == p.fg_id));
        fGroup.fibers = [];
        fprintf ('Seen this fiber group before: %d\n', p.fg_id);
        addFG = false;
    else
        fGroup = dtiNewFiberGroup (['FG ' int2str(ids(fg_index))]);
        fGroup.query_id = p.fg_id;
        addFG = true;
    end;
    fGroup.colorRgb = r.color;
    fGroup.visible = r.visible;
    startIndex = 1;
    % plus 1 is for matlab 1-indexing.
    % no longer need to convert - paths are all in AC-PC space to begin with...
    %r.points = r.points - repmat((getACPCTranslation(handles)+1)', 1, size(r.points,2));
    for i = 1:length(r.pathIndices)
        fGroup.fibers{i,1} = r.points(:,startIndex:startIndex+r.pathIndices(i)-1);
        startIndex = startIndex + r.pathIndices(i);
    end;
    if (addFG)
        [handles,blah] = dtiAddFG (fGroup, handles);
    else
        handles.fiberGroups(find([handles.fiberGroups.query_id] == p.fg_id)) = fGroup;
    end;
    % handles.fiberGroups{length(handles.fiberGroups)+1} = fGroup;
end;
handles = dtiRefreshFigure(handles,0);
guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuHelp_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuHelp_about_Callback(hObject, eventdata, handles)
helpdlg('mrDiffusion: Bob Dougherty and many others in the VISTA LAB at - Stanford University.', 'About');
return;

% --------------------------------------------------------------------
function menuHelp_userGuide_Callback(hObject, eventdata, handles)
% helpdlg('Please visit http://white.stanford.edu/newlm/index.php/MrDiffusion', 'User Guide Info');
disp('User guide: http://white.stanford.edu/newlm/index.php/MrDiffusion');
web('http://white.stanford.edu/newlm/index.php/MrDiffusion','-browser')
return;

% --------------------------------------------------------------------
function menuFile_mrfInit_Callback(hObject, eventdata, handles)
expName = '';
handles.mrfiles = mrfInit(handles.mrfiles, handles.subName, expName);
guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuFile_SaveRois_Callback(hObject, eventdata, handles)
% see mrLoadRet-3.0/ROIs/roiSaveHdf5
roi = dtiGet(handles,'curroi');
pathStr = ['/ROIs/', roi.name];
handles.mrfiles = mrFilesSet(handles.mrfiles, 'path', pathStr);
[handles.mrfiles, savePos] = mrfPos(handles.mrfiles, 'new');
saveFlag = 'Yes';
% This could have some additional 'noninteractive' condition
if savePos > 0
    saveFlag = questdlg(['ROI "',roi.name,'" already exists.  New Version?'], ...
        'Save ROI','Yes','No','No');
    if strcmp(saveFlag, 'No'), return; end
end
if strcmp(saveFlag, 'Yes')
    disp(['Saving ROI "',roi.name,'".']);
    % It's easy to add or overwrite metadata here
    %roi.subject = sessionGet(mrSESSION, 'subject');
    %roi.expTitle = sessionGet(mrSESSION,'title');
    mrfSaveHdf5(handles.mrfiles, roi, 'coords');
else
    disp('ROI not saved.');
end
return;

% --------------------------------------------------------------------
function menuFile_LoadRois_Callback(hObject, eventdata, handles)
% see mrLoadRet-3.0/ROIs/roiLoadHdf5
return;


% --------------------------------------------------------------------
function menuFile_mrFileCommit_Callback(hObject, eventdata, handles)
mrfCommit(handles.mrfiles);
return;


% --------------------------------------------------------------------
function menuAnalyze_CurPosMenu_Callback(hObject, eventdata, handles)
return;

% ---- Move this function out, gift it a better name.
function handles = loadRawAdc(handles)
% Why is this function here?  It has good functionality.  It reads the raw
% data, the bvecs and the bvals all at once.  That's nice.  Shouldn't it be
% a main function that we call a lot?

% Use mrvSelectFigure
if(~isfield(handles,'adcNi'))
    [p,f,e] = fileparts(handles.dataFile);
    if(length(f)==3), f = 'rawDti';
    elseif(length(f)>4), f = f(1:end-4);
    end
    
    rawFname = fullfile(p,'raw',[f '.nii.gz']);
    if(~exist(rawFname,'file')), rawFname = fullfile(p,[f '.nii.gz']); end
    if(~exist(rawFname,'file'))
        [f,p] = uigetfile('*.nii;*.nii.gz', 'Select raw NIFTI file...', rawFname);
        if(isnumeric(f)) disp('User canceled'); return; end
        rawFname = fullfile(p,f);
    end
    
    handles.adcNi = niftiRead(rawFname);
end

[p,f,e] = fileparts(handles.adcNi.fname); [junk,f] = fileparts(f);

% Read the bvecs file
if(~isfield(handles.adcNi,'bvecs'))
    bvecsFname = fullfile(p,[f '.bvecs']);
    if(~exist(bvecsFname,'file'))
        [f,p] = uigetfile('*.*', 'Select bvecs file...', bvecsFname);
        if(isnumeric(f)), disp('User canceled'); return; end
        bvecsFname = fullfile(p,f);
    end
    
    handles.adcNi.bvecs = dlmread(bvecsFname,' ');
end

% Read the bvals file
if(~isfield(handles.adcNi,'bvals'))
    bvalsFname = fullfile(p,[f '.bvals']);
    if(~exist(bvalsFname,'file'))
        [f,p] = uigetfile('*.*', 'Select bvals file...', bvalsFname);
        if(isnumeric(f)), disp('User canceled'); return; end
        bvalsFname = fullfile(p,f);
    end
    handles.adcNi.bvals = dlmread(bvalsFname,' ')./handles.adcScale;
end

return;

% --------------------------------------------------------------------
function menuAnalyze_roiAdcEllipsoid_Callback(hObject, eventdata, handles)
roi = dtiGet(handles,'currentRoi');
if(isempty(roi))
    disp('No ROIs! Using current position...');
    roi.coords = dtiGet(handles,'AcPcPos');
    roi.name = sprintf('acpc=[%0.0f %0.0f %0.0f]',roi.coords);
end
coords = unique(round(mrAnatXformCoords(inv(handles.xformToAcpc), roi.coords)),'rows');
figHandle = dtiRenderAdcEllipsoids(handles.dt6, coords, roi.name, 'diffusionEllipsoid');
%handles = loadRawAdc(handles);
%figHandle = dtiRenderAdcEllipsoids(handles.adcNi, handles.adc_bvecs, roi.coords, roi.name, 'd');
guidata(hObject, handles);
return;


% --------------------------------------------------------------------
function menuAnalyze_roiAdcProfile_Callback(hObject, eventdata, handles)
roi = dtiGet(handles,'currentRoi');
if(isempty(roi))
    disp('No ROIs! Using current position...');
    roi.coords = dtiGet(handles,'AcPcPos');
    roi.name = sprintf('acpc=[%0.0f %0.0f %0.0f]',roi.coords);
end
handles = loadRawAdc(handles);
if isempty(handles), disp('User canceled'); return; end

coords = unique(round(mrAnatXformCoords(handles.adcNi.qto_ijk, roi.coords)),'rows');
figHandle = dtiRenderAdcEllipsoids(handles.adcNi, coords, roi.name, 'adcProfile');
guidata(hObject, handles);

return;

function menuViewBackgroundType_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuView_CINCH_Callback(hObject, eventdata, handles)
return;


%% Quench callbacks  
% Quite a mess.  We should get ready of all that Ver 2 stuff.
% We should pull out the main function from here.  It is very long and
% could be useful in a script.  Someone thought they should add 1000 lines
% of code here.  Sigh.
function menuView_quench_Callback(hObject, eventdata, handles)
% hObject    handle to menuView_quench (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return;

function menuView_quench_getPathsVer2_Callback(hObject, eventdata, handles)
menuView_quench_getPaths_Callback(hObject, eventdata, handles, 2);
return;

function menuView_quench_pushPathsVer2_Callback(hObject, eventdata, handles)
menuView_quench_pushPaths_Callback(hObject, eventdata, handles, 2);
return;

function menuView_quench_getPathsVer3_Callback(hObject, eventdata, handles)
menuView_quench_getPaths_Callback(hObject, eventdata, handles, 3);
return;

function menuView_quench_pushPathsVer3_Callback(hObject, eventdata, handles)
menuView_quench_pushPaths_Callback(hObject, eventdata, handles, 3);
return;


% --------------------------------------------------------------------
function menuView_quench_getPaths_Callback(hObject, eventdata, handles, version)
% hObject    handle to menuView_quench_getPaths (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles.fiberGroups(handles.curFiberGroup).fibers
if (~quenchCheckServer())
    warndlg ('Quench is not running. Cannot get pathways.');
    return;
end;
r = questdlg('Are you sure you want to pull fibers? Fiber groups may be overwritten!',...
    'Confirm Pull', 'Yes','No','Yes');
if(~strcmp(r,'Yes'))
    disp('Get paths canceled.');
    return;
end;

[id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'get_fg_ids');


%% plugin code for version 3
if version == 3
    % round of to the nearest 8 byte boundary
    a = int32(length(r)/8)*8;
    l = length(r);
    if a ~= l
        r(1, l:a)=zeros(1,a-l);
    end
    
    fg_info = typecast( uint8(r),'single');
    
    pos = 1;
    num_fibers = fg_info(pos);
    r.mapping = fg_info(2:num_fibers+1);
    pos = num_fibers+2;
    num_unique_fg = fg_info(pos); pos = pos+1;
    r.fg_id_array = zeros(1, num_unique_fg);
    r.color_array= zeros(1, num_unique_fg*3);
    r.visible_array = zeros(1, num_unique_fg);
    
    for i = 1:num_unique_fg;
        r.fg_id_array(i)           = fg_info(pos); pos = pos+1;
        r.visible_array(i)         = fg_info(pos); pos = pos+1;
        r.color_array( (i-1)*3+1 ) = fg_info(pos); pos = pos+1;
        r.color_array( (i-1)*3+2 ) = fg_info(pos); pos = pos+1;
        r.color_array( (i-1)*3+3 ) = fg_info(pos); pos = pos+1;
        
        % Ignore the name for now
        dummy = fg_info(pos); pos = pos+1 + dummy;
    end
    % end plugin code for version 3
end
%%

ids = r.fg_id_array;
if (~isempty(handles.fiberGroups))
    known_group_ids = find ([handles.fiberGroups.query_id] ~= -1);
    known_query_ids = [];
    for groupNum = 1:length(known_group_ids)
        known_query_ids(groupNum) = handles.fiberGroups(known_group_ids(groupNum)).query_id;
    end;
    toDelete = sort(known_group_ids(~ismember (known_query_ids, ids)), 2, 'descend');
    for deleteIndex = 1:length(toDelete)
        fprintf ('Deleting fg %d\n', toDelete(deleteIndex));
        handles = dtiDeleteFG(toDelete(deleteIndex), handles);
    end;
end;


p.fg_id = 0;%ids(fg_index);
[id, s, r2] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'get_fg', p);

if (~exist('xform','var') || isempty(xform))
    xform = eye(4);
end
mt = dtiLoadMetrotracPathsFromStr(r2,xform);
%[id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'get_paths');

for fg_index = 1:length(ids)
    
    p.fg_id = ids(fg_index);
    
    % r.color_array 1D array: [r, g, b] tuples
    % r.visible_array - 1 if visible, 0 otherwise.
    % will need to transform into path structure, and make a new fiber
    % group.
    if (isempty(handles.fiberGroups) == false & find([handles.fiberGroups.query_id] == p.fg_id))
        % seen this one before
        fGroup = handles.fiberGroups(find([handles.fiberGroups.query_id] == p.fg_id));
        fGroup.fibers = [];
        fprintf ('Seen this fiber group before: %d\n', p.fg_id);
        addFG = false;
    else
        fGroup = dtiNewFiberGroup (['FG ' int2str(ids(fg_index))]);
        fGroup.query_id = p.fg_id;
        addFG = true;
    end;
    fGroup.pathwayInfo = mt.pathwayInfo;
    fGroup.colorRgb = r.color_array((fg_index-1)*3+1:fg_index*3);
    fGroup.visible = r.visible_array(fg_index);
    startIndex = 1;
    % plus 1 is for matlab 1-indexing.
    % no longer need to convert - paths are all in AC-PC space to begin with...
    %r.points = r.points - repmat((getACPCTranslation(handles)+1)', 1, size(r.points,2));
    fGroup.pathwayInfo(:)=[];
    for i = 1:length(mt.pathways)
        if r.mapping(i) == ids(fg_index)
            fGroup.fibers{end+1,1}=mt.pathways{i,1};
            fGroup.pathwayInfo(end+1)=mt.pathwayInfo(i);
        end
    end;
    
    if isfield(mt,'statHeader')
        % If mt has stats info then add that too
        for ss = 1:length(mt.statHeader)
            statstruct.name = mt.statHeader(ss).agg_name;
            statstruct.uid=mt.statHeader(ss).uid;
            statstruct.ile=mt.statHeader(ss).is_luminance_encoding;
            statstruct.icpp=mt.statHeader(ss).is_computed_per_point;
            statstruct.ivs=mt.statHeader(ss).is_viewable_stat;
            statstruct.agg=mt.statHeader(ss).agg_name;
            statstruct.lname=mt.statHeader(ss).local_name;
            for pp = 1:length(mt.pathwayInfo)
                statstruct.stat(pp) = mt.pathwayInfo(pp).pathStat(ss);
            end
            mt.params{ss} =  statstruct;
        end
    end
    
    if isfield(mt,'params')
        fGroup.params = mt.params;
        for i = 1:length(fGroup.params)
            fGroup.params{i}.stat = [];
        end
        for i = 1:length(mt.pathways)
            if r.mapping(i) == ids(fg_index)
                for j = 1:length(fGroup.params)
                    fGroup.params{j}.stat(end+1) = mt.params{j}.stat(i);
                end
            end
        end
    end
    
    if (addFG)
        [handles,blah] = dtiAddFG (fGroup, handles);
    else
        handles.fiberGroups(find([handles.fiberGroups.query_id] == p.fg_id)) = fGroup;
    end;
    % handles.fiberGroups{length(handles.fiberGroups)+1} = fGroup;
end;
handles = dtiRefreshFigure(handles,0);
guidata(hObject, handles);
return;

%% Should be pulled out into quenchPushPaths
function menuView_quench_pushPaths_Callback(hObject, eventdata, handles, version)
% hObject    handle to menuView_quench_pushPaths (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (length(handles.fiberGroups) == 0)
    warndlg('No fiber groups to push.');
    return;
end;

% fg has
%  1. params: array of structures, used as statistic header for a pdb of size numstats
%       string name, int uid, int ile, int icpp,int ivs, string agg,
%       string lname, double *stat[numfibers]
%
%  2. pathwayInfo: array of structures of size numfibers
%       int algo_type, int seed_point_index, double pathStat[numStats],
%       double point_stat_array[num points per fiber]
%
%  3. fibers array of size numfibers
%       double <3x num points per fiber>

% Cases that can arise
% All fibers have proper data
% No fibers have pathwayInfo and params
% 3 fiber cases, 1 means has it 0 means it doesnt
% 1 1 0
% 0 1 1
% 0 0 1
% 0 1 0
% 1 0 0
% 1 0 1
% str = fiberToStr(fgm);
% myf = fopen('merge.pdb','wb');fwrite(myf,str,'uint8');fclose(myf);

fgm = handles.fiberGroups(1);
if (~quenchCheckServer())
    r = questdlg ('Quench is not running. Would you like to start it?');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    quenchStart();
    pause(1);
    p = struct();
    p.datapath = [handles.dataDir filesep 'bin'];
    if ~cinchGenerateData (handles.dataFile, p.datapath)
        disp ('Canceled.');
        return;
    end;
    [id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'set_datapath', p);
    % Set the data directory
else
    r = questdlg('Are you sure you want to push fibers? All fibers will be overwritten in Quench!',...
        'Confirm Push', 'Yes','No','Yes');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    % CINCH is already running
    
    p = struct();
    if version == 2
        [id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'get_datapath', p);
        CINCH_datapath = r.datapath;
        if (~strcmp (CINCH_datapath, [handles.dataDir filesep 'bin']) || strcmp (CINCH_datapath, '[none]'))
            disp ('Refreshing Quench data...');
            p.datapath = [handles.dataDir filesep 'bin'];
            if ~cinchGenerateData (handles.dataFile, p.datapath)
                disp ('Canceled.');
                return;
            end;
            [id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'set_datapath', p);
        end;
    end
end;

% fg has
%  1. params: array of structures, used as statistic header for a pdb of size numstats
%       string name, int uid, int ile, int icpp,int ivs, string agg,
%       string lname, double *stat[numfibers]
%
%  2. pathwayInfo: array of structures of size numfibers
%       int algo_type, int seed_point_index, double pathStat[numStats],
%       double point_stat_array[num points per fiber]
%
%  3. fibers array of size numfibers
%       double <3x num points per fiber>

% This version merges data only if the fibers have matching statistics.
fgm = handles.fiberGroups(1);
fgm.pathwayInfo = addDummyPathwayInfo(fgm, size(fgm.fibers,1),length(fgm.params));
% append all fibers
for fgNum = 2:length(handles.fiberGroups)
    fg = handles.fiberGroups(fgNum);
    numFibers = size(fgm.fibers,1);
    newnumFibers = numFibers + length(fg.fibers);
    % Add the params
    if(size(fgm.params,1)==0 || isfield(fgm,'params')==0)
        fgm.params = fg.params;
    else
        %Make sure that pathwayInfo is not empty, add some dummy data if
        %empty
        fg.pathwayInfo = addDummyPathwayInfo(fg, size(fg.fibers,1),length(fgm.params));
        % Expand the pathwayInfo to incorporate the data
        dummy = fgm.pathwayInfo(1);
        dummy.point_stat_array = [];
        fgm.pathwayInfo(numFibers+1:newnumFibers)=dummy;
        % Add the params
        for i = 1: length(fg.params)
            bParamExist = 0;
            for j = 1:length(fgm.params)
                if(fg.params{i}.uid == fgm.params{j}.uid)
                    bParamExist = 1;
                    fgm.params{j}.stat = [fgm.params{j}.stat  fg.params{i}.stat];
                    addMissingParamFields(fgm.params{j});
                    % add the point_stat_vector to the merged place
                    for k = numFibers+1: newnumFibers
                        fgm.pathwayInfo(k).point_stat_array(j,:)=fg.pathwayInfo(k-numFibers).point_stat_array(i,:);
                    end
                    break;
                end
            end
            %If the param did not exist fill it up with zeros
            if bParamExist == 0
                disp('Fibers dont have matching statistics');
                return;
            end
        end
        
        % Add the params other way around
        for i = 1: length(fgm.params)
            bParamExist = 0;
            for j = 1:length(fg.params)
                if(fg.params{j}.uid == fgm.params{i}.uid)
                    bParamExist = 1;
                    break;
                end
            end
            %If the param did not exist fill it up with zeros
            if bParamExist == 0
                disp('Fibers dont have matching statistics');
                return;
            end
        end
        
    end
    fgm.fibers = [fgm.fibers ; fg.fibers];
end
str = fiberToStr(fgm);
%myf = fopen('mymerge.pdb','wb');fwrite(myf,str,'uint8');fclose(myf);
mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'push_paths', str);


if version == 3
    % compute the total number of paths
    total_paths = 0;
    for fgNum = 1:length(handles.fiberGroups)
        total_paths = total_paths + length(handles.fiberGroups(fgNum).fibers);
    end;
    out = zeros(1, 1+total_paths + 1 + 5*length(handles.fiberGroups));
    
    % store the assignment for each group
    pos = 1;
    out(pos) = total_paths; pos = pos+1;
    for fgNum = 1:length(handles.fiberGroups)
        % get the group id
        fg = handles.fiberGroups(fgNum);
        numPaths = length(handles.fiberGroups(fgNum).fibers);
        if (~isfield(fg, 'query_id'))
            fg.query_id = -1;
        end;
        if (fg.query_id ~= -1)
            group_id = fg.query_id;
        end;
        
        % now store the assignment
        for j = 1:numPaths;
            out(pos) = group_id; pos = pos + 1;
        end
    end;
    out(pos) = length(handles.fiberGroups); pos = pos+1;
    
    % add the fiber group info
    for fgNum = 1:length(handles.fiberGroups)
        fg = handles.fiberGroups(fgNum);
        if (~isfield(fg, 'query_id'))
            fg.query_id = -1;
        end;
        if (fg.query_id ~= -1)
            out(pos) = fg.query_id; pos = pos + 1;
        else
            out(pos) = 0; pos = pos + 1;
        end;
        out(pos) = fg.visible; pos = pos + 1;
        out(pos) = fg.colorRgb(1); pos = pos + 1;
        out(pos) = fg.colorRgb(2); pos = pos + 1;
        out(pos) = fg.colorRgb(3); pos = pos + 1;
        
        % save the name
        out(pos) = length(fg.name); pos = pos + 1;
        for index = 1:length(fg.name)
            out(pos) = fg.name(index); pos = pos + 1;
        end
    end;
    out_buf = typecast ( single(out), 'uint8');
    mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'push_fg_info', out_buf);
    
    
else
    
    
    pathCount = 0;
    for fgNum = 1:length(handles.fiberGroups)
        fg = handles.fiberGroups(fgNum);
        numPaths = length(handles.fiberGroups(fgNum).fibers);
        p = struct();
        p.assignment_min = pathCount;
        p.assignment_max = pathCount+numPaths;
        p.visible = fg.visible;
        p.color = fg.colorRgb';
        p.name = fg.name;
        if (~isfield(fg, 'query_id'))
            fg.query_id = -1;
        end;
        if (fg.query_id ~= -1)
            p.query_id = fg.query_id;
        end;
        [id, s, r] = mrMesh([handles.mrMesh.host, ':4001'], handles.mrMesh.id, 'push_fg_info', p);
        handles.fiberGroups(fgNum).query_id = r.query_id;
        pathCount = pathCount + numPaths;
    end;
    
end;

guidata(hObject, handles);

return;

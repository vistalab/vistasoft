function varargout = mrFlatMesh(varargin)
% MRFLATMESH Application M-file for mrFlatMesh.fig (cortical flattening)
%    
%    FIG = MRFLATMESH launch mrFlatMesh GUI.
%    
%    MRFLATMESH('callback_name', ...) invokes the named callback.
%
% Last Modified by GUIDE v2.5 17-Sep-2009 15:29:36

if (nargin == 0 || iscell(varargin{1}))  % LAUNCH GUI
    
    fig = openfig(mfilename,'reuse');
    
    % Generate a structure of handles to pass to callbacks, and store it. 
    handles = guihandles(fig);
    if(nargin>0 && iscell(varargin{1}))
        % Set the specified defaults
        param = varargin{1};
        for(ii=1:2:length(param))
            if(strcmp(param{ii},'grayPath')) 
                set(handles.inputGrayPath, 'String', param{ii+1});
            end
            if(strcmp(param{ii},'meshPath')) 
                set(handles.inputMeshPath, 'String', param{ii+1});
            end
            if(strcmp(param{ii},'savePath')) 
                set(handles.inputSavePath, 'String',  param{ii+1});
            end
            if(strcmp(param{ii},'startXYZ')) 
                set(handles.editStartX, 'String', num2str(param{ii+1}(1)));
                set(handles.editStartY, 'String', num2str(param{ii+1}(2)));
                set(handles.editStartZ, 'String', num2str(param{ii+1}(3)));
            end
            if(strcmp(param{ii},'unfoldRadiusMM'))
                set(handles.editUnfoldSize, 'String', num2str(param{ii+1}));
            end
            if(strcmp(param{ii},'hemi'))
                hemi = getPopupValue(handles.popHemi,param{ii+1});
                set(handles.popHemi, 'Value',hemi);
            end
        end
    end
    
    guidata(fig, handles);
    
    if (nargout > 0)
        varargout{1} = fig;
    end % endif nargout
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    
%     try
         [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
%     catch
%         disp(lasterr);
%     end % end try/catch
    
end % end function


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.

%-------------------------
function retVar=browseGrayButton_Callback(h,eventData,handles)
%thisFig=gcf;
set (handles.status,'String','Waiting for gray matter segmentation file.');

grayFile = get(handles.inputGrayPath,'String');
if isempty(grayFile), grayFile = meshFindPath(handles); end

[fileName,inputGrayPath]=myUiGetFile(grayFile,{'*.?ray'; '*.mat'},'Get .gray file or coords.mat file');
if fileName == 0, disp('User canceled.'); return; end

set(handles.inputGrayPath,'String',fullfile(inputGrayPath,fileName));    
set (handles.status,'String','Gray file set');
return;

%-------------------------
function retVar=browseMeshButton_Callback(h,eventData,handles)
%thisFig=gcf;
set (handles.status,'String','Waiting for mrGray mesh file *.MrM or *.mrm.');

inputMeshPath = get(handles.inputMeshPath,'String');
if isempty(inputMeshPath), inputMeshPath = meshFindPath(handles); end

[fileName,inputMeshPath]=myUiGetFile(inputMeshPath,{'*.mrm'; '*nii.gz'},'Get mesh file *.MrM or *.mrm or *.nii.gz');
if  fileName == 0, disp('User canceled.'); return; end

set(handles.inputMeshPath,'String',fullfile(inputMeshPath,fileName));
set (handles.status,'String','Mesh file set');
return;

%-------------------------
function retVar=saveMeshFile_Callback(h,eventData,handles)
%thisFig=gcf;
set (handles.status,'String','Setting output path.');

savePath = get(handles.inputSavePath,'String');
if isempty(savePath), savePath = meshFindPath(handles); end

[fileName,outputMeshPath]=myUiPutFile(savePath,'*.mat','Select an output file');
if  fileName == 0, disp('User canceled.'); return; end

set(handles.inputSavePath,'String',fullfile(outputMeshPath,fileName));
set (handles.status,'String','Output path set');
return;

%-------------------------
function retVar=go_Callback(h,eventData,handles)
% Press Go (green) button (Go!)

set (handles.status,'String','Running unfold.');
% Get filenames, coords and unfold size
meshFileName=get(handles.inputMeshPath,'String');
grayFileName=get(handles.inputGrayPath,'String');
flatFileName=get(handles.inputSavePath,'String');

xPos=str2num(get(handles.editStartX,'String'));
yPos=str2num(get(handles.editStartY,'String'));
zPos=str2num(get(handles.editStartZ,'String'));
if isempty(xPos) | isempty(yPos) | isempty(zPos)
    errordlg('You must fill in the starting positions.');
    return;
end
startPos=[xPos,yPos,zPos];

classes = get(handles.popHemi,'String');
hemi = classes{get(handles.popHemi,'value')};

% sagMM=get(handles.editScaleSag,'String');
% axMM=get(handles.editScaleAx,'String');
% corMM=get(handles.editScaleCor,'String');
% scaleFactor=[eval(sagMM),eval(axMM),eval(corMM)];
scaleFactor = [];

unfoldSize=eval(get(handles.editUnfoldSize,'String'));

contents = get(handles.popSpacing,'String'); 
spacingMethod = contents{get(handles.popSpacing,'Value')};
gridSpacing = str2double(get(handles.editGridSpacing,'String'));

showFigures=get(handles.showFiguresCheck,'Value');
saveExtra=get(handles.saveExtraCheck,'Value');
truePerimDist=get(handles.perimDistCheck,'Value');

set(handles.status,'UserData','unfoldMesh v1.7 2001');
% Go, go ,go !!!!
statusHandle=handles.status;
busyHandle=handles.busyBar;
unfoldMeshFromGUI(meshFileName,grayFileName,flatFileName,startPos,scaleFactor,unfoldSize,statusHandle,busyHandle,spacingMethod,gridSpacing,showFigures,saveExtra,truePerimDist,hemi);

return;

%-------------------------
function retVal=cancel_Callback(h,eventData,handles)
% This button actually says Close (in red) on the screen.
close(handles.figure1);
return;


%-------------------------
function retVal=help_Callback(h,eventData,handles)
web1 = 'web([''file:///'' which(''unfoldMeshHelp.html'')],''-browser'')';
web2 = 'web([''file:///'' which(''unfoldMeshHelp.html'')])';

eval(web1,web2);

return;

%-----------------------------------------------
function p = meshFindPath(handles)
% Method for finding the best current path during selection. This
% code is supposed to reduce the amount of clicking around to find files
%

p = get(handles.inputGrayPath,'String');
if ~isempty(p), p=fileparts(p); return;
else p = get(handles.inputMeshPath,'String');
    if ~isempty(p), p=fileparts(p); return;
    else
        p = fileparts(getAnatomyPath('wandell'));
    end
end
return;


% --- Executes during object creation, after setting all properties.
function xaxisX_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;

%-------------------------
function xaxisX_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function xAxisY_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;

%-------------------------
function xAxisY_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function xAxisZ_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;


function xAxisZ_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function xAxisX_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

return;


function xAxisX_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function popSpacing_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;

% --- Executes on selection change in popSpacing.
function popSpacing_Callback(hObject, eventdata, handles)
% Don't do anything.  We read the pop-up when we calculate in the go
% routine above.
return;


% --- Executes during object creation, after setting all properties.
function editGridSpacing_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
return;


function editGridSpacing_Callback(hObject, eventdata, handles)
str2double(get(hObject,'String'));
return;

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function menuFileSaveParams_Callback(hObject, eventdata, handles)
% File |Save
% This should get the handles from the edit boxes and save them to a
% user-chosen matlab file

% something like:
% params = mrfGet(handles,'editFields');
% fullFileName = mrSelectFile('w');
% if isempty(fullFileName), disp('User canceled.'); end
% save(fullFileName,'params');%
%

disp('Not yet implemented')
return

% --------------------------------------------------------------------
function menuFileLoadParams_Callback(hObject, eventdata, handles)
% File | Load Params
% This should read a matlab file containing the editable fields and set
% them.
%
% Inverse of the save above with a 
% handles = mrfSet(handles,'editFields',params);
%
disp('Not yet implemented')
return

% --------------------------------------------------------------------
function menuFileQuit_Callback(hObject, eventdata, handles)
cancel_Callback(hObject,eventdata,handles);
return;


% --------------------------------------------------------------------
function ii = getPopupValue(h,target)
% Given a handle to a popup, h, find the value
str = get(h,'String');
if ~iscell(str)  % Only one term
    if strcmpi(str,target), ii = 1; return; end
else
    for ii=1:length(str)
        if strcmpi(str{ii},target)
            return;
        end
    end
end

% Returns a safe value, but maybe it should be null?
ii = 1;
return;
function varargout = rendergui(varargin)
% This function creates a GUI in which a patch model can be 
% rotated, zoomed and translated with the mouse
%
% rendergui(FV);
%
% inputs,
%	FV : The patch structure, see renderpatch.m
% 
% Function is written by D.Kroon University of Twente (April 2009)


% Edit the above text to modify the response to help rendergui

% Last Modified by GUIDE v2.5 09-Mar-2010 17:18:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rendergui_OpeningFcn, ...
                   'gui_OutputFcn',  @rendergui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before rendergui is made visible.
function rendergui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rendergui (see VARARGIN)

% Choose default command line output for rendergui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rendergui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Set the default options
defaultoptions=struct( ...
    'Width', 512, ...
    'Height', 512);

% Check the input options
if(nargin>1), 
    options=defaultoptions; 
else
    options=varargin{2};
    tags = fieldnames(defaultoptions);
    for i=1:length(tags)
         if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
    end
    if(length(tags)~=length(fieldnames(options))), 
        warning('Render:unknownoption','unknown options found');
    end
end

% Set the Paint function
FV=varargin{1};

% Use a struct as data container
data.Width=options.Width;
data.Height=options.Height;
data.I = zeros([data.Width data.Height 6]);
data.LastXY=[0 0];
data.zoom=1;
data.FirstRender=true;
data.mouse_button='';
data.handles=handles;
if(~isfield(FV,'projectionmatrix'))
    FV.projectionmatrix=[1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1];
end
if(~isfield(FV,'modelviewmatrix')),
    FV.modelviewmatrix=[1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1];
end


data.FV=FV;

% Store all data for this OpenGL window
setappdata(gcf,'data',data);
 refresh_screen


function refresh_screen
    data=getappdata(gcf,'data');
    J=renderpatch(data.I,data.FV); 
    J=J(:,:,1:3);
   
    % Show the image
    if(data.FirstRender)
        data.imshow_handle=imshow(J);
        set(get(data.handles.axes1,'Children'),'ButtonDownFcn','rendergui(''axes1_ButtonDownFcn'',gcbo,[],guidata(gcbo))');
        setappdata(gcf,'data',data);
    else
        set(data.imshow_handle,'Cdata',J);
        drawnow('expose')
    end

% --- Outputs from this function are returned to the command line.
function varargout = rendergui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getappdata(gcf,'data');
data.mouse_button=get(handles.figure1,'SelectionType');
data.LastXY=data.XY;
setappdata(gcf,'data',data);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getappdata(gcf,'data');
data.XY=get(0, 'PointerLocation');
diffXY=data.XY-data.LastXY;        
switch(data.mouse_button)
    case 'open'
    case 'normal'
        R=RotationMatrix([30*diffXY(1)/data.Width 30*diffXY(2)/data.Width 0]);
        data.FV.projectionmatrix(1:3,1:3)=R(1:3,1:3)*data.FV.projectionmatrix(1:3,1:3);
    case 'extend'
        t=[-diffXY(2)/data.Width diffXY(1)/data.Width 0];
        T=[1 0 0 t(1);
           0 1 0 t(2);
           0 0 1 t(3);
           0 0 0 1];
       
         data.FV.projectionmatrix=T*data.FV.projectionmatrix;
    case 'alt'
        s=1+max(min((diffXY(1)+diffXY(2))/data.Width,0.99),-0.99);
        S=[s 0 0 0;
           0 s 0 0;
           0 0 s 0;
           0 0 0 1];
         data.FV.projectionmatrix(1:3,1:3)=S(1:3,1:3)*data.FV.projectionmatrix(1:3,1:3);
    otherwise
        setappdata(gcf,'data',data);
        return;
end
data.FirstRender=false;
setappdata(gcf,'data',data);
refresh_screen;

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getappdata(gcf,'data');
data.mouse_button='';
setappdata(gcf,'data',data);

function M=ResizeMatrix(s)
	M=[s(1) 0 0 0;
	   0 s(2) 0 0;
	   0 0 s(3) 0;
	   0 0 0 1];
	   
function R=RotationMatrix(r)
% Determine the rotation matrix (View matrix) for rotation angles xyz ...
    Rx=[1 0 0 0; 0 cosd(r(1)) -sind(r(1)) 0; 0 sind(r(1)) cosd(r(1)) 0; 0 0 0 1];
    Ry=[cosd(r(2)) 0 sind(r(2)) 0; 0 1 0 0; -sind(r(2)) 0 cosd(r(2)) 0; 0 0 0 1];
    Rz=[cosd(r(3)) -sind(r(3)) 0 0; sind(r(3)) cosd(r(3)) 0 0; 0 0 1 0; 0 0 0 1];
    R=Rx*Ry*Rz;

function M=TranslateMatrix(t)
	M=[1 0 0 t(1);
	   0 1 0 t(2);
	   0 0 1 t(3);
	   0 0 0 1];

function varargout = mrmMakeMovieGUI_Pause(varargin)
% MRMMAKEMOVIEGUI_PAUSE M-file for mrmMakeMovieGUI_Pause.fig
%      MRMMAKEMOVIEGUI_PAUSE, by itself, creates a new MRMMAKEMOVIEGUI_PAUSE or raises the existing
%      singleton*.
%
%      H = MRMMAKEMOVIEGUI_PAUSE returns the handle to a new MRMMAKEMOVIEGUI_PAUSE or the handle to
%      the existing singleton*.
%
%      MRMMAKEMOVIEGUI_PAUSE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MRMMAKEMOVIEGUI_PAUSE.M with the given input arguments.
%
%      MRMMAKEMOVIEGUI_PAUSE('Property','Value',...) creates a new MRMMAKEMOVIEGUI_PAUSE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mrmMakeMovieGUI_Pause_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mrmMakeMovieGUI_Pause_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mrmMakeMovieGUI_Pause

% Last Modified by GUIDE v2.5 18-Jun-2010 20:12:09

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @mrmMakeMovieGUI_Pause_OpeningFcn, ...
                       'gui_OutputFcn',  @mrmMakeMovieGUI_Pause_OutputFcn, ...
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
end

function mrmMakeMovieGUI_Pause_OpeningFcn(hObject, eventdata, handles, parentFigure, editData)
    % Choose default command line output for mrmMakeMovieGUI_Pause
    if (~exist('editData', 'var')), editData = []; end
    
    handles.output      = hObject;
    handles.parent      = parentFigure;
    handles.editData    = editData; 

    % Update handles structure
    guidata(hObject, handles);
    Pause_InitFcn(hObject, handles);

end

function Pause_InitFcn(hObject, handles)
    if (~isempty(handles.editData))
        editData = handles.editData;
        
        set(handles.PauseAddButton, 'String', 'Update');
        set(handles.FrameCountTextField, 'String', num2str(editData.frames));
        set(handles.PauseLabelTextField, 'String', editData.label);
    end
end

function varargout = mrmMakeMovieGUI_Pause_OutputFcn(hObject, eventdata, handles) 

    varargout{1} = handles.output;

end

function PauseAddButton_Callback(hObject, eventdata, handles)
    frames = get(handles.FrameCountTextField, 'String');
    if (isempty(frames)) 
        errordlg('Please specify a frame count.');
        return;
    end
    pause.eventType = 'pause';
    pause.frames    = str2num(frames);
    pause.label     = get(handles.PauseLabelTextField, 'String');
    set(handles.parent, 'UserData', pause);
    close(handles.figure1);
    
end

function mrmMakeMovieGUI_Pause_DeleteFcn(hObject, eventdata, handles)
    set(handles.parent, 'UserData', []);
end
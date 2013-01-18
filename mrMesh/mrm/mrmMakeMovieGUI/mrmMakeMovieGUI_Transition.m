function varargout = mrmMakeMovieGUI_Transition(varargin)
% MRMMAKEMOVIEGUI_TRANSITION M-file for mrmMakeMovieGUI_Transition.fig
%      MRMMAKEMOVIEGUI_TRANSITION, by itself, creates a new MRMMAKEMOVIEGUI_TRANSITION or raises the existing
%      singleton*.
%
%      H = MRMMAKEMOVIEGUI_TRANSITION returns the handle to a new MRMMAKEMOVIEGUI_TRANSITION or the handle to
%      the existing singleton*.
%
%      MRMMAKEMOVIEGUI_TRANSITION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MRMMAKEMOVIEGUI_TRANSITION.M with the given input arguments.
%
%      MRMMAKEMOVIEGUI_TRANSITION('Property','Value',...) creates a new MRMMAKEMOVIEGUI_TRANSITION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mrmMakeMovieGUI_Transition_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mrmMakeMovieGUI_Transition_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mrmMakeMovieGUI_Transition

% Last Modified by GUIDE v2.5 29-Jun-2010 23:04:34

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @mrmMakeMovieGUI_Transition_OpeningFcn, ...
                       'gui_OutputFcn',  @mrmMakeMovieGUI_Transition_OutputFcn, ...
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

function mrmMakeMovieGUI_Transition_OpeningFcn(hObject, eventdata, handles, parentFigure, editData)
    % Choose default command line output for mrmMakeMovieGUI_Transition
    if (~exist('editData', 'var')), editData = []; end
       
    handles.output      = hObject;
    handles.parent      = parentFigure;
    handles.editData    = editData;
    
    % Update handles structure
    guidata(hObject, handles);
    Transition_InitFcn(hObject, handles);
    
end

function Transition_InitFcn(hObject, handles)
    strings = {'+', 'FIX', '-'};
    set(handles.RotateXMenu, 'String', strings);
    set(handles.RotateYMenu, 'String', strings);
    set(handles.RotateZMenu, 'String', strings);
    
    if (~isempty(handles.editData))
        editData = handles.editData;
        
        set(handles.TransitionAddButton, 'String', 'Update');
        ind = cellfind(strings, editData.rotate{1});
        set(handles.RotateXMenu, 'Value', ind);
        ind = cellfind(strings, editData.rotate{2});
        set(handles.RotateYMenu, 'Value', ind);
        ind = cellfind(strings, editData.rotate{3});
        set(handles.RotateZMenu, 'Value', ind);
        set(handles.FrameCountTextField, 'String', num2str(editData.frames));
        set(handles.TransitionLabelTextField, 'String', editData.label);
        
    end
    
    guidata(hObject, handles);
end

function varargout = mrmMakeMovieGUI_Transition_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;
end

function TransitionAddButton_Callback(hObject, eventdata, handles)
    frames = get(handles.FrameCountTextField, 'String');
    if (isempty(frames)) 
        errordlg('Please specify a frame count.');
        return;
    end
    strings = {'+', 'FIX', '-'};
    transition.eventType    = 'transition';
    transition.rotate       = cell(1,3);
    transition.rotate{1}    = strings{get(handles.RotateXMenu, 'Value')};
    transition.rotate{2}    = strings{get(handles.RotateYMenu, 'Value')};
    transition.rotate{3}    = strings{get(handles.RotateZMenu, 'Value')};
    transition.frames       = str2num(frames);
    transition.label        = get(handles.TransitionLabelTextField, 'String');
    set(handles.parent, 'UserData', transition);
    close(handles.figure1);
end

function mrmMakeMovieGUI_Transition_DeleteFcn(hObject, eventdata, handles)
    set(handles.parent, 'UserData', []);
end

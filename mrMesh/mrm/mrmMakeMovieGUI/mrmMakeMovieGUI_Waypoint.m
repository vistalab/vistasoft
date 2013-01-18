function varargout = mrmMakeMovieGUI_Waypoint(varargin)
% MRMMAKEMOVIEGUI_WAYPOINT M-file for mrmMakeMovieGUI_Waypoint.fig
%      MRMMAKEMOVIEGUI_WAYPOINT, by itself, creates a new MRMMAKEMOVIEGUI_WAYPOINT or raises the existing
%      singleton*.
%
%      H = MRMMAKEMOVIEGUI_WAYPOINT returns the handle to a new MRMMAKEMOVIEGUI_WAYPOINT or the handle to
%      the existing singleton*.
%
%      MRMMAKEMOVIEGUI_WAYPOINT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MRMMAKEMOVIEGUI_WAYPOINT.M with the given input arguments.
%
%      MRMMAKEMOVIEGUI_WAYPOINT('Property','Value',...) creates a new MRMMAKEMOVIEGUI_WAYPOINT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mrmMakeMovieGUI_Waypoint_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mrmMakeMovieGUI_Waypoint_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mrmMakeMovieGUI_Waypoint

% Last Modified by GUIDE v2.5 29-Jun-2010 23:05:44

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @mrmMakeMovieGUI_Waypoint_OpeningFcn, ...
                       'gui_OutputFcn',  @mrmMakeMovieGUI_Waypoint_OutputFcn, ...
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

function mrmMakeMovieGUI_Waypoint_OpeningFcn(hObject, eventdata, handles, parentFigure, meshID, editData)
    % Choose default command line output for mrmMakeMovieGUI_Waypoint
    if (~exist('editData', 'var')), editData = []; end
        
    handles.output      = hObject;
    handles.parent      = parentFigure;
    handles.meshID      = meshID;
    handles.editData    = editData;

    % Update handles structure
    guidata(hObject, handles);
    Waypoint_InitFcn(hObject, handles);

end

function Waypoint_InitFcn(hObject, handles)
    set(handles.ViewJumpMenu, 'String', {'Front','Back','Left','Right','Bottom','Top'});
    
    if (~isempty(handles.editData))
        editData = handles.editData;
        
        set(handles.WaypointAddButton, 'String', 'Update');
        set(handles.WaypointLabelTextField, 'String', editData.label);
        
    end
    guidata(hObject, handles);
end

function varargout = mrmMakeMovieGUI_Waypoint_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;
end

function WaypointAddButton_Callback(hObject, eventdata, handles)
    [rotation frustum origin] = mrmGetRotation(handles.meshID);
    waypoint.eventType  = 'waypoint';
    waypoint.rotation   = rotation;
    waypoint.frustum    = frustum;
    waypoint.origin     = origin;
    waypoint.label      = get(handles.WaypointLabelTextField, 'String');
    set(handles.parent, 'UserData', waypoint);
    close(handles.figure1);
end


function ViewJumpMenu_Callback(hObject, eventdata, handles)
    strings = get(handles.ViewJumpMenu, 'String');
    index   = get(handles.ViewJumpMenu, 'Value');
    mrmRotateCamera(handles.meshID,strings{index})
end

function mrmMakeMovieGUI_Waypoint_DeleteFcn(hObject, eventdata, handles)
    set(handles.parent, 'UserData', []);
end

function [rot, frustum, origin] = mrmGetRotation(id)
% Written by RFD?  Copied from original mrmMakeMovieGUI

    % Get rotation and zoom
    p.actor=0; p.get_all=1; 
    [id,stat,r] = mrMesh('localhost', id, 'get', p);
    zoom = diag(chol(r.rotation'*r.rotation))';
    rotMat = r.rotation/diag(zoom);
    % Note- there may be slight rounding errors allowing the inputs to
    % asin/atan go outside of the range (-1,1). May want to clip those.
    rot(2) = asin(rotMat(1,3));
    if (abs(rot(2))-pi/2).^2 < 1e-9,
        rot(1) = 0;
        rot(3) = atan2(-rotMat(2,1), -rotMat(3,1)/rotMat(1,3));
    else
        c      = cos(rot(2));
        rot(1) = atan2(rotMat(2,3)/c, rotMat(3,3)/c);
        rot(3) = atan2(rotMat(1,2)/c, rotMat(1,1)/c);
    end
    rot(1) = -rot(1); % flipped OpenGL Y-axis.
    rot(3) = -rot(3); % ??? don't know why it's necessary
    frustum = r.frustum;
    origin = r.origin;
end
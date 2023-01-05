function handles = dtiCmapInit(handles)
% Initialize color maps for mrDiffusion (dtiFiberUI)
%
% handles:  The dtiFiberUI handles
%
%   handles = dtiCmapInit(handles)
%
% Called in dtiFiberUI startup.  Not elsewhere.
%
% Brian (c) VISTASFOT Team, 2012

% I wonder if we need a cmap structure for the future?

handles.cmaps(1).name = 'autumn';
handles.cmaps(1).rgb = autumn(256);
handles.cmaps(2).name = 'winter';
handles.cmaps(2).rgb = winter(256);
handles.cmaps(3).name = 'spring';
handles.cmaps(3).rgb = spring(256);
handles.cmaps(4).name = 'summer';
handles.cmaps(4).rgb = summer(256);
handles.cmaps(5).name = 'hot';
handles.cmaps(5).rgb = hot(256);
handles.cmaps(6).name = 'cool';
handles.cmaps(6).rgb = cool(256);
handles.cmaps(7).name = 'gray';
handles.cmaps(7).rgb = gray(256);
handles.cmaps(8).name = 'red';
handles.cmaps(8).rgb = vividColormap(256,[0.15 0.85],'r');
handles.cmaps(9).name = 'green';
handles.cmaps(9).rgb = vividColormap(256,[0.15 0.85],'g');
handles.cmaps(10).name = 'blue';
handles.cmaps(10).rgb = vividColormap(256,[0.15 0.85],'b');
handles.cmaps(11).name = 'cyan';
handles.cmaps(11).rgb = vividColormap(256,[0.15 0.85],'c');
handles.cmaps(12).name = 'magenta';
handles.cmaps(12).rgb = vividColormap(256,[0.15 0.85],'m');
handles.cmaps(13).name = 'yellow';
handles.cmaps(13).rgb = vividColormap(256,[0.15 0.85],'y');

end

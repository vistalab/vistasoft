function handles = dtiLoadFibers(hObject,handles,fileName)
%Load fibers from the dtiFiberUI
%
%   handles = dtiLoadFibers(hObject,handles,[fileName]);
%
% See also: dtiReadFibers
%
%
% HISTORY:
%  2004.?? Wandell & Dougherty wrote it.
%  2005.01.17 RFD: added coordinate space field and option to xform fiber
%  coords from non-acpc spaces.
%
% (c) Stanford VISTA Team

if(~exist('fileName','var') || isempty(fileName))
    % File->Load Fibers
    fn = handles.defaultPath;
    if(exist(fullfile(fn, 'fibers'),'dir')) fn = fullfile(fn, 'fibers', filesep); end
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load Fibers...', fn);
    if(isnumeric(f)), disp('Load Fibers canceled.'); return; end
    fileName = fullfile(p,f);
    refreshFig = 1;
else
    refreshFig = 0;
end

%@@TH: Need to handle no t1 case.
if(~isfield(handles,'t1NormParams'))
	fg = dtiReadFibers(fileName);
else
    fg = dtiReadFibers(fileName, handles.t1NormParams);
end

handles = dtiAddFG(fg,handles);
if(refreshFig), handles = dtiRefreshFigure(handles, 0); end
if(~isempty(hObject)), guidata(hObject, handles); end

return

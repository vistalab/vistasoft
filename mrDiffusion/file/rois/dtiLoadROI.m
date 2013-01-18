function handles = dtiLoadROI(hObject,handles,fileName);
%
%  handles = dtiLoadROI(hObject,handles,[fileName]);
%
%Author: Wandell, Dougherty
%Purpose:
%

persistent defaultPath;

if(~exist('fileName','var') | isempty(fileName))
    if(isempty(defaultPath))
        fn = handles.defaultPath;
        if(exist(fullfile(fn, 'ROIs'),'dir')) fn = fullfile(fn, 'ROIs', filesep); end
    else
        fn = defaultPath;
    end
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load ROI...', fn);
    if(isnumeric(f)), disp('Load ROI canceled.'); return; end
    defaultPath = p;
    fileName = fullfile(p,f);
    refreshFig = 1;
else
    refreshFig = 0;
end
if(isfield(handles, 't1NormParams'))
  roi = dtiReadRoi(fileName, handles.t1NormParams);
else
  roi = dtiReadRoi(fileName);
end

handles = dtiAddROI(roi,handles);
if(refreshFig) handles = dtiRefreshFigure(handles, 0); end
if(~isempty(hObject)) guidata(hObject, handles); end
return;

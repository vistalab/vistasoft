function dtiLoadManyROIs(hObject,handles)
%
%  dtiLoadManyROIs(hObject,handles)
%
%Author: Dougherty
%Purpose:
%

persistent defaultPath;
if(isempty(defaultPath))
    fn = handles.defaultPath;
    if(exist(fullfile(fn, 'ROIs'),'dir')) fn = fullfile(fn, 'ROIs', filesep); end
else
    fn = defaultPath;
end
p = uigetdir(fn, 'ROI directory');
if isnumeric(p), disp('Load ROIs ... canceled.'), return; end

d = dir(fullfile(p,'*.mat'));

if(isempty(d))
    error('No ROIs found');
    return;
end

for ii=1:length(d)
    str = char(d(ii).name);
    str = str(1:findstr(str,'.mat')-1);
    fileList{ii} = str;
end

[s,ok] = listdlg('PromptString','Select an ROI',...
    'SelectionMode','multiple',...
    'ListString',fileList, 'ListSize', [300 300]);
if ok
    for ii=1:length(s)
        handles = dtiLoadROI([],handles,fullfile(p, [char(fileList(s(ii))),'.mat']));
    end
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
else
    disp('Load ROIs ... canceled.');
end

return;
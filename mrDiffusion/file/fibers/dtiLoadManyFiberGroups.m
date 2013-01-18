function dtiLoadManyFiberGroups(hObject,handles)
%
%  dtiLoadManyFiberGroups(hObject,handles)
%
% Author: Dougherty
% Purpose:
%

fn = handles.defaultPath;
if(exist(fullfile(fn, 'fibers'),'dir')) fn = fullfile(fn, 'fibers', filesep); end
p = uigetdir(fn, 'Fibers directory');
if isnumeric(p), disp('Load fibers ... canceled.'), return; end

d = dir(fullfile(p,'*.mat'));

if(isempty(d))
    error('No fibers found');
    return;
end

for ii=1:length(d)
    str = char(d(ii).name);
    str = str(1:findstr(str,'.mat')-1);
    fileList{ii} = str;
end

[s,ok] = listdlg('PromptString','Select fiber groups',...
    'SelectionMode','multiple',...
    'ListString',fileList, 'ListSize', [300 300]);
if ok
    for ii=1:length(s)
        fn = fullfile(p, [char(fileList(s(ii))),'.mat']);
        handles = dtiLoadFibers([],handles,fn);
    end
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
else
    disp('Load ROIs ... canceled.');
end

return;
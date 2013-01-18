function mrvMesh = dtiAddFibersToWorld(handles, mrvMesh)
% Obsolete
%
%  mrvMesh = dtiAddFibersToWorld(handles, [mrvMesh])
%
% if mrvMesh (the mrVista mesh) isn't passed in, we'll get the current
% mesh from the currently selected volume view.
%
% HISTORY:
% 2004.07.14 RFD: wrote it.
%

error('Obsolete %s\n',mfilename);

return

if(~exist('mrvMesh','var') | isempty(mrvMesh))
    mrvMesh = viewGet(getSelectedVolume,'mesh');
    updateMesh = 1;
else
    updateMesh = 0;
end
mrvOrigin = mrmGet(mrvMesh, 'origin');
id = meshGet(mrvMesh,'id');
host = meshGet(mrvMesh,'host');
scale = meshGet(mrvMesh,'mmPerVox');

fibers = meshGet(mrvMesh, 'fibers');

% clear t; t.enable = 0;
% [id, s, r] = mrMesh(host, id, 'transparency', t);

% Clear out any old fibers
if(~isempty(fibers))
    for(ii=1:length(fibers))
        clear t; t.actor = fibers(ii).actor;
        if(~isempty(t.actor)) mrMesh(host, id, 'remove_actor', t); end
    end
end
fibers = [];

% Check the current fiber group show mode
if(handles.fiberGroupShowMode==3)
    groupNumList = [1:length(handles.fiberGroups)];
elseif(handles.fiberGroupShowMode==2)
    groupNumList = handles.curFiberGroup;
else
    groupNumList = [];
end
for(grpNum=groupNumList)
    fg = dtiXformFibersToMrVista(handles, grpNum);
    clear t;
    t.class = 'mesh';
    [id,s,t] = mrMesh(host, id, 'add_actor', t);
    % t will catch the actor number
    t.points = [];
    for(ii=1:length(fg.fibers))
        pts = fg.fibers{ii}';
        pts = pts.*repmat(scale',1,size(pts,2));
        pts = pts([2,1,3],:);
        t.points = [t.points, pts, [999;999;999]];
    end
    t.color = [fg.colorRgb 255];
    t.sides = 6;
    t.radius = .5;
    t.cap = 1;
    [id,s,r] = mrMesh(host, id, 'tube', t);
    % We seem to have to set the origin separately:
    t.origin = surfOrigin;
    [id,s,r] = mrMesh(host, id, 'set', t);
    fibers(length(fibers)+1).actor = t.actor;
end



% clear t;
% t.enable = 1;
% [id, s, r] = mrMesh(host, id, 'transparency', t);
% clear c; c.actor=1; c.get_all=1;
% [id, s, r] = mrMesh(host, id, 'get', c);
% coords = round(r.origin - brainOrigin);
% VOLUME{1} = newROI(VOLUME{1}, num2str(coords));
% VOLUME{1}.ROIs(end).coords = coords;
% 
% for(ii=1:length(fg.fibers))
%     clear t;
%     t.origin = brainOrigin;
%     t.actor = tubes{grpNum}(ii).actor
%     [id,s,r] = mrMesh(host, id, 'set', t);
% end

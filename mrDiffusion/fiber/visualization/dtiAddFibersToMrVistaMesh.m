function mrvMesh = dtiAddFibersToMrVistaMesh(handles, mrvMesh, showMode, maskPoints)
% Add fibers to a mrMesh
%
%   mrvMesh = dtiAddFibersToMrVistaMesh(handles, mrvMesh, [showMode], [maskPoints])
%
% showMode: 1 = just show fibers, 2 = just paint fiber intersections, 
% 3 = do both
%
% extrapLen: the length (in mrVista anatomy units, usually mm) to extend
% each fiber tip.
%
% HISTORY:
% 2004.07.14 RFD: wrote it.
%
% (c) Stanford VISTA Team

if(~exist('showMode','var') || isempty(showMode)), showMode = 1; end
if(~exist('maskPoints','var')), maskPoints = []; end
extrapLen = 0;

% used in enpoint mapping (showMode 2 or 3). Fiber enpoints further that
% this from the nearest vertex won't get mapped.
distThresh = 3;

mrvOrigin = mrmGet(mrvMesh, 'origin');
id = meshGet(mrvMesh,'id');
host = meshGet(mrvMesh,'host');
scale = meshGet(mrvMesh,'mmPerVox');
%scale = scale([2,1,3]);

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
if(handles.fiberGroupShowMode==2)
    groupNumList = handles.curFiberGroup;
else
    groupNumList = [1:length(handles.fiberGroups)];
end

for(grpNum=groupNumList)
    if(handles.fiberGroups(grpNum).visible)
        fg = dtiXformFibersToMrVista(handles, grpNum, scale);
        % extrapolate fibers
        for(ii=1:length(fg.fibers))
            % remove degenerate fibers
            if(size(fg.fibers{ii},2)<2)
                fg.fibers{ii} = [];
            else
                if(extrapLen>0)
                    ex1 = (fg.fibers{ii}(:,1)-fg.fibers{ii}(:,2))*extrapLen+fg.fibers{ii}(:,1);
                    ex2 = (fg.fibers{ii}(:,end)-fg.fibers{ii}(:,end-1))*extrapLen+fg.fibers{ii}(:,end);
                else
                    ex1 = []; ex2 = [];
                end
                fg.fibers{ii} = [ex1 fg.fibers{ii} ex2];
            end 
        end

        if(bitand(showMode,2))
            d = mrmGet(mrvMesh,'data');
            distSqThresh = distThresh.^2;
            coords = zeros(length(fg.fibers)*2, 3);
            for(ii=1:length(fg.fibers))
                if(~isempty(fg.fibers{ii}))
                    % We only look at fiber endpoints (first and last point)
                    coords((ii-1)*2+1,:) = [fg.fibers{ii}(:,1)'];
                    coords((ii-1)*2+2,:) = [fg.fibers{ii}(:,end)'];
                else
                    coords((ii-1)*2+1,:) = [nan, nan, nan];
                    coords((ii-1)*2+2,:) = [nan, nan, nan];
                end
            end
            coords(isnan(coords(:,1)),:) = [];
            if(~isempty(maskPoints))
                [removeThese, sqDist] = nearpoints(coords', maskPoints');
                coords(removeThese(sqDist>maskThresh.^2),:) = [];
            end
            coords = coords(:,[2,1,3]);
            % inputs should be 3xN
            [vertInds, bestSqDist] = nearpoints(coords',mrvMesh.initVertices);
            vertInds = vertInds(bestSqDist<=distSqThresh);
            clear t;
            t.points = zeros(3,length(vertInds)*3);
            for(ii=1:length(vertInds))
                t.points(:,(ii-1)*3+1) = d.vertices(:,vertInds(ii))-d.normals(:,vertInds(ii)).*2;
                t.points(:,(ii-1)*3+2) = d.vertices(:,vertInds(ii))+d.normals(:,vertInds(ii)).*2;
                t.points(:,(ii-1)*3+3) = [999;999;999];
            end
            % We should always render as cylinders, since there aren't that
            % many polygons anyway.
            if(1)%(fg.thickness>0)
                clear p;
                p.class = 'mesh';
                [id,s,p] = mrMesh(host, id, 'add_actor', p);
                t.actor = p.actor;
                t.color = [fg.colorRgb 255];
                t.sides = 6;
                t.radius = abs(fg.thickness);
                t.cap = 1;
                [id,s,r] = mrMesh(host, id, 'tube', t);
            else
                % Render fibers as polylines
                clear p;
                p.class = 'polyline';
                [id,s,p] = mrMesh(host, id, 'add_actor', p);
                t.actor = p.actor;
                t.width = abs(fg.thickness);
                t.color = [fg.colorRgb 255];
                [id,s,r] = mrMesh(host, id, 'set', t);
            end
            
            
%             marker.camera_space = 0;
%             % The following will build an icosohedron
%             x = 0.525731112119133606;
%             z = 0.850650808352039932;
%             marker.vertices = [-x,0,z; x,0,z;  -x,0,-z; x,0,-z; ...
%                                0,z,x;  0,z,-x; 0,-z,x;  0,-z,-x; ...
%                                z,x,0; -z,x,0;  z,-x,0; -z,-x,0]';
% 
%             marker.triangles = [0,4,1;  0,9,4;  9,5,4;  4,5,8;  4,8,1; ...
%                                 8,10,1; 8,3,10; 5,3,8;  5,2,3;  2,7,3; ...
%                                 7,10,3; 7,6,10; 7,11,6; 11,0,6; 0,1,6; ...
%                                 6,1,10; 9,0,11; 9,11,2; 9,2,5;  7,2,11]';
%             marker.rotation = eye(3);
%             marker.colors = repmat([10 10 10 192]', 1, size(marker.vertices,2));
%             marker.origin = mrvOrigin;
            
%             ms = marker;
%             %ms.triangles = zeros(3, size(marker.triangles,2)*length(inds);
%             ms.triangles = [];
%             ms.vertices = [];
%             for(ii=1:length(inds))
%                 if(~isempty(inds{ii}))
%                     for(jj=1:size(inds{ii},2))
%                         ms.triangles = [ms.triangles, marker.triangles+size(ms.vertices,2)];
%                         ms.vertices = [ms.vertices, marker.vertices + repmat(inds{ii}([4,3,5],jj),1,size(marker.vertices,2))];
%                     end
%                 end
%             end
%             ms.colors = repmat([10 10 10 192]', 1, size(ms.vertices,2));
%             clear p;
%             p.class = 'mesh';
%             [id,s,p] = mrMesh(host, id, 'add_actor', p);
%             ms.actor = p.actor;
%             [id,s,r] = mrMesh(host, id, 'set_mesh', ms);
            
            p.origin = mrvOrigin;
            [id,s,r] = mrMesh(host, id, 'set', p);
            fibers(length(fibers)+1).actor = p.actor;
        end 
        
        if(bitand(showMode,1) & fg.thickness~=0)
            clear t;
            for(ii=1:length(fg.fibers))
                fg.fibers{ii} = [fg.fibers{ii} [999;999;999]];
            end
            t.points = horzcat(fg.fibers{:});
            t.points = t.points([2,1,3],:);
            %realPts = t.points(1,:)~=999 & t.points(2,:)~=999 & t.points(3,:)~=999;
            % A negative thickness means to render the fibers as polylines  
            if(fg.thickness>0)
                clear p;
                p.class = 'mesh';
                [id,s,p] = mrMesh(host, id, 'add_actor', p);
                % p will catch the actor number
                t.actor = p.actor;
                t.color = [fg.colorRgb 255];
                t.sides = 6;
                t.radius = fg.thickness;
                t.cap = 1;
                [id,s,r] = mrMesh(host, id, 'tube', t);
            else
                % Render fibers as polylines
                clear p;
                p.class = 'polyline';
                [id,s,p] = mrMesh(host, id, 'add_actor', p);
                t.actor = p.actor;
                t.width = abs(fg.thickness);
                t.color = [fg.colorRgb 255];
                [id,s,r] = mrMesh(host, id, 'set', t);
            end
            % We seem to have to set the origin separately:
            p.origin = mrvOrigin;
            [id,s,r] = mrMesh(host, id, 'set', p);
            fibers(length(fibers)+1).actor = p.actor;
        end
    end
end
mrvMesh = meshSet(mrvMesh, 'fibers', fibers);
return;

%% ----- For testing
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

%mex -O -I. dtiFiberIntersectMesh.cxx libRAPID.a
load /biac1/wandell/data/anatomy/dougherty/leftMesh.mat
scale = meshGet(msh,'mmPerVox');
%fibers = {[[1:100];[1:100];[1:100]]};
fg = dtiXformFibersToMrVista(guidata(gcf), 1, scale);
fibers = fg.fibers;
inds = dtiFiberIntersectMesh(fibers, uint32(msh.data.triangles), msh.initVertices);
triInds = vertcat(inds{:}); triInds = double(triInds(:,1))+1;
vertInds = double(msh.data.triangles(:,triInds))+1;

[msh, lights] = mrmInitMesh(msh);
newColors = msh.data.colors;
newColors(1,vertInds) = 0; newColors(2,vertInds) = 255; newColors(3,vertInds) = 0;
msh = mrmSet(msh, 'colors', newColors');

clear t;
for(ii=1:length(fibers))
    fibers{ii}(:,end) = [999;999;999];
end
t.points = horzcat(fibers{:});
t.points = t.points([2,1,3],:);
realPts = t.points(1,:)~=999 & t.points(2,:)~=999 & t.points(3,:)~=999;
clear p;
p.class = 'polyline';
[id,s,p] = mrMesh(msh.host, msh.id, 'add_actor', p);
t.actor = p.actor;
t.width = 0.5;
t.color = [255 0 0 255];
[id,s,r] = mrMesh(msh.host, msh.id, 'set', t);
p.origin = msh.data.origin;
[id,s,r] = mrMesh(msh.host, msh.id, 'set', p);

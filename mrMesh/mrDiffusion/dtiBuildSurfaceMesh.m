figNum = 5;
handles = guidata(figNum);
%faThresh = str2double(get(handles.editFaThresh, 'String'));
faThresh = 0.2;

[fa,mm,mat] = dtiGetNamedImage(handles.bg, 'fa');
fa(isnan(fa)) = 0;
faMask = fa>=faThresh;
% we smooth with a 5 voxel kernel
faMask = dtiCleanImageMask(faMask, 5);
%anat = dtiGetNamedImage(handles.bg, 'B0');
% anat = fa;
% anat = anat*255;
% whiteMean = mean(anat(faMask(:)));
% grayMask = imdilate(faMask,strel('disk',2));
% grayMask(faMask) = 0;
% grayMean = mean(anat(grayMask(:)));
% csfMean = 0;
% %figure; imagesc(makeMontage(faMask));
% %figure; imagesc(makeMontage(grayMask));
% %figure; imagesc(makeMontage(anat)); colormap(gray);
% faMaskFix = mrgRemBridges(uint8(faMask), anat, [csfMean grayMean whiteMean]);
% faMaskFix(faMaskFix==225) = 1; % unchanged
% faMaskFix(faMaskFix==226) = 4; % 'alternative' voxels ???
% faMaskFix(faMaskFix==236) = 3; % remove (cut should be made)
% faMaskFix(faMaskFix==245) = 2; % should be added
% figure; imagesc(makeMontage(faMaskFix));
% faMask = faMaskFix;

id = -1;
[id,wasOpen] = mrmCheckMeshServer(id, 'localhost');
% if(id~=mesh.id)
%     mesh.id = id;
%     [mesh, lights] = mrmInitMesh(mesh);
% else
    [mesh,lights,tenseMesh] = mrmBuildMesh(uint8(faMask), mm, 'localhost', id, 'RelaxIterations', 25);
    %[mesh,lights,tenseMesh] = mrmBuildMesh(uint8(faMask), mm, 'localhost', id);
% end
%[mesh,lights,tenseMesh] = mrmBuildMesh(uint8(faMask), mm, 'localhost', id);

handles = guidata(figNum);
curPosition = str2num(get(handles.editPosition,'String'));
excludeSingletons = 0; % flag to exclude fibers that only intersect the mesh once
cmapName = 'dist';
fiberCoords = vertcat(handles.fiberGroups(handles.curFiberGroup).fibers{:});
fiberCoords = mrAnatXformCoords(inv(dtiGetStandardXform(handles,mat)), fiberCoords);
fiberCoords = [ fiberCoords(:,1).*mesh.mmPerVox(1), ...
           fiberCoords(:,2).*mesh.mmPerVox(2), ...
           fiberCoords(:,3).*mesh.mmPerVox(3) ];
vertexCoords = tenseMesh.data.vertices';

% We also keep track of which coordinates go with which fiber
fiberNum = zeros(size(fiberCoords(:,1)));
curIndex = 1;
minDist = zeros(length(handles.fiberGroups(handles.curFiberGroup).fibers),1);
minDistXYZ = zeros(length(handles.fiberGroups(handles.curFiberGroup).fibers),3);
for(ii=1:length(handles.fiberGroups(handles.curFiberGroup).fibers))
    numCoords = size(handles.fiberGroups(handles.curFiberGroup).fibers{ii},1);
    fiberNum(curIndex:curIndex+numCoords-1) = repmat(ii,numCoords,1);
    curIndex = curIndex+numCoords;
    d = sqrt((handles.fiberGroups(handles.curFiberGroup).fibers{ii}(:,1)-curPosition(1)).^2 ...
        + (handles.fiberGroups(handles.curFiberGroup).fibers{ii}(:,2)-curPosition(2)).^2 ...
        + (handles.fiberGroups(handles.curFiberGroup).fibers{ii}(:,3)-curPosition(3)).^2);
    minDist(ii) = min(d);
    minIndex = find(d==min(d)); minIndex = minIndex(1);
    minDistXYZ(ii,1) = handles.fiberGroups(handles.curFiberGroup).fibers{ii}(minIndex,1)-curPosition(1);
    minDistXYZ(ii,2) = handles.fiberGroups(handles.curFiberGroup).fibers{ii}(minIndex,2)-curPosition(2);
    minDistXYZ(ii,3) = handles.fiberGroups(handles.curFiberGroup).fibers{ii}(minIndex,3)-curPosition(3);
end
% Find the fiber endpoints
endpoints = diff(fiberNum);
endpoints = [1; endpoints] | [endpoints; 1];

% Map each vertex to an end coord.
% The following is an ugly hack, but it usually works and is really fast.
% Alternatives would involve something like bwdist and takes an order of
% magnitude longer.
% *** USE dsearchn
map = zeros(size(mesh.data.vertices(1,:)));
distThresh = 6;
[map,dist] = nearpoints(vertexCoords', fiberCoords');
map(dist>distThresh^2) = 0;
idx = find(map>0);
% dist = sqrt(dist);
% idx = [1:10000];
% for(ii=1:length(idx))
%     vc = vertexCoords(idx(ii),:);
%     fc = fiberCoords(map(idx(ii)),:);
%     d = sqrt(sum((vc-fc).^2));
%     %if(d~=dist(idx(ii)))
%         d2 = sum((repmat(vc, size(fiberCoords,1), 1)-fiberCoords).^2,2);
%         nr = find(d2==min(d2)); nr = nr(1);
%         d2 = sqrt(d2(nr));
%         if(d2~=dist(idx(ii)))
%         fprintf('%d: %0.3f %0.3f vc=[%0.1f %0.1f %0.1f] npfc= %d [%0.1f %0.1f %0.1f] myfc= %d [%0.1f %0.1f %0.1f] (%0.3f)\n',...
%                  idx(ii),d,dist(idx(ii)),vc,map(idx(ii)),fc,nr,fiberCoords(nr,:),d2);
%         end
% end

% fiberCoords = round(fiberCoords);
% vertexCoords = round(vertexCoords);
% [goodLocInd, loc] = ismember(round(vertexCoords/2), round(fiberCoords/2), 'rows');
% map(goodLocInd) = loc(goodLocInd);
% [goodLocInd, loc] = ismember(round(vertexCoords), round(fiberCoords), 'rows');
% map(goodLocInd) = loc(goodLocInd);

map = int32(map);

% Now, restrict mapping to only fiber ends
endPointMapInds = ismember(map, find(endpoints));
map(~endPointMapInds) = 0;

%p.actor = mesh.data.actor;
p.actor = mesh.actor;
p.colors = mesh.data.colors;
mapVertices = find(map>0);
mapFiberNum = fiberNum(map(mapVertices));
[uniqueFibers,uniqueFiberIndex] = unique(mapFiberNum);
if(excludeSingletons)
    % exclude singletons- fibers that intersect the mesh only once
    [uniqueFibers,uniqueFiberIndex] = unique(mapFiberNum);
    mapFiberNum(uniqueFiberIndex) = 0;
    nonUnique = ismember(mapFiberNum, fiberNum(map(mapVertices)));
    mapVertices = mapVertices(nonUnique);
    mapFiberNum = fiberNum(map(mapVertices));
    [uniqueFibers,uniqueFiberIndex] = unique(mapFiberNum);
end
numFiberVertices = length(mapVertices);
numUniqueFiberVertices = length(uniqueFibers);
switch(cmapName)
    case 'hsv'
        cmap = round(hsv(numUniqueFiberVertices)*255)';
        [junk, fiberNumCmapIndex] = ismember(mapFiberNum, uniqueFibers);
        cmap = cmap(:,fiberNumCmapIndex);
    case 'jet'
        cmap = round(jet(numUniqueFiberVertices)*255)';
        [junk, fiberNumCmapIndex] = ismember(mapFiberNum, uniqueFibers);
        cmap = cmap(:,fiberNumCmapIndex);
    case 'rand'
        cmap = [randperm(numUniqueFiberVertices); randperm(numUniqueFiberVertices); randperm(numUniqueFiberVertices)]';
        cmap = round((cmap-1)./(numUniqueFiberVertices-1)*255)';
        [junk, fiberNumCmapIndex] = ismember(mapFiberNum, uniqueFibers);
        cmap = cmap(:,fiberNumCmapIndex);
    case 'solid'
        cmap = repmat(handles.fiberGroups(handles.curFiberGroup).colorRgb, length(mapFiberNum), 1)';
    case 'dist'
        clear cmap;
        %cmap(1,:) = max(minDist(mapFiberNum))-minDist(mapFiberNum);
        %cmap(2,:) = minDist(mapFiberNum);
        %cmap(3,:) = 0;
        %cmap = cmap-repmat(min(cmap')',1,size(cmap,2));
        %cmap = cmap./repmat(max(cmap')',1,size(cmap,2));
        %cmap(isnan(cmap)) = 0;
        %cmap = cmap.*255;
        cmap = zeros(3,length(mapFiberNum));
        %cmap([1:2],:) = minDistXYZ(mapFiberNum,[2:3])';
        %cmap = cmap./max(abs(cmap(:)));
        %cmap = cmap*96+127;
        
%         % If fiber coord is more negative than curPos, then it will get
%         % more red, if it is more positive, then we get more green.
%         d = minDistXYZ(mapFiberNum,2)';
%         cmap(1,:) = d;
%         cmap(1,cmap(1,:)<0) = 0;
%         cmap(1,:) = 255-round(cmap(1,:)./max(cmap(1,:)) * 255);
%         cmap(2,:) = -d;
%         cmap(2,cmap(2,:)<0) = 0;
%         cmap(2,:) = 255-round(cmap(2,:)./max(cmap(2,:)) * 255);
         d = minDist(mapFiberNum)';
         d = d-min(d); d = d./max(d);
         cmap(1,:) = 255-round(d*255);
         cmap(2,:) = round(d*255);
    otherwise
        error('Unknown cmap name.');
end
p.colors(1:3,mapVertices) = cmap;
mrMesh(mesh.host, mesh.id, 'modify_mesh', p);

% cm = unique(cmap','rows')
% figure; image([1:size(cmap,2)]); colormap(cmap'./255);

%c=round(mrmSetCursorCoords(mesh)); c=c([2 1 3]); 
%tc=mrAnatXformCoords(handles.acpcXform, c)

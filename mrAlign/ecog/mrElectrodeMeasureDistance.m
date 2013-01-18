%mrmStart;


fName = '/biac1/wandell/data/anatomy/dougherty/t1_class.nii.gz'

% Grow 1 layer
[nodes,edges,classData] = mrgGrowGray(fName,1,0,'left'); 
mmPerVox = classData.header.mmPerVox;
wm = uint8( (classData.data == classData.type.white) | (classData.data == classData.type.gray));
msh = meshColor(meshSmooth(meshBuildFromClass(wm,mmPerVox)));
meshVisualize(msh,2);

roiCoords = [46,148,113]';
nCoords = size(roiCoords,2);
eNode = zeros(1,nCoords);
for(ii=1:nCoords)
    % Nodes are in voxel space
    [eNode(ii), nearestDistSq] = nearpoints(roiCoords(:,ii), nodes(1:3,:));
    if(sqrt(nearestDistSq)>10/mean(mmPerVox)), warning('distance too big!'); end
end
for(ii=1:3), roiCoordsMm(ii,:) = roiCoords(ii,:)*mmPerVox(ii); end

eVert = zeros(1,nCoords);
eVertDist = zeros(1,nCoords);
for(ii=1:nCoords)
    % Vertices are in mm space, so we use eCoordsMm
    [eVert(ii), eVertDist(ii)] = nearpoints(roiCoordsMm(:,ii), msh.vertices);
end
eVertDist = sqrt(eVertDist);



msh.colors(1,eVert) = 255;
meshVisualize(msh,3);
% It would be cool to render a sphere at each electrode position...




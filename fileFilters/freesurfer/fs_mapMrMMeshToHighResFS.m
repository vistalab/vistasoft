function [lowToHighMap,dists]=fs_mapMrMMeshToHighResFS(mrmMeshPath, highResMeshPath)
% [lowToHighMap,dists]=fs_mapMrMMeshToHighResFS(mrmMeshPath, highResMeshPath)
% Returns a set of indices: For each node in the mrm mesh, this is the index
% of the nearest node in the fs highResMesh
% Use this function to map .w files onto decimated meshes in mrMesh
% mrmMeshColor=wFileVals(lowToHighMap)


if (ieNotDefined('mrmMeshPath'))
    [mrmMeshName,mrmMeshPath]=uigetfile('*.*','Pick a MLR mesh file');
    mrmMeshPath=fullfile(mrmMeshPath,mrmMeshName);
end

disp('Reading MLR Mesh data')
thisMesh=load(mrmMeshPath);

% Now try the highresh freesurfer mesh

if (ieNotDefined('highResMeshPath'))
    [fsMeshName,fsPath]=uigetfile('*.*','Pick a high-resolution freesurfer mesh file');
    highResMeshPath=fullfile(fsPath,fsMeshName);
end

disp('Reading high-res mesh data from Freesurfer')

[path,name,ext,ver]=fileparts(highResMeshPath);

if (strcmp(upper(ext),'.TRI'))
    [hvertex,hface]=freesurfer_read_tri(highResMeshPath);
% else    
    [hvertex,hface]=freesurfer_read_surf(highResMeshPath);
% end

% We now have to bring these two meshes into register (zero points,
% axis order) before we call nearpoints
mrmvertex=thisMesh.msh.initVertices;

% anticlockwise).


% Pass the fs nodes through the same xform as they saw in the export to
% mrMesh:

vertex=hvertex(:,[2 3 1]);  % Switching axes LGA. From fs_writeEMSEMeshFromFreesurfer
vertex = rz(vertex,-90,'degrees'); % default -90 **** LGA
vertex=vertex';


v=vertex(1:2,:);
%v=v-128;
 
rotMat=[0 -1;1 0];
v=v'*rotMat;
vertex(1:2,:)=v'+129;
LR=vertex(3,:);


LR=(-LR+129); % Result should run from 1 to 256
vertex(3,:)=LR;





tSlice=120;
% Check : find all the points in a single plane and plot them
splane=find((mrmvertex(2,:)>tSlice) .* (mrmvertex(2,:)<(tSlice+1)));
toPlot1=mrmvertex([1 3],splane);
splane2=find((vertex(2,:)>(tSlice)) .* (vertex(2,:)<(tSlice+1)));
toPlot2=vertex([1 3],splane2);



figure(2);
hold off;

plot(toPlot1(1,:),toPlot1(2,:),'.k');
hold on;
% toPlot2(2,:)=256-toPlot2(2,:)+1;
% toPlot2(1,:)=toPlot2(1,:)+1;
plot(toPlot2(1,:),toPlot2(2,:),'.r');


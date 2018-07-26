% a scratchpad of test commands used during mrMeshPy development

% % %  Callback: MSH = viewGet(VOLUME{1}, 'Mesh');
% % %  vertexGrayMap = mrmMapVerticesToGray( meshGet(MSH, 'vertices'), viewGet(VOLUME{1}, 'nodes'), viewGet(VOLUME{1}, 'mmPerVox'), viewGet(VOLUME{1}, 'edges') ); 
% % %  MSH = meshSet(MSH, 'vertexgraymap', vertexGrayMap); 
% % %  VOLUME{1} = viewSet(VOLUME{1}, 'Mesh', MSH); 
% % %  clear MSH vertexGrayMap
% % % 
% % % 
% % % 
% % % msh = mrmBuildMeshMatlab(cFile,1.0);
% % % msh.colors(4,:) = 255;
% % % msh.vertexGrayMap = mrmMapVerticesToGray( meshGet(msh, 'vertices'), viewGet(VOLUME{1}, 'nodes'), viewGet(VOLUME{1}, 'mmPerVox'), viewGet(VOLUME{1}, 'edges') )
% % % VOLUME{1} = rmfield(VOLUME{1},'mesh')


filename = '/groups/Projects/P1252/Data/Anatomy/R3517/key_files/t1_class_edit.nii.gz';
msh = meshBuildFromNiftiClass_mrMeshPy(filename,'right'); %puts voxels in workspace
voxels = permute(voxels,[3,2,1]);
save /tmp/voxels.mat voxels;
system('/groups/examples/mrMeshPy/mrMeshPy/matlabRoutines/launchMeshBuild.sh /groups/examples/mrMeshPy/testCode/testMeshBuild.py')
msh = load('/tmp/temp.mat');
msh = meshFormat(msh);               % Converts old format to new.
msh.initialvertices =  msh.initVertices;
vertices = meshGet(msh,'vertices');
msh = meshSet(msh,'origin',-mean(vertices,2)');
msh = meshSet(msh,'mmPerVox',mmPerVox);
vertexGrayMap = mrmMapVerticesToGray(...
    meshGet(msh, 'initialvertices'),...
    viewGet(vw, 'nodes'),...
    viewGet(vw, 'mmPerVox'),...
    viewGet(vw, 'edges'));
msh = meshSet(msh, 'vertexgraymap', vertexGrayMap);
save ./test3.mat msh


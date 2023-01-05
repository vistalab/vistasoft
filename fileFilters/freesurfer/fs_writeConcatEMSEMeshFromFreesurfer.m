function p=writeConcatEMSEMeshFromFreesurfer(fsMeshName1,fsMeshName2,outMeshName,meshType,decimationFraction)
%function p=writeConcatEMSEMeshFromFreesurfer(fsMeshName1,fsMeshName2,outMeshName,meshType,decimationFraction)
% Does what it says. Takes a FREESURFER mesh and turns it into EMSE format
% Returns a structure 'p' containing the mesh.
% Requires Darren Weber's EEG toolbox (eeg.sourceforge.net)
% ARW 012104
if (ieNotDefined('fsMeshName1'))
   [fsMeshName1,fsPath1]=uigetfile('*.*','Pick first freesurfer mesh file');
   fsMeshName1=fullfile(fsPath1,fsMeshName1);

end
 
if (ieNotDefined('fsMeshName2'))
   [fsMeshName2,fsPath2]=uigetfile('*.*','Pick second freesurfer mesh file');
   fsMeshName2=fullfile(fsPath2,fsMeshName2);

end

% Read in both fs meshes : Left and right. We could even consider naming
% these automatically from just the .pial extension
[path1,name1,ext,ver]=fileparts(fsMeshName1);

if (strcmp(upper(ext),'.TRI'))
    [vertex1,face1]=freesurfer_read_tri(fsMeshName1);
else
    
[vertex1,face1]=freesurfer_read_surf(fsMeshName1);
end

[path2,name2,ext,ver]=fileparts(fsMeshName2);

if (strcmp(upper(ext),'.TRI'))
    [vertex2,face2]=freesurfer_read_tri(fsMeshName2);
else
    
[vertex2,face2]=freesurfer_read_surf(fsMeshName2);
end

% Pick an output filename. Only one.
if (~ieNotDefined('outMeshName'))
    
[path,name,ext] = fileparts(outMeshName);
else
    [pathname,filename]=uiputfile('*.wfr','EMSE wireframe to place');
    [path,name,ext]=fileparts(strcat(filename,pathname));
     
end
if (~exist('meshType','var'));
    meshType='cortex';
    disp('Default meshtype: cortex');
    
end
if (ieNotDefined('decimationFraction'))
    decimationFraction=0.1;
    disp('Decimating by 0.1 as a default');
end

% Do the decimation separately for each hemisphere.

p.mesh.path=path;
p.mesh.file=[name,ext];


vertex=[vertex1;vertex2];
face=[face1;face2+size(vertex1,1)];
%vertex = vertex+128;
%vertex(:,3)=vertex(:,3)+1;

vertex=vertex(:,[2 3 1]);  % Switching axes LGA
%size(vertex)


p.mesh.data.meshtype={meshType};
p.mesh.data.vertices={vertex};
p.mesh.data.faces={face(:,[3 2 1])};
%p.mesh.data.faces={face(:,[1 2 3])};
 
newStruct.vertices=p.mesh.data.vertices{1};
newStruct.faces=p.mesh.data.faces{1};
disp('Decimating : This can take some time...');
tic
P=reducepatch(newStruct,decimationFraction);
toc
p.mesh.data.faces={P.faces};
p.mesh.data.vertices={P.vertices};


mesh_write_emse(p);



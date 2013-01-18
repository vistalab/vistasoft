function p=writeEMSEMeshFromFreesurfer(fsMeshName,outMeshName,meshType,decimationFraction)
% writeEMSEMeshFromFreesurfer(fsMeshName,outMeshName,meshType,decimationFraction)
% Does what it says. Takes a FREESURFER mesh and turns it into EMSE format
% Returns a structure 'p' containing the mesh.
% Requires Darren Weber's EEG toolbox (eeg.sourceforge.net)
% ARW 012104
if (ieNotDefined('fsMeshName'))
   [fsMeshName,fsPath]=uigetfile('*.*','Pick a freesurfer mesh file');
   fsMeshName=fullfile(fsPath,fsMeshName);

end
 
[path,name,ext,ver]=fileparts(fsMeshName);

if (strcmp(upper(ext),'.TRI'))
    [vertex,face]=freesurfer_read_tri(fsMeshName);
else
    
[vertex,face]=freesurfer_read_surf(fsMeshName);
end

%vertex=vertex+128;

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
    decimationFraction=0.2;
    disp('Decimating by 0.2 as a default');
end


p.mesh.path=path;
p.mesh.file=[name,ext];
vertex=vertex(:,[2 3 1]);  % Switching axes LGA



p.mesh.data.meshtype={meshType};
p.mesh.data.vertices={vertex};
p.mesh.data.faces={face(:,[3 2 1])};
 
newStruct.vertices=p.mesh.data.vertices{1};
newStruct.faces=p.mesh.data.faces{1};
disp('Decimating : This can take some time...');
tic
P=reducepatch(newStruct,decimationFraction);
toc
p.mesh.data.faces={P.faces};
p.mesh.data.vertices={P.vertices};

p.mesh.fileName=mesh_write_emse(p);



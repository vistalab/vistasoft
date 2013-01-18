function mrmSaveOffFile(msh,meshFile)
% Save mesh in OOGL (.off) file format
%
%   mrmSaveOffFile(msh,[meshFile])
%
% 2007.06.26 AJS wrote it.

if ieNotDefined('msh')
    error('Must define mesh to save!');
end

if ieNotDefined('meshFile'),
    outPathName = pwd;
    [f,p] = uiputfile('*.off', 'Select output file...', outPathName);
    if(isnumeric(f)); error('User cancelled.'); end
    meshFile = fullfile(p,f);
    drawnow;
end

% Check the mesh data format
% If data field exists this is probably an older mesh
if(isfield(msh,'data'))
    triangles = msh.data.triangles;
    origin    = msh.data.origin;
    vertices  = msh.data.vertices;
else
    triangles = msh.triangles;
    origin    = msh.origin;
    vertices  = msh.vertices;
end
% if(isfield(msh,'initVertices')&&~isempty(msh.initVertices))
%     vertices = msh.initVertices;
% end


%
% WRITE .off FILE
%
% Open file
fid = fopen(meshFile, 'w');
if fid == -1
  error('Could not open file for writing.'); 
end;

% XXX Should write this in binary
% Header
fprintf(fid, 'OFF\n');
fprintf(fid, '%d %d %d\n', ...
        size(vertices,2), size(triangles,2), 0); 

% Vertices
for ii=1:3
  vertices(ii,:) = vertices(ii,:) + origin(ii); 
end
fprintf(fid, '%f %f %f\n', vertices);

% Faces
fprintf(fid, '3 %d %d %d\n', triangles);

% Close file
fclose(fid);

return;


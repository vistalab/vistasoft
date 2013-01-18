function msh = mrmInflate(meshFile,iter,inflatedMeshFile)
% Inflate (unfold) mesh while minimizing distance and area distortions.
%
%   msh = mrmInflate([meshFile],[iterations=400],[inflatedMeshFile]);
%
% Must be run on a Linux machine, as this mainly uses Jonas Larson's
% surfrelax (Linux executable) 
%

if ieNotDefined('meshFile'),
  [filename, pathname] = uigetfile('*.mat','Select mrMesh file');
  meshFile             = fullfile(pathname,filename);
  drawnow;
end;
if ieNotDefined('iter'),
    iter = 400;
end;
if ieNotDefined('inflatedMeshFile')
    if(nargout<1)
        [p,f,e]          = fileparts(meshFile);
        inflatedMeshFile = fullfile(p, [f '_surfRelaxed_' num2str(iter) e]);
    else
        inflatedMeshFile = '';
    end
end;

surfrelaxFile = fullfile(fileparts(which('mrMesh')), 'surfrelax');

if(ischar(meshFile))
    load(meshFile);
elseif(isstruct(meshFile))
    msh = meshFile;
    clear meshFile;
else
    error('First argument must be either a filename or a mesh structure.');
end

% if data field exists this is probably an older mesh
if(isfield(msh,'data'))
    triangles = msh.data.triangles;
    origin    = msh.data.origin;
    vertices  = msh.data.vertices;
else
    triangles = msh.triangles;
    origin    = msh.origin;
    vertices  = msh.vertices;
end
if(isfield(msh,'initVertices')&&~isempty(msh.initVertices))
    vertices = msh.initVertices;
end

% Save mesh in OOGL (.off) format
inFile = [tempdir 'tempOOGL.off'];
outFile = [tempdir 'tempOOGL_relaxed.off'];

%
% WRITE .off FILE
%
% Open file
fid = fopen(inFile, 'w');
if fid == -1,
  delete(inFile);
  error('Could not open file'); 
end;

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

%--- actual smoothing
opt = ['-iter ' num2str(iter) ' -dist 0.1'];
system([surfrelaxFile ' ' opt ' ' inFile ' ' outFile]);

% Read new vertex locations
fid = fopen(outFile, 'r', 'ieee-be');
if fid == -1,
  delete(inFile);
  delete(outFile);
  error('Could not open file'); 
end
    
%--- read .off output file
% Header
hdr = fgetl(fid); %#ok<NASGU>
n = fread(fid, 3, 'int32');

% Read the vertices
vertices = fread(fid, [3 n(1)], 'float32');
newTriangles = fread(fid, [5 n(2)], 'int32');
fclose(fid);

for ii=1:3
  vertices(ii,:) = vertices(ii,:) - origin(ii);
end

newTriangles = newTriangles(2:4,:);
if(sum(newTriangles(:)-triangles(:))>0)
    error('triangles do not match!');
end

%--- put back
if isfield(msh,'data'),
  % mrMesh will recompute the normals if we remove them
  if(isfield(msh.data,'normals'))
    msh.data =  rmfield(msh.data,'normals');
  end;
  msh.data.vertices = vertices;
else
  if(isfield(msh,'normals'))
    msh =  rmfield(msh,'normals');
  end;
  msh.vertices = vertices;
end;
msh.lights = [];
msh.id = -1;

if(~isempty(inflatedMeshFile))
    % save
    [p, msh.name] = fileparts(inflatedMeshFile);
    msh.fileName = inflatedMeshFile;
    save(inflatedMeshFile, 'msh');
end
% clean up
delete(inFile);
delete(outFile);
if(nargout==0)
    clear msh;
end

return;

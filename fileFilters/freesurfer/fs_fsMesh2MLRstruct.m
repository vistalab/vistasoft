function [msh,lights,tenseMsh] = fs_FSMesh2MLR(fsMeshName,mmPerVox, host, id, varargin);
%
%   [msh,lights,tenseMsh] = fs_fs_FSMesh2MLR(fsMeshName,mmPerVox, host, id, varargin);
%
%
% Author: ARW (based on RFD's mrmBuildMesh)
% Purpose:
%  Take a mesh in Freesurfer sorf format and convert it into a mrLoadRet /
%  mrMesh-type mesh. Allows you to do the usual mrMesh type things like
%  relaxation...
%  Additional processing options can be set as well.  These 
%  options include:
%     * 'RelaxIterations'- the next value specifies how many extra smoothing iterations.
%     * 'SavetenseMsh'- if you specify any RelaxIterations and add this option, then
% you will get two meshes- the relaxed mesh and the unrelaxed (tense) mesh.
% 
% Returns:
% The mesh structure and a lights structure.
% You can also get the unrelaxed mesh out (tenseMsh).
%
% See Also
%  mrmMapVerticesToGray
%
mrGlobals;

summaryParams = 1;
meshName = '';
QueryFlag = 1;
relaxIter = 1;
saveTense = 0;  
backColor = [0.2 0 0];  % CHanged from Gray - partly just to keep track of EMSE meshes...

if (ieNotDefined('fsMeshName'))
   [fsMeshName,fsPath]=uigetfile('*.*','Pick a freesurfer mesh file');
   fsMeshName=fullfile(fsPath,fsMeshName);

end
if ieNotDefined('mmPerVox'), 
    mmPerVox=[1 1 1];
    disp('Assuming 1 1 1 mm per vox');
end
if ieNotDefined('host'), host = 'localhost'; end
if ieNotDefined('id'), id = 1; end

if(nargout>2),  saveTense = 1; end

% Parse the varargin values
for(ii=1:length(varargin))
    if    (strcmpi(varargin{ii}, 'RelaxIterations')), relaxIter = varargin{ii+1}; 
    elseif(strcmpi(varargin{ii}, 'QueryFlag')),       QueryFlag = varargin{ii+1}; 
    elseif(strcmpi(varargin{ii}, 'MeshName')),        meshName = varargin{ii+1}; 
    elseif (strcmpi(varargin{ii},'Background')),      backColor = varargin{ii+1};
    end
end

% Set initial parameters for the mesh.
msh = meshDefault(host,id,mmPerVox,relaxIter,meshName);

if QueryFlag,  msh = meshQuery(msh,summaryParams); end

% If the window is already open, no harm is done.
msh = mrmInitHostWindow(msh)

[msh, lights] = mrmInitMesh(msh,backColor);

disp('Importing mesh data from Freesurfer')
% 

% ***************************************************************
% We need to construct a basic msh structure from the file data.

[path,name,ext,ver]=fileparts(fsMeshName);

if (strcmp(upper(ext),'.TRI'))
    [vertex,face]=freesurfer_read_tri(fsMeshName);
else
    
[vertex,face]=freesurfer_read_surf(fsMeshName); 
end

% Now  I'm a little curious about this: It seemed to me that the faces in
% regular FS mesh files are in quad format (4 vertices per face). And so I
% don't understand how mrMesh can deal with this. But using mris_convert 
% you can generate triangle mesh files from regular freesurfer meshes so I
% propose to do this and avoid all confusion.
 
size(vertex)
size(face)
vertex=vertex'+128;
face=face'; 
face=face(:,[3 2 1]);

 
% Vertices come back rotated in an odd way. The entire cortex is rotated 90
% degrees about the L/R axis (i.e. the sag view is rotated 90degrees
% anticlockwise).
vertex=vertex([2 3 1],:);

v=squeeze(vertex([1,2],:));
v=v-128;

rotMat=[-1 0;0 -1];
v=v'*rotMat; 
vertex([1,2],:)=v'+128;


nVerts=length(vertex);

p.vertices=(vertex);
p.triangles=face;
p.triangles = p.triangles - 1
p.class='mesh';




% Sometimes we pass in the whole array of meshes.  Mostly, just one,
% though.
host = meshGet(msh,'host');
windowID = meshGet(msh,'windowid');


if isempty(host), host = 'localhost'; end

if isempty(windowID), error('Mesh must specify a window'); end
%[id, status, result] = mrMesh ('localhost', windowID, 'add_actor', p)
p.scale = meshGet(msh,'mmPerVox');
p = setSmooth(p,msh,1);
p = setDecimate(p,msh,1);
p.actor = meshGet(msh,'actor');
disp(p);

p.colors=ones(4,length(p.vertices))*255;

[a,b,c]=mrmesh('localhost',id,'set_mesh',p)
       
        p.scale = meshGet(msh,'mmPerVox');
        p = setSmooth(p,msh,1);
        p = setDecimate(p,msh,1);
        %p.actor = meshGet(msh,'actor'); 
        p.normals=mrmGet(msh,'normals');
        p.actor = meshGet(msh,'actor');
 

%disp('Building smoothed and decimated mesh for display...');
%mrmSet(msh,'buildMeshAndDecimateAndSmooth',voxels);
%[msh] = mrmSet(msh,'smooth')

% This is a little 'center object' routine.  We could put this into mrmSet,
% really.


vertices = mrmGet(msh,'vertices');
mrmSet(msh,'origin',-mean(vertices'));

% Save these unsmoothed data.
unSmoothedData = mrmGet(msh,'data');
msh.initVertices=vertices;
msh.grayLayers=3;
view=getSelectedVolume;
    disp('Finding vertex to gray map');
    % You have to do this before smoothing...
    
v2gMap = mrmMapVerticesToGray(vertices,view.nodes,[1 1 1],view.edges);

msh.vertexGrayMap=v2gMap;
msh.grayToVertexMap = mrmMapGrayToVertices(view.nodes,vertices, [1 1 1]);

% Now also try to find the other mapping: the mapping from the mesh to all
% the gray nodes: So that we can ask: for any arbitray gray node, which
% mesh point is it closest to?


% If we smooth, the mesh, it is done here.
if(relaxIter>0)
    
    mrmSet(msh,'smooth');
    
    % We get the curvature colors from the uninflated mesh
    % We should figure out the correct value to use as our threshold. The mean
    % isn't ideal, since it is moved around by the large areas with arbitrary
    % curvature (eg. corpus callosum). What we really want is the value that
    % corresponds to zero curvature.
    % maybe make the specific curvature map colors adjustable?
    % We now use the actual curvature values, so we know that zero is zeros
    % curvature.
    disp('Setting up the curvature colors');
    
    % Attach curvature data to the mesh.  We turn on the color later, I think.
    msh=mrmSet(msh,'curvature');
    p.colors=[repmat(msh.curvature,3,1); ones(1,length(msh.curvature))]*255;
    %[a,b,c]=mrmesh('localhost',id,'set_mesh',p)
    
    curvColorIntensity = 128*meshGet(msh,'curvatureModDepth'); % mesh.curvature_mod_depth;
    
    monochrome = uint8(round((double(msh.curvature>0)*2-1)*curvColorIntensity+127.5));
    
    msh = mrmSet(msh,'colors',monochrome);
    
    disp('Storing the smoothed mesh data computed by mrMesh...');
    data = mrmGet(msh,'data');
    msh = meshSet(msh,'data',data);
    msh = meshSet(msh,'connectionMatrix',1);
    
else
    % We don't smooth the data with mrMesh.  We just assign it.
    msh = meshSet(msh,'data',unSmoothedData);
    msh = meshSet(msh,'connectionMatrix',1);
end


% In either case, we return a version of the data without smoothing.  This
% mesh is used to register with the gray coordinates.  This is a little
% disorganized.  If we don't smooth, tenseMesh is identically msh.  
tenseMsh = msh;
tenseMsh = meshSet(tenseMsh,'data',unSmoothedData);

return;

%---------------------------------------
function p = setSmooth(p,mesh,val)
if val
    p.do_smooth = 1;
    p.smooth_iterations = meshGet(mesh,'smoothiterations');
    p.smooth_relaxation = meshGet(mesh,'smoothrelaxation');
    p.smooth_sinc_method = meshGet(mesh,'smoothmethod');
    p.do_smooth_pre = meshGet(mesh,'smooth_pre');
else
    p.do_smooth = 0;
    p.do_smooth_pre = 0;
end

return;

%----------------------------
function p = setDecimate(p,mesh,val)

if val
    p.do_decimate = 1;
    p.decimate_reduction = meshGet(mesh,'decimatereduction');
    p.decimate_iterations = meshGet(mesh,'decimateiterations');
else
    p.do_decimate = 0;
end

return;

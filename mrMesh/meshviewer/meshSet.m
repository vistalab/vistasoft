function msh = meshSet(msh,param,val,varargin)
% Set VTK mesh structure values
%
%   msh = meshSet(msh,param,val,varargin)
%
% The mesh structure contains enough information to recreate an image in a
% mrMesh window.  We need to write a display routine, meshDisplay(mesh),
% that duplicates the mesh perfectly.  That routine doesn't exist yet. 
%
% The actor (object) data in the mrMesh window can be obtained perfectly
% from a mrmGet call.  These are stored in msh.data The other parameters
% needed to crreate the image, such as the lights, camera position,
% smoothing and decimation options, are stored in the other fields of the
% mesh structure.
%
% See also, mrmGet and mrmSet
%    These routines retrieve values directly from a window
%    controlled by the mrMesh server.  These routines use the mesh
%    structure described here.
%
% Examples:
%   msh = meshSet(msh,'path',pwd);
%
%  Notes:  A single window is capable of displaying multiple actors.  The
%  choice of the word 'mesh' from this structure is probably a mistake.  It
%  is an object.  Also, the assignment of lights and camera position to the
%  actor is also probably a mistake.  There should be a
%  mrMeshWindow.lights, mrMeshWindow.actors, mrMeshWindow.renderParameters,
%  and so forth.
%
%  High on our list:  Separately control actors from the mrMeshWindow in
%  Matlab.

% TODO
%   We recently changed the format for .data.XXX to .XXX.  We left some old
%   compatibility code down below, and in meshGet.  Six months from now
%   (June or later), we should be able to get rid of the old code or just
%   test and produce a warning.

if ieNotDefined('msh'), error('Mesh not defined.'); end
if ieNotDefined('param'), error('Param not defined.'); end
if ~exist('val','var'), error('Val not defined.'); end

% remove spaces and capitals
param = mrvParamFormat(param);

switch(lower(param))
    case {'name','meshname'}
        msh.name = val;
    case {'type'}
        msh.type = val;
    case {'host','hostcomputer'}
        msh.host = val;
    case {'windowid','window','id'}
        msh.id = val;

    case {'filename'}
        msh.filename = val;
    case {'path','savepath'}
        msh.path = val;
        
    case {'actor','object','actornumber','objectnumber','whichactor','whichobject'}
        if ~isa(val,'numeric') | (val < 32)
            error('Bad actor number.'); 
        else msh.actor = val;
        end
        
    case {'lights','alllights'}
        msh.lights = val;
    case {'addlight'}
        if ~checkfields(msh,'lights'), msh.lights{1} = val;
        else msh.lights{end+1} = val;
        end
        
    case {'scale','mmpervox','millimeterspervoxel'}
        msh.mmPerVox = val;
    case {'ngray','ngraylayers','graylayers'}
        msh.grayLayers = val;
    case {'vertexgraymap','vertex2gray','vertex2graymap'}
        msh.vertexGrayMap = val;
    case {'grayvertexmap','gray2vertex','gray2vertexmap'}
        msh.grayVertexMap = val;
    case {'originalvertices','initvertices','initialvertices','unsmoothedvertices'}
        msh.initVertices = val;
    case {'curvature','curvatures','datacurvature'}
        msh.curvature = val;   
    case {'curvaturecolor','curvature_color'}
        msh.curvature_color = val;
    case {'modulatecolor','modulate_color'}
        msh.modulate_color = val;
    case {'mod_depth'}
        if checkfields(msh,'curvature_mod_depth'), msh.curvature_mod_depth = val;
        else msh.mod_depth = val; end
        
    % Mesh rendering parameters for build and smooth mesh routines
    case {'smooth_sinc_method','smoothsincmethod','smoothmethod'}
        msh.smooth_sinc_method = val;
    case {'smooth_relaxation','smoothrelaxation'}
        msh.smooth_relaxation = val;
    case {'smoothiterations','smooth_iterations'}
        msh.smooth_iterations = val;
      
        
    % At some point in time, the .data.XXX part should go away.  We leave it
    % now because of compatibility questions.  If the .data structure
    % exists we place the variables inside it.  If it doesn't exist, we
    % place them where we want them.
    case {'data','alldata'}
        msh.data = val;
    case {'vertices'}
        if checkfields(msh,'data'), msh.data.vertices = val; 
        else msh.vertices = val; end           
        
    case {'triangles'}
        if checkfields(msh,'data'), msh.data.triangles = val; 
        else msh.triangles = val; end           

    case {'normals'}
        if checkfields(msh,'data'), msh.data.normals = val; 
        else msh.normals = val; end           

    case {'actorrotation','rotation'}
        if checkfields(msh,'data'), msh.data.rotation = val; 
        else msh.rotation = val; end           

    case {'datacolors','datacolor','colors','color','overlaycolor','overlaycolors'}
        if checkfields(msh,'data'), msh.data.colors = val; 
        else msh.colors = val; end           

    case {'origin','center'}
        if checkfields(msh,'data'), msh.data.origin = val; 
        else msh.origin = val; end 
        
    case {'camera_space','center'}
        if checkfields(msh,'data'), msh.data.camera_space = val; 
        else msh.camera_space = val; end 
        
    case {'camerarotation'}
        % We don't store the camera rotation in the msh.  It changes too
        % frequently and can get dissociated from the display.  We set the
        % camera rotation from the open3dWindow (Edit) and we read/write it
        % using mrmGet/mrmSet.
        % msh.cameraRotation = val;
    case {'relaxiterations'}
        msh.relaxIterations = val;
        
    case {'connectionmatrix','conmat'}
        % mesh = mrmSet(msh,'conmat',1);
        m.uniqueVertices = meshGet(msh,'vertices')';              
        m.uniqueFaceIndexList = (meshGet(msh,'triangles') + 1 )';
        msh.conMat = findConnectionMatrix(m);
        
    case {'fibers'}
        % All fiber groups
        msh.fibers = val;

    otherwise
        error('Unknown mesh field.');
end

return;

    

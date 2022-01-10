function val = meshGet(msh,param,varargin)
%Get values from a mesh structure.
%
%   val = meshGet(msh,param,varargin)
%
%     'meshname'
%     'type'
%     'hostname'
%     'windowid'
%     'filename'
%     'savepath'
%     'actor'
%     'millimeterspervoxel'
%     'vertex2graymattermap'
%     'ngraylayers'
%     'unsmoothedvertices'
%     'data'
%     'origin'
%     'vertexcoordinates'
%     'triangles'
%     'normals'
%     'colors'
%     'connectionmatrix'
%     'datacolors'
%     'curvaturecolor'
%     'curvaturemodulationdepth'
%     'curvature'
%     'modulatecolor'
%     'relaxiterations'
%     'relaxfactor'
%     'smooth_sinc_method'
%     'smooth_relaxation'
%     'smoothiterations'
%     'smoothpre'
%     'decimate_reduction'
%     'decimate_iterations'
%     'lights'
%     'fibers'
%     'grayvertexmap'
%
%  These structures are used with
%  mrmViewer and open3dWindow in mrVista.  Some day, they will replace
%  the mrGray functionality.
%
% See also: meshSet, mrmGet, and mrmSet.
%
% Examples:
%    n = meshGet(msh,'filename');
%    h = meshGet(msh,'host');
%
% Author: Wandell
% Programming Notes:
% Checkfields more often

val = [];

% remove spaces and capitals
param = mrvParamFormat(param);

switch(lower(param))
    case {'name','meshname'}
        if checkfields(msh,'name'), val = msh.name; end
    case {'type'}
        if checkfields(msh,'type'), val = msh.type; end
    case {'host','hostname'}
        % Almost always localhost.  We have urged Dima to make it this way.
        if checkfields(msh,'host'),  val = msh.host;
        else val = 'localhost';
        end
    case {'filename','file'}
        % n = meshGet(msh,'filename');
        if checkfields(msh,'filename'), val = msh.filename; end
    case {'windowid','window','id'}
        % This is the window number.  We need to be able to query mrmGet
        % for how many windows are currently open.
        if checkfields(msh,'id'),  val = msh.id; end
    case {'path','savepath'}
        if checkfields(msh,'path'), val = msh.path; end

    case {'actor','object'}
        % I think there should be multiple actors and this is a vector.
        % Not really set up right yet.
        if checkfields(msh,'actor'), val = msh.actor; end


    case {'mmpervox','millimeterspervoxel'}
        if checkfields(msh,'mmPerVox'), val = msh.mmPerVox; end
    case {'vertexgraymap','vertex2graymattermap'}
        if checkfields(msh,'vertexGrayMap'), val = msh.vertexGrayMap; end
    case {'grayvertexmap','graymatter2vertexmap'}
        if checkfields(msh,'grayVertexMap'), val = msh.grayVertexMap; end
    case{'graylayers','ngraylayers'}
        if checkfields(msh,'grayLayers'), val = msh.grayLayers; end
    case {'originalvertices','initvertices','initialvertices','unsmoothedvertices'}
        if checkfields(msh,'initVertices'), val = msh.initVertices; end

    case {'data'}
        % In newer versions of mesh creation, we don't use the data
        % subfield.  We just put the same variables into msh.Mumble.  For
        % backwards compatibility, if the data field doesn't exist we still
        % return the data structure data.XXX but we create it on the fly
        % using the code below.
        % Notice that there are many cases where we check for the data
        % structure below.  At some point, no new meshes will have the data
        % structure and these checks could go away.
        if checkfields(msh,'data'), val = msh.data;
        else
            val.camera_space = 0;
            val.triangles = meshGet(msh,'triangles');
            val.vertices  = meshGet(msh,'vertices');
            val.rotation  = eye(3);
            val.colors    = meshGet(msh,'colors');
            val.origin    = meshGet(msh,'origin');
        end
    case {'origin','center'}
        if checkfields(msh,'data','origin'), val = msh.data.origin;
        elseif checkfields(msh,'origin'),    val = msh.origin;
        end
        if isempty(val)
            % No relevant field, so we compute the default, which is the
            % middle of the vertices.
            if isfield(msh,'vertices')
            val = -mean(msh.vertices,2)';
            else
                val=NaN;
            end
            
        end
               
    case {'vertices','vertexcoordinates'}
        if checkfields(msh,'data','vertices'), val = msh.data.vertices; end
        if checkfields(msh,'vertices'), val = msh.vertices; end
    case {'nvertices','numberofvertices'}
        if checkfields(msh,'data','triangles'),val = size(msh.data.vertices,2); end
        if checkfields(msh,'triangles'), val = size(msh.vertices,2); end

    case {'triangles'}
        if checkfields(msh,'data','triangles'),val = msh.data.triangles; end
        if checkfields(msh,'triangles'), val = msh.triangles; end
    case {'ntriangles'}
        if checkfields(msh,'data','triangles'),val = size(msh.data.triangles,2); end
        if checkfields(msh,'triangles'), val = size(msh.triangles,2); end

    case {'nedges'}
        val = length(findEdgesInGroup2(msh,nodeIndices));
    case {'normals'}
        if checkfields(msh,'data','normals'),val = msh.data.normals; end
        if checkfields(msh,'normals'), val = msh.normals; end

    case {'colors'}
        if checkfields(msh,'data','colors'),val = msh.data.colors; end
        if checkfields(msh,'colors'), val = msh.colors; end

    case {'connectionmatrix','conmat'}
        % We could always compute this on the fly, and we probably should,
        % from the triangles and so forth.  See meshSet();
        if checkfields(msh,'conMat'), val = msh.conMat; end
    case {'datacolors','datacolor','color','colors'}
        if checkfields(msh,'data','colors'), val = msh.data.colors; end

        % Rendering parameters
    case {'curvaturecolor'}
        val = msh.curvature_color;
    case {'curvaturemoddepth','curvaturemodulationdepth','mod_depth'}
        if checkfields(msh,'curvature_mod_depth'),val = msh.curvature_mod_depth;
        elseif checkfields(msh,'mod_depth'), val = msh.mod_depth; end
    case {'curvature','curvatures'}
        val = msh.curvature;
    case {'modulate_color','modulatecolor'}
        if checkfields(msh,'modulate_colors'), val = msh.modulate_color; end

    case {'relaxiter','relaxiterations'}
        if checkfields(msh,'relaxIterations'), val = msh.relaxIterations;
        else val = 2;
        end
    case {'relaxfactor'}
        if(meshGet(msh,'smooth_sinc_method') == 1), val = .0001;
        else  val = 1.0;
        end

    case {'smooth_sinc_method','smoothsincmethod','smoothmethod'}
        if checkfields(msh,'smooth_sinc_method'), val = msh.smooth_sinc_method; end
    case {'smooth_relaxation','smoothrelaxation'}
        if checkfields(msh,'smooth_relaxation'), val = msh.smooth_relaxation; end
    case {'smoothiterations','smooth_iterations'}
        if checkfields(msh,'smooth_iterations'), val = msh.smooth_iterations; end

    case {'smoothpre','smooth_pre'}
        val = msh.smooth_pre;

    case {'decimate_reduction','decimatereduction'}
        val = msh.decimate_reduction;
    case {'decimate_iterations','decimateiterations'}
        val = msh.decimate_iterations;

    case {'lights'}
        % Lights structures are returned.
        if(isfield(msh,'lights')),  val = msh.lights;
        else                        val = [];
        end
        
    case {'fibers'}
        % All fiber groups
        if(isfield(msh,'fibers')),   val = msh.fibers;
        else                         val = [];
        end

    otherwise
        error('Unknown parameter');

end

return;

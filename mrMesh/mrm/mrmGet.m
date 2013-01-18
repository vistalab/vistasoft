function val = mrmGet(msh,param,varargin)
% Communicate parameter values with a mrMesh window.
%
%   val = mrmGet(msh,param,varargin)
%
% The general object mesh, typically a brain surface, contains  various
% important parameters.  These include the identity of the host computer
% running the mrMesh server (usually 'localhost') the number of the mrMesh
% window the Actor (i.e., object) within the window
%
% Actor values [0,31] are reserved with camera (0), cursor (1). New meshes
% and lights are  assigned an actor value of 32 and above.
%
% The values in the mesh structure are accessed through the meshGet routine.
% The same mesh structure is used by mrMesh, mrGray and mrFlatMesh.  Hence,
% the mesh interface routines are kept in mrLoadRet-3.0\mrMesh\.
%
% Some parameters require additional specification. These can be passed as
% additional arguments that are parsed by the varargin mechanism.
%
% See also:  mrmSet, mrMesh, meshGet, meshSet
%
% Examples:
%    l = mrmGet(msh,'listOfActors');
%    cRot    = mrmGet(msh,'camerarotation');
%    bColor  = mrmGet(msh,'background');
%    d       = mrmGet(msh,'data');
%
% BW (c) Copyright Stanford VISTASOFT Team

% Programming Notes
%   * See mrmSet TODO List.
%   * Because mesh is a Matlab command, use the variable
%   name msh for the mesh parameter.
%

%% Default parameters
if ieNotDefined('msh'), error('You must specify a mesh.'); end
val = [];

host = meshGet(msh,'host'); 
if isempty(host), host = 'localhost'; end

windowID = meshGet(msh,'window id'); 
if isempty(windowID)|| windowID == -1, error('Mesh must specify a window'); end

%%
param = mrvParamFormat(param);

switch lower(param)
    case 'help'
        % Help command doesn't seem to return anything into val
        % [tmp,foo,val] = mrMesh(host,windowID,'help');
        help mrMesh
        
    case {'actordata','data','meshdata','alldata'}
        % If actorID is specified we only need msh.host and msh.windowID specified.
        % val = mrmGet(msh,'meshdata',actorID)  
        % val = mrmGet(msh,'meshdata')
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_all = 1;
        % p.actor = actorCheck(msh);
        [tmp,status,val] = mrMesh(host,windowID,'get',p); %#ok<*ASGLU>
        if status < 0, val = []; end
    case {'meshvertices','vertices'}
        % val = mrmGet(msh,'meshvertices',actorID)
        % val = mrmGet(msh,'meshvertices')
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_vertices = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        if isempty(v)
            
            warning('No vertices returned');
        else
            val = v.vertices;
        end
    case {'meshtriangles','triangles'}
        % val = mrmGet(msh,'meshtriangles',actorID)
        % val = mrmGet(msh,'meshtriangles')
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_triangles = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        val = v.triangles;
    case {'normals','meshnormals'}
        % val = mrmGet(msh,'mesh normals',actorID)
        % val = mrmGet(msh,'mesh normals');
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_normals = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        val = v.normals;
    case {'actorrotation','rotation'}
        % val = mrmGet(msh,'actorrotation',actorID)
        % val = mrmGet(msh,'actorrotation')
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_rotation = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        val = v.rotation;
    case {'actororigin','origin'}
        % val = mrmGet(msh,'actororigin',actorID)
        % val = mrmGet(msh,'actororigin')
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_origin = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        val = v.origin;
    case {'actorcolors','colors','coloroverlay'}
        % val = mrmGet(msh,'actorcolors',actorID)
        % coloroverlay = mrmGet(msh,'actorcolors');
        if isempty(varargin), p.actor = actorCheck(msh); 
        else p.actor = varargin{1}; end
        p.get_colors = 1;
        [tmp,foo,v] = mrMesh(host,windowID,'get',p);
        % Should we return RGBalpha, or RGB?
        val = v.colors;
    case {'getactorproperties','getall'}
        % val = mrmGet(msh,param,actorNumber)
        if length(varargin) < 1, error('Actor number required.'); end
        p.actor = varargin{1};
        p.get_all = 1;
        [tmp,foo,val] = mrMesh(host,windowID,'get',p);
    case {'allactors','actorlist','listofactors'}
        % val = mrmGet(msh,'actor list');
        %
        % The camera is always actor 0. We don't returning that in this
        % list. The cursor appears to be 2-4?
        % We assume lights and objects are in the actors range   32-64
        % We should probably have a different range for images, say 16-31?
        % Or 65-96?  We can also decode which is which by the returned
        % values.  So, mesh parameters have 
        %
        % We test using the origin because lights and objects have an origin
        % and it is a small transfer.
        % 
        p.get_origin = 1;
        for ii=1:10; 
            p.actor = ii;
            [s,s(ii)] = mrMesh('localhost',windowID,'get',p);
        end
        systemList = find(s == 1);
        for ii=1:32; 
            p.actor = ii+31;
            [s,o(ii)] = mrMesh('localhost',windowID,'get',p);
        end
        objectList = find(o == 1); objectList = objectList + 31;
        val.objectList = objectList;    % Lights and Meshes are here
        val.systemList = systemList;    % Camera and origin lines are here (I think).
        
    case {'camera','camera_all','cameraall'}
        p.actor = 0;
        p.get_all = 1;
        [tmp,foo,res] = mrMesh(host,windowID,'get',p);
        val = res;
    case 'camerarotation'
        p.get_rotation = 1;
        p.actor = 0;
        [tmp,foo,res] = mrMesh(host,windowID,'get',p);
        val = res.rotation;
    case 'cameraorigin'
        % val = mrmGet(msh,'cameraorigin');
        p.actor = 0;
        p.get_origin = 1;
        [tmp,foo,res] = mrMesh(host,windowID,'get',p);
        val = res.origin;
    case 'cameraspace'
        % val = mrmGet(msh,'cameraspace');
        p.actor = 0;
        p.get_camera_space = 1;
        [tmp,foo,res] = mrMesh(host,windowID,'get',p);
        val = res.camera_space;
        
    case 'background' % doesn't seem to work?
        [tmp,foo,val] = mrMesh(host,windowID,'get_background');
        
    case 'screenshot'
		% ras 05/2007: somehow, I get the back-buffer which is not 
		% updated (a previous mesh image, not the current screenshot).
		% I'm trying to insert a dummy command to update this buffer; hope
		% it doesn't make this unwieldy. I will try to resolve the issue
		% then come back and simplify this again.
		mrMesh(host,windowID,'refresh');
		
        p.filename = 'nosave';
        [tmp,foo,v] = mrMesh(host,windowID,'screenshot',p);
        val = permute(v.rgb, [2,1,3]);
            
    case {'cursorposition','cursor'}
        % val = mrmGet(msh,'cursor')
        p.actor = 1;
        % 2004.05.12 RFD: we now use new 'get_selection' command. This
        % returns the vertex number and the actor number rather than 3d
        % coords. In the end, this is the more appropriate thing to do.
        %tmp.get_origin = 1;
        %[id,stat,res] = mrMesh(host, windowID, 'get', tmp);
        %val = res.origin - meshGet(msh,'origin');
        %val = val([2,1,3]) ./ meshGet(msh,'mmPerVox');
        %val = val([2,1,3]);
        [id,stat,res] = mrMesh(host, windowID, 'get_selection', p);

        % This is more 0,1 differences between C and Matlab
        res.vertex = res.vertex+1;
        if(res.actor == meshGet(msh,'actor'))
            vert = meshGet(msh,'unsmoothedVertices');
            val = vert(:,res.vertex)';
            val = val([2,1,3]);
            val = val ./ meshGet(msh,'mmPerVox');
        else
            val = res.position - meshGet(msh,'origin');
            val = val([2,1,3]);
            val = val ./ meshGet(msh,'mmPerVox');
        end
        
    case {'cursorvertex'}
        p.actor = 1;
        [id,stat,res] = mrMesh(host, windowID, 'get_selection', p);
        if(res.actor == meshGet(msh,'actor'))
            % The vertex numbering in mrMesh runs from [0,N-1].  In Matlab
            % the vertices run from [1,N].  
            val = res.vertex + 1;
        else
            % not assigned to a vector, return -1
            val = -1;
        end
        
    case {'cursorraw','cursorinvolume'}
        % Warning:  Remember that the vertex number returned by Dima is not
        % the same vertex number (it is one less) than the one we use to
        % list our vertices.  We start from 1.  He starts from 0.
        p.actor = 1;
        [id,stat,res] = mrMesh(host, windowID, 'get_selection', p);
        val = res;
    
    case {'curroi','roi'}
        [id,stat,val] = mrMesh(host, windowID, 'get_cur_roi');
        if(isfield(val,'vertices'))
            val.vertices = val.vertices+1;
        end
        
    case {'meshsettings','settings','viewsettings','viewprefs'}
        val = meshSettings(msh); % ras 03/06        
        
    otherwise
        error('Unknown mrmMesh parameter');
        
end

return;

%----------------------

function actor = actorCheck(msh)
% We need to know which actor corresponds to this mesh. I wrote this
% routine rather than repeating the test throughout the code.
%
actor = meshGet(msh,'actor');

if isempty(actor)
    error('meshGet(msh,''get'') requires an actor in the mesh structure.'); 
end

return;

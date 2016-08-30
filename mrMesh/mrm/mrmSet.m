function [msh, ret] = mrmSet(msh,param,varargin)
% General interface for communicating with mrMesh parameters.  
%
%   [msh, ret] = mrmSet(msh,param,varargin)
%
%  This routine keeps track of what we need to do to adjust different types
%  of visual properties of the image.
%
%  The routine tries to update the msh structure to keep it in synch with
%  the display.  There may be bugs therein.
%
%  The mesh structure contains parameters that include various important
%  parameters.  These include the 
%    * identity of the host computer running the mrMesh server (usually 'localhost')
%    * the number of the mrMesh window (id)
%    * the Actor (i.e., object) within the window
%
%  Actor values [0,31] are reserved with camera (0), cursor (1). 
%  Meshes are assigned an actor value of 32 and above.
%
%  The values in the mesh structure are accessed through the meshGet
%  routine. The same mesh structure is used by mrMesh, mrGray and
%  mrFlatMesh.  
%
%  Some parameters require additional specification. These can be passed
%  as additional arguments that are parsed by the varargin mechanism in
%  Matlab.
%
% See also:  mrmSet, mrMesh, meshGet, meshSet
%
% Examples:
%     mrmSet(msh,'background',[.3,.3,.3,1]);
%     mrmSet(msh,'addlight',ambient,diffuse,origin);
%
% Programming Notes:  (TODO List)
%   * Query for the names and number of open mrMesh windows.
%   * Get the vertex number from a click (not just the XYZ position of the surface.
%   * Remove an actor from the window.  Add a new actor at a distinct position.
%   * Get various types of build_mesh working, not just smooth and decimate.
%   * Hide the lights
%
% HISTORY:
%
% 2004.06.11 RFD: fixed hideCursor. We also now need to use 'showcursor' to
% turn it back on, as it no longer comes on when you click the mesh. I've
% added a 'toggleCursor' command to make the GUI changes minimal (still
% uses just one button).
%
% Started by Wandell many years ago
%

% Default parameters
if ieNotDefined('msh'), error('You must specify a mesh.'); end

% Sometimes we pass in the whole array of meshes.  Mostly, just one,
% though.
if iscell(msh)
    host = meshGet(msh{1},'host');
    windowID = meshGet(msh{1},'windowid'); 
else
    host = meshGet(msh, 'host');
    windowID = meshGet(msh, 'windowid');
end

% Confirm that we have a host and windowID ready to go
if isempty(host), host = 'localhost'; end
if isempty(windowID), error('Mesh must specify a window'); end

% Lower case and remove spaces
param = mrvParamFormat(param);
switch param
    case {'close','closeone','closecurrent'}
        mrMesh(host,windowID,'close');
        msh = meshSet(msh,'id',-1);
    case {'closeall','allclose'}
        % mrmSet(msh(),'closeall');
        for ii=1:length(msh),  msh{ii} = mrmSet(msh{ii},'close'); end
        ret = msh;
        
    case {'actor','addactor','meshactor'}
        % msh = mrmSet(msh,'addactor');
        % Add an actor to an existing window, or if no window is open
        % open one, set open an actor, and set its windowID. 
        p.class = 'mesh';
        [~, ~, val] = mrMesh(host, windowID, 'add_actor', p);
        if checkfields(val,'actor'), 
            msh = meshSet(msh,'actor',val.actor);
            msh = meshSet(msh,'windowid',windowID);
        else 
            error('Problem adding mesh actor to window.'); 
        end
        
    case {'lightorigin'}
        % mrmSet(msh,'lightorigin',lightActor,origin);
        light.class  = 'light';        
        if length(varargin) < 2 || isempty(varargin{2}), 
            error('Require lightActor and origin');
        else
            light.actor  = varargin{1};
            light.origin = varargin{2};
        end
        mrMesh(host, windowID, 'set', light);
               
    case {'showlight'}
        % Sets up a light defined by the three parameters in window of the
        % msh.
        
        % mrmSet(msh,'addlight',ambient,diffuse,origin);
        l.class = 'light';
        [~,stat,res] = mrMesh(host, windowID, 'add_actor', l);
        if stat < 0, error('Error adding light actor.'); end
        
        light.actor = res.actor;
        
        if length(varargin) < 1 || isempty(varargin{1}), ambient = [0 0 0]; %[.3,.3,.3]; 
        else ambient = varargin{1}; end
        if length(varargin) < 2 || isempty(varargin{2}), diffuse = [1 1 1]; % [0.5, 0.5, 0.6]; 
        else diffuse = varargin{2}; end
        if length(varargin) < 3 || isempty(varargin{3}), origin = [500,0,300]; 
        else origin = varargin{3}; end
        
        light.ambient = ambient;
        light.diffuse = diffuse;
        light.origin = origin;
        mrMesh(host, windowID, 'set', light);

        % Should we add this light to the mesh structure?  Probably.  For
        % now, we return light if requested.
        if nargout > 1, ret = light; end
        
    case {'addlight'}
        if length(varargin) < 1 || isempty(varargin{1}), ambient = [.3,.3,.3]; 
        else ambient = varargin{1}; end
        if length(varargin) < 2 || isempty(varargin{2}), diffuse = [0.5, 0.5, 0.6]; 
        else diffuse = varargin{2}; end
        if length(varargin) < 3 || isempty(varargin{3}), origin = [500,0,300]; 
        else origin = varargin{3}; end
        
         [msh,ret] = mrmSet(msh,'showlight',ambient,diffuse,origin);
         msh = meshSet(msh,'addlight',ret);        
        
    case {'addimage','addimageactor'}
        % imgParameters.img = ieScale(rand(64,64),0,1);
        % imgParameters.actor = 38;
        % imgParameters.origin = [50,0,50];
        %
        % mrmSet(msh,'addimage',imgParameters)
        % imgParameters should contain
        %    .img     ( values between 0,1; image size is a power of 2 though we will pad if needed)
        %    .origin  (default = [0,0,0])
        %    .rotation
        % This code is an initial draft.  It needs more work and better
        % understanding.  But, it does put up an image in the window.
        %
        % The image must be a power of 2 in size because of openGL
        % considerations.
        % The image appears as a texture in a plane specified within the
        % parameters
        im.class = 'image';
        
        % Set up the parameters
        imgParameters = varargin{1};
        if checkfields(imgParameters,'rotation'), im.rotation = imgParameters.rotation;
        else im.rotation = [0 0 1; 0 1 0; 1 0 0]; end
        if checkfields(imgParameters,'origin'), im.origin = imgParameters.origin;
        else im.origin = [0 0 0]; end
        if checkfields(imgParameters,'actor'), im.actor = imgParameters.actor;
        else
            [~,~,r] = mrMesh(imageMesh.host, imageMesh.id, 'add_actor', im);
            im.actor = r.actor;
        end
        imgData = imgParameters.img;
        
        % Check the parameters
        if max(imgData(:)) > 1 || min(imgData(:)) < 0, error('Image data must be between 0 and 1'); end
        if size(imgData,3) ~= 1, error('We are expecting a gray scale image.'); end
        
        % Set up size parameters, making sure the array is a power of 2.
        % padarray(img,1,padsize(1));
        % padarray(img,2,padsize(2));
        imSize = 2.^ceil(log2(size(imgData)));
        im.width = imSize(1); 
        im.height = imSize(2);
        im.tex_width = imSize(2);
        im.tex_height = imSize(1);
            
        % Copy the data into the center of the image that has the proper
        % size.  Presumably, there is a way to do this with padarray().
        sz = size(imgData');
        pos = floor((imSize-sz)./2)+1;
        newData = zeros(imSize);
        newData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = imgData';
        
        im.texture = repmat(newData(:)', 3,1);
        
        % Set alpha to 0 if transparency is enabled (erode/dilate to smooth)
        % mask = imdilate(imerode(imData>0.1,strel('disk',4)),strel('disk',4));
        % im.texture(4,:) = double(mask(:));
        
        % No transparency
        im.texture(4,:) = ones(size(im.texture(1,:)));
        
        % Add the image data to the actor
        [~,~,~] = mrMesh(host, windowID, 'set', im);
        
    case {'removeactor','deleteactor','removeactors','deleteactors','removelistofactors','deletelistofactors'}
        % mrmSet(msh,'deleteActor',33)
        % Do we need to specify the class, such as light/mesh/image?
        
        if ~isempty(varargin{1}), deleteList = varargin{1};
        else  warning('mrmSet: No actors to delete.'); return;
        end
        
        deleteList = deleteList(deleteList);
        
        for ii=1:length(deleteList)
            p.actor = deleteList(ii);
            mrMesh(host, windowID, 'remove_actor', p);
        end
    
    case {'builddecimatesmooth','buildmeshanddecimateandsmooth'}
        % mrmSet(msh,'buildMeshAndDecimateAndSmooth',voxels);
        if length(varargin) < 1; error('Must pass in voxels.'); end
        p.voxels = varargin{1};
        % It is possible that scale should be scale = scale([2,1,3]) -- BW
        p.scale = meshGet(msh,'mmPerVox');
        p = setSmooth(p,msh,1);
        p = setDecimate(p,msh,1);
        p.actor = meshGet(msh,'actor'); 
        mrMesh(host, windowID, 'build_mesh', p);
        
    case {'buildnosmooth'}
        % mrmSet(msh,'buildMeshAndDecimateAndSmooth',voxels);
        if length(varargin) < 1; error('Must pass in voxels.'); end
        p.voxels = varargin{1};
        % It is possible that scale should be scale = scale([2,1,3]) -- BW
        p.scale = meshGet(msh,'mmPerVox');
        p = setSmooth(p,msh,0);
        p = setDecimate(p,msh,1);
        p.actor = meshGet(msh,'actor'); 
        mrMesh(host, windowID, 'build_mesh', p);
        
    case {'setmesh','setdata','data'}
        % mrmSet(msh,'setdata')
        p = meshGet(msh,'data');
        p.actor = actorCheck(msh);
        mrMesh(host, windowID, 'set_mesh', p);
        
    case {'meshvertices','vertices'}
        % mrmSet(msh,'vertices');
        p.actor = actorCheck(msh);
        p.vertices = meshGet(msh,'vertices');
        mrMesh(host, windowID, 'modify_mesh', p);

    case 'camerarotation'
        if isempty(varargin); error('Must pass in rotation matrix.'); end
        p.actor = 0;
        if ~isequal(size(varargin{1}),[3,3]), error('Rotation matrix is not 3x3');
        else p.rotation = varargin{1};
        end
        mrMesh(host,windowID,'set',p);
        
    case 'cameraorigin'
        if isempty(varargin); error('Must pass in origin.'); end
        if length(varargin{1}) ~= 3, error('Origin must be 3d vector');
        else p.origin = varargin{1};
        end
        p.actor = 0;
        mrMesh(host,windowID,'set',p);
        
    case 'cameraspace'
        p.actor = 0;
        p.camera_space = varargin{1}; % ?? val;
        mrMesh(host,windowID,'set',p);
      
    case 'background'
        % Set the RGB color of the background.
        c = varargin{1};
        if length(c) == 3, c(4) = 1; 
        elseif length(c) == 4
        else error('color must be RGB or RGBalpha');
        end
        p.color = c;
        mrMesh(host,windowID,'background',p);
        
    case 'transparency'
        % mrmSet(mesh,'transparency',1/0);
        if ~isempty(varargin), p.enable = double(varargin{1});
        else  p.enable = 1; end
        mrMesh(host, windowID, 'transparency', p);
            
    case {'windowsize','meshwindowsize','displaysize'}
        % mrmSet(msh,'windowSize',256,256);
        if length(varargin) < 2, error('Window size requires width and height'); end
        p.height = varargin{1};
        p.width =  varargin{2};
        mrMesh(host,windowID,'set_size',p);

    case {'refresh','windowrefresh'}
        [~,ret] = mrMesh(host,windowID,'refresh');

    case 'actorrotation'
        %  mrmSet(msh,'actorrotation',rMatrix);
        % Not debugged thoroughly!
        if isempty(varargin), error('Rotation matrix required.'); end
        p.rotation = varargin{1};
        p.actor = meshGet(msh,'Actor'); 
        mrMesh(host, windowID, 'set', p);
        msh = meshSet(msh,'rotation',p.rotation);

    case {'actororigin','origin'}
        %  mrmSet(msh,'origin',origin);
        if isempty(varargin), error('Origin argument.'); end
        p.origin = varargin{1};
        p.actor = meshGet(msh,'Actor'); 
        mrMesh(host, windowID, 'set', p);
        msh = meshSet(msh,'origin',p.origin);

    case {'applysmooth','applysmoothing'}
        % mrmSet(msh,'applysmooth');
        warning('Use meshSmooth, not mrmSet(msh,''applysmooth'') to smooth meshes')
        return;        
        %         p.smooth_iterations = msh.smooth_iterations;
        %         p.smooth_relaxation = msh.smooth_relaxation;
        %         p.smooth_sinc_method = msh.smooth_sinc_method;
        %         p.actor = meshGet(msh,'actor');
        %         [id,stat] = mrMesh(host, windowID, 'smooth', p);

    case {'smooth','smoothmesh','meshsmooth'}
        % mrmSet(msh,'smooth');
        warning('Use meshSmooth, not mrmSet(msh,''smoothlarge'') to smooth meshes')
        return;        
        %         p.smooth_iterations = meshGet(msh,'relaxIter');
        %         p.smooth_relaxation = meshGet(msh,'relaxFactor');
        %         p.smooth_sinc_method = meshGet(msh,'smoothMethod');
        %         p.actor = meshGet(msh,'actor');
        %         [id,stat] = mrMesh(host, windowID, 'smooth', p);
        
    case {'smoothlarge','smoothmeshlarge','meshsmoothlarge'}
        % mrmSet(msh,'smoothlarge',[smoothFactor = 3]);
        % RFD- we now fix the smoothing relaxation value and let the user
        % specify the number of iterations.
        warning('Use smoothpatch, not mrmSet(msh,''smoothlarge'') to smooth meshes')
        return;
        
        %         if isempty(varargin), sFactor = 3; else sFactor = varargin{1}; end
        %         p.smooth_iterations = sFactor;
        %         p.smooth_sinc_method = meshGet(msh,'smoothMethod');
        %         if(p.smooth_sinc_method)
        %             p.smooth_relaxation = 0.0001;
        %         else
        %             p.smooth_relaxation = 1.0;
        %         end
        %         p.actor = meshGet(msh,'actor');
        %         [id,stat] = mrMesh(host, windowID, 'smooth', p);
        %
    case {'decimate','decimatemesh'}
        % mrmSet(msh,'decimate_mesh');
        warning('Use reducepatch, not mrmSet(msh,''smoothlarge'') to smooth meshes')
        return;
        
        %         p.decimate_reduction = meshGet(msh,'decimate_reduction');
        %         p.actor = meshGet(msh,'actor');
        %         [id,stat,res] = mrMesh(host, windowID, 'decimate', p);
        %
    case {'curvature','curvatures'}
        % mrmSet(mesh,'curvature')
        % Shows the curvature shading and also attaches the values to the
        % mesh data structure
        % Hunh?  This routine looks like it gets the curvature values from
        % the window and puts them into msh rather than setting them.
        %         warning('Use meshColor, to color the mesh with its curvature')
        %         return;
        
        p.actor =          meshGet(msh,'actor');
        p.modulate_color = meshGet(msh,'curvaturecolor'); 
        p.mod_depth = meshGet(msh,'curvaturemodulationdepth'); 
        p.get_values = 1;
        
        [~, ~, v] = mrMesh(host, windowID, 'curvatures', p);
        msh = meshSet(msh,'curvature',v.values);
        
    case {'originlines'}
        %mrmSet(mesh,'originlines',0)   (Turn off)
        %mrmSet(mesh,'originlines',1)   (Turn on)
        if ~isempty(varargin), p.enable = varargin{1}; 
        else p.enable=0; end
        p.actor = meshGet(msh,'Actor'); 
         mrMesh(host, windowID, 'enable_origin_arrows', p);
        
    case {'cursorposition','cursor'}
        % msh = viewGet(VOLUME{1},'currentmesh');
        % mrmSet(msh,'cursorPosition',meshGet(msh,'origin'));
        % mrmSet(msh,'cursorPosition',[-100,-100,-100]);

        if ~isempty(varargin), val = varargin{1};
        else error('Must provide a coordinate.'); end
        val = val(:)';
        if length(val) ~= 3, error('Cursor coordinates must be 3D'); end
        
        mmPerVox = meshGet(msh,'mmpervox');
        origin = meshGet(msh,'origin');
        p.actor = 1;
        %p.origin = val([2,1,3]) .* mmPerVox + origin;
        %[id,stat,res] = mrMesh(msh.host,msh.id, 'set', p);
        p.position = (val([2,1,3]) .* mmPerVox + origin)';
        [~,~,res] = mrMesh(host,windowID, 'set_selection', p);
        if(isfield(res,'error'))
            disp([mfilename ': mrMesh error "' res.error '"']);
        end
        mrmSet(msh,'refresh');
        
    case {'cursorvertex'}
        if ~isempty(varargin), val = varargin{1};
        else error('Must provide a vertex.'); end
        vert = meshGet(msh,'vertices');
        origin = meshGet(msh,'origin');
        p.position = vert(:,val) + origin';
        p.actor = 1;
        [~,~,~] = mrMesh(host, windowID, 'set_selection', p);

    case {'cursorraw'}
        if(length(varargin)==1 && numel(varargin{1})==3), val = varargin{1};
        else error('Must provide a 1x3 coordinate.'); end
        p.position = val(:);
        p.actor = 1;
        mrMesh(host, windowID, 'set_selection', p);
        %if(stat~=0) disp(res); end
	
    case {'hidecursor','cursoroff'}
        % mrmSet(msh,'hidecursor');
        p.enable = 0;
        mrMesh(host,windowID, 'enable_3d_cursor', p);
    case {'showcursor','cursoron'}
        % mrmSet(msh,'showcursor');
        p.enable = 1;
        mrMesh(host,windowID, 'enable_3d_cursor', p);
        
    case {'colors','overlaycolors','overlay'}
        % mrmSet(mesh,'colors',rgbAlpha);
        if isempty(varargin), error('rgbAlpha data required.'); end
        c = varargin{1};
        
        % If it is a 1D variable, make it a gray scale color map.
        if min(size(c)) == 1, c = c(:); c = repmat(c,1,3); end

        % If the data are 3D, add the alpha channel now
        if size(c,2) == 3, c(:,4) = 255*ones(size(c,1),1); end
        if size(c,2) ~= 4, error('Bad color data.'); end
        p.actor = meshGet(msh,'actor');
        p.colors = uint8(c');
        mrMesh(host, windowID, 'modify_mesh', p);
        msh = meshSet(msh,'colors',p.colors);
        
     case {'alpha','alphachannel'}
        % mrmSet(mesh,'alpha',alpha);
        if isempty(varargin), error('alpha data required.'); end
        c = varargin{1};
        c = c(:);
        if(length(c)>1 && length(c)~=length(msh.data.colors(4,:)))
            error('Bad alpha data.'); 
        end
        p.actor = meshGet(msh,'actor');
        p.colors = uint8(msh.data.colors);
        if isa(c, 'uint8')
            p.colors(4,:) = c;
        else
            p.colors(4,:) = uint8(round(c*255));
        end
        mrMesh(host, windowID, 'modify_mesh', p);
        msh = meshSet(msh,'colors',p.colors);
        
    case {'windowtitle','title'}
        % mrmSet(msh,'windowtitle','title goes here');
        if isempty(varargin), error('Title required.'); end
        p.title = varargin{1};
        mrMesh(host, windowID, 'set_window_title',p);

    otherwise
        error('Unknown mrmMesh parameter');
        
end

return;

%----------------------

function actor = actorCheck(msh)
%
% We need this a lot, so I wrote this routine rather than repeating it
% throughout.
%
actor = meshGet(msh,'actor');

if isempty(actor)
    error('This meshGet call requires an actor in the mesh structure.'); 
end

return;

%---------------------------------------
function p = setSmooth(p,msh,val)
if val && meshGet(msh,'smoothiterations')>0
    p.do_smooth = 1;
    p.smooth_iterations = meshGet(msh,'smoothiterations');
    p.smooth_relaxation = meshGet(msh,'smoothrelaxation');
    p.smooth_sinc_method = meshGet(msh,'smoothmethod');
    p.do_smooth_pre = meshGet(msh,'smooth_pre');
else
    p.do_smooth = 0;
    p.do_smooth_pre = 0;
end

return;

%----------------------------
function p = setDecimate(p,msh,val)

if val && meshGet(msh,'decimateiterations')>0
    p.do_decimate = 1;
    p.decimate_reduction = meshGet(msh,'decimatereduction');
    p.decimate_iterations = meshGet(msh,'decimateiterations');
else
    p.do_decimate = 0;
end

return;


        % These don't seem to be much needed and could be eliminated.  They
        % are left around just in case we go on a building spree and decide
        % we need these
%     case {'builddecimate','buildmeshanddecimate','buildanddecimate'}
%         % mrmSet(mesh,'buildMeshAndDecimate',voxels);
%         if length(varargin) < 1; error('Must pass in voxels.'); end
%         p.voxels = varargin{1};
%         p.scale = meshGet(mesh,'mmPerVox');
%         p = setSmooth(p,mesh,0);
%         p = setDecimate(p,mesh,1);
%         p.actor = actorCheck(mesh);
%         [id, stat, res] = mrMesh(host, windowID, 'build_mesh', p);
%     case {'buildsmooth','buildandsmooth'}
%         % mrmSet(mesh,'buildSmooth',voxels);
%         if length(varargin) < 1; error('Must pass in voxels.'); end
%         p.voxels = varargin{1};
%         p.scale = meshGet(mesh,'mmPerVox');
%         p = setSmooth(p,mesh,1);
%         p = setDecimate(p,mesh,0);
%         p.actor = actorCheck(mesh);
%         [id, stat, res] = mrMesh(host, windowID, 'build_mesh', p);
%     case {'build','buildonly','buildmesh','buildmeshonly'}
%         % mrmSet(mesh,'buildMesh',voxels);
%         if length(varargin) < 1; error('Must pass in voxels.'); end
%         p.voxels = varargin{1};
%         p.scale = meshGet(mesh,'mmPerVox');
%         p = setDecimate(p,mesh,0);
%         p = setSmooth(p,mesh,0);
%         p.actor = actorCheck(mesh);
%         [id, stat, res] = mrMesh(host, windowID, 'build_mesh', p);

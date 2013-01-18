function [msh,lights,tenseMsh] = mrmBuildMesh(voxels, mmPerVox, host, id, varargin)
%
%   [msh,lights,tenseMsh] = mrmBuildMesh(voxels, mmPerVox, host, id, [options]);
%
% Build a mesh from a set of classification voxels. 
%
% Additional processing options can be set as well.  These 
% include:
%   'RelaxIterations'- the next value specifies how many extra smoothing iterations.
%   'QueryFlag'
%   'MeshName'
%   'Background'
%
% Returns:
% The mesh structure, a lights structure, and the unrelaxed mesh out
% (tenseMsh). 
%
% See Also: mrmMapVerticesToGray
%
% Examples:
%   fName ='/biac2/wandell/data/anatomy/dougherty/t1_class.nii.gz';
%   [class,mm] = readClassFile(fName,0,0,'left');
%   voxels = uint8(class.data == class.type.white);
%   msh = mrmBuildMesh(voxels, mm, 'Background', [0.3,0.4,0.5]);
%   msh = mrmBuildMesh(voxels, mm, 'localhost', -1);
%   msh = mrmBuildMesh(voxels, mm, [], [], 'RelaxIterations', 50); 
% 
%   meshVisualize(msh);
%
% Notes:
%  2003.09.17 RFD: vertex-to-volume mapping is now done in a separate
%  function (mrmMapVerticesToGray), and we don't call it. So, the calling
%  function will need to compute that mapping and add the appropriate
%  fields to the mesh struct.
%
% Author: RFD

% transparency is off by default because it is slow.
summaryParams = 1;
meshName = '';
QueryFlag = 1;
relaxIter = 0;
saveTense = 0;  
backColor = [1,1,1];  % Should this be mrmDefaultBackgroundColor; ????

if ieNotDefined('voxels'), error('Voxels are required.'); end
if ieNotDefined('mmPerVox'), error('mmPerVox is required.'); end
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
msh = mrmInitHostWindow(msh); 

[msh, lights] = mrmInitMesh(msh,backColor);

fprintf('[%s]: Building unsmoothed mesh for vertex mapping...', mfilename);

mrmSet(msh,'buildNoSmooth',voxels);

% This is a little 'center object' routine.  We could put this into mrmSet,
% really.
vertices = mrmGet(msh,'vertices');
mrmSet(msh,'origin',-mean(vertices'));

% Save these unsmoothed data.
unSmoothedData = mrmGet(msh,'data');

fprintf('[%s]: Smoothing mesh for curvature calculation...', mfilename);
p.actor = msh.actor;
p.smooth_sinc_method = msh.smooth_sinc_method;
p.smooth_iterations = msh.smooth_iterations;
p.smooth_relaxation = msh.smooth_relaxation;
mrMesh(msh.host,msh.id,'smooth',p);
%msh = meshSmooth(msh);

% Attach curvature data to the mesh.  We turn on the color later, I think.
msh = mrmSet(msh,'curvature');

% If we smooth, the mesh, it is done here.
if(relaxIter>0)
    fprintf('[%s]: Smoothing mesh for display...', mfilename);
    p.smooth_iterations = relaxIter;
    mrMesh(msh.host,msh.id,'smooth',p);
    
    % We get the curvature colors from the uninflated mesh
    % We should figure out the correct value to use as our threshold. The mean
    % isn't ideal, since it is moved around by the large areas with arbitrary
    % curvature (eg. corpus callosum). What we really want is the value that
    % corresponds to zero curvature.
    % maybe make the specific curvature map colors adjustable?
    % We now use the actual curvature values, so we know that zero is zeros
    % curvature.
    fprintf('[%s]: Setting up the curvature colors', mfilename);
    curvColorIntensity = 128*meshGet(msh,'curvatureModDepth'); % mesh.curvature_mod_depth;
    monochrome = uint8(round((double(msh.curvature>0)*2-1)*curvColorIntensity+127.5));
    msh = mrmSet(msh,'colors',monochrome);
    
    fprintf('[%s]: Storing the smoothed mesh data computed by mrMesh...', mfilename);
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

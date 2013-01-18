function [msh, lights] = mrmInitMesh(msh,bColor)
%Initialize the mrMesh window with the mesh data and the mesh lighting.
%
%   [msh, lights] = mrmInitMesh(msh,[bColor])
%
% The background color can be specified (bColor).  
%
% We should write a varargin{} interface to this so we can manually set
% more parameters.
%
% Removed: A scale factor (sFactor) can be set to make the default mesh
% size look reasonable.sFactor is not implemented  yet. 
%
% If no window exists, the calls in this routine open up an unwanted
% window.  Can we figure out how to prevent this?  Something about mrMesh?
%
% (c) Stanford Vista, 2010

if ieNotDefined('bColor'), bColor = [1,1,1]; end
if ieNotDefined('wSize'), wSize = [512,512]; end

if ~mrmCheckServer, mrmStart(1); 
else                mrmSet(msh,'refresh');  % Is this necessary?
end

disp('mrmInitMesh: Add mesh actor...');
msh = mrmSet(msh,'add actor');

msh = mrmSet(msh,'set data');
mrmSet(msh,'origin lines',0);

origin = meshGet(msh,'origin');
if ~isempty(origin), mrmSet(msh,'actor origin',origin); end

lights = meshGet(msh,'lights');
if isempty(lights)
    disp('Adding two default lights.')
    msh = mrmSet(msh,'addlight',[.4 .4 .3],[0.5 0.5 0.6],[500,0,300]);
    msh = mrmSet(msh,'addlight',[.4 .4 .3],[0.5 0.5 0.6],[-500,0,-300]);
    lights = meshGet(msh,'lights');
else
    % We should really address these through meshGet/Set.  But now we can
    % only get the whole lights structure.
    if isstruct(lights)
        % Some older meshes stored lights as an array of structs.  In the
        % newer version we have lights as a cell array.  If the lights is
        % an array of structs, we convert them to a cell array here, save
        % them, and carry on.
        tmp = cell(1,length(lights));
        for ii=1:length(lights), tmp{ii} = lights(ii); end
        clear lights
        lights = tmp;
    end
    for ii=1:length(lights)
        origin = lights{ii}.origin;
        ambient = [.4 .4 .3]; % lights{ii}.ambient;
        diffuse = [.5 .5 .6]; % lights{ii}.diffuse;
        mrmSet(msh,'showlight',ambient,diffuse,origin);
    end
end

% Why not gray?
mrmSet(msh,'background',bColor);

% Default window size
mrmSet(msh,'windowSize',wSize(1),wSize(2));

% We should have a general principle for how to set the scaling here.  For
% now, this is something that works with small pieces of brain.
defaultRotation = ...
    [ -0.9988    0.0496    0.0025;...
        -0.0492   -0.9940    0.0975; ...
        0.0073    0.0973    0.9952];
mrmSet(msh,'camerarotation',defaultRotation);

disp('Done.')

return;

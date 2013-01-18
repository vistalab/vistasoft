function newMsh = meshSmooth(msh,QueryFlag)
%Smooth a VTK mesh and update if there is a mesh in a current window
%
%   newMsh = meshSmooth(msh,QueryFlag)
%
% The msh can either be a file name to a white matter classification
% file or one of our VTK mesh data structures (see meshGet, meshSet).
%
% Several msh fields are checked to determine the smoothing
% parameters.  These are
%   smooth_iterations  (default 35)
%   smooth_relaxation  (default 0.15)
%   smooth_sinc_method (default 1)
%
% If you set  QueryFlag = 1, you will be asked about these parameter
% values.
%
% The relaxation factor only changes the smoothness by increasing the
% current value. If want you choose a value that is smaller than the
% current mesh smoothing, you should really revert to the original mesh and
% then smooth it.  Yes, we know, we could do that for you here.
%
% The smooth iterations specifies how much you want to process in order to
% converge.
%
% Example:
%  fName ='X:\anatomy\nakadomari\left\20050901_fixV1\left.Class';
%  msh = meshBuild(fName);
%
%  Not very smooth, default = 35
%  msh = meshSet(msh,'smooth_iterations',1);
%  msh = meshSmooth(msh);
%  msh = meshVisualize(msh);
%
% Author GB
% ras 01/07: if there's a mesh window open, auto-update the vertices
% rfb 08/10: populate initial vertices within meshSmooth
% al 04/11: removed a line in the code that repopulated the initialVertices 

if notDefined('msh'), error('This function needs a mesh input'); end
if notDefined('QueryFlag'), QueryFlag = 0; end
% If the input is a string, we build the mesh.
if ischar(msh), msh = meshBuild(msh); end

% If the parameters are set, we don't query the user.  If they are not set,
% we will pop up a window and check the parameters.
%
if isempty(meshGet(msh,'smooth_iterations')), msh = meshSet(msh,'smooth_iterations',30);  end
if isempty(meshGet(msh,'smooth_relaxation')), msh = meshSet(msh,'smooth_relaxation',0.5);  end
if isempty(meshGet(msh,'smooth_sinc_method')), msh = meshSet(msh,'smooth_sinc_method',0);  end
if isempty(meshGet(msh,'mod_depth')), msh = meshSet(msh,'mod_depth',0.15);  end
if QueryFlag
    prompt = {'Smooth with Windowed Sinc (0|1):',...
        'Smooth Iterations:',...
        'Smooth Relaxation (0-2):'};
    defAns = {num2str(meshGet(msh,'smooth_sinc_method')),...
        num2str(meshGet(msh,'smooth_iterations')),...
        num2str(meshGet(msh,'smooth_relaxation'))};
    resp = inputdlg(prompt, 'Set Mesh Build Parameters', 1, defAns);
    if(~isempty(resp))
        msh = meshSet(msh,'smooth_sinc_method',str2num(resp{1}));
        msh = meshSet(msh,'smooth_iterations',str2num(resp{2}));
        msh = meshSet(msh,'smooth_relaxation',str2num(resp{3}));
    else
        newMsh = msh;
        return
    end
end
fprintf('[%s]: Smoothing mesh...', mfilename)
smoothedMsh = smooth_mesh(msh);
fprintf('done. \n');
newMsh = msh;

newMsh = meshSet(newMsh,'vertices',meshGet(smoothedMsh,'vertices'));
newMsh = meshSet(newMsh,'colors',meshGet(smoothedMsh,'colors'));
newMsh = meshSet(newMsh,'normals',meshGet(smoothedMsh,'normals'));
newMsh = meshSet(newMsh,'triangles',meshGet(smoothedMsh,'triangles'));

% update display if it's open - which we detect by the presence of an id
if newMsh.id > 0
    mrmSet(newMsh, 'vertices');
end

return

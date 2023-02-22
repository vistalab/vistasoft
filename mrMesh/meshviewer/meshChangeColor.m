function newMsh = meshChangeColor(msh,modDepth)
%Change the color a VTK mesh according to its local curvature
%
%   newMsh = meshChangeColor(msh,[modDepth])
%
% If modDepth is not sent in, the mshGet(msh,'mod_depth') is checked.  If
% that field is empty, then the default is 0.20.
%
% Example:
%  fName ='X:\anatomy\nakadomari\left\20050901_fixV1\left.Class';
%  msh = meshBuild(fName);
%  msh = meshSmooth(msh);
%  msh = meshColor(msh);
%  msh = meshChangeColor(msh);
%  meshVisualize(msh);
%
% Author GB
%
% TODO:  Probably should be called meshChangeCurvatureMod
%

if ieNotDefined('msh'), error('This function needs a mesh input'); end
if ieNotDefined('modDepth')
    modDepth = ieReadNumber('Curvature Modulation Depth (0-1)',num2str(meshGet(msh,'mod_depth')));
    if isempty(modDepth), disp('User canceled'); return; end
end
msh = meshSet(msh,'mod_depth',modDepth);

if isempty(meshGet(msh,'curvature'))
    fprintf('Coloring mesh using curvature ...');
    coloredMsh = curvature(msh);
    fprintf('done\n');

    newMsh = msh;
    newMsh = meshSet(newMsh,'vertices',meshGet(coloredMsh,'vertices'));
    newMsh = meshSet(newMsh,'colors',meshGet(coloredMsh,'colors'));
    newMsh = meshSet(newMsh,'normals',meshGet(coloredMsh,'normals'));
    newMsh = meshSet(newMsh,'triangles',meshGet(coloredMsh,'triangles'));
    newMsh = meshSet(newMsh,'curvature',meshGet(coloredMsh,'curvature'));

else
    newMsh = msh;
end

curvColorIntensity = 128*meshGet(newMsh,'mod_depth'); % mesh.curvature_mod_depth;
monochrome = uint8(round((double(newMsh.curvature>0)*2-1)*curvColorIntensity+127.5));

colors = meshGet(newMsh,'colors');
colors(1:3,:) = repmat(monochrome,[3 1]);
newMsh = meshSet(newMsh,'colors',colors);

return;
function msh = meshFV2msh(fv,mmPerVox,windowID, actor)
% Convert Matlab faces/vertices to vistasoft mesh
%
% Example:  See t_meshSimpleShapes, t_meshCurvature
%
% BW (c) VISTASOFT Team, Stanford, 2013

%% Check and initialize parameters
if notDefined('mmPerVox'), mmPerVox = [1 1 1]; end
if notDefined('windowID'), windowID = 1000; end
if notDefined('actor'), actor = 33; end

% Create a vista mesh structure
msh = meshCreate;
msh = meshSet(msh,'window id',windowID);
msh = meshSet(msh,'actor',actor);

%% Copy the Matlab vertices faces and vertices into msh
msh = meshSet(msh,'vertices',double(fv.vertices'));

%% Set the scene origin
vertices = meshGet(msh,'vertices');
msh = meshSet(msh,'origin',-mean(vertices,2)');

% Set the scale
msh = meshSet(msh,'mmPerVox',mmPerVox);

%% Triangles and normals

% Permute the triangle order, for some reason.  Otherwise we have apparent
% holes in the meshes - one side is transparent and the other side opaque.
% We haven't understood this yet.
msh = meshSet(msh,'triangles',double(fv.faces(:,[3 2 1])' - 1));

% Compute and set vertex normals
msh = meshSet(msh,'normals',patchnormals(fv)');

%% Calculate mean curvature

% try
%     % [Umin,Umax,Cmin,Cmax,Cmean,Cgauss,Normal]
%     % Cmax is no good
%     % Cmin is possible
%     % Cmean is good
%     % Cgauss is not so good
%     % n is useless
%     [~,~,~,~,Cmean,~,~] = compute_curvature(fv.vertices,fv.faces);
%     msh = meshSet(msh,'curvature',Cmean);
% catch err
% Different calculation, slower, but it seems to run.
fprintf('Using tricurv_v01\n');
curvatures = tricurv_v01(fv.faces,fv.vertices);
msh = meshSet(msh,'curvature',curvatures.km);
% end

%% Build  color values from curvature

% This should become a separate routine

% Negative curvature is brighter because we multiply by -1.
% We compress because we are mostly interested in the curvature near 0.
% s = 0.1;
% c = ((2*c > 0) - 1) * .25 * 128 + 127.5;  % Formula from meshColor

% If curvature is negative, make the color index bigger
curvatureSaturation = 0.1;
curvatureContrast = 0.45;
curvatureCutpoint = -0.15;
c = -1 * (msh.curvature(:)) ./ (abs(msh.curvature(:)) + curvatureSaturation);
c = (c > curvatureCutpoint) * curvatureContrast * 128 + 96;  % Formula from meshColor

% Place the color map in a 4xN
c = c*ones(1,3);  
c(:,4) = 255;  % Make opaque (not working well)
c = round(c);
msh = meshSet(msh,'colors',c');

%% meshVisualize(msh)
end
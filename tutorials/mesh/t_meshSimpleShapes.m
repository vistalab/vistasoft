%% t_meshSimpleShapes
%
% Build a matlab mesh from the itkGray class files with simple shapes
%
% BW (c) Stanford VISTASOFT Team, 2013

%% Load the class file.  A sphere is 1 and everything else 0
fName = fullfile(mrvDataRootPath,'anatomy','sphere.nii.gz');
niClass = niftiRead(fName);
% showMontage(niClass.data)

%% View the data in Matlab
fv = isosurface(niClass.data,0.9);

% To view in Matlab window, you can do this.
% mrvNewGraphWin;
% patch(fv, 'FaceColor','red','EdgeColor','none');
% view(3); daspect([1,1,1]); axis tight
% camlight; camlight(-80,-10); lighting phong; 
% title('Iso surface via isosurface')

% The imperfections in the small sphere are highlighted by the curvature
% map.
mmPerVox = [1 1 1];
windowID = 1000;
msh = meshFV2msh(fv,mmPerVox,windowID);
meshVisualize(msh);

% mrvNewGraphWin; crv = meshGet(msh,'curvature'); hist(crv,50);

%% Smooth the sphere using smoothpath and show again.
smoothMode = 1; nIter = 30;
fv2 = smoothpatch(fv,smoothMode,nIter); 
mmPerVox = [1 1 1];
msh = meshFV2msh(fv2,mmPerVox,windowID);
meshVisualize(msh);

% mrvNewGraphWin; crv = meshGet(msh,'curvature'); hist(crv,50);

%% Load the class file.  A sphere is 1 and everything else 0
fName = fullfile(mrvDataRootPath,'anatomy','harmonic.nii.gz');
niClass = niftiRead(fName);
% showMontage(niClass.data)

%% View the data in Matlab
fv = isosurface(niClass.data,0.9);
% mrvNewGraphWin;
% patch(fv, 'FaceColor','red','EdgeColor','none');
% view(3); daspect([1,1,1]); axis tight
% camlight; camlight(-80,-10); lighting phong; 
% title('Iso surface via isosurface')

smoothMode = 1; nIter = 10;
fv = smoothpatch(fv,1,nIter); 
msh = meshFV2msh(fv);
meshVisualize(msh);


%% End

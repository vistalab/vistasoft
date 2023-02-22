%% t_meshFromClass
%
%   Convert itkGray Class file to mesh using Matlab tools.
%
% See also: t_meshShow
%
% BW (c) Stanford VISTA Team 

%% You might first check whether you can visualize a VISTASOFT mesh 
% Either run: t_meshShow
% Or, just run this code
%  load(fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','leftMesh.mat'));
%  meshVisualize(msh);

%% Build a matlab mesh from the itkGray class file 

niCFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','t1_class.nii.gz');
niClass = niftiRead(niCFile);
Ds = uint8(niClass.data);

% The ITKGRAY class labels are
%    0: unlabeled
%    1: CSF
%    2: Subcortical
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 

% Set the labels for everything that is not left gray or white to
% unlabeled. 
Ds(Ds == 1) = 0; 
Ds(Ds == 2) = 0; 
Ds(Ds == 4) = 0; 
Ds(Ds == 5) = 0; 
Ds(Ds == 6) = 0; 
% showMontage(double(Ds))

%% Matlab calculations reducing the patches and computing normals

% Make a picture of the cortical mesh.  We have all the information.
fv = isosurface(Ds,1);

% Reduce to about 30K faces.  That's enough
nFaces = size(fv.faces,1);
maxFaces = 4*10^4;    % 40,000 faces?
if nFaces > maxFaces
    p = maxFaces/nFaces;
    fv = reducepatch(fv.faces,fv.vertices, p);
end

% Smooth
smoothMode = 1; nIter = 3;
fv = smoothpatch(fv,smoothMode,nIter);  

% mrvNewGraphWin;
% patch(fv, 'FaceColor','red','EdgeColor','none');
% view(3); daspect([1,1,1]); axis tight
% camlight; camlight(-80,-10); lighting phong; 
% title('Iso surface via isonormals')

%% Now, take the Matlab information and put it into VISTASOFT mesh 
mmPerVox = [1 1 1];
windowID = 1000;
actor = 33;
msh = meshFV2msh(fv,mmPerVox,windowID, actor);
meshVisualize(msh);

%% End



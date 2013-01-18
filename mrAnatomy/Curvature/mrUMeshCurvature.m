function curv = mrUMeshCurvature
%
% AUTHOR: M. Khoury
% DATE:   07.31.99
% PURPOSE:
%    Call back for creating curvature from a mrGray mesh file.  Also used in
% utility for a while to calculate the curvautre.
%
% NOTES:

% 
% DEBUGGING
%curdir = pwd;
%chdir('X:\anatomy\poirson\right\unfold\smallTest');
% 

% Find out where you are, and then change to the general anatomy
% area 
curDir = pwd;
chdir(getAnatomyPath(''));

% Read in the flat file
% 
[fname pname] = uigetfile('*.mat','Flat File');
if (pname == 0) 
  curv = [];
  return;
end

chdir(pname);
curv.flatfile = [pname fname];
load(fname);

%% Read data from the MrM file
% 
[fname pname] = uigetfile('*.mrm','Mesh File');
chdir(pname);
curv.meshfile = [pname fname];
mesh = mrReadMrM(fname);

%% Get the curv values and assign them to the 3D points
% 
curv.val = mrMeshCurvature(mesh, gLocs3d );

  
%% Plot the flattened image
% 
gLocs2d(isnan(gLocs2d))=0;
[imUnfold rowF colF fSize] = viewUnfold(gLocs2d,1,mkGaussKernel(8,4),...
  					[cool(64); .5 .5 .5],curv.val);
figure;
imshow(imUnfold,[]);
grid on; axis on

%% Save the curv to flat.mat
%
[fname, pname] = uiputfile('*.mat', 'Select file name');

if fname == 0
   disp('Your work has NOT been saved.');
else
   chdir(pname);
   curvature = curv.val;
   if exist('perimeterIdx','var')
   	save(fname,'curvature','gLocs2d','gLocs3d','perimeterIdx',...
         'gLocs3dfloat','startPoint','unfList','xSampGray');
   else
   	save(fname,'curvature','gLocs2d','gLocs3d',...
         'gLocs3dfloat','startPoint','unfList','xSampGray');
   end
   disp(['Your work has been saved in ', fname]);
end

% Go back where you started
% 
chdir(curDir);

return;


%% t_mrdViewFibers
%
% Load and view a set of fibers stored in a PDB (v3) file using mrMesh.
% 
% (c) Stanford VISTA Team

%% Make sure that vistadata is on your path
% vistaDataPath;


%% dtiStart for scripts

dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
% Initialize mrDiffusion
[dtiFig, dtiH]= mrDiffusion('on',dt6Name);
% At this point you can use dtiSet/Get on dtiH

if isunix, disp('Start mrMeshSrv.exe')
else       mrmStart
end

%% Load fiber group structure
difDir = fullfile(mrvDataRootPath,'diffusion','sampleData','dti40');
chdir(difDir)

fgName = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb');
% The mtr<> function name is old from metrotrac days.  It will probably change some
% day.
fg = mtrImportFibers(fgName);

%% Show fibers in mrMesh

% Attach the fiber group to the handles
dtiH = dtiSet(dtiH,'add fiber group',fg);

set(dtiH.cbUseMrMesh, 'Value',1);     % Use mrMesh for update
set(dtiH.cbShowFibers,'Value',1);     % Show loaded fibers
set(dtiH.cbShowMatlab3d,'Value',0);   % No 3d Matlab window
set(dtiH.popupBackground,'Value',2);  % Mean diffusivity

guidata(dtiFig,dtiH);  % Refresh the Matlab window handles.

mrmCloseWindow(dtiH.mrMesh.id,dtiH.mrMesh.host);

showMeshWindow = 1;
dtiH = dtiRefreshFigure(dtiH,showMeshWindow);

%% The code below pulls out key routines from dtiRefreshFigure 

% Closing the window and then running this is much faster than removing the
% previous actors.
mrmCloseWindow(dtiH.mrMesh.id,dtiH.mrMesh.host);

% This code, which is not normally used, permits a faster reload of the
% mrMesh window. The code below here could be placed in a routine like
%
%   id = dtiMeshView(dtiH,varargin);
%
set(dtiH.popupBackground,'Value',1);  % Choose type of background (1-4)
set(dtiH.rbSagittal,'Value',1);       % Choose which planes
set(dtiH.rbCoronal, 'Value',0);
set(dtiH.rbAxial,   'Value',1);

% With mrMesh - This started with the code from dtiRefreshFogure/dtiFiberUI
% Needs anat, anatXform
[xSliceRgb,ySliceRgb,zSliceRgb,anat,anatXform, ...
    mmPerVoxel,xform,xSliceAxes,ySliceAxes,zSliceAxes] = ...
    dtiGetCurSlices(dtiH);

curPosition = dtiGet(dtiH,'curpos');

% Should be:
% anatXform = dtiGet(dtiH,'anatXform');

[zIm] = dtiGetSlice(anatXform, anat, 3, curPosition(3), [], dtiH.interpType);
[yIm] = dtiGetSlice(anatXform, anat, 2, curPosition(2), [], dtiH.interpType);
[xIm] = dtiGetSlice(anatXform, anat, 1, curPosition(1), [], dtiH.interpType);
% figure; imagesc(zIm); axis image; colormap(gray)

% This is a little slow.
[xIm,yIm,zIm] = dtiMrMeshSelectImages(dtiH,xIm,yIm,zIm);
origin = dtiMrMeshOrigin(dtiH);
dtiH = dtiMrMesh3AxisImage(dtiH, origin, xIm, yIm, zIm);

%%  Manipulating the mesh view

% Need to permute the rotation matrix, I think, for various cases.
% I haven't worked that out.

msh = dtiGet(dtiH,'mesh'); % If you have a mrDiffusion guidata in dtiH
mrmRotateCamera(msh.id,'front',1); pause(1)
mrmRotateCamera(msh.id,'back',1);  pause(1)
mrmRotateCamera(msh.id,'top',1);   pause(1)
mrmRotateCamera(msh.id,'bottom',1);pause(1)
mrmRotateCamera(msh.id,'right',1); pause(1)
mrmRotateCamera(msh.id,'left',1);


%% End after here


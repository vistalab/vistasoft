function dtiH = fgMesh(dtiH,fgList,meshID,wClose)
% Show fibers in a mrMesh plot
%
%   dtiH = fgMesh(dtiH,[fgList=1:nFiberGroups],[meshID=174],[wClose = -1])
%
% dtiH is a mrDiffusion set of handles
% fgList is a vector listing which fiber groups numbers to show
% meshID:  WIndow number, default is 174
% wClose:  Boolean, should we close the mesh window (faster) before showing
% or not.
%
% Example:
%
%  dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
%  dt6Name = fullfile(dataDir,'dti40','dt6.mat');
%  [dtiFig, dtiH]= mrDiffusion('off',dt6Name);
%  fgName = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb');
%  fg = mtrImportFibers(fgName);
%  dtiH = dtiAddFG(fg,dtiH);
%
%  fgMesh(dtiH)           %Close current window.  Reoppen.
%  fgMesh(dtiH,1,174,1);  %Close window 174.  Then reopen
%  fgMesh(dtiH,1,101,0);  %Don't close 101.  Replace data in 101.
%
% If the meshID does not match the current open windows, they are not
% closed.
%
% See also:  t_mrdViewFibers, t_mrdFibers, dtiRefreshFigure, fgGet
%
% (c) Stanford Vista Team

% Programming TODO
% We should be able to show the fibers without the background image, or
% with a specified background image (e.g., a T1).
%
% Sometimes the fiber coordinates are not in ACPC.  We should be able to
% figure out where they are and put them in ACPC for visualization.
% Perhaps there should be a fg.coordSpace flag that lets us figure this
% out.

if notDefined('dtiH'), [dtiFig, dtiH]= mrDiffusion('off');
else                    dtiFig = dtiGet(dtiH,'main figure');
end

nFG = dtiGet(dtiH,'n fibergroups');
if notDefined('fgList'), fgList = 1:nFG; end
if notDefined('wClose'), wClose = 1; end
if notDefined('meshID'), meshID = 174; end

% Current meshID is this: meshGet(dtiH.mrMesh,'windowID')

% Get mrDiffusion structure set right.  We should probably be able to turn
% on which fiber groups we show by a flag.
set(dtiH.cbUseMrMesh, 'Value',1);     % Use mrMesh for update
set(dtiH.cbShowFibers,'Value',1);     % Show loaded fibers
set(dtiH.cbShowMatlab3d,'Value',0);   % No 3d Matlab window
dtiH.fiberGroupShowMode = 3 ;         % Show the fiber groups with fg.visible=1
dtiH.mrMesh = meshSet(dtiH.mrMesh,'windowID',meshID);

% Set visibility of the different fiber grups
v = zeros(nFG,1); v(fgList) = 1;
for ii=1:nFG
    dtiH.fiberGroups(ii).visible = v(ii);
end

guidata(dtiFig,dtiH);  % Refresh the Matlab window handles.

if wClose
    mrmCloseWindow(meshID,dtiH.mrMesh.host);
    %     if isunix, disp('Start mrMeshSrv.exe')
    %     else       mrmStart
    %     end
end

% The title is supposed to be set in dtiMrMesh3AxisImage.  It is not
% appearing correctly, though.
showMeshWindow = 1;
dtiH = dtiRefreshFigure(dtiH,showMeshWindow);

return

%% t_mrdFibersLoad
%
% OLD - probably should be deleted.
%
% Initialize a fiber group, potentially cull them using old ER code, and
% save them (culled).
%
% See: t_mrdArcuatePredictions
%
% (c) Stanford VISTA Team

doculling = 0;

%% Read the dt6 file.

% We load up the dt6 and open the mrDiffusion window so that we can easily
% transform between spaces.
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

% get the xForm from image space 3 acpc space
xForm.img2acpc = dtiGet(dtiH,'img 2 acpc xform');

% get the xForm from acpc space to image space
xForm.acpc2img = dtiGet(dtiH,'acpc2img xform');

% Set the colors of the three fiber groups.
cList = {[200,50 ,50],[50,200,50],[50,50,200]};

%% Load the first STT group

fgName{1} = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','R_Arcuate_Box_STT.mat');
temp = dtiReadFibers(fgName{1}); % Fiber coordinates in acpc space

if doculling
 % Remove redundant fibers from the group:
 fgAcpc(1) = dtiCullFibers(temp, dt6Name);
else
 fgAcpc(1) = temp;    
end

%% read ConTrac fiber group
fgName{2} = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','R_Arcuate_ctr_clean.mat');
temp = dtiReadFibers(fgName{2}); % Fiber coordinates in acpc space

if doculling
 % Remove redundant fibers from the group:
 fgAcpc(2) = dtiCullFibers(temp, dt6Name);
else
  fgAcpc(2) = temp;  
end

%% Merge them first fiber group
fgName{3} = 'R_Arcuate_Box_merged_stt_ctr-culled.mat';
fgAcpc(3) = dtiMergeFiberGroups(fgAcpc(1),fgAcpc(2),fgName{3}); % Fiber coordinates in acpc space

%% Spatial transforms into image space

% Fibers are stored in ACPC space.
% In this space, they are in mm
%    fLengths = fgGet(fg,'fiber lengths');
%     \mrvNewGraphWin; hist(fLengths,100)
fgImg = struct(fgAcpc);
for ii = 1:length(fgAcpc)
 dtiH = dtiSet(dtiH,'add fiber group',fgAcpc(ii));
 
 % Have a look at the fibers.  Visualizations are in ACPC space.
 % fgMesh(fgAcpc{i},dtiH);
 
 % Create a version of the fiber group in image space for computations
 % There is a problem:  See dtiXformFiberCoords.  But since this script
 % should probably go away, I am not fixing it now.
 fgImg(ii) = dtiXformFiberCoords(fgAcpc(ii),xForm.acpc2img);
 
 fgImg(ii).colorRgb = cList{ii};

end

%% Save

% Becasuse dtiCullFibers takes a while for the large group, we save these
% out. 
culledFiberGroups = ...
    fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','culledFiberGroups.mat');
save(culledFiberGroups,'fgImg');

%% To view the saved fibers ... 

% guidata(dtiF,dtiH);
% figure(dtiF)

% To load the fiber groups:
%   load(culledFiberGroups,'fgImg')

%% End
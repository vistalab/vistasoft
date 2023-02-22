function t_mrdFiberArcuatePredictions(fitTool)
% OUT OF DATE
%
% Needs to be cleaned up to work with LiFE.  Should be part of tutorial
% training for that project.
%
%
% (A.1) Load a fiber group for the Arcuate Fasciculum estimated with STD
% (A.2) Load a precomputed ROI centered on the Arcuate
% (A.3) Estimate diffusion predictions in the ROI.
%
% (B.1) Load a fiber group for the Arcuate Fasciculum estimated with conTrack
% (B.2) Load a precomputed ROI centered on the Arcuate
% (B.3) Estimate diffusion predictions in the ROI.
%
% (C.1) Merge fibers from A and B
% (C.2) Load a precomputed ROI centered on the Arcuate
% (C.3) Estimate diffusion predictions in the ROI given the merged fibers.
%
% fitTool can be 'cvx' or 'linprog'
%
% Example:  
%    t_mrdFiberArcuatePredictions(1)
%
% See also:  t_mrdTensors, t_mrdViewFibers, dwiLoad, dtiGet/Set, t_mrdFiberPredictions
%
% (c) Stanford VISTA Team

recompute = 0; % recompute all variables from stored vars

% here we recompute all the variables for the minimization, this is slow,
% so in alternative we have saved some variables in
% vistadata/diffusion/fiberPrediction/stored/testminimization.mat
if ~recompute
 load(fullfile(mrvDataRootPath,'diffusion','fiberPrediction','stored','testMinimization.mat'));
 dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
 dt6Name = fullfile(dataDir,'dti40','dt6.mat');
 [dtiF, dtiH] = mrDiffusion('off',dt6Name);
keyboard
else
 %% set up the fiber group structures, remove redundant fibers and set up dti files and xForms:
 doculling = 1;
 fprintf('[%s] setting up the three fiber groups\n',mfilename)
 [fgImg fgAcpc dtiH dtiF dt6Name xForm dwi] = setFiberGroups(doculling);
 
 %  Initialize variables and select some voxels coordinates
 bvecs = dwiGet(dwi,'diffusion bvecs');
 nB    = dwiGet(dwi,'n diffusion bvecs');
 bvals = dwiGet(dwi,'diffusion bvals');
 
 
 %% Find the voxels (in image coords) that contain fibers
 fprintf('[%s] Loading the ROI and finding its coordinates in image space\n',mfilename)
 allCoords = dtiGet(dtiH,'fg img coords unique');
 
 % We will look at a subset of the voxels of the fibers passing through a saved ROI
 roiName = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','ROIs','R_Arcuate_Box.mat');
 roi = dtiReadRoi(roiName);
 
 % Loading a region of interest to analyze.
 % take the ROI coordinates that lives in Acpc space and transform into
 % image indices
 roiCoords = unique(round(mrAnatXformCoords(inv(xForm.img2acpc), roi.coords)),'rows');
 
 % now we'll remove any fibers that don't pass through the roi and also any
 % roi coords that don't have fibers in them
 fgImg = rmfield(fgImg,'subgroup');
 
 %  intersect fibers with the roi to remove fibers that do not pass through
 %  the roi
 for ifg = 1:length(fgImg)
  fgImg(ifg) = dtiIntersectFibersWithRoi([],'and',[],dtiNewRoi('tmp','r',roiCoords),fgImg(ifg));
  fgImg(ifg).subgroup = []; % add back the filed just removed so that dtiIntersect could work.
  
  % intersect roi with fibers to remove roi coordinates that do not
  % contain fibers
  fgcoords{ifg} = horzcat(fgImg(ifg).fibers{:})';
  fgcoords{ifg} = unique(round(fgcoords{ifg}),'rows');
  coords{ifg}   = intersect(fgcoords{ifg},roiCoords,'rows');
 end
 
 %% Make the list of tensors for each fiber and node
 % These parameters could be adjusted to improve the quality of the fit.
 fprintf('[%s] Making a list of tensors for each fiber\n',mfilename)
 d_ad = 1.5; d_rd = 0.5;
 dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
 for i = 1:length(fgImg)
  fgImg(i).Q = fgTensors(fgImg(i),dParms); % make a tensor-based rapresentation fo each fiber
 end
 
 %% Find all the sample locations of each fiber that pass through each voxel
 fprintf('[%s] Finding all locations of fibers passing through each voxel in the ROI\n',mfilename)
 for ifg = 1:length(fgImg)
  % We create a cell array,node2voxel{} of the same size as the fibers{}. The
  % entries of node2voxel specify whether a node in the fiber is inside of a
  % particular row in coords.  If the node is not in any of the coords, the
  % entry is set to 0.
  nFiber{ifg} = fgGet(fgImg(ifg),'n fibers');
  node2voxel  = cell(size(fgImg(ifg).fibers));
  for ii      = 1:nFiber{ifg}
   nodeCoords = round(fgImg(ifg).fibers{ii}');
   
   % The values in loc are the row of the coords matrix that contains
   % that sample point in a fiber.  For example, if the number 100 is
   % in the 10th position of loc, then the 10th sample point in the
   % fiber passes through the voxel in row 100 of coords.
   [tf, node2voxel{ii}] = ismember(nodeCoords, coords{ifg}, 'rows');
  end
  
  %% Now, compute the (fiber,node) pairs in each voxel
  fprintf('[%s] Computing fiber/node pairs in each voxel\n',mfilename)
  nCoords = size(coords{ifg},1);
  voxel2FNpair = cell(1,nCoords);
  for thisFiber=1:nFiber{ifg}
   % We need to know both the nodes that pass through a voxel
   lst = (node2voxel{thisFiber}~=0);
   nodes = find(lst);
   
   % And we need to know which voxels they pass through
   voxelsInFiber = node2voxel{thisFiber}(lst);
   
   % Then we store for each voxel the (fiber,node) pairs that pass through
   % it.
   for jj=1:length(voxelsInFiber)
    voxel2FNpair{voxelsInFiber(jj)} = ...
     [voxel2FNpair{voxelsInFiber(jj)},[thisFiber,nodes(jj)]];
   end
  end
  
  %%  Some gets on voxel2FNpair
  % Histogram of the number of nodes in each voxel
  nPairs = zeros(1,nCoords);
  for cc = 1:nCoords
   nPairs(cc) = length(voxel2FNpair{cc})/2;
  end
  mrvNewGraphWin; hist(nPairs,30)
  title(sprintf('Number of nodes per voxel',fgImg(ifg).name))
  
  % Histogram of the number of unique fibers in each voxel
  nFibersU = zeros(1,nCoords);
  for cc = 1:nCoords
   % (f,n), so 1:2:end are the fiber numbers
   % We unique them for each voxel
   f = voxel2FNpair{cc}(1:2:end);
   nFibersU(cc) = length(unique(f));
  end
  mrvNewGraphWin; hist(nFibersU,30)
  title(sprintf('[%s] Number of unique fibers per vox',fgImg(ifg).name))
  
  % Histogram of the number of times more than a single node from a fiber is
  % present in a diffusion voxel
  mrvNewGraphWin; hist(nPairs ./ nFibersU, 30);
  title(sprintf('[%s] Ratio of nodes per fiber',fgImg(ifg).name))
  
  %% Build the master matrix, A, one voxel at a time
  fprintf('[%s] Building the master matrix, A, one voxel at a time\n',mfilename)
  
  cc = 1:size(coords{ifg},1); % use all the voxels in the ROI
  
  % Matrix that will be inverted is set up here
  nVoxels = length(cc);
  nodesPerFiberPerVoxel = 1.5;  % Assume average of 2 nodes per fiber voxel
  nzmax = round((nB * (sum(nPairs) + nVoxels))/nodesPerFiberPerVoxel);
  A{ifg} = spalloc(nVoxels*nB,nFiber{ifg} + nVoxels,nzmax);
  dSig{ifg} = zeros(nB*nVoxels,1);
  
  tic
  for vv = 1:nVoxels
   fprintf('[%s] Adding voxel %i/%i to A\n',mfilename,vv,nVoxels)
   
   % Get the fiber/node pairs for this voxel
   FN = voxel2FNpair{cc(vv)};    % Here are its fiber/node pairs
   Q = zeros(nPairs(cc(vv)), 9); % Allocate space for all the tensors
   for ii=1:nPairs(cc(vv))       % Get the tensors
    f = 2*ii - 1; n = f+1;       % Fiber and node indices into FN
    Q(ii,:) = fgImg(ifg).Q{FN(f)}(FN(n),:);
   end
   % size(Q)
   
   % Calculate all the ADC values for the nodes contributing to this voxel.
   S0 = dwiGet(dwi,'S0 image',coords{ifg}(cc(vv),:));
   ADC = dtiADC(Q,bvecs);
   
   % From the ADC values, compute the signal loss for all the tensors.
   voxDsigBasis = S0*exp(- (repmat(bvals,1,size(Q,1)) .* ADC));
   
   % Sum the diffusion predictions across nodes of a single fiber
   f = voxel2FNpair{cc(vv)}(1:2:end);
   uniqueF = sort(unique(f));
   combineM = zeros(length(f), length(uniqueF));
   
   % The matrix combineM is a set of 0s and 1s that will sum together the
   % nodes from a single fiber.
   for ii=1:length(uniqueF)
    combineM(:,ii) = (f == uniqueF(ii));
   end
   % mrvNewGraphWin; imagesc(combineM)
   
   % The matrix for this voxel starts with each node, and when we multiply
   % by combineM we create the resulting matrix that represents each fiber
   % (not each node) as a column
   voxDsigBasis = voxDsigBasis*combineM;
   
   % Include a constant column vector to allow for isotropic diffusion
   % voxDsigBasis = [voxDsigBasis, ones(nB,1)*mean(voxDsigBasis(:))];
   % voxDsigBasis = [voxDsigBasis, ones(nB,1)];
   
   % Assign the voxDsigBasis to the master matrix.  First, make the master
   % matrix:
   % The number of columns is nFiber{ifg} + nVoxels.  Each voxel gets an
   % individual constant value.  We put all of these constants in the columns
   % at the end, I guess.
   
   % Place the columns for this voxel into the relevant locations of the
   % big matrix that includes the data from all the voxels.
   % Use spalloc to create the right size for A.
   %
   % To figure out the number of non-zero entries we figure
   % nodeDirections = nB * (sum(nPairs) + nVoxels)
   % mEntries = nVoxels*nB *(nFiber{ifg} + nVoxels)
   % nodeDirections/mEntries % Sparseness
   startRow = (vv-1)*nB + 1;
   theseRows  = startRow:(startRow+(nB-1));
   for ii=1:length(uniqueF)
    A{ifg}(theseRows,uniqueF(ii)) = voxDsigBasis(:,ii);
   end
   
   % Add the isotropic diffusion term
   A{ifg}(theseRows,nFiber{ifg} + vv) = ones(1,nB)*mean(voxDsigBasis(:));
   
   % Retrieve the diffusion data for this voxel and add it to the dSig
   dSig{ifg}(theseRows) = dwiGet(dwi,'diffusion signal image',coords{ifg}(cc(vv),:));
  end
  t = toc;
  fprintf('[%s] DONE building the master matrix, A, one voxel at a time\n  ...computing time: %f seconds',mfilename,t)
  
 end
end
  
% Show the fibers we have
fgMesh(dtiH);
  
% now fit each fiber group and show the results
for ifg = 1:length(fgImg)
 %% CVX calls
 % L1 - CVX: http://cvxr.com/
 % Calculate weights using an L1-minimization (constraining sparsity, i.e., many w will be 0)

 % this requires the installation of the cvx toolbox:
 % http://cvxr.com/download/
 theseVx = 1:200;size(A{ifg},1);
 
 % now run the CVX code to solve the L1-minimization problem:
 cvx_C = full(A{ifg}(theseVx,:));
 n = size(cvx_C,2);
 cvx_dSig = dSig{ifg}(theseVx);
 fprintf('[%s] Start L1 minimization using CVX...\n',mfilename)
 tic
 l = -1;
 u = 2;
 cvx_begin       % start te cvx environment
     variable cvx_w(n) % set the variable we are looking to fit in the cvx environment
     minimize(norm(cvx_C * cvx_w - cvx_dSig,1)) % minimize using L1 norm
     subject to
     cvx_w >= l;
     cvx_w <= u;
 cvx_end % this last command actually runs the job.
 t = toc;
 fprintf('[%s] DONE L1 minimization using CVX.\nComputation took: %f seconds...\n',mfilename,t)
 
 %% plot
 mrvNewGraphWin;
 subplot(1,2,1), plot(cvx_w,'o'), axis square
 title('L1 - Fibers weights\nCVX solution')
 xlabel('Fiber number')
 ylabel('Weight')
 
 predSig = cvx_C*cvx_w;
 subplot(1,2,2),plot(cvx_dSig(:),predSig(:),'.')
 axis equal, grid on; axis square, identityLine(gca);
 title(sprintf('L1 - CVX solution\nComputing time: %f',t))
 ylabel('Predicted')
 xlabel('Observed')
 
 %% A means of selecting fibers from the weights and showing the subset
 list = (abs(cvx_w(1:nFiber{ifg})) > 0.4 ); % get the larger weights
 fgBW = fgExtract(fgImg(ifg),list);
 fgBW = fgSet(fgBW,'color',[200,20,0]);
 
 % prepare dtiH for bringing the fibers up on mrMesh
 xform = dtiGet(dtiH,'img2acpc xform');
 fgBW = dtiXformFiberCoords(fgBW,xform);
 [dtiH, BWNum] = dtiAddFG(fgBW,dtiH);
 
 fgMesh(dtiH,BWNum,1)
end


return


%%
% End main code section.  The stuff below includes some code we will want
% to save, it includes CVX which we will probably use in the end.

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------


%% Play around with L1 and L2 minimization %%

% first we chose a subset of voxels
% (a) theseVx = 1:1920; % This is not solved: run into numerical problems, infeasible
%
% (b) if we remove voxels 1200 and 1287 the problem is solvable
%     theseVx = [1:1199, 1201:1286, 1288:1920];
%
% (c) so it looks like that voxel number 1200, 1287 could be the bad boys but both the following works, the two bad voxels can be solved when alone
%     theseVx = 1200;
%     theseVx = 1287;

% These are the good voxels
theseVx = 1:size(coords,1);
% the following plot shows the two bad boys with all the other voxels. they
% do not seem to differe in any meaningful way:
%
% mrvNewGraphWin; plot(A{ifg}([1:1199, 1201:1286, 1288:1920],:)','b.-'); % all good voxels
% hold on, plot(A{ifg}(1200,:),'r.-','LineWidth',2); % Bad boy #1
% plot(A{ifg}(1287,:),'g.-','LineWidth',2); % Bad boy #2
% xlabel('Fiber Number')


%% L1 - LINPROG: doc linprog
% Here I use Matlab Linear Programming tools from the Optimization Toolbox
% Calculate weights using an L1-minimization (constraining sparsity, i.e.,
% many w will be 0)
lp_C    = full(A{ifg}(theseVx,:));
lp_dSig = dSig{ifg}(theseVx);
n = size(lp_C,2);
m = size(lp_C,1);

f    = [zeros(n,1);  ones(m,1);   ones(m,1) ];
Ceq  = [lp_C,       -eye(m),     +eye(m)    ];
lb   = [-inf(n,1);   zeros(m,1);  zeros(m,1)];
fprintf('Start L1 minimization suing Linear programming...\n')
tic
wzz  = linprog(f,[],[],Ceq,lp_dSig,lb,[]);
lp_w = wzz(1:n,:);
t = toc;
fprintf('DONE L1 minimization using Linear programming.\nComputation took: %f seconds...\n',t)

% plot
% mrvNewGraphWin; plot(lp_w,'o')

mrvNewGraphWin;
predSig = lp_C*lp_w;
plot(lp_dSig(:),predSig(:),'.')
axis equal, grid on; identityLine(gca);
title(sprintf('L1 - Linear programming solution\nComputing time: %f',t))
ylabel('Predicted')
xlabel('Observed')

%% Based on the weights, select the fibers.


%% Show the new fibers in a visualization



%% L2 - Matlab matrix operation
% Calculate weights using an L2-minimization
m_C = A{ifg}(theseVx,:);
tic
m_w = m_C\dSig(theseVx,:);
t = toc;

mrvNewGraphWin;
predSig = m_C*m_w;
plot(dSig(:),predSig(:),'.')
axis equal, grid on; identityLine(gca);
title(sprintf('L2 - Matlab solution\nComputing time: %f',t))
ylabel('Predicted')
xlabel('Observed')


%% CVX calls
% L1 - CVX: http://cvxr.com/
% Calculate weights using an L1-minimization (constraining sparsity, i.e., many w will be 0)

% this requires the installation of the cvx toolbox:
% http://cvxr.com/download/

% now run the CVX code to solve the L1-minimization problem:
cvx_C = full(A{ifg}(theseVx,:));
% n = size(cvx_C,2);
cvx_dSig = dSig(theseVx);
% cvx_C = max(dSig(:))*C/max(cvx_C(:));
fprintf('Start L1 minimization using CVX...\n')

tic
l = 0;
u = 1;
cvx_begin       % start te cvx environment
variable cvx_w(n) % set the variable we are looking to fit in the cvx environment
minimize(norm(cvx_C * cvx_w - cvx_dSig(:),1)) % minimize using L1 norm
subject to
cvx_w >= l;
cvx_w <= u;
cvx_end % this last command actually runs the job.
t = toc;
fprintf('DONE L1 minimization using CVX.\nComputation took: %f seconds...\n',t)

% plot
% mrvNewGraphWin; plot(cvx_w,'o')

mrvNewGraphWin;
predSig = cvx_C*cvx_w;
plot(cvx_dSig(:),predSig(:),'.')
axis equal, grid on; identityLine(gca);
title(sprintf('L1 - CVX solution\nComputing time: %f',t))
ylabel('Predicted')
xlabel('Observed')


%% L2 - CVX: http://cvxr.com/
% Calculate weights using an L2-minimization
% this requires the installation of the cvx toolbox:
% http://cvxr.com/download/

% now run the CVX code to solve the L1-minimization problem:
cvx_C = full(A{ifg}(theseVx,:));
n = size(cvx_C,2);
cvx_dSig = dSig(theseVx);

l = 0;
u = 1;
fprintf('Start L2 minimization using CVX...\n')
tic
cvx_begin       % start te cvx environment
variable cvx_w(n) % set the variable we are looking to fit in the cvx environment
minimize(norm(cvx_C * cvx_w - cvx_dSig(:),2)) % minimize using L1 norm
subject to
cvx_w >= l;
cvx_w <= u;
cvx_end % this last command actually runs the job.
t = toc;
fprintf('DONE L2 minimization using CVX.\nComputation took: %f seconds...\n',t)

% plot
% mrvNewGraphWin; plot(cvx_w,'o')

mrvNewGraphWin;
predSig = cvx_C*cvx_w;
plot(cvx_dSig(:),predSig(:),'.')
axis equal, grid on; identityLine(gca);
title(sprintf('L2 - CVX solution',t))
ylabel('Predicted')
xlabel('Observed')


%% L2 - Optimization Toolbox: doc linprog
% Calculate weights using an L2-minimization
lp_C    = A{ifg}(theseVx,:);
lp_dSig = dSig(theseVx);

lb  = 0;
ub  = 1;
fprintf('Start L2 minimization using CVX...\n')
tic
lp_w = quadprog(2*(lp_C'*lp_C), -2*lp_C'*lp_dSig,[],[],[],[],lb,ub);
t = toc;
fprintf('DONE L2 minimization using CVX.\nComputation took: %f seconds...\n',t)

% plot
% mrvNewGraphWin; plot(lp_w,'o')

mrvNewGraphWin;
predSig = lp_C*lp_w;
plot(cvx_dSig(:),predSig(:),'.')
axis equal, grid on; identityLine(gca);
title(sprintf('L2 - Linear programming solution',t))
ylabel('Predicted')
xlabel('Observed')


%%%%%%%%%%%%%%%%%%
% setFiberGroups %
%%%%%%%%%%%%%%%%%%
function [fgImg fgAcpc dtiH dtiF dt6Name xForm dwi] = setFiberGroups(doculling)
% this function loads the two fber groups we will be working on.

% Read dwi data.
dataDir = fullfile(mrvDataRootPath,'diffusion','fiberPrediction');
dwi = dwiLoad(fullfile(dataDir,'raw','dti_g13_b800_aligned.nii.gz'));

% Read the dt6 file.
% Fibers are stored in ACPC space.
% We load up the dt6 and open the mrDiffusion window so that we can easily
% transform between spaces.
dt6Name = fullfile(dataDir,'dti06','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

% get the xForm from image space 3 acpc space
xForm.img2acpc = dtiGet(dtiH,'img 2 acpc xform');

% get the xForm from acpc space to image space
xForm.acpc2img = dtiGet(dtiH,'acpc2img xform');

% read STT fiber group
fgName{1} = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','R_Arcuate_Box_STT.mat');
temp = dtiReadFibers(fgName{1}); % Fiber coordinates in acpc space

if doculling
 % Remove redundant fibers from the group:
 temp = dtiCullFibers(temp, dt6Name);
end
fgAcpc(1) = temp;

% read ConTrac fiber group
fgName{2} = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','R_Arcuate_ctr_clean.mat');
temp = dtiReadFibers(fgName{2}); % Fiber coordinates in acpc space

if doculling
 % Remove redundant fibers from the group:
 temp = dtiCullFibers(temp, dt6Name);
end
fgAcpc(2) = temp;

% Merge them first fiber group
fgName{3} = 'R_Arcuate_Box_merged_stt_ctr.mat';
fgAcpc(3) = dtiMergeFiberGroups(fgAcpc(1),fgAcpc(2),fgName{3}); % Fiber coordinates in acpc space

% In this space, they are in mm
% fLengths = fgGet(fg,'fiber lengths');
%  mrvNewGraphWin; hist(fLengths,100)
for i = 1:length(fgAcpc)
 dtiH = dtiSet(dtiH,'add fiber group',fgAcpc(i));
 
 % Have a look at the fibers.  Visualizations are in ACPC space.
 % fgMesh(fgAcpc{i},dtiH);
 
 % Create a version of the fiber group in image space for computations
 fgImg(i) = dtiXformFiberCoords(fgAcpc(i),xForm.acpc2img);
end

% change the color of the merged group.
fgImg(3).colorRgb = [20 200 20];

return

%% t_mrdArcuatePredictions
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


%% Notes

% We need to show the number of fibers per node for the STT solution
% (before culling)
% We need to show the number of fibers per node after culling (ER)
% And then again after removing the 0-weight fibers.
% This should reduce the 'volume' nonuniformity problem.
%
% We we need a function that uses the code below to simply plot the number
% of fibers per voxel after each of these stages.
%


%% Read the full dwi data.
dataDir = fullfile(mrvDataRootPath,'diffusion','fiberPrediction');
[dwi,bvals,bvecs] = dwiLoad(fullfile(dataDir,'raw','dti_g13_b800_aligned.nii.gz'));

% This should be a function that says which ones to average and then
% returns the averaged data set.

% Combine the dwi data  by averaging  the common directions This should be
% a routine, say dwiAverage, that takes dwi and the unique directions as
% input and returns a modified dwi.
dim = dwiGet(dwi,'size');
nDirs = 13;  % Diffusion and non-diffusion
d = zeros(dim(1),dim(2),dim(3),nDirs);
newbvecs = zeros(nDirs,3);
for ii=1:nDirs
    d(:,:,:,ii) = mean(dwi.nifti.data(:,:,:,ii:nDirs:dim(4)),4);
    newbvecs(ii,:) = mean(bvecs(ii:nDirs:dim(4),:),1);
end
bvals = bvals(1:13);
bvecs = newbvecs;
fprintf('Averaged over %d repeats\n',dim(4)/nDirs);

% Replace ethe original data with the averages
dwi = dwiSet(dwi,'bvals',bvals);
dwi = dwiSet(dwi,'bvecs',bvecs);
dwi = dwiSet(dwi,'data',d);

%  Initialize variables and select some voxels coordinates
bvecs = dwiGet(dwi,'diffusion bvecs');
nB    = dwiGet(dwi,'n diffusion bvecs');
bvals = dwiGet(dwi,'diffusion bvals');

% dwiPlot(dwi,'bvecs')

%% Set up the dti window and transforms
% Read the dt6 file.
% We load up the dt6 and open the mrDiffusion window so that we can easily
% transform between spaces.
dt6Name = fullfile(dataDir,'dti06','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

% get the xForm from image space 3 acpc space
xForm.img2acpc = dtiGet(dtiH,'img 2 acpc xform');

% get the xForm from acpc space to image space
xForm.acpc2img = dtiGet(dtiH,'acpc2img xform');

%% Set up the fiber groups into the dtiH structure
fprintf('Loading  the three fiber groups from disk.\n')
% To process the fibers from scratch do this
%   t_arcuateLoadFibers;
%
culledFiberGroups = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','culledFiberGroups.mat');
load(culledFiberGroups,'fgImg')

% These need to be converted to acpc before being added
for ii=1:3
    dtiH = dtiSet(dtiH,'add fiber group',dtiXformFiberCoords(fgImg(ii),xForm.img2acpc),ii);
end
% guidata(dtiF,dtiH); dtiRefreshFigure(dtiH);


%% Find the voxels (in image coords) that contain fibers
fprintf('Loading the ROI and finding its coordinates in image space\n')

% This should be a routine takes in fiber groups and an ROI, and it returns
% new fiber groups and ROI that have the property:
%  All fibers pass through the ROI
%  Every ROI coordinate has at least one fiber in it
%

% Are these the voxels we want?  This is from the current group.
% allCoords = dtiGet(dtiH,'fg img coords unique');   % These are the fiber coords.

% We will look at a subset of the voxels of the fibers passing through a saved ROI
% This looks like the wrong ROI to me.  Too many (7344) points.  What
% happened to the small sphere Jason created?
roiName = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','ROIs','R_Arcuate_Box.mat');
roi = dtiReadRoi(roiName);
dtiH = dtiSet(dtiH,'add roi',roi);   % Set to current roi
% guidata(dtiF,dtiH); dtiRefreshFigure(dtiH,0);

% Loading a region of interest to analyze.
% Convert  ROI coordinates to Acpc space from image indices
% roiCoords = unique(round(mrAnatXformCoords(xForm.acpc2img, roi.coords)),'rows');
roiCoords = dtiGet(dtiH,'current roi coords image unique');

%Not sure why we need to do this given that we add it back 
fgImg = rmfield(fgImg,'subgroup');  

% For each group, remove  fibers that don't pass through the roi 
% Also remove roi coords that don't have fibers 
fgcoords = cell(1,length(fgImg));
coords   = cell(1,length(fgImg));
for ifg = 1:length(fgImg)
    fgImg(ifg) = dtiIntersectFibersWithRoi([],'and',[],dtiNewRoi('tmp','r',roiCoords),fgImg(ifg));
    fgImg(ifg).subgroup = []; % add back the field just removed so that dtiIntersect could work.
    
    % intersect roi with fibers to remove roi coordinates that do not
    % contain fibers
    fgcoords{ifg} = horzcat(fgImg(ifg).fibers{:})';
    fgcoords{ifg} = unique(round(fgcoords{ifg}),'rows');
    coords{ifg}   = intersect(fgcoords{ifg},roiCoords,'rows');
end

%% If you would like to see the fiber groups after they intersect the ROI 

% Place the fibers in acpc space
% Add them to the mrDiffusion handle.
for ii=1:3
    dtiH = dtiSet(dtiH,'add fiber group',dtiXformFiberCoords(fgImg(ii),xForm.img2acpc),ii);
end
% guidata(dtiF,dtiH); dtiRefreshFigure(dtiH);

%% Make the tensors for each node in the  fiber groups

% These parameters could be adjusted to improve the quality of the fit.
fprintf('Making tensors for each fiber node.\n')
d_ad = 1.5; d_rd = 0.7;
dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
for ii = 1:length(fgImg)
    fgImg(ii).Q = fgTensors(fgImg(ii),dParms); % make a tensor-based rapresentation fo each fiber
end

% for ii=1:3
%     dtiH = dtiSet(dtiH,'add fiber group',dtiXformFiberCoords(fgImg(ii),xForm.img2acpc),ii);
% end
% guidata(dtiF,dtiH); dtiRefreshFigure(dtiH);

%% Find all the sample locations of each fiber that pass through each voxel

% This should be a function that contains additional functions
% The main function should take the ROI, a fiber group, and the DWI
% It should return
%   The fibers and nodes in each ROI voxel
%   The A matrix
%   The dSig
%
% This function should not change the fiber groups or the ROI.

% Loop on ifg
%   Reduce each fiber group to the 

% Do we touch the fiber groups in here?  Or do we just make the dSig and A
% values?
fprintf('Finding all locations of fibers passing through each voxel in the ROI\n')
nFiber = cell(1,length(fgImg));
for ifg = 1:length(fgImg)
    % We create a cell array,node2voxel{} of the same size as the fibers{}. The
    % entries of node2voxel specify whether a node in the fiber is inside of a
    % particular row in coords.  If the node is not in any of the coords, the
    % entry is set to 0.
    nFiber{ifg} = fgGet(fgImg(ifg),'n fibers');
    node2voxel = cell(size(fgImg(ifg).fibers));
    for ii=1:nFiber{ifg}
        nodeCoords = round(fgImg(ifg).fibers{ii}');
        
        % The values in loc are the row of the coords matrix that contains
        % that sample point in a fiber.  For example, if the number 100 is
        % in the 10th position of loc, then the 10th sample point in the
        % fiber passes through the voxel in row 100 of coords.
        [tf, node2voxel{ii}] = ismember(nodeCoords, coords{ifg}, 'rows');
    end
    
    %% Now, compute the (fiber,node) pairs in each voxel
    fprintf('Computing fiber/node pairs in each voxel\n')
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
    title(sprintf('Number of nodes per voxel %s',fgImg(ifg).name))
    
    % Histogram of the number of unique fibers in each voxel
    nFibersU = zeros(1,nCoords);
    for cc = 1:nCoords
        % (f,n), so 1:2:end are the fiber numbers
        % We unique them for each voxel
        f = voxel2FNpair{cc}(1:2:end);
        nFibersU(cc) = length(unique(f));
    end
    mrvNewGraphWin; hist(nFibersU,30)
    title(sprintf('Number of unique fibers per vox %s',fgImg(ifg).name))
    
    % Histogram of the number of times more than a single node from a fiber is
    % present in a diffusion voxel
    mrvNewGraphWin; hist(nPairs ./ nFibersU, 30);
    title(sprintf('Ratio of nodes per fiber: %s',fgImg(ifg).name))
    
    %% Build the master matrix, A, one voxel at a time
    fprintf('Building the master matrix, A, one voxel at a time\n')
    
    cc = 1:size(coords{ifg},1); % use all the voxels in the ROI
    
    % Matrix that will be inverted is set up here
    nVoxels = length(cc);
    nodesPerFiberPerVoxel = 1.5;  % Assume average of 2 nodes per fiber voxel
    nzmax = round((nB * (sum(nPairs) + nVoxels))/nodesPerFiberPerVoxel);
    A{ifg} = spalloc(nVoxels*nB, nFiber{ifg} + nVoxels, nzmax);
    dSig{ifg} = zeros(nB*nVoxels,1);
    
    tic
    for vv = 1:nVoxels
        % fprintf('Adding voxel %i/%i to A\n',vv,nVoxels)
        
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
    fprintf('DONE building the master matrix, A, one voxel at a time\n  ...computing time: %f seconds\n',t)
    
end
% mrvNewGraphWin; imagesc(full(A{2}))


%% Save the A matrix
culledAMatrix = fullfile(mrvDataRootPath,'diffusion','fiberPrediction','fibers','culledAMatrix.mat');
save(culledAMatrix,'A','dSig');

%% Show the fibers we have
% load this, load that ...
% load(culledAMatrix)
% 

%% Now fit each fiber group and show the results
for ifg = 1:length(fgImg)
    % CVX calls
    % L1 - CVX: http://cvxr.com/
    % Calculate weights using an L1-minimization (constraining sparsity,
    % i.e., many w will be 0). This requires the installation of the cvx toolbox:
    % http://cvxr.com/download/
    
    % Modeled for a fiber with this axial and radial diffusivity
    d_ad = 1.5 
    d_rd = 0.7

    % Normally, use all the voxels.
    theseVx = 1:size(A{ifg},1);
    if length(theseVx) < size(A{ifg},1) - nVoxels
        warning('Under-determined: Fewer voxels than fibers.');
    end
    
    % now run the CVX code to solve the L1-minimization problem:
    cvx_C = full(A{ifg}(theseVx,:));
    n = size(cvx_C,2);
    cvx_dSig = dSig{ifg}(theseVx);
    fprintf('Start L1 minimization using CVX...\n')
    
    l = 0;                % Lower and upper bounds on the weights
    u = 1;
    fFraction =0.2;       % Fraction of fibers to retain
    cvx_precision('low')  % We can handle low precision during testing.
    
    tic
    cvx_begin           % start te cvx environment
      cvx_solver sedumi   % set the solver (sedumi or sdpt3)
      variable cvx_w(n) % set the variable we are looking to fit in the cvx environment
      
      minimize(norm(cvx_C * cvx_w - cvx_dSig,1)) % minimize using L1 norm
      
      % set constrains to the minimization, upper and lower bounds for the
      % weights and a small variance across the weights
      subject to
        norm(cvx_w(1:n),1) <= fFraction*nFiber{ifg};
        cvx_w >= l;
        cvx_w <= u;
    cvx_end 
    t = toc;
   
    % Pull out fiber weights and isotropic voxel weights
    fWeights = cvx_w(1:nFiber{ifg});        % Fiber weights
    vWeights = cvx_w((nFiber{ifg}+1):end);  % Voxel isotropy weights
   
    % plots
    mrvNewGraphWin;
    subplot(2,2,1), plot(fWeights,'o'), axis square
    set(gca,'ylim',[-0.1 u*1.1]);
    title('L1 - Fibers weights - CVX solution')
    xlabel('Fiber number')
    ylabel('Weight')
    
    subplot(2,2,2), plot(vWeights,'o'), axis square
    set(gca,'ylim',[-0.1 u*1.1]);
    title('L1 - Isotropic values - CVX solution')
    xlabel('Voxel number')
    ylabel('Weight')
    
    subplot(2,2,3), hist(vWeights,40), 
    title('L1 - Isotropic values - CVX solution')
    xlabel('Voxel number')
    ylabel('Weight')
    
    predSig = cvx_C*cvx_w;
    pVarEx = corr2(predSig(:),cvx_dSig(:));
    subplot(2,2,4),plot(cvx_dSig(:),predSig(:),'.')
    axis equal, grid on; axis square, identityLine(gca);
    title(sprintf('L1 - CVX solution %.3f\nComputing time: %.1f',pVarEx,t))
    ylabel('Predicted')
    xlabel('Observed')
    
end

%% Cross validate results
nDirs = 12;
nBoots = 1000;
for ifg = 1:3
 for iBoot = 1:nBoots % bootstrap the crossvalidation r2
 % Randomly chosen initial direction for each voxel
 outVols = ceil(rand(length(dSig{2})./nDirs,1).*nDirs);
 
 % Now we will make a vector that has a 1 for each row of dsig to fit
 % and a 0 for each row to hold out for cross validation
 rows = [];
 for ii = 1:length(outVols)
  tmp = ones(nDirs,1);
  tmp(outVols(ii)) = 0;
  nextrow = length(rows) + 1;
  rows(nextrow:nextrow+nDirs-1) = tmp;
 end
 rows = logical(rows);
 
 w{ifg} = [];testA{ifg} = [];testedDSig{ifg} = [];r2{ifg} = [];predictedDSig{ifg} = [];
 for i = 1:nDirs
  % shift by one the index of the directions to be left out of each voxel
  % this allows to leave out each direction in 12 folds
  these_rows = reshape(rows,12,length(dSig{2})./nDirs);
  these_rows = circshift(these_rows,1);
  all_rows(i,1:length(rows)) = reshape(these_rows,size(rows,1),size(rows,2));
  
  % fit the model to the subsampled dataset
  [cvx_w, ATest, dSigPredict, dSigTest, rows, R2] = t_mrdArcuateXvalidate(dSig{ifg},A{ifg},all_rows(i,:,:),[]);
  
  % store the variables
  w{ifg} = [w{ifg};cvx_w];
  testedDSig{ifg}    = [testedDSig{ifg}; dSigTest];
  predictedDSig{ifg} = [predictedDSig{ifg}; dSigPredict];
  r2{ifg} = [r2{ifg}, R2];
 end
 
 % compute the r2 of the model over all the 12 repetitions
 % Amount of deviation in the data explained by the model
 % relative to the total variance in the data.
 total_r2_better{ifg}(iBoot) = 100 * (1-sum((predictedDSig{ifg} - testedDSig{ifg}).^2) / sum((testedDSig{ifg}-mean(testedDSig{ifg})).^2));
 total_r2_simple{ifg}(iBoot) = 100 * corr(predictedDSig{ifg},testedDSig{ifg})^2;
 end
end

%%  How do we properly write these out as Quench viewable?
% fgBW = dtiCreateQuenchStats(fgBW,'Length','Length', 1);
% mtrExportFibers(fgBW,'deleteMe.pdb');

ifg = 1;

% A means of selecting fibers from the weights and showing the subset
list = find((abs(fWeights) > 0.05 )); % get the larger weights
length(list)
fgGet(fgImg(ifg),'n fibers')

% Positive weights
fgBW = fgExtract(fgImg(ifg),list);
fgBW = fgSet(fgBW,'name',sprintf('%s-PosWgts',fgGet(fgImg(ifg),'name')));

% prepare dtiH for bringing the fibers up on mrMesh
xform = dtiGet(dtiH,'img2acpc xform');
fgBW = dtiXformFiberCoords(fgBW,xForm.img2acpc);
dtiH = dtiSet(dtiH,'add fiber group',fgBW);
% guidata(dtiF,dtiH); dtiRefreshFigure(dtiH);

meshID = ifg;
fgMesh(dtiH,ifg,ifg)

%% End main code section.
% The stuff below includes some code we will want
% to save, it includes CVX which we will probably use in the end.




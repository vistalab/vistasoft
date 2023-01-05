%% t_mrdFiberPredictions
%
% Start with estimated fiber groups and compute diffusion predictions.
%
% See also:  t_mrdTensors, t_mrdViewFibers, dwiLoad, dtiGet/Set
%
% Should be updated for LiFE?  What do you think?
%
% See also:  The vistaproj life directory.
%
% (c) Stanford VISTA Team

%% Read the fibers and dwi data.
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dwi = dwiLoad(fullfile(dataDir,'raw','dwi.nii.gz'));

% Fibers are stored in ACPC space.
% We load up the dt6 and open the mrDiffusion window so that we can easily
% transform between spaces.
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

fgName = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb');
xForm = dtiGet(dtiH,'img 2 acpc xform');
fgAcpc = mtrImportFibers(fgName,xForm); % Fiber coordinates in acpc space

% Remove fibers that are extremely similar
% Not working with spm8 and on Windows.  Investigate.
% fgAcpc = dtiCullFibers(fgAcpc, dt6Name);

% In this space, they are in mm
%  fLengths = fgGet(fgAcpc,'fiber nodes');
%  mrvNewGraphWin; hist(fLengths,100)
dtiH = dtiSet(dtiH,'add fiber group',fgAcpc);

% Have a look at the fibers.  Visualizations are in ACPC space.
% fgMesh(fgAcpc,dtiH);

% Create a version of the fiber group in image space for computations
acpcToImage = dtiGet(dtiH,'acpc2img xform');
fgImg = dtiXformFiberCoords(fgAcpc,acpcToImage);

% ROI coords are saved in acpc space
% roiName = 'rect_-46_-40__04.mat';
% roi = dtiReadROI(roiName)
% We need gets and sets on ROIs
% We need a script that illustrate how to load and visualize ROIs
% using the mrDiffusion methods

%% Make the list of tensors for each fiber and node

% These parameters could be adjusted to improve the quality of the fit.
d_ad = 1.5; d_rd = 0.5;
dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
fgImg.Q = fgTensors(fgImg,dParms);

%% Find the voxels (in image coords) that contain fibers
allCoords = dtiGet(dtiH,'fg img coords unique');

% Look at a subset of the voxels
coords = allCoords(1000:1400,:);

% Each row of dSig contains the diffusion data for a coordinate.
% We will turn this into a single long vector of length nCoords x nDiff
% dSig = dwiGet(dwi,'diffusion signal image',coords);
% dSig(2,1)
% dSig = dSig'; dSig = dSig(:); dSig(81)
% mrvNewGraphWin; plot(dSig(:)); xlabel('coords-dir'); ylabel('Diffusion signal')

%% Find all the sample locations of each fiber that pass through each voxel

% We create a cell array,node2voxel{} of the same size as the fibers{}. The
% entries of node2voxel specify whether a node in the fiber is inside of a
% particular row in coords.  If the node is not in any of the coords, the
% entry is set to 0.
nFibers = fgGet(fgImg,'n fibers');
node2voxel = cell(size(fgImg.fibers));
for ii=1:nFibers
    nodeCoords = round(fgImg.fibers{ii}');
    
    % The values in loc are the row of the coords matrix that contains
    % that sample point in a fiber.  For example, if the number 100 is
    % in the 10th position of loc, then the 10th sample point in the
    % fiber passes through the voxel in row 100 of coords.
    [tf, node2voxel{ii}] = ismember(nodeCoords, coords, 'rows');
end

%% Now, compute the (fiber,node) pairs in each voxel
nCoords = size(coords,1);
voxel2FNpair = cell(1,nCoords);
for thisFiber=1:nFibers
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

%% Check whether the inversion is correct
%
% We ask whether (fiber,node) is in the voxel.
%
% v = 425                 % Pick a voxel
% tmp = voxel2FNpair{v};    % The (fiber,node) pairs
% thisC = coords(v,:)     % Print the voxel coord
% for ii=1:2:(length(tmp)-1)  % Go through the pairs and check they equal
%     round(fgImg.fibers{tmp(ii)}(:,tmp(ii+1)))'
% end

%%  Some gets on voxel2FNpair

% Histogram of the number of nodes in each voxel
nPairs = zeros(1,nCoords);
for cc = 1:nCoords
    nPairs(cc) = length(voxel2FNpair{cc})/2;
end
mrvNewGraphWin; hist(nPairs,30)
title('Number of nodes per voxel')

% Histogram of the number of unique fibers in each voxel
nFibersU = zeros(1,nCoords);
for cc = 1:nCoords
    % (f,n), so 1:2:end are the fiber numbers
    % We unique them for each voxel
    f = voxel2FNpair{cc}(1:2:end);
    nFibersU(cc) = length(unique(f));
end
mrvNewGraphWin; hist(nFibersU,30)
title('Number of unique fibers per vox')

% Histogram of the number of times more than a single node from a fiber is
% present in a diffusion voxel
mrvNewGraphWin; hist(nPairs ./ nFibersU, 30);
title('Ratio of nodes per fiber')

%%  Initialize variables and select some voxels coordinates

bvecs = dwiGet(dwi,'diffusion bvecs');
nB = dwiGet(dwi,'n diffusion bvecs');
bvals = dwiGet(dwi,'diffusion bvals');

% Create the master diffusion matrix for these coords
% cc = [77,100,166];
cc = 1:17:400;
% 166 is circular                  
% Here is a coordinate.(cc = 100 has one pair)
% 77 is an interesting one, a lot of diffusion.
% 308 is useful

% Matrix that will be inverted is set up here
nVoxels = length(cc);
nodesPerFiberPerVoxel = 1.5;  % Assume average of 2 nodes per fiber voxel
nzmax = round((nB * (sum(nPairs) + nVoxels))/nodesPerFiberPerVoxel);
A = spalloc(nVoxels*nB,nFibers + nVoxels,nzmax);
dSig = zeros(nB*nVoxels,1);

%% Build the master matrix, A, one voxel at a time
tic
for vv = 1:nVoxels

    % Get the fiber/node pairs for this voxel
    FN = voxel2FNpair{cc(vv)};    % Here are its fiber/node pairs
    Q = zeros(nPairs(cc(vv)), 9); % Allocate space for all the tensors
    for ii=1:nPairs(cc(vv))            % Get the tensors
        f = 2*ii - 1; n = f+1;     % Fiber and node indices into FN
        Q(ii,:) = fgImg.Q{FN(f)}(FN(n),:);
    end
    % size(Q)

    % Check the parameters made a quadratic with AD and RD right
    % svd(reshape(Q(1,:),3,3))

    % Calculate all the ADC values for the nodes contributing to this voxel.
    S0 = dwiGet(dwi,'S0 image',coords(cc(vv),:));
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
    % The number of columns is nFibers + nVoxels.  Each voxel gets an
    % individual constant value.  We put all of these constants in the columns
    % at the end, I guess.

    % Place the columns for this voxel into the relevant locations of the
    % big matrix that includes the data from all the voxels.
    % Use spalloc to create the right size for A.
    %
    % To figure out the number of non-zero entries we figure
    % nodeDirections = nB * (sum(nPairs) + nVoxels)
    % mEntries = nVoxels*nB *(nFibers + nVoxels)
    % nodeDirections/mEntries % Sparseness
    startRow = (vv-1)*nB + 1;
    theseRows  = startRow:(startRow+(nB-1));
    for ii=1:length(uniqueF)
        A(theseRows,uniqueF(ii)) = voxDsigBasis(:,ii);
    end
    
    % Add the isotropic diffusion term
    A(theseRows,nFibers + vv) = ones(1,nB)*mean(voxDsigBasis(:));

    % Retrieve the diffusion data for this voxel and add it to the dSig
    dSig(theseRows) = dwiGet(dwi,'diffusion signal image',coords(cc(vv),:));
end
toc

%% Visualize some of the fibers

wClose = 1;  % Close the mesh window for speed

% Get a subset of fibers in image coords
fgImg2 = fgSet(fgImg,'fibers',fgGet(fgImg,'fibers',1:50:nFibers));

% Transform them to acpc and put them in the handles
xform = dtiGet(dtiH,'img2acpc xform');
fgAcpc2 = dtiXformFiberCoords(fgImg2,xform);
[dtiH, thisFGNum] = dtiAddFG(fgAcpc2,dtiH);

% Show them
fgMesh(dtiH,thisFGNum,wClose);

fgAcpc = fgSet(fgAcpc,'color',[50 50 200]);
[dtiH, thisFGNum] = dtiAddFG(fgAcpc,dtiH);

% nFG = dtiGet(dtiH,'n fiber groups');

fgMesh(dtiH,thisFGNum,wClose);
fgMesh(dtiH,3,wClose);

%% End

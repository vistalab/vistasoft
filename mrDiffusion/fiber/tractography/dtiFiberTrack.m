function [fg,opts] = dtiFiberTrack(dt6, seeds, mmPerVox, xform, fgName, opts)
%
% [fg,opts] = dtiFiberTrack(dt6, seeds, mmPerVox, xform, fgName, opts)
%
% seeds should be in ac-pc coordinate space (inv(xform) should 
% put them into the same space as the dt6 array when
% pre-multiplied).
%
% trackOpts is a struct with tracking options (see dtiFiberTrackOpts).
% If trackOpts is empty or not passed, the user will be prompted.
%
% Note that every seed voxel gets at least one seed. opts.seedVoxelOffsets
% is the relative position of the seed(s) within each seed voxel. E.g.,
% seedVoxelOffsets = [0.5] will put one seed at the center of each voxel,
% while [0.25 0.75] will place 8 seeds in each voxel.
% opts.offsetJitter is the standard deviation of a a random jitter applied
% to the seeds (in voxel units). E.g., offsetJitter=0.1 will jitter each
% seedVoxelOffset by a random amount with mean 0 and sigma 0.1.
%
% HISTORY
% 2005.01.24 RFD: wrote it (mostly pulled code from dtiFiberUI)

% % 2005.09.02 RFD: Fixed a slight fiber coord offset error. Previously, we
% % referenced fiber points to the voxel corner of the DTI sampling grid. The
% % result was a mmPerVox/2 offset with repect to the standard coordinate
% % frame that we use elsewhere (eg. ROIs, slice-select, etc.). The error was
% % typically 1mm, so wan't obvious in noisy single-subject data. But, it
% % became apparent in averaged data when fiber coords wer compared to ROI
% % coords.

fg = [];
if(~exist('opts','var') || isempty(opts))
  opts = dtiFiberTrackOpts;
  prompt = {'Step size (mm):','Angle threshold:','FA Threshold',...
            'Length threshold (mm):', 'Puncture Coefficient', ...
            'Algorithm Type (0=STT Euler, 1=STT RK4, 2=TEND Euler, 3=TEND RK4):',...
            'Interpolation Type (0=NN, 1=linear):', ...
            'Seed Voxel Offset:', 'Offset Jitter:', 'Name:'};
  def = {num2str(opts.stepSizeMm), num2str(opts.angleThresh), num2str(opts.faThresh), ...
         num2str(opts.lengthThreshMm), num2str(opts.wPuncture), ...
         num2str(opts.whichAlgorithm), num2str(opts.whichInterp), ...
         num2str(opts.seedVoxelOffsets), num2str(opts.offsetJitter), fgName};
  resp = inputdlg(prompt, 'Fiber tracking parameters', 1, def);
  if(isempty(resp)) return; end
  opts.stepSizeMm = str2double(resp{1});
  opts.angleThresh = str2double(resp{2});
  opts.faThresh = str2double(resp{3});
  opts.lengthThreshMm = str2num(resp{4});
  opts.wPuncture = str2double(resp{5});
  opts.whichAlgorithm = str2num(resp{6});
  opts.whichInterp = str2num(resp{7});
  opts.seedVoxelOffsets = str2num(resp{8});
  opts.offsetJitter = str2num(resp{9});
  fgName = resp{10};
  opts.trackOptionFlags = {};
end
if(~isfield(opts,'offsetJitter') || isempty(opts.offsetJitter))
    opts.offsetJitter = 0.0;
end

fg = dtiNewFiberGroup(fgName);

sz = size(dt6);

if(ndims(seeds)==3&&all(size(seeds)==sz(1:3)))
    % then seeds is an image mask
    [x,y,z] = ind2sub(size(seeds),find(seeds(:)));
    seeds = [x,y,z];
else
    seeds = mrAnatXformCoords(inv(xform), seeds);
end
seeds = unique(round(seeds),'rows');
nSeedVox = size(seeds,1);
nSeeds = numel(opts.seedVoxelOffsets).^3 * nSeedVox;
% Initialize the seed list.
if(opts.offsetJitter==0)
    % zeros if no jitter
    newSeeds = zeros(nSeeds, 3);
else
    % or- add some jitter
    newSeeds = randn(nSeeds, 3) .* opts.offsetJitter;
    % Clip to 3 std. dev.:
    newSeeds(newSeeds>opts.offsetJitter*3) = opts.offsetJitter*3;
end
ind = 1;
for(ii=opts.seedVoxelOffsets)
    for(jj=opts.seedVoxelOffsets)
        for(kk=opts.seedVoxelOffsets)
            newSeeds(ind:ind+nSeedVox-1,:) = newSeeds(ind:ind+nSeedVox-1,:) + (seeds + repmat([ii,jj,kk],nSeedVox,1));
            ind = ind+nSeedVox;
        end
    end
end
seeds = newSeeds;

% The fiber points are centered on the voxel corner, but we like everything
% to be referenced to the voxel center.
% the second (Y) axis is opposite because that axis is index from the
% bottom-up.
%xform = xform*affineBuild([0.5 -0.5 0.5]);
fibers = {};
tic
fibers = dtiFiberTracker(dt6, seeds'-1, mmPerVox(:), ...
                         opts.whichAlgorithm, opts.whichInterp, ...
                         opts.stepSizeMm, opts.faThresh, opts.angleThresh, ...
                         opts.wPuncture, opts.lengthThreshMm, xform);
toc

fiberLength = cellfun('prodofsize',fibers)/3;
keepFibers = fiberLength>1;
fibers = fibers(keepFibers);
seeds = mrAnatXformCoords(xform, seeds(keepFibers,:));
fiberLength = fiberLength(keepFibers).*opts.stepSizeMm;

if(~isempty(fibers))
    fprintf('%d fibers, mean length %0.0fmm (max %0.0fmm; min %0.0fmm).\n', ...
            size(seeds,1),mean(fiberLength),max(fiberLength),min(fiberLength));
else
    disp('No fibers.');
end

% Build the fiber group data structure and add it to the window data structure.
fg.seeds = seeds;
fg.seedRadius = 0;
fg.seedVoxelOffsets = opts.seedVoxelOffsets;
fg.params = {'faThresh',opts.faThresh,'lengthThreshMm',opts.lengthThreshMm, ...
             'stepSizeMm',opts.stepSizeMm};
fg.fibers = fibers;
return;

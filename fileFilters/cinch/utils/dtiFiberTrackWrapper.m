function [fg,opts,keepFibers] = dtiFiberTrackWrapper(dt6, seeds, mmPerVox, xform, fgName, opts)
%
% [fg,opts] = dtiFiberTrackWrapper(dt6, seeds, mmPerVox, xform, fgName, opts)
%
% seeds should be in voxel coordinate space (xform should 
% put them into AC-PC space when pre-multiplied).
%
% trackOpts is a struct with the following fields:
%  opts.stepSizeMm = 1;
%  opts.faThresh = 0.20;
%  opts.lengthThreshMm = 20;
%  opts.angleThresh = 30;
%  opts.wPuncture = 0.2;
%  opts.whichAlgorithm = 1;
%  opts.whichInterp = 1;
%  opts.seedVoxelOffsets = [0.25 .75];
%
%
% If trackOpts is empty or not passed, the user will be prompted.
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
  % Query for tracking parameters
  opts.stepSizeMm = 1;
  opts.faThresh = 0.15;
  opts.lengthThreshMm = 20;
  opts.angleThresh = 30;
  opts.wPuncture = 0.2;
  opts.whichAlgorithm = 1;
  opts.whichInterp = 1;
  opts.seedVoxelOffsets = [0.25 0.75];
  prompt = {'Step size (mm):','Angle threshold:','FA Threshold',...
            'Length threshold (mm):', 'Puncture Coefficient', ...
            'Algorithm Type (0=STT Euler, 1=STT Runge-Kutta4, 2=TL Euler):',...
            'Interpolation Type (0=NN, 1=linear):', ...
            'Seed Voxel Offset:', 'Name:'};
  def = {num2str(opts.stepSizeMm), num2str(opts.angleThresh), num2str(opts.faThresh), ...
         num2str(opts.lengthThreshMm), num2str(opts.wPuncture), ...
         num2str(opts.whichAlgorithm), num2str(opts.whichInterp), ...
         num2str(opts.seedVoxelOffsets), fgName};
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
  fgName = resp{9};
  opts.trackOptionFlags = {};
end

fg = dtiNewFiberGroup(fgName);

% The fiber points are centered on the voxel corner, but we like everything
% to be referenced to the voxel center.
% the second (Y) axis is opposite because that axis is index from the
% bottom-up.
%xform = xform*affineBuild([0.5 -0.5 0.5]);
fibers = dtiFiberTracker(dt6, seeds'-1, mmPerVox(:), ...
                         opts.whichAlgorithm, opts.whichInterp, ...
                         opts.stepSizeMm, opts.faThresh, opts.angleThresh, ...
                         opts.wPuncture, opts.lengthThreshMm, xform);

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

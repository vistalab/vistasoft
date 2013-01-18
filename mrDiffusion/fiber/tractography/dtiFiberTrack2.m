function [fg,opts] = dtiFiberTrack2(dt6, coords, numFibersPerCoord, stdOfSeedsJitter, mmPerVox, xform, fgName, opts)
%
% [fg,opts] = dtiFiberTrack2(dt6, coords, numFibersPerCoord, stdOfSeedsJitter, mmPerVox, xform, fgName, opts)
%
% coords should be in ac-pc coordinate space (inv(xform) should
% put them into the same space as the dt6 array when
% pre-multiplied).
%
% trackOpts is a struct with tracking options (see dtiFiberTrackOpts).
% If trackOpts is empty or not passed, the user will be prompted.
%
% *coords* is a set of acpc coordinates.
%
%
% HISTORY
% 2005.01.24 RFD: wrote it (mostly pulled code from dtiFiberUI)

fg = [];
if(~exist('opts','var') || isempty(opts))
  % GEt defult Parameters for dtiFiberTracker
  opts = dtiFiberTrackOpts;
  
  % Set up the fields of a GUI
  prompt = {'Step size (mm):','Angle threshold:','FA Threshold',...
    'Length threshold (mm):', 'Puncture Coefficient', ...
    'Algorithm Type (0=STT Euler, 1=STT RK4, 2=TEND Euler, 3=TEND RK4):',...
    'Interpolation Type (0=NN, 1=linear):', ...
    'Name:'};
  def = {num2str(opts.stepSizeMm), num2str(opts.angleThresh), num2str(opts.faThresh), ...
    num2str(opts.lengthThreshMm), num2str(opts.wPuncture), ...
    num2str(opts.whichAlgorithm), num2str(opts.whichInterp), ...
    fgName};
  
  % Open the GUI, to get the tracking parameters.
  resp = inputdlg(prompt, 'Fiber tracking parameters', 1, def);
  
  if(isempty(resp)) error('Parameters not passed.'); end
  
  % GEt the input parameters into the options structure.
  opts.stepSizeMm       = str2double(resp{1});
  opts.angleThresh      = str2double(resp{2});
  opts.faThresh         = str2double(resp{3});
  opts.lengthThreshMm   = str2num(resp{4});
  opts.wPuncture        = str2double(resp{5});
  opts.whichAlgorithm   = str2num(resp{6});
  opts.whichInterp      = str2num(resp{7});
  opts.trackOptionFlags = {};
  
  % We track one fiber per coordinate.
  %
  % We set these two fields to 0, so that dtiFiberTracker geenrates only
  % one fiber per coordinate. The coordinates are then used to generate
  % seeds for tracking.
  opts.offsetJitter     = 0;
  opts.seedVoxelOffsets = 0;
  
  % Fiber group name.
  fgName = resp{10};
end

% Create a new fiber group
fg = dtiNewFiberGroup(fgName);

% We track one fiber per each coordinate.
%
% So to increase the number of fibers trackedwe replicate the coordinates
% using a gaussian distribution centered at 0 and with standard deviation
% defined by stdOfSeeds.
%
% Coordinates are in Acpc. So that the jitter we add for tracking is in mm.
seedsAcpc = repmat(coords,1,numFibersPerCoord);

% Gaussian sampling centered at each coordinate.
seedsAcpc = seedsAcpc + randn(size(seedsAcpc)) .* stdOfSeedsJitter; % in mm

% Uniform sampling centered at each coordinate.
%maxval = (seedsAcpc + stdOfSeedsJitter);
%minval = (seedsAcpc - stdOfSeedsJitter);
%rng  = (maxval - minval); % range of seeds in mm
%cntr = minval; % center of each seed in Acpc (mm)
%seedsAcpc = cntr + rng .* rand(size(seedsAcpc));

% We transform the seeds in image coordinates, because dtiFiberTracker will
% apply a transform the generate fiber coordinates in Acpc space, see
% comments below.
seedsImg = mrAnatXformCoords(inv(xform), seedsAcpc)';

% Track one fiber for each coordinate in seeds.
%
% This subtration is necessary because dtiFiberTracker is c code. c-code
% starts idnexing at 0, Matlab at 1. Subtracting 1 r the matlab
% indexes into c-code indexes.
c_seeds  = seedsImg - 1;

tic
% Remember that here dtiFiberTracke uses the xform to transform the fiber
% coordinates from Image to ACPC coordinates. Se, we send in coordinates in
% Image Coordinate but the returned fibers are in Acpc coordinates.
fibers   = dtiFiberTracker(dt6, c_seeds, mmPerVox(:), ...
  opts.whichAlgorithm, opts.whichInterp, ...
  opts.stepSizeMm, opts.faThresh, opts.angleThresh, ...
  opts.wPuncture, opts.lengthThreshMm, xform);

% Remove the fibers that did not pass the length threshold and were
% returned empty
fibers = fibers(~cellfun('isempty',fibers));

% Show that each seed received node for a fiber, times the numbe rof fibers
%for ii = 1:length(fibers)
%  %[ind(ii,:) d(ii,:)] = nearpoints(seedsAcpc,fibers{ii});
%  [ind(ii,:) d(ii,:)] = ismember(seedsAcpc,fibers{ii},'rows');
%end
%any(all(ind==0,1))

% Compute the fiber lenght for each fiber
fiberLength = cellfun('prodofsize',fibers)/3;

% Keep only fibers that have more than one node
keepFibers  = fiberLength > 1;
fiberLength = fiberLength(keepFibers).*opts.stepSizeMm;
fibers      = fibers(keepFibers);

if(~isempty(fibers))
  fprintf('\n[%s] %i fibers tracked in %3.3f seconds,\n                 Mean fiber length %0.0fmm (min %0.0fmm; max %0.0fmm).\n', ...
    mfilename,size(seedsImg,2),toc,mean(fiberLength),min(fiberLength),max(fiberLength));
else
  error('No fibers tracked.');
end

% Save the used parameters into the fiber group.
fg.fibers = fibers; % Save the fibers
fg.coords = coords; % Save the coordinates passed in to track from
fg.seeds  = seedsAcpc;
fg.params = {'faThresh',opts.faThresh,                 ...
             'lengthThreshMm',opts.lengthThreshMm,     ...
             'stepSizeMm',opts.stepSizeMm,             ...
             'numOfFibersPerCoords',numFibersPerCoord, ...
             'StdOfSeedsJitterMm', stdOfSeedsJitter};

fg = orderfields(fg);

return;

function opts = dtiFiberTrackOpts(varargin)
%
% opts = dtiFiberTrackOpts([options])
%
% trackOpts is a struct with the following fields:
%  opts.stepSizeMm = 1;
%  opts.faThresh = 0.20;
%  opts.lengthThreshMm = 20;
%  opts.angleThresh = 30;
%  opts.wPuncture = 0.2;
%  opts.whichAlgorithm = 1;
%  opts.whichInterp = 1;
%  opts.seedVoxelOffsets = [-0.25  0.25];
%  opts.offsetJitter = 0;
%
% See dtiFiberTracker for details on the options.
%
% If no args are passed, an opts struct with default values is returned.
% If you want to override a default, pass it as an 'name,value pair. Eg:
% opts = dtiFiberTrackOpts('lengthThreshMm',30,'angleThresh',50);
%
% HISTORY
% 2008.05.14 RFD: wrote it.
% 2009.06.16 RFD & SA: changed default seedVoxelOffset to be [-0.25 0.25].
% The fiber tracker mex function assumes that image coordinates refer to
% the voxel center, so [-0.25 0.25] will grid the voxel appropriately. With
% the old default, the fibers were actually shifted 1/2 voxel from what the
% user assumed they'd be.

  opts.stepSizeMm = 1;
  opts.faThresh = 0.15;
  opts.lengthThreshMm = 20;
  opts.angleThresh = 30;
  opts.wPuncture = 0.2;
  opts.whichAlgorithm = 1;
  opts.whichInterp = 1;
  opts.seedVoxelOffsets = [-0.25 0.25];
  opts.offsetJitter = 0.0;

if(~isempty(varargin))
    for(ii=1:2:numel(varargin)-1)
        opts = setfield(opts, varargin{ii}, varargin{ii+1});
    end
end
        
return;

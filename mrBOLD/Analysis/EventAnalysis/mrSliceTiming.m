function [newTS,newTBase] = mrSliceTiming(ts,frameAdjustment,method)
% Adjust the time series of a slice/scan based on the slice position
%
%   [newTS,newTBase] = mrSliceTiming(ts,frameAdjustment,method)
%
% This function takes in the time series (ts) and recreates a new time
% series at each voxel.  It calculates the time at which the ts was
% actually measured and then interpolates to a new time frame.  All of the
% different slices are interpolated to the same time frame, which is the
% basis of slice timing adjustment.  The adjustment to all of the slices is
% done by calling this routine repeated from AdjustSliceTiming.
%
% This is  the core routine for time series slice timing adjustment.
% AdjustSliceTiming has overhead associated with creating the data type and
% so forth.  This routine is just the calculation.
%
% ts:               Time series from a single slice within a scan 
% frameAdjustment:  The fraction of the frame (TR) this time series must
%                   be resampled (not in seconds)
% method:           'linear' or 'spline'
%
% Slice timing adjustment smooths noisy time series a little bit.  The
% linear choice smooths more than the spline choice.
%
% Example:
%   We don't call this routine on its own.  We call it from the
%   wrapper AdjustSliceTiming().
%

if notDefined('ts'), error('Time series required'); end
if notDefined('frameAdjustment'), error('frameAdjustment value required'); end
if notDefined('method'), method = 'spline'; end

% get nFrames, the number of time samples, from data
nFrames    = size(ts,1);

% Pad the with a replication of the first and last frames to deal with
% extrapolation: 
ts = [ts(1, :); ts; ts(nFrames, :)];

% deal w/ NaNs. These may occur due to motion correction, for example. 
% For now, replace with zero. We should probably replace with the mean of
% the neighbors at some point. 
%
% nanInds = find(isnan(ts));
% ts(nanInds) = 0;
ts(isnan(ts)) = 0;

% These are the time samples for the amended (padded) ts.  We don't
% bother multiplying by TR, though of course we could.
tBaseRef = (0:nFrames+1);

% If the timing between frames is deltaFrame, and the difference in slice
% between this one and the standard slice is refSlice - slice, then we need
% to adjust the times between this slice and the reference as here.  This
% calculation should be replaced by a routine that includes the slice
% ordering; the slice ordering should be saved!
% newTBase = (1:nFrames) + deltaFrame * (refSlice - slice);
newTBase = (1:nFrames) + frameAdjustment;

switch lower(method)
    case 'spline'
        % Ress used spline temporal interpolation routine
        newTS = spline(tBaseRef, ts', newTBase)';
    case 'linear'
        % This should be an option, as well as others.
        newTS = interp1(tBaseRef(:), ts, newTBase(:));
    otherwise
        error('Undefined method %s\n',method);
end

return

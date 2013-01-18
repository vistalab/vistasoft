function voxAmps = er_voxAmpsMatrix(voxData,params);
%
% voxAmps = er_voxAmpsMatrix(voxData,params);
%
% Given a 4-D voxData matrix, compute the
% mean amplitude for each voxel, given
% the event-related params (see er_getParams).
%
% Generally, the amplitudes are the mean
% signal during the peak period minus the 
% signal during the baseline period for 
% each trial. (Down the line, it may be
% nice to add a parameter allowing prefs to
% be set for using, say, dot-product amplitudes
% vs. this measure.)
%
% The output matrix is 3D w/ format:
% trials x voxels x conditions
%
% ras 04/05/05.
if ~exist('params', 'var') | isempty('params')
    params = er_defaultParams;
end

tr = params.framePeriod;

tmp.params = params;
peakFrames = tcGet(tmp, 'peakFrames');
bslFrames = tcGet(tmp, 'bslFrames');

peak = voxData(peakFrames,:,:,:);
bsl = voxData(bslFrames,:,:,:);

if size(peak,1) > 1
    peak = nanmean(peak);
end
if size(bsl,1) > 1
    bsl = nanmean(bsl);
end

switch params.ampType
	case 'raw'
		voxAmps=peak;
	otherwise
		voxAmps = peak-bsl;
end

voxAmps = permute(voxAmps,[2 3 4 1]);

return

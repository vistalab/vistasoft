function mv = mv_subset(mv, runs);
% Select a subset of runs from a multivoxel structure.
% 
% mv = mv_subset(mv, runs);
%
% This replaces the time series, amplitudes, and event onset info for an mv
% struct with that for the specified runs. (NOTE: the runs list is relative
% to the number of unique runs specified in mv.trials.run: that is, if
% mv.trials.run has runs 3:8, and you select the subset runs=[1:4], it will
% take data for runs [3 4 5 6], rather than running into an error. But  you
% will get an error if you try to select runs [6:8])
%
% ras, 06/30/08.
if nargin<2, error('Need both input arguments.');	end

[mv.tSeries, mv.trials] = er_dataSubset(mv, runs);

mv.voxData = er_voxDataMatrix(mv.tSeries, mv.trials, mv.params);
mv.voxAmps = er_voxAmpsMatrix(mv.voxData, mv.params);

if isequal( mv.params.ampType, 'betas' ) | isfield(mv, 'glm')
	mv = mv_applyGlm(mv);
end
	
return

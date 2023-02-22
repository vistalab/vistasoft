function tc = tc_resample(tc, newTR);
% Resample a time course struct to reflect a different sampling rate.
%
%  tc = tc_resample(tc, newTR);
%
% newTR is the new temporal sampling period ('frameRate') for the time
% course. This will affect tc.wholeTc, and by extension, tc.meanTcs and
% tc.amps, as well as any GLMs or CorAnals applied to the tc.
% 
% ras, 11/04/2008  (Go Obama!)
if notDefined('tc'),	tc = get(gcf, 'UserData');			end
if notDefined('newTR'),	error('Need to specify a new TR.');	end

oldTR = tc.TR;

%% resample the time course
% if the new and old TRs are integer multiples of one another (in either
% direction), we can use MATLAB's RESAMPLE command. I'm guessing this is
% one of the better implementations for resampling. If not, we may need to
% do something grodier (like using INTERP3).
if isinteger( oldTR / newTR)
	tc.wholeTc = resample(tc.wholeTc, oldTR/newTR, 1);
elseif isinteger( newTR / oldTR )
	tc.wholeTc = resample(tc.wholeTc, 1, newTR/oldTR);
else
	tc.wholeTc = interp(tc.wholeTc, oldTR/newTR);
end
	
%% recompute the other TC fields
tc.TR = newTR;
tc.params.framePeriod = newTR;
tc.trials.TR = newTR;
tc.trials.onsetFrames = round(tc.trials.onsetSecs ./ newTR) + 1;
tc = tc_recomputeTc(tc, 1);

return

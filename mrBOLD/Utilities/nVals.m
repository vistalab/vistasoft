function nOut = nVals(trialOrder);
% nVals: detect repetition of entries in a numeric
% array.
%
% nOut = nVals(trialOrder);
%
% Here's the idea: trialOrder is an array of numbers. The n-value for each entry counts the
% number of times each value has been used. The first instance of a value has n=1, the
% second has n = 2, etc. So if trialOrder is:
%
% 1 1 1 2 1 2 2 3 4 5 1
%
% nOut will be:
%
% 1 2 3 1 4 2 3 1 1 1 5
%
% 1/03 by ras.
nOut = zeros(1,length(trialOrder));
vals = unique(trialOrder);
for i = 1:length(vals)
	currVal = vals(i);
	ind = find(trialOrder==currVal);
	cnt = 1:length(ind);
	nOut(ind) = cnt;
end

return

function iOut = iVals(trialOrder,ignoreNulls);
% iOut = iVals(trialOrder,ignoreNulls);
% iVals: Calculate i-value (intervening trials) for fMR-A Expts (but maybe more generally useful).
% 
% Here's the idea: trialOrder is an array of numbers, generally with values that are repeated. 
% The i-value of each element counts the number of intervening entries between repeated values.
% If the value for a given element in trialOrder has not occurred before in trialOrder, i = -1. 
% If the value has occurred immediately before the current element, i = 0;
% If the value last occurred two elements before, i = 1 (one element between repetitions), and so on.
%
% So if trialOrder is:
%
% 1 1 2 1 3 3 1 1 1 2
%
% nOut will be:
%
% -1 0 -1 1 -1 -1 2 0 0 6
%
% If ignoreNulls is set to 1, iOut will ignore intervening elements with a value of 0 in counting
% (e.g., 1 0 0 1 will have an iOut of -1 -1 -1 0 instead of -1 -1 0 2).
%
% 1/03 by ras.
% 10/03 ras: updated to work with matrices. If a matrix is passed, it will run through eac
% row and get the ivals.
if ~exist('ignoreNulls','var')	ignoreNulls = 0;		end

if size(trialOrder,1) > 1 & size(trialOrder,2) > 1
	iOut = [];
	for i = 1:size(trialOrder,1)
		iOut = [iOut; iVals(trialOrder(i,:))];
	end
	return
end


if ignoreNulls
	nonNulls = find(trialOrder~=0);
	nulls = find(trialOrder==0);
	fullOrder = trialOrder;
	trialOrder = trialOrder(nonNulls);
end

for i = 1:length(trialOrder)
	currVal = trialOrder(i);
	ind = find(trialOrder==currVal);
	if ind(1)==i
		iOut(i) = -1;
	else
		loc = find(ind==i);
		lastInstance = ind(loc-1);
		iOut(i) = i - lastInstance - 1;
	end
end

if ignoreNulls
	tmp = iOut;
	iOut = zeros(1,length(fullOrder));
	iOut(nonNulls) = tmp;
	iOut(nulls) = -1;
end

return

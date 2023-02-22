function hist = gethistory(theorder)
% hist = gethistory(theorder)
% each row of history is a condition
% each column shows how many times trials of condition R are
% preceded by condition C
% assumes 1-D vector input of condition order
while length(find(theorder > 0)) < length(theorder)
    theorder = theorder + 1;
end

numtrials = length(theorder);
numconds = length(unique(theorder));
hist = zeros(numconds, numconds);
for n = 2:numtrials
        hist(theorder(n), theorder(n-1)) = hist(theorder(n), theorder(n-1))+1;
end

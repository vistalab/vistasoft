function initials = tc_condInitials(condNames);
%
% initials = tc_condInitials(condNames);
%
% Provides brief initials for a set of condition names.
%
% PROBLEM: when creating bar graphs or other images where conditions
% are plotted against one another, oftentimes there isn't space for the
% full condition label. (And often there's a legend with the full label
% next to the colors). So, just as a reminder, we want to have some
% abbreviated form of the condition names.
%
% SOLUTION: This code figures out 'good' initials, meaning initials that
% are the smallest possible to be unambiguous. If each condition name starts
% with a different letter, it will just be the first letters. If some are
% the same, it will use heuristics like finding capital letters or spacers
% (e.g. '_'), and making each initial unique.
%
% The returned initials are all capital, in a cell array of strings.
%
% ras, 02/06.
nConds = length(condNames);

% check that there aren't duplicate condition names: if so, the
% code below may get stuck in a loop (because there are always non-unique
% identifiers), so fix them by appending numbers
condNames = lower(condNames);
for i = 1:nConds
    test = cellfind(condNames, condNames{i});
    if length(test) > 1
        msg = sprintf(['Condition name %s is not unique! ' ...
                       'Appears in entries %s. ' ...
                       'Am numbering these duplicate entries. '], ...
                       condNames{i}, num2str(test));
        warning(msg);
        for j = test
            condNames{j} = [condNames{j} num2str(j)];
        end
    end
end

% remove any leading and trailing spaces from condNames:
for i = 1:nConds
    while isequal(condNames{i}(1), ' ')
        condNames{i} = condNames{i}(2:end);
    end
end

% initialize the initials ( :-) ) as the first letter of each cond name
for i = 1:nConds
    initials{i} = upper(condNames{i}(1));
end

% if each letter is unique, great! We're done.
if length(unique(initials))==length(initials)
    return;
end

% if we got here, there are some non-unique letters. Find them and fix
% them:

% First, go through each non-unique cond name, and see if we can find
% a 'second word', meaning a string after a space or an underscore,
% or a capital letter (or number). If we find one for a condition name, 
% reshape that condition name to be 2D (words by characters in word).
for i = 1:nConds
    str = condNames{i};
    
    % blank spacers
    spacers = [findstr('_', str) findstr(' ', str)];
    
    % upper-case letters (ASCII range 65-90): find the preceding letter as
    % the spacer:
    spacers = [spacers find(ismember(str, 65:90))-1];  

    % do the same operation for numbers as for upper-case letters, only
	% the ASCII range for number strings is 48-57:
    spacers = [spacers find(ismember(str, 48:57))-1];  
	
    % sort into ascending indices in the string; remove spacers at end
    % points:
    spacers = spacers(spacers>1 & spacers<length(str));
    spacers = unique( sort(spacers) );
    if ~isempty(spacers)
        for j = spacers
            str = strvcat(str(1:j-1), str(j+1:end));
        end
        condNames{i} = str;
    end    
end

notUnique = ones(size(initials)); % initialize index of remaining non-unique entries
while any(notUnique)
    % find which entries are repeated
    for i = 1:length(initials)
        if length(cellfind(initials, initials{i})) > 1
            notUnique(i) = 1;
        else
            notUnique(i) = 0;
        end
    end

    % for each non-unique entry, add one more character
    for j = find(notUnique)
        N = min( length(initials{j})+1, prod(size(condNames{j})) );
        initials{j} = upper(condNames{j}(1:N));
		
		% if the initials are as long as the condition name, stop.
		if N == numel(condNames{j})
			notUnique(j) = 0;
		end
    end  
end

initials = upper(initials);

return


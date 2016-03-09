function exploded = explode(separator, inString, itemWrapper)
% Separate the string into a cell array of components using the separator
%
%  explodedCellArray = explode(separator, stringToExplode, itemWrapper)
%
% separator:        Character separating the strings
% stringToExplode:  String of separated strings  
% itemWrapper:      Removes an itemWrapper from the beginning and end of
%               the strings.  See example below.
%
% Easiest to use examples:
%   explode(',', 'one,two,three')            returns {'one', 'two', 'three'}
%   explode(';', '"one";"two";"three"', '"') returns {'one', 'two', 'three'}
%
% RETURNS: a cell array that is the PHP-style explosion of the string
%
% 2001.02.01 Bob Dougherty <bob@white.stanford.edu>
% ras 06/30/05 imported into mrVista 2.0 Test repository
% baw commented, fixed example to run, and allocated exploded and changed
%   var names. 

%% Parse inputs

if(~exist('separator','var') ...
        || ~exist('inString','var') ...
        || isempty(inString) ...
        || (exist('itemWrapper','var') && length(itemWrapper)>1))
    help(mfilename);
    return;
end

if(~exist('itemWrapper','var'))
    itemWrapper = '';
end

%% Explode the strong
sep = strfind(inString,separator);
exploded = cell(1,length(sep)+1);

if(isempty(sep))
    % No separator, just return the string
    exploded{1} = inString;
else
    % First string
    exploded{1} = inString(1:sep(1)-1);
    for i= (1:length(sep)-1)
        % For each
        exploded{i+1} = inString(sep(i)+1:sep(i+1)-1);
    end
    % Last string follows the last separator
    exploded{length(exploded)} = inString(sep(end)+1:end);
end


%% Remove the itemWrapper char from the beginning and end of strings

if(~isempty(itemWrapper))
    for i=1:length(exploded)
        if(exploded{i}(1)==itemWrapper)
            exploded{i} = exploded{i}(2:end);
        end
        if(exploded{i}(end)==itemWrapper)
            exploded{i} = exploded{i}(1:end-1);
        end
    end
end

end
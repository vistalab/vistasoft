function implodedString = implode(separator, cellArrayToImplode, itemWrapper)
% 
% implodedString = implode(separator, cellArrayToImplode, [itemWrapper])
%
% Import of a very cool php function.  Also optionally allows an itemWrapper,
% which is useful for putting quotes around the cellArray items.
%
% Easiest to use examples:
%   implode(',', {'one', 'two', 'three'}) produces 'one,two,three'
%   implode(' \t ', {'one', 'two', 'three'}) produces 'one \t two \t three'
%   implode(';', {'one', 'two', 'three'}, '"') produces '"one";"two";"three"'
%
% RETURNS: a string that is the PHP-style implosion of the cellArray
%
% 2001.01.24 Bob Dougherty <bob@white.stanford.edu>
% ras 06/30/05 imported into mrVista 2.0 Test repository

if(~exist('separator','var') | ~exist('cellArrayToImplode','var') ...
    | isempty(cellArrayToImplode))
    help(mfilename);
    return;
end
% do something intelligent if called with a non-cell object
if(~iscell(cellArrayToImplode))
    if(ischar(cellArrayToImplode))
        implodedString = cellArrayToImplode;
    else
        implodedString = num2str(cellArrayToImplode);
    end
    return;
end
if(~exist('itemWrapper','var'))
    itemWrapper = '';
end

if(ischar(cellArrayToImplode{1}))
    curItem = cellArrayToImplode{1};
else
    curItem = num2str(cellArrayToImplode{1});
end
implodedString = [itemWrapper,curItem,itemWrapper];
for i=[2:length(cellArrayToImplode)]
    if(ischar(cellArrayToImplode{i}))
        curItem = cellArrayToImplode{i};
    else
        curItem = num2str(cellArrayToImplode{i});
    end
    implodedString = [implodedString,separator,itemWrapper,curItem,itemWrapper];
end

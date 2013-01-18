function nums = findNumericStrings(str);
% nums = findNumericStrings(str);
%
% Given a string or cell array of strings,
% parse each string to see if they contain
% any numbers. Return a numeric array which 
% contains the numeric value of the longest
% such string in each entry, or NaN if none
% are found.
%
% This is distinct from str2num, because that
% function required that the whole string
% specify the number. This function only
% checks if part of the string contains the
% number -- e.g., 'myFile23.jpg' will return
% 23, 'test2part11' will return 11, and 
% 'hello' will return NaN.
%
% Originally written to deal with I-file
% names in mrVista.
%
% ras 03/05.
if iscell(str)
    % go recursively through each entry
    nums = NaN*ones(size(str));
    sz = prod(size(str));
    for i = 1:sz
         nums(i) = findNumericStrings(str{i});
    end
    return
elseif ~ischar(str)
    help(mfilename);
    return
end

% if we got here, we're dealing with a char.
% Search for a numeric string within this char:
asciiVals = uint8(str);
isNumber = ismember(asciiVals,[48:57]); % Ascii vals for '0' ... '9'

if all(isNumber==0)
	nums = NaN;
    return
else
    % check for longest string of sequential #s
    inarow = nVals(isNumber);
    nDigits = max(inarow(isNumber==1));
    
    % find entries pertaining to longest
    % string:
    ind = find(inarow==nDigits & isNumber==1);
    ind = ind(1); 
    rng = ind-nDigits+1:ind;
    
    % grab the numeric value for this range:
    nums = str2num(str(rng));
end

return

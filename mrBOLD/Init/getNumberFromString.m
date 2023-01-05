function number = getNumberFromString(string, loc, delimiter)
% number = getNumberFromString(string, loc, delimiter);
%
% Extract a number from the input string. Numbers are
% assumed to be delimited by the input delimiter; default
% is a space. Input loc is an integer specifying which
% number to return if several are present in the string;
% default value is 1.
%
% ARW 111802: Changed name to avoid conflict with PsychToolbox function.
%
% Ress 9/01% $Author: wade $
% $Date: 2002/11/19 01:20:17 $

if ~exist('delimiter', 'var'), delimiter = ' '; end
if ~exist('loc', 'var'), loc = 1; end
numbers = [];
number = [];
iD = findstr(string, delimiter);
if isempty(iD)
  number = str2num(string);
  return
end

nD = length(iD);
i0 = 1;
for ii=1:nD
  numbers = [numbers str2num(string(i0:iD(ii)))];  i0 = iD(ii) + 1;
end

if i0 <= length(string)
  numbers = [numbers str2num(string(i0:end))];
end  
if length(numbers) >= loc, number = numbers(loc); end

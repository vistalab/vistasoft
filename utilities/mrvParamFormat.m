function sformatted = mrvParamFormat(s)
% Converts the cell array of key/value pairs in s to (lower case, no spaces)
%
% Syntax
%    sformatted = mrvParamFormat(s)
%
% Description:
%   If input is a string, converted to lower case and spaces are removed.
%  
%   If input is a cell array, then stParamFormat is called on the odd
%   entries of the array.  This converts a varargin that contains key/value
%   pairs.
%
% Example:
%   mrvParamFormat('Exposure Time')
%   mrvParamFormat({'Exposure Time',1})
%   mrvParamFormat({'Exposure time',1,'number of rays',128})
%
% Examples in code
%
% Copyright ImagEval Consultants, LLC, 2010

% Examples:
%{
    mrvParamFormat('Exposure Time')
    keyValuePairs{1} = 'Exposure Time';
    keyValuePairs{2} = 1;
    keyValuePairs{3} = 'iWasCamelCase';
    keyValuePairs{4} = 'Do Not Convert Me';
    keyValuePairs = stParamFormat(keyValuePairs)
%}

if (~ischar(s) && ~iscell(s)), error('s has to be a string or cell array'); end

% Lower case
if (ischar(s))
    % To lower and remove spaces
    sformatted = lower(s);
    sformatted = strrep(sformatted,' ','');
    
elseif (iscell(s))
    
    % If a cell array, it must be parameter/value pairs
    if mod(length(s),2)
        error('Parameter/Value - must be even number of cells.');
    end
    
    % Convert
    sformatted = s;
    for ii = 1:2:length(s)
        sformatted{ii} = mrvParamFormat(s{ii});
    end
end

end

function val = ParamGet(paramStruct, paramIn)

% USAGE: A wrapper for DictParamDriver
%
% INPUT: paramStruct, paramIn
% The struct that will be searched to find the specific value, as well as
% the parameter that relates to that struct location.
%
% OUTPUT: val
% The value stored at the location necessary within the parameter struct 


paramIn = mrvParamFormat(paramIn);

val = DictParamDriver(paramStruct,paramIn);

return
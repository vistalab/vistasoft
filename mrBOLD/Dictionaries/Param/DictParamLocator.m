function structLocation = DictParamLocator(paramKey)

%
% USAGE: Translates input parameters into their location in the struct.
%
% INPUT: paramKey
% Parameter key that will already have been stripped of capitalization as well as
% whitespace. Should be perfectly matched since created internally within
% this system.
%
%
% OUTPUT: structLocation
% A string pointing to the location in the struct of the data necessary.

global DictParamLocate

if isempty(DictParamLocate)
    %Define and construct DictParamLocate
    DictParamLocate = containers.Map;
    
    DictParamLocate('nscans') = 'nScans';    
    DictParamLocate('dim') = 'dim';
    DictParamLocate('pixdim') = 'pixdim';
end

if DictParamLocate.isKey(paramKey)
    structLocation = DictParamLocate(paramKey);
else
    warning('Dict:ParamHelperWarning', 'The input of %s does not appear to be in the dictionary', paramKey);
    structLocation = '';
end

return
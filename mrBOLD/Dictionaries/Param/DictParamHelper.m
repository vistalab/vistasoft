function helpMessage = DictParamHelper(paramKey)

%
% USAGE: Translates input keys into help functions for that key.
%
% INPUT: paramKey
% Parameter key that will already have been stripped of capitalization as well as
% whitespace. Should be perfectly matched since created internally within
% this system.
%
% OUTPUT: paramKey
% The internal key used by the system as the key to all of the data maps



global DictParamHelp

if isempty(DictParamHelp)
    %Define and construct DictParamHelp
    DictParamHelp = containers.Map;
    
    DictParamHelp('nscans') = 'The total number of scans that this param stores.';    
    DictParamHelp('dim') = 'The screen space dimensions of the data. Can be thought of as size(data).';
    DictParamHelp('pixdim') = 'The real world dimensions of each pixel of data. Usually in mm or seconds.';
end


if DictParamHelp.isKey(paramKey)
    helpMessage = DictParamHelp(paramKey);
else
    warning('Dict:ParamHelperWarning', 'The input of %s does not appear to be in the dictionary', paramKey);
    helpMessage = '';
end

return
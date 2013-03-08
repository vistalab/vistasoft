function val = DictParamDriver(paramIn)


% USAGE: Gets an input parameter and returns the value in the struct it is
% associated with.
%
% INPUT: paramKey
% Parameter key that will already have been stripped of capitalization as well as
% whitespace. Should be perfectly matched since created internally within
% this system.
%
% OUTPUT: paramKey
% The internal key used by the system as the key to all of the data maps

global DictParamTranslate

if (paramIn = 'help')
    %We need to return the help file. Let's do that:
    params = keys(DictParamTranslate);
    for param 
end

if empty(DictParamHelp)
    %Define and construct DictParamHelp
    DictParamHelp = containers.Map;
    
    DictParamHelp('nscans') = 'The total number of scans that this param stores.';    
    DictParamHelp('dim') = 'The screen space dimensions of the data. Can be thought of as size(data).';
    DictParamHelp('pixdim') = 'The real world dimensions of each pixel of data. Usually in mm or seconds.';
end


if DictParamHelp.isKey(paramIn)
    helpMessage = DictParamHelp(paramIn);
else
    warning('Dict:ParamHelperWarning', 'The input of %s does not appear to be in the dictionary', paramIn);
    helpMessage = '';
end

return
function paramKey = DictParamTranslator(paramIn)

%
% USAGE: Translates input parameters into real parameter keys
%
% INPUT: paramIn
% Parameter input that will be stripped of all capitalization as well as
% whitespace before it is attempted to be translated. If it is not
% translated, a warning is returned as well as an empty answer.
%
%
% OUTPUT: paramKey
% The internal key used by the system as the key to all of the data maps


global DictParamTranslate


if isempty(DictParamTranslate)
    %Define and construct DictParamTranslate
    DictParamTranslate = containers.Map;
    
    DictParamTranslate('numscans') = 'nscans';
    DictParamTranslate('numberofscans') = 'nscans';
    DictParamTranslate('nscans') = 'nscans';
    
    DictParamTranslate('dim') = 'dim';
    DictParamTranslate('dims') = 'dim';
    DictParamTranslate('dimension') = 'dim';
    DictParamTranslate('dimensions') = 'dim';

    DictParamTranslate('pixdim') = 'pixdim';
    DictParamTranslate('pixeldimension') = 'pixdim';
    DictParamTranslate('pixeldim') = 'pixdim';
    DictParamTranslate('pixeldims') = 'pixdim';
    DictParamTranslate('voxelsize') = 'pixdim';
    DictParamTranslate('voxsize') = 'pixdim';
end


if DictParamTranslate.isKey(paramIn)
    paramKey = DictParamTranslate(paramIn);
else
    warning('Dict:ParamTranslatorWarning', 'The input of %s does not appear to be in the dictionary', paramIn);
    paramKey = '';
end

return
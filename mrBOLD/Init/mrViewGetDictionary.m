function [translatedValue] = mrViewGetDictionary(valueToTranslate)
%
%
% USAGE:
%   This function is called to translate a parameter value to the internal
%   key assigned to that value. This internal key will be used for the
%   other dictionaries containing Help and struct location information.
%
% INPUT:
%   valueToTranslate - The parameter passed in to this dictionary
%
% OUTPUT:
%   translatedValue - The internal key used by all of the
%   viewGetDictionaries
%
% EXAMPLE:
%   a = mrViewGetDictionary('Anatomy Data Size')
%   a = 
%       anatdatasize
%
%
GLOBAL viewGetDict;


if (isempty(viewGetDict))
    %If this is the first run and viewGetDict hasn't been initialized,
    %let's do that.
    viewGetDict = containers.Map;
    viewGetDict = mrViewGetDictionarySetup(viewGetDict); %Initializing it
end


if viewGetDict.isKey(valueToTranslate)
    translatedValue = viewGetDict(valueToTranslate);
else
    translateValue = ''; %Return empty
    warning('vista:ViewGetDict','The value supplied to mrViewGetDictionary is invalid. Please try again.';
end
function viewGetDict = mrViewGetDictionarySetup(viewGetDict)
%
%
% USAGE:
%   This function is called upon initialization / first use to create
%   create the dictionary hash map for viewGet. This dictionary maps all of
%   the possible input combinations to the unique key that pertains to that
%   value.
%
% INPUT:
%   valueToTranslate - the orientation string, e.g. 'RAS'
%   searchString - the one character string to search for, e.g. 'S'
%   Note: the search string needs to be one of 'L','R','A','P','I','S'
%
% OUTPUT:
%   Number such that vectorString[number] = searchString
%   Note: if there are multiple occurences, then only the first one is
%   returned, along with a warning
%
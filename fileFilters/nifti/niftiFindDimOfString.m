function [dim] = niftiFindDimOfString(vectorString, searchString)
%
%
% USAGE:
%   This function can be called to return the dimension of a specific
%   orientation inside a vectorString.
%
% INPUT:
%   vectorString - the orientation string, e.g. 'RAS'
%   searchString - the one character string to search for, e.g. 'S'
%   Note: the search string needs to be one of 'L','R','A','P','I','S'
%
% OUTPUT:
%   Number such that vectorString[number] = searchString
%   Note: if there are multiple occurences, then only the first one is
%   returned, along with a warning
%
% Adds text underneat the axes of an inplane window informing the user
% which side is left and which is right, based in information in the I-file
% header from the inplanes.
%Taking a vector, find the dimension of the string given in 'searchString'
%This is essentially a wrapper of 'find', however, it will return only 1
%result since there should only be 1 of each L/R, A/P, S/I. You can also
%only use only one of the directions (L or R, A or P, S or I) and it will
%return both

dim = 0; %Initialize

if isempty(vectorString) || isempty(searchString)
    warning('vista:nifti:transformError', 'The input was empty. Please try again. Returning empty.');
    return
end

%Declare this as persistent so we don't need to redeclare it every time
persistent searchStringOppositeMap;

searchStringOppositeMap = containers.Map;

searchStringOppositeMap('L') = 'R';
searchStringOppositeMap('R') = 'L';
searchStringOppositeMap('A') = 'P';
searchStringOppositeMap('P') = 'A';
searchStringOppositeMap('S') = 'I';
searchStringOppositeMap('I') = 'S';


tmp = strfind(vectorString,searchString);

if isempty(tmp) %it means that we need to get the opposite string
    tmp = strfind(vectorString,searchStringOppositeMap(searchString));
    if isempty(tmp) %We have neither? Badly formatted string!
        warning('vista:niftiError', 'Unable to parse the vector string and create the Xform matrix. Returning empty.');
        return
    end %if
end %if

if numel(tmp) ~= 1
    %We should only have 1 of each searchString inside a correctly made
    %string.
    warning('vista:niftiError', 'Incorrectly formatted vectorString, we have more than one of the searchString inside it. Returning empty.');
    return
end %if
    
dim = tmp(1);

return
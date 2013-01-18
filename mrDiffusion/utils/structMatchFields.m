function [S1, S2] = structMatchFields(S1, S2)
% Set structures to have the same fields - each has union of all fields
%
%   [S1, S2] = function structMatchFields(S1, S2)
%
% Fields missing in one or the other are added, and initialized to empty. 
%
% Input: Two arrays of structures. Within each, they all must have the
% same fields. The two different ones may or may not contain similar
% fields.
%
% Output: The array structures are returned with each structure having all
% of the fields. When the fields were not previously present, they are
% initialized as empty. 
%
% Example:
%   s = meshCreate; s2 = meshCreate;
%   s1(1) = s; s1(2) = s2; 
%   [a,b] = cellStructUnion(s1,s2);
%
% HISTORY:
%  ER wrote it 03/2010
%
% (c) Stanford VISTA Team 2010

% TODO:  Should rename the function via SVN.
%        The only place it is used at present is dtiAddFG.m
%

AllFields = union(fieldnames(S1), fieldnames(S2));

% We need to check that S1 and S2 are both structures.  In some of the
% calls we have seen S1 is an array of structures.  That would break this
% code.
for f=1:length(AllFields)
    if ~isfield(S1, AllFields{f})
        S1.(AllFields{f})=[];
    end
    if ~isfield(S2, AllFields{f})
        S2.(AllFields{f})=[];
    end

end

tmp = orderfields(S2,S1);
S2 = tmp;

return
function outStruct = mergeStructures(s1, s2)
% outStruct = mergeStructures(firstStruct, secondStruct)
%
% returns a structure with fields from both input structures.
% If both input structures have the same fields, the s2
% fields overwrite the s1 fields.
%
% ras, 09/06/2005, imported into mrVista 2.0
% ras, 07/21/2007, deals with struct arrays and empty structs.

% if s1 is empty, our job is easy: we can overwrite it with s2:
if isempty(s1)
	outStruct = s2;
	return
end

% deal with different sizes of structures:
% we can do this if s2 is a struct array, but not if
% s1 is (for now)
if length(s1) > 1
	error('firstStruct needs to be length 1 or empty.')
end


if length(s2) > 1
	% we allow only for up to 2 dimensions here
	for i = 1:size(s2, 1)
		for j = 1:size(s2, 2)
			outStruct(i,j) = mergeStructures(s1, s2(i,j));
		end
	end
	return
end

%% core part of merge:
% make sure all fields which belong to either s1 or s2 are assigned to
% outStruct:
outStruct = s1;

if ~isempty(s2)
	fieldNames = fieldnames(s2);
	for i = 1:length(fieldNames)
		f = fieldNames{i};
		outStruct.(f) = s2.(f);
	end
end

return


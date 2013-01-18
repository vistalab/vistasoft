function outStruct = mergeStructures(firstStruct, secondStruct)
% outStruct = mergeStructures(firstStruct secondStruct)
%
% returns a structure with fields from both input structures.
% If both input structures have the same fields, the secondStruct
% fields overwrite the firstStruct fields.
%
% ras, 09/06/2005, imported into mrVista 2.0
% ras, 07/21/2007, deals with struct arrays and empty structs.
outStruct = firstStruct;

% if firstStruct is empty, our job is easy: we can overwrite it with
% secondStruct:
if isempty(firstStruct)
	outStruct = secondStruct;
	return
end

% deal with different sizes of structures:
% we can do this if secondStruct is a struct array, but not if
% firstStruct is (for now)
if length(firstStruct) > 1
	error('firstStruct needs to be length 1 or empty.')
end

if length(secondStruct) > 1
	% we allow only for up to 2 dimensions here
	for i = 1:size(secondStruct, 1)
		for j = 1:size(secondStruct, 2)
			outStruct(i,j) = mergeStructures(firstStruct, secondStruct(i,j));
		end
	end
	return
end

if ~isempty(secondStruct)
	fieldNames = fieldnames(secondStruct);
	for i = 1:length(fieldNames)
		f = fieldNames{i};
		outStruct.(f) = secondStruct.(f);
	end
end

return


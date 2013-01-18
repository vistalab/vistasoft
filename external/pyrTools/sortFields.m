function sortedStruct = sortFields(struct)
%struct = sortFields(struct)
%
%Returns a structure with the fields in alphabetical order.
%Useful because you can't make an array of structures if
%the fields of the structures are defined in different orders,
%which is very lame.
%
%EXAMPLE:
%foo1.a = 10;
%foo1.b = 20;
%foo2.b = 30;
%foo2.a = 40;
%catFoo = [sortFields(foo1),sortFields(foo2)]
%
%note: [foo1,foo2] doesn't work
%
%dar 3/07: now works on structure arrays too - irrelevant function in light
%of "orderfields" builtin??

if length(struct(:)) > 1
	% recursively sort each struct
	for n = 1:length(struct(:))
		sortedStruct(n) = sortFields(struct(n));
	end
	sortedStruct = reshape(sortedStruct, size(struct));
	return
end

fields = fieldnames(struct);
sortedFields = sort(fields);

for f = sortedFields(:)'
	sortedStruct.(f{1}) = struct.(f{1});
end

return;
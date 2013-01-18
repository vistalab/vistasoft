function mystruct = addToStruct(mystruct, mynewentry, rule)
% mystruct = addToStruct(mystruct, mynewentry, [rule = 'old'])
% Add a new element to a structure by finding corresponding fields.
%
% mystruct:     a matlab structure of any length
% mynewentry:   a matlab structure of length 1
% rule:         can be:
%                   'old' (output struct will have same fields as 'mystruct')
%                   'new' (output struct will have same fields as 'mynewentry')                       
%                   'all' (output struct will have any field in 'mystruct' or 'mynewentry')                       
%               default = 'old'
% mystruct(1).a = 1; mystruct(1).b = 2;
% mynewentry.b = 3;
% % this will produce an error; mystruct(2) = mynewentry
% % Instead, use: 
% mystruct = addToStruct(mystruct, mynewentry)
%
% jw: 6/15/2010
%%

if ~exist('rule', 'var'), rule = 'old'; end

fields.old = fieldnames(mystruct);
fields.new = fieldnames(mynewentry);

switch lower(rule)
    case {'o', 'old', 'first', '1'}
        fields.keep = fields.old;
        fields.remove = setdiff(fields.new, fields.old);
        for ii = 1:numel(fields.remove)
            mynewentry = rmfield(mynewentry, fields.remove{ii});
        end
        
    case {'n', 'new', 'second', '2'}
        fields.keep = fields.new;
        fields.remove = setdiff(fields.old, fields.new);
        for ii = 1:numel(fields.remove)
            mystruct = rmfield(mystruct, fields.remove{ii});
        end
    
    case {'a', 'all', 'both', 'b'}
        fields.keep = union(fields.old, fields.new);
end
    
n      = numel(mystruct) + 1;

for f = 1:numel(fields.keep)
    if isfield(mynewentry, fields.keep{f})
        mystruct(n).(fields.keep{f}) = mynewentry.(fields.keep{f});
    else
        mystruct(n).(fields.keep{f}) = [];
    end
end

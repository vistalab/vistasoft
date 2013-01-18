function newMsh = meshFormat(oldMsh,newMsh)
% Updates an older mesh object (oldMesh) to the new mesh format.
%
%    newMsh = meshFormat(oldMsh,[newMsh])
%
% The old field values that still are used are copied to the new mesh.
% Other fields, which are unused, are not copied. This routine can also be
% used to copy multiple fields from a partial mesh, (oldMesh), into a
% properly formatted new mesh (newMsh).
%
% Examples:
%
% GB 02/13/05
% (c) Stanford VISTA Team

if notDefined('newMsh'), newMsh = meshCreate;
elseif ~meshCheck(newMsh);
    error('First mesh must be defined consistent with meshCreate');
end

% Get the field names defined by meshCreate into a cell array
fields = fieldnames(newMsh);

% Copy any of the fields in the partial mesh into the new mesh that we
% output.  The new mesh has a flat data structure.  The old mesh had one
% field (data) with subfields in it.
for ii=1:length(fields)
    if checkfields(oldMsh,fields{ii}) || checkfields(oldMsh,'data',fields{ii})
        
        if (~isempty(meshGet(oldMsh,fields{ii}))) 
            % I don't know how, but some null fields were slipping by here
            % They caused a problem when they were passed into meshSet (for
            % example, a null actor field generated an error on line 60.
            % This additional isempty check fixed things. ARW 052407
            newMsh = meshSet( newMsh, fields{ii}, meshGet(oldMsh, fields{ii}) );
        end
        
    end
end


return;

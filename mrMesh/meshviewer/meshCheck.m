function ok = meshCheck(msh)
%meshCheck -- Verify that the mesh structure is consistent with meshCreate
%
%   ok = meshCheck(msh)
%
% Example
%
%   meshCheck(meshCreate)
%
%   msh.vertices = 0;
%   meshCheck(msh)
% ras 06/06: rewritten to give more information
defaultFields = fieldnames(meshCreate);
meshFields = fieldnames(msh);

ok = 1;

extraFields = setdiff(meshFields, defaultFields);
if ~isempty(extraFields)
    disp('Extra fields detected in this mesh: ')
    extraFields
    ok = 0;
end

missingFields = setdiff(defaultFields, meshFields);
if ~isempty(missingFields)
    warning('Missing fields detected in this mesh: ')
    missingFields
    ok = 0;
end


return;


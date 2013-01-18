function txt = infoText(mr, format);
%
% Print out info about an mr file (or other struct)
% in a human-readable set of strings.
%
% txt = infoText(mr, [format]);
% 
% mr: mr data struct, or path to an mr file to load.
%
% format: a flag; if 0 [default], returns as a cell-of-strings
%         for display in a listbox uicontrol;
%         if 1, returns as a single char vector w/ control
%         characters (/n) inserted.
%
% This function could be applied to other structs besides the 
% mr.info struct it was first written for. It simply takes
% all fields in the struct that are numeric or char, and prints the
% field name next to the field value.
%
% ras, 10/2005.
if notDefined('format'), format = 0; end


% (1) initialize an empty text cell
txt = {};

% (2) get basic info about the voxel size and extent of the data
% path
txt{end+1} = sprintf('Path: %s', mr.path);

% voxel size
if iscell(mr.dimUnits)
    units = mr.dimUnits{1};
else
    units = mr.dimUnits;
end
txt{end+1} = sprintf('Voxel Size: %2.1f x %2.1f x %2.1f %s', ...
                mr.voxelSize(1), mr.voxelSize(2), mr.voxelSize(3), ...
                units);
            
% dimensions
if ndims(mr.data) <= 3
    txt{end+1} = sprintf('Data Dimensions : %2.1f x %2.1f x %2.1f Voxels', ...
                mr.dims(1), mr.dims(2), mr.dims(3));
else
    txt{end+1} = sprintf(['Data Dimensions: %2.1f x %2.1f x %2.1f x %2.1f' ...
                          ' Voxels'], mr.dims(1), mr.dims(2), mr.dims(3));
end

% extent
txt{end+1} = sprintf('Spatial Extent : %2.1f x %2.1f x %2.1f %s', ...
            mr.extent(1), mr.extent(2), mr.extent(3), units);

            
% (3) add fields from the info sub-struct, if there are any
for f = fieldnames(mr.info)'
    val = mr.info.(f{1});
    if ischar(val)
        txt{end+1} = sprintf('%s: %s', f{1}, val);
    elseif isnumeric(val) & (size(val,1)==1 | size(val,2)==1)
        txt{end+1} = sprintf('%s: %s', f{1}, num2str(val));
    end
end

if format==1    % format as a single string
    tmp = '';
    for i = 1:length(txt)
        tmp = sprintf('%s \n%s',tmp,txt{i});
    end
    txt = tmp;
end

return

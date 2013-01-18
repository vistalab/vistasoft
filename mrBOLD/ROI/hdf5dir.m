function [groups, datasets] = hdf5dir(h5info, path, pos)
% [groups, datasets] = hdf5dir(h5info, path, pos)
%
% This function never returns an error - but will return the same thing for
% an empty group or failure to locate a node
%
% h5info - A Group in the hierarchy (send at least
% something.GroupHierarchy)
% path (optional) - the location of the hdf5 dataset or group
% pos (optional, mostly for recursion) - the path represented by h5info. 

if nargin < 2
    path = '/';
end

if nargin < 3
    pos = '';
end

% The top level hdf5info doesn't drop you into the groups, so we check into
% that first
if isfield(h5info, 'GroupHierarchy')
    h5info = h5info.GroupHierarchy;
end

groups = {};
datasets = {};

[tok, path] = strtok(path, '/');

if isempty(tok)
    if length(h5info.Groups) > 0
        groups = h5info.Groups;
    end
    
    if length(h5info.Datasets) > 0
        datasets = h5info.Datasets;
    end
else
    pos = [pos, '/', tok];
    
    for i = 1:length(h5info.Groups)
        if strcmp(pos, h5info.Groups(i).Name)
            [groups, datasets] = hdf5dir(h5info.Groups(i), path, pos);
        end
    end
    
    for i = 1:length(h5info.Datasets)
        if strcmp(pos, h5info.Datasets(i).Name)
            datasets = {h5info.Datasets(i).Name};
        end
    end
end
    
return
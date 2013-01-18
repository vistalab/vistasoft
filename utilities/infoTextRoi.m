function txt = infoTextRoi(roi, format);
%
% Print out info about an ROI file / struct
% in a human-readable set of strings.
%
% txt = infoTextRoi(roi, [format]);
% 
% roi: roi data struct, or path to an roi file to load.
%
% format: a flag; if 0 [default], returns as a cell-of-strings
%         for display in a listbox uicontrol;
%         if 1, returns as a single char vector w/ control
%         characters (/n) inserted.
%
% This function could be applied to other structs besides the 
% roi.info struct it was first written for. It simply takes
% all fields in the struct that are numeric or char, and prints the
% field name next to the field value.
%
% ras, 10/2005.
if notDefined('format'), format = 0; end


% (1) initialize an empty text cell
txt = {};

% (2) add fields from the struct
fields = setdiff(fieldnames(roi), {'coords' 'lineHandles'});
for f = fields(:)'
    val = roi.(f{1});
    if ischar(val)
        txt{end+1} = sprintf('%s: %s', f{1}, val);
        
    elseif isnumeric(val) & (size(val,1)==1 | size(val,2)==1)
        txt{end+1} = sprintf('%s: %s', f{1}, num2str(val));
        
    end
end

% (3) Add list of first <=100 coords:
nVoxels = size(roi.coords,2);
txt{end+1} = sprintf('# of Voxels: %i', nVoxels);
txt{end+1} = sprintf('Total Volume: %3.2f %s^3', ...
                     nVoxels * prod(roi.voxelSize), roi.dimUnits{1});
txt{end+1} = '';
txt{end+1} = sprintf('Coordinates in %s:', roi.reference);
nCoords = min(100, nVoxels);
if nCoords < nVoxels
    txt{end+1} = '(First 100 only)';
end

for n = 1:nCoords
    txt{end+1} = num2str(roi.coords(:,n)');
end

if format==1    % format as a single string
    tmp = '';
    for i = 1:length(txt)
        tmp = sprintf('%s \n%s',tmp,txt{i});
    end
    txt = tmp;
end

return

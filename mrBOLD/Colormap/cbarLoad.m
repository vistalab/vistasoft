function cbar = cbarLoad(pth);
% Load a saved colorbar file.
%
% cbar = cbarLoad([pth=dialog]);
%
% The initial format of a saved colorbar is a simple
% MATLAB file, so this call isn't much different
% from cbar = load(pth); However, this does some file 
% checks and field checks as well.
%
% ras, 02/24/07.
if notDefined('pth') % dialog
	pth = mrvSelectFile('r', 'mat', 'Select a saved colorbar file');
end

if ~exist(pth, 'file')
	error(sprintf('File %s not found.', pth))
end

cbar = load(pth);

% fields check
template = cbarDefault;
cbar = mergeStructures(template, cbar);

return

	
function status = cbarSave(cbar, pth);
% Save a colorbar to a MATLAB file.
%
% status = cbarSave(cbar, [pth=dialog]);
%
% Returns a 1 if the save was successful and a 0 otherwise.
%
% ras, 02/24/07.
status = 0;

if notDefined('cbar'), error('Need a colorbar.'); end

if notDefined('pth') % dialog
	pth = mrvSelectFile('w', 'mat', [], 'Save a colorbar...');
end

save(pth, '-struct', 'cbar');

if exist(pth, 'file')
	status = 1;
end

return


function status = recursiveDelete(pth);
% completely remove a directory, including all subdirectories. 
% equivalent to the 'rm -r' command in unix, but this uses MATLAB
% commands and so should be more platform-independent.
%
% Returns 1 if the delete was successful, 0 otherwise.
% ras, 03/07.
status = 0;

if notDefined('pth')
	error('Need to specify a directory to delete.')
end

if ~exist(pth, 'dir')
	warning( sprintf('%s not found.', pth) );
	return
end

w = dir(pth);

% remove '.' and '..' entries
names = {w.name};
ok = setdiff( 1:length(names), find(ismember(names, {'.' '..'})) );
w = w(ok);

if ~isempty(w)
	% clean out directory, using recursion if necessary
	for ii = 1:length(w)
		if w(ii).isdir
			status = recursiveDelete( fullfile(pth, w(ii).name) );
		else
			delete( fullfile(pth, w(ii).name) );
		end
	end
end

% now directory should be empty -- we can remove it
rmdir(pth);


if ~exist(pth, 'dir')
	status = 1;
end

return

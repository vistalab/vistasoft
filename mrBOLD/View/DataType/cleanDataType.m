function cleanDataType(dataTypeName, query)
%
%  cleanDataType(dataTypeName, [query])
%
% Deletes:
%   Inplane/dataType/*.mat
%   Inplane/dataType/TSeries/Scan*/*.mat
%   Likewise for Volume, Gray, and Flat*
%
% If you change this function make parallel changes in:
%     cleanGray, cleanFlat
%
% djh, 2/2001
% We could remove the directory for that data type, too.  Maybe we should.
% ras, 03/07: agreed. now nukes everything in the deleted data type dir.
global HOMEDIR
if ~exist('query','var')
    query = 0;
end
if query
	q = sprintf('Completely delete data type %s?', dataTypeName);
    confirm = questdlg(q, mfilename);
else
    confirm = 'Yes';
end
if strcmp(confirm,'Yes')
    disp(['Deleting dataType: ',dataTypeName]);
    [nDirs,dirList] = countDirs(fullfile(HOMEDIR,'Flat*'));
    dirList{nDirs+1} = 'Inplane';
    dirList{nDirs+2} = 'Gray';
    dirList{nDirs+3} = 'Volume';
    for d = 1:nDirs+3
        datadir = fullfile(HOMEDIR,dirList{d},dataTypeName);
        if exist(datadir,'dir')
            if isunix
                unix(sprintf('rm -r %s', datadir))
			else
				try
					rmdir(datadir, 's');
				catch
					disp('Couldn''t remove the directory.')
				end
            end
        end
    end
end
return

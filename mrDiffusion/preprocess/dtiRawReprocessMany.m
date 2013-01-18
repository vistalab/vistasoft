function dtiRawReprocessMany(subDirList, dtiDirName, rawBaseName, t1File, rawDirName)
%
% dtiRawReprocessMany(subDirList, dtiDirName, dwRawBaseName, [t1File='t1/t1.nii.gz'], [rawDirName='raw'])
%
% E.g.:
% subDirList = '/biac3/wandell4/data/reading_longitude/dti_adults/*';
% dtiDirName = 'dti06';
% rawBaseName = 'dti_g13_b800';
%
%
%

if(~exist('rawDirName','var')||isempty(rawDirName))
    rawDirName = 'raw';
end
if(~exist('t1File','var')||isempty(t1File))
    t1File = fullfile('t1','t1.nii.gz');
end
if(~iscell(subDirList))
    subDirList = {subDirList};
end

% Expand any subjectList entries that have a wildcard
allSubs = {};
for(ii=1:numel(subDirList))
    subDir = subDirList{ii};
    [parDir,sDir] = fileparts(subDir);
    if(~isempty(strfind(sDir,'*')))
        % expand the widcard
        d = dir(subDir);
        for(jj=1:numel(d))
            if(d(jj).isdir&&d(jj).name(1)~='.'&&exist(fullfile(parDir,d(jj).name,dtiDirName),'dir'))
                allSubs{end+1} = fullfile(parDir,d(jj).name);
            end
        end
    else
        % no wildcard- just add the directory to the list
        allSubs{end+1} = subDir;
    end
end

n = numel(allSubs);
for(ii=1:n)
    subDir = allSubs{ii};
	fprintf('Processing %s (%d of %d)...\n', subDir, ii, n);
    rawDir = fullfile(subDir, rawDirName);
    d = dir(fullfile(rawDir, [rawBaseName '.*']));
    bvec = ''; bval = ''; dwRaw = '';
    if(numel(d)>=3)
        tmp = {d.name};
        % now sort bvecs, bvals, nifti file
        try
            bvec = tmp{find(~cellfun('isempty',regexpi(tmp,'\.bvec.$','once')))};
            bval = tmp{find(~cellfun('isempty',regexpi(tmp,'\.bval.$','once')))};
            dwRaw = tmp{find(~cellfun('isempty',regexpi(tmp,'\.nii$|\.nii.gz','once')))};
        catch
        end
    end
    if(isempty(bvec)||isempty(bval)||isempty(dwRaw))
        disp('FAILED: Can''t find dwRaw/bvec/bval files.');
    else
        if(~exist(fullfile(subDir, t1File),'file'))
            disp('FAILED: Can''t find t1 file.');
        else
            outDir = fullfile(subDir, dtiDirName);
            oldDir = fullfile(subDir, [dtiDirName '_OLD' datestr(now,'yymmdd')]);
            % Rename the current data dir and put old raw 'aligned' files
            % in there.
            try
                movefile(outDir, oldDir);
                movefile(fullfile(rawDir, [rawBaseName '_aligned.*']), oldDir);
            catch
            end
            dtiRawPreprocess(fullfile(rawDir,dwRaw), fullfile(subDir, t1File), [], [], false, outDir);
        end
    end      

end

return;

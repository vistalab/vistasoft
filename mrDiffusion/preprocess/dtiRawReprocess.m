function dtiRawReprocess(subDir, dtiDirName, rawBaseName, t1File, rawDirName)
%
% dtiRawReprocessMany(subDir, dtiDirName, dwRawBaseName, t1File, [rawDirName='raw'])
%
% E.g.:
% subDirList = '/biac3/wandell4/data/reading_longitude/dti_adults/ab_090809';
% dtiDirName = 'dti06';
% rawBaseName = 'dti_g13_b800';
% t1File = 'full/path/to/t1.nii.gz';
%
% DY 09/2008: modified from dtiRawReprocessMany to work for just one
% subject at a time in the context of dti_FFA_preprocessScript_fixEddyRT
%
% NOTE: I also set clobber to TRUE just in case (forces recomputation of
% everything). Also, I checked that the eddyCorrect flag is set to default
% (true). 

if(~exist('rawDirName','var')||isempty(rawDirName))
    rawDirName = 'raw';
end

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
    if(~exist(t1File,'file'))
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
        dtiRawPreprocess(fullfile(rawDir,dwRaw), t1File, [], [], true, outDir);
    end
end



return;

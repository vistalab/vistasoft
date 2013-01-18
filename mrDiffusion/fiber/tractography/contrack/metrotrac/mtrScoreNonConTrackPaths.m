function mtrScoreNonConTrackPaths(subjectDir, fgFile, roi1File, roi2File, smoothParam, shapeParam, lengthParam, optionsFile, fgOutFile)

% mtrScoreNonConTrackPaths(subjectDir, fgFile, roi1File, roi2File, smoothParam, shapeParam, lengthParam, optionsFile, fgOutFile)
%
% 06/10/2007: AJS created it.
%
% This function takes STT fibers (fgFile), takes only those that pass
% through two desired ROIs (roi1File, roi2File), clips them, then writes
% the clipped fibers and their ConTrack scores to file (fgOutFile). 
%
% It requires certain parameters that Tony will hopefully document here
% soon (smoothParam, lengthParam, optionsFile). 


%% Setup the options file
% Prepare the roi filename by concatenating the ROI names
[pathstr, file1, ext, versn] = fileparts(roi1File); %#ok<NASGU>
[pathstr, file2, ext, versn] = fileparts(roi2File); %#ok<NASGU>
maskFile = fullfile(pathstr,['mask_' file1 '_' file2 '.nii.gz']);

mtrCreateConTrackOptionsFromROIs(subjectDir, roi1File, roi2File, optionsFile, optionsFile, 'junk', maskFile);

%% Update options file with user parameters
dt6 = load(fullfile(subjectDir,'dt6.mat'),'xformToAcPc');
mtr = mtrLoad(fullfile(subjectDir,'conTrack',optionsFile),dt6.xformToAcPc);
mtr = mtrSet(mtr, 'smooth_std', smoothParam);
mtr = mtrSet(mtr, 'abs_normal', lengthParam);
mtr = mtrSet(mtr, 'shape_params_vec', [shapeParam 0.15 100]); %#ok<NASGU>

%% Clip the pathways to the supplied ROIs
mtrClipFiberGroupToROIs( fullfile(subjectDir,'fibers',fgFile), ...
                         fullfile(subjectDir,'dt6.mat'), ...
                         fullfile(subjectDir,'ROIs',roi1File), ...
                         fullfile(subjectDir,'ROIs',roi2File), ...
                         fullfile(subjectDir,'bin','wmMask.nii.gz'), ...
                         fullfile(subjectDir,'fibers',fgOutFile) );

%% Export to format for the executable
[pathstr, file, ext, versn] = fileparts(fgOutFile); %#ok<NASGU>
fgOutFileDat = fullfile(pathstr,[file '.dat']);
mtrExportFiberGroupToMetrotrac( fullfile(subjectDir,'fibers',fgOutFileDat), ...
                                fullfile(subjectDir,'fibers',fgOutFile), ...
                                fullfile(subjectDir,'bin','fa.nii.gz') );

%% Check environment we are running in
if(ispc)
    executable = which('resample_pdb.exe');
elseif(strcmp(computer,'GLNXA64'))
    executable = which('resample_pdb.glxa64');
elseif (strcmp(computer,'GLNX86'))
    executable = which('resample_pdb.glx');
else
    error('Not compiled for %s.',computer);
end


%% Run the executable
workDir = fullfile(subjectDir,'conTrack');
args = sprintf(' -i %s -o tempScoreNonCTRK  -lpn %d %s', optionsFile, intmax, fullfile(subjectDir,'fibers',fgOutFileDat));
cmd = [executable args];
disp(cmd); disp('...')
if(ispc)
    mtrExecuteWinBash(cmd,workDir);
else
    system(cmd,'-echo');
end
disp('Done')

if( exist(fullfile(subjectDir,'fibers',fgOutFileDat),'file') )
    delete(fullfile(subjectDir,'fibers',fgOutFileDat));
end
tempPaths = dir(fullfile(subjectDir,'conTrack','tempScoreNonCTRK*.dat'));
if(size(tempPaths,1)>1)
    fileList = tempPaths(1).name;
    for ii = 2:size(tempPaths,1); fileList = [fileList ', ' tempPaths(ii).name]; end
    error(['Special temp name already used for intermediate path creation please remove the following files ' fileList]);
end
movefile(fullfile(subjectDir,'conTrack',tempPaths(1).name),fullfile(subjectDir,'fibers',fgOutFileDat),'f');
disp(['Final pathway file has been written to ' fullfile(subjectDir,'fibers',fgOutFileDat)]);

return;
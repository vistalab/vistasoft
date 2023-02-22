function dtiInitDt6Files(dt6FileName,dwDir,t1FileName)
% 
%  function dtiInitDt6Files(dt6FileName,dwDir,t1FileName)
% 
% Create and save the files structure in the dt6.mat file with the paths to
% the data, including the t1 relative path.
%
% INPUTS
%   dt6FileName - Full path to the dt6 file created in dtiInit.
%   dwDir       - structure created from within dtiInit containing the
%                 relevant folder information. 
%   t1FileName  - full path to the t1 image used for registration
% 
% WEB Resources
%   mrvBrowseSVN('dtiInitDt6Files');
%
% Example:
%   dtiInitDt6Files(dt6FileName,dwDir,t1FileName)
%
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%% Setup dt6.files
% 
dt6   = load(dt6FileName,'files');
files = dt6.files;

% Make the t1 path relative unless we used the MNI template - then we copy
% that image to the subjects dir so that it can be loaded easily.
if strcmpi(t1FileName,fullfile(dwDir.mrDiffusionDir,'templates','MNI_EPI.nii.gz'))
    cmd = ['cp ' t1FileName ' ' mrvDirup(dt6FileName,2)];
    system(cmd);
end
    k = strfind(t1FileName,dtiGetSubjDirInDT6(dt6FileName));
    if isempty(k) || ~exist(t1FileName(k:end),'file')
        [tmp,t1RelFileName,e] = fileparts(t1FileName); %#ok<ASGLU>
        t1RelFileName = [t1RelFileName e];
        if(exist(fullfile(dwDir.subjectDir,'t1'),'dir'))
            t1RelFileName = fullfile('t1',t1RelFileName);
        end
    else
        t1RelFileName = t1FileName(k+1+length(dtiGetSubjDirInDT6(dt6FileName)):end);
    end
    
    files.t1 = t1RelFileName;
    
% Add the raw data file names (these will be full paths)
files.alignedDwRaw   = dwDir.dwAlignedRawFile;
files.alignedDwBvecs = dwDir.alignedBvecsFile;
files.alignedDwBvals = dwDir.alignedBvalsFile;
save(dt6FileName,'files','-APPEND');

return

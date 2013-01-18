function dt6 = dtiRawFixDt6File(dt6FileName,t1FileName)
% Fix the paths in a dt6 file.
% dt6 = dtiRawFixDt6File(dt6FileName,[t1FileName='t1/t1.nii.gz'])
%
% Note that this function enforces unix-style file seperators (/) because
% these work on all platforms (Windows prefers \, but will take /). 
%
% Also note that if you catch the output argument, the fixed dt6 struct
% will NOT be saved.
%
% TODO: Allow t1 file to be outside the subject dir.
%
% 2007.08.01 RFD wrote it based on a script from Sherbondy.

if(~exist('dt6FileName','var')||isempty(dt6FileName))
    [f,p] = uigetfile({'*.mat';'*.*'},'Select a dt6 file to fix...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    dt6FileName = fullfile(p,f); 
end
if(~exist('t1FileName','var')||isempty(t1FileName))
    t1FileName='t1/t1.nii.gz';
end

[dt6Dir,fName,ext] = fileparts(dt6FileName);
if(isempty(dt6Dir)) dt6Dir = pwd; end
[subDir,dt6DirName] = fileparts(dt6Dir);
if(isempty(subDir)) subDir = pwd; end

dt6 = load(dt6FileName);
if isfield(dt6.files,'homeDir'); dt6.files = rmfield(dt6.files,'homeDir'); end
if isfield(dt6.files,'binDir'); dt6.files = rmfield(dt6.files,'binDir'); end
fieldList = fieldnames(dt6.files);
for ff=1:length(fieldList)
    [p,f,e] = fileparts(getfield(dt6.files,fieldList{ff}));
    f = [f e];
	dt6.files = setfield(dt6.files,fieldList{ff},[dt6DirName '/bin/',f]);
end
dt6.files.t1 = t1FileName;


if(~exist(fullfile(subDir,dt6.files.t1),'file'))
    [f,p] = uigetfile({'*.mat';'*.*'},'Select the associated t1 file (cancel for none)...');
    if(isnumeric(f))
        dt6.files.t1 = '';
    else
        dt6.files.t1 = [p '/' f]; 
    end
end
if(nargout==0)
    save(dt6FileName, '-struct', 'dt6');
end

return;

baseDir = '/teal/scr1/dti/probtrack_compare';
subjDirs = {'bg040719' 'md040714'  'mho040625'  'rfd040630'  'ss040804' 'db061209'};
ogDir = pwd;
for dd=1:length(subjDirs)
    disp(['Fixing dt6 for subject: ' subjDirs{dd} ' ...']);
    dt6FileName = fullfile(baseDir,subjDirs{dd},'dti06','dt6.mat');
    dtiRawFixDt6File(dt6FileName);
end
cd(ogDir);
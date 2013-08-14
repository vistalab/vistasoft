function [dt6Struct, dataFile, defaultPath, dataDir] = dtiLoadDt6Info(fname)
%
%  dt6Struct = dtiLoadDt6Info(fname);
%
%   Load the info fields of a dt6 (tensor) data file. These are mainly just
%   the fields that describe where the various data files can be found. Use
%   dtiLoadDt6 to load the actual data.
%
% TO DO:
%  * Change the convention so that the top-level data dir (the dir
%  containing the dt6 file) is not hard-coded in the stored files struct.
%  Doing so makes it annoying to move the data around.
%
% HISTORY:
%  2007.07.11 AJS: Wrote it.
%  2007.10.29 RFD: renamed from dtiLoadDT6NoGui
%  2007.10.29 RFD: hack to fix find the data even if the top-level data dir
%  has been renamed. (But this should be fixed- see "TO DO".)

dt6Struct = [];
dataFile = [];
defaultPath = [];
dataDir = [];
if(~exist('fname','var')||isempty(fname))
    [f,p] = uigetfile({'*.mat'}, 'Select a dt6 file...', pwd);
    if(isnumeric(f)), disp('Load Tensor canceled.'); return; end
else
    [p,f,e] = fileparts(fname);
    f = [f e];
    % crude test for a relative path...
%     if(isempty(p) || (isunix && p(1)~=filesep) || (ispc && p(2)~=':'))
%         p = fullfile(pwd,p);
%     end
end
if(isempty(p)), p = pwd; end

dataFile = fullfile(p,f);
defaultPath = p;
dataDir = p;
[junk,dataDirName] = fileparts(dataDir);

dt6Struct = load(dataFile);

% Convert each one of the filenames in this struct from relative to
% absolute
subjDir = dtiGetSubjDirInDT6(dataFile);

if(isfield(dt6Struct,'files'))
    % Then it's in new NIFTI format- fix up the file names. 
    fieldList = fieldnames(dt6Struct.files);
    for ff=1:length(fieldList)
        f = dt6Struct.files.(fieldList{ff});
        % FIX ME! We should not hard-code the top-level data dir, since it
        % is easy to find (it contains the dt6 file) and is often moved and
        % renamed by users. Until we change the convention, this hack will
        % fix things. The only problem is the t1, which can be anywhere. 
        if(strcmp(f,filesep)==0)
            if(filesep=='/')
                f = strrep(f,'\',filesep);
            else
                f = strrep(f,'/',filesep);
            end
        end
        [curDataDirName,restOfPath] = strtok(f,filesep);
        if(~strcmp(fieldList{ff},'t1') && ... % This is the T1
            ~strcmp(curDataDirName,dataDirName) && ... % It already has the dataDirName
            ~strcmp(curDataDirName, 'raw'))  % This is raw data
            f = [dataDirName restOfPath];
        end
        
        % Make a special case for the files in the 'raw' directory.
        % In this case, we will construct the absolute path to the raw
        % directory, which is next door in most case: 
        idx = strfind(f, 'raw');
        if ~isempty(idx)  
           f = f(idx:end);
        end
        
        dt6Struct.files.(fieldList{ff}) = fullfile(subjDir,f);
    end
else
   % It's in the old format, so the data have actually aleardy been loaded.
   % 
   % Check for an explicit brain mask that will be used to override the
   % brain mask saved in the dt6 file. 
   bmFile = fullfile(dataDir,'dtBrainMask.nii.gz');
   if(exist(bmFile,'file'))
       ni = niftiRead(bmFile);
       if(isfield(dt6Struct,'dtBrainMask')&&~isempty(dt6Struct.dtBrainMask))
           disp(['Over-riding brain mask with explicit mask in ' bmFile '.']);
       end
       dt6Struct.dtBrainMask = ni.data;
   end
end

return;

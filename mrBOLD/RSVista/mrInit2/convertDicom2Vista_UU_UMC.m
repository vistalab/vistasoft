function convertDicom2Vista_UU_UMC(subjectName,SkipVols,TR,SessionName)
% convertDicom2Vista_UU_UMC(subjectName,SkipVols,TR,SessionName) 
%
%
% Input:
%   subjectName: subject last name, no capitals
%   SkipVols: number of initial time-frames to remove from the data
%   TR: repetition time of fMRI scanner (should really get from the data)
%   SessionName: name of the experiment
%
% The script takes (3D) nifti files converted usign r2agui and converts
% them to mrVista format.
% 
% It is adapted from prepareUCSFParnassusUniversal and relies on spm(5) to
% read the nifti files.
% 


%% Some checks

if(isempty(which('spm_dicom_headers')))
    error('Requires spm2+ tools! I recommend spm5');
end
if ~exist('subjectName','var') || isempty(subjectName)
    error('Need the lastname of subject as input');
end
if ~exist('SessionName','var') || isempty(SessionName)
    error('Need SessionName, i.e. what is the experiment called');
end
if ~exist('SkipVols','var') || isempty(SkipVols);
    error('Need SkipVols, i.e. the number of initial time frames to remove from the data');
end
if ~exist('TR','var') || isempty(TR);
    error('Need TR, FIX ME I need to be able to read this from the data');
end



%% Clean up old mrVista structure
fprintf('[%s]:WARNING:Removing old mrVista structures!',mfilename);
if exist('mrSESSION_backup.mat','file')
    delete mrSESSION_backup
end
if exist('mrSESSION.mat','file')
    delete mrSESSION
end
if exist('prepareUUvars.mat','file')
    delete prepareUUvars.mat
end


%% Some defaults
if ~exist('Raw','dir')
    error('Data needs to be stored in directories under Raw directory');
end
RawDir = 'Raw';


%% find scans
d = dir(RawDir);
% find directory names
d = d([d.isdir]);
% remove '.' and '..'
remove = false(numel(d),1);
for n=1:numel(d)
    if strcmp(d(n).name,'.') || strcmp(d(n).name,'..')
        remove(n) = true;
    end
end
dirs = d(~remove);

if isempty(dirs)
    fprintf(1,'[%s]:WARNING:No directories found in %sRaw\n',mfilename,filesep);
    if ~isempty(dir(fullfile(RawDir,'*nii*')))
        dirs(1).name = [];
        fprintf(1,'[%s]:WARNING:But found nifti files continuing...\n',mfilename);
    else
        fprintf(1,'[%s]:WARNING:EXITING.\n',mfilename);
        return
    end
end



%% find functionals
c = 0;
for n=1:numel(dirs)
    % find files
    f = dir(fullfile(RawDir,dirs(n).name,'*.nii'));
    
    if numel(f)>10
        c = c+1;
        foundScans(c).Action = 'Functional'; %#ok<AGROW>
        
        hdr = spm_vol(['Raw/' dirs(n).name filesep f(1).name]);
        if c==1
            roughAlignment = hdr.mat;
        end
        
        % sort files in order
        fileNameOrder=zeros(numel(f),1);
        % hack time number is after (-)
        for ii=1:numel(f)
            sep1 = findstr(f(ii).name,'-');
            sep2 = findstr(f(ii).name,'.');
            fileNameOrder(ii) = str2double(f(ii).name(sep1+1:sep2-1));
        end
        [junk,sIndex] = sort(fileNameOrder); % Because we don't know how DIR might order the output
        f             = f(sIndex); % Apply the sort
        
        foundScans(c).FileNames = cell(numel(f),1); %#ok<AGROW>
        for ii=1:numel(f);
            foundScans(c).FileNames{ii} = f(ii).name; %#ok<AGROW>
        end
        foundScans(c).DirName   = dirs(n).name;%#ok<AGROW>
        foundScans(c).Sequence  = hdr.descrip;%#ok<AGROW>
        foundScans(c).SkipVols  = SkipVols;%#ok<AGROW>
        foundScans(c).Cycles    = 8;%#ok<AGROW>
        
        
        foundScans(c).TR        = TR;%#ok<AGROW>
        foundScans(c).RawDir    = RawDir;%#ok<AGROW>
        foundScans(c).Files     = numel(f);%#ok<AGROW>
        foundScans(c).Slices    = hdr.dim(3);%#ok<AGROW>
        foundScans(c).Volumes   = numel(f);%#ok<AGROW>
    else
        c = c+1;
        foundScans(c).Action = 'Anatomical'; %#ok<AGROW>
        
        hdr = spm_vol(['Raw/' dirs(n).name filesep f(1).name]);
        if c==1
            roughAlignment = hdr.mat;
        end
        
        % sort files in order
        fileNameOrder=zeros(numel(f),1);
        % hack time number is after (-)
        for ii=1:numel(f)
            sep1 = findstr(f(ii).name,'-');
            sep2 = findstr(f(ii).name,'.');
            fileNameOrder(ii) = str2double(f(ii).name(sep1+1:sep2-1));
        end
        [junk,sIndex] = sort(fileNameOrder); % Because we don't know how DIR might order the output
        f             = f(sIndex); % Apply the sort
        
        foundScans(c).FileNames = cell(numel(f),1); %#ok<AGROW>
        for ii=1:numel(f);
            foundScans(c).FileNames{ii} = f(ii).name; %#ok<AGROW>
        end
        foundScans(c).DirName   = dirs(n).name;%#ok<AGROW>
        foundScans(c).Sequence  = hdr.descrip;%#ok<AGROW>
        foundScans(c).SkipVols  = SkipVols;%#ok<AGROW>
        foundScans(c).Cycles    = 8;%#ok<AGROW>
        
        
        foundScans(c).TR        = TR;%#ok<AGROW>
        foundScans(c).RawDir    = RawDir;%#ok<AGROW>
        foundScans(c).Files     = numel(f);%#ok<AGROW>
        foundScans(c).Slices    = hdr.dim(3);%#ok<AGROW>
        foundScans(c).Volumes   = numel(f);%#ok<AGROW>
    end
end


disp('Making directories');
mkdir('Inplane');
mkdir('Volume');
mkdir('Gray');


save prepareUUvars

status=mrInitRetFromNifti(foundScans,lower(subjectName),SessionName);

disp('Result of mrInitRetFromNifti');
disp(status);

loadSession;
mrSESSION.alignment = roughAlignment;
saveSession;
    
return



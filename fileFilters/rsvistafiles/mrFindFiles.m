function filepaths = mrFindFiles(startDir,pattern);
% Find mrVista 2.0 mr files/directories in a directory, 
% optionally filtering by a given pattern.
% 
% filepaths = mrFindFiles(startDir,[pattern]);
%
% startDir: directory to look for mr files. Defaults to current dir.
% pattern: if specified, will restrict to files matching a certain
% pattern (e.g. 'tSeries*').
%
% ras 09/2005.
if ~exist('startDir','var') | isempty(startDir), startDir = pwd; end
if ~exist('pattern','var') | isempty(pattern), pattern = ''; end

% search for *.mat files in the directory
ml = what(startDir);

% also check for NIFTI files
nifti = dir(fullfile(startDir,'*.nii*'));

% check for ANALYZE files
analyze = dir(fullfile(startDir,'*.img*'));

% check for P-mag files
analyze = dir(fullfile(startDir,'P*.7.mag'));

% check for directories containing DICOM or GE I files
tmp = dir(startDir); dicom = {}; ifile = {};
isdir = [tmp.isdir];
isdir(1:2) = 0; % remove . and ..
subdirs = {tmp(isdir==1).name};
for d = subdirs(:)'
%     tmp = dir(fullfile(startDir,d{1},'*.dcm'));
%     if ~isempty(tmp), dicom{end+1} = d{1}; end

    tmp = dir(fullfile(startDir,d{1},'I*.*'));
    if ~isempty(tmp), ifile{end+1} = d{1}; end
end    
    
% concat all the names found
fnames = [ml.mat(:)'  {nifti.name} {analyze.name} ifile];

% filter with pattern if selected
if exist('pattern','var') | ~isempty(pattern)
    for i = 1:length(fnames)
        % this might be tough...
    end
end


% convert into full paths
filepaths = {};
for i = 1:length(fnames)
    filepaths{i} = fullfile(startDir,fnames{i});
end



return

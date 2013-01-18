function status = SetupRawDir(dirs,anatSeriesNames,makeIFileFlag)
% Set up the directories containing Pfiles, Anat files
%
%  status = SetupRawDir([dirs,anatSeriesNames,makeIFileFlag]);
%
% This routine is useful if you've dumped the Pfiles and DICOM files (using
% sftp and get11, respectively) in a single directory. 
%
% dirs: specify the directory, or a cell specifying many directories.
% Default is current working directory.
%
% anatSeriesNames: a cell specifying the names of each
% anatomical series, e.g. {'3plane' 'Inplane' 'SS'}.
% Anatomical series are identified as directories with
% numeric names like '001' or '099'. The script
% will rename the series in numeric order according to the
% name. Leave empty to not rename that series. (E.g.,
% {'Inplane' '' '' 'SS'} ignores the 2 middle series.)
% enter the number 0 to get a default: 
% {'Localizer' 'Inplane' 'SS'}
% leave blank and it will prompt for each series #.
%
% makeIFileFlag: if 1, use dcm2gen to convert DICOM images
% to genesis I-files for each anatomical subdir.
%
% Analogous to the old script simptrans3.sh [now defunct],
% set up the Raw directory for a session/sessions, with
% the appropriate subdirectories. 
%
% ras 12/01/04.
status = 0;


if ~exist('dirs','var') || isempty(dirs)
    dirs = pwd;
end

if ~exist('makeIFileFlag','var') || isempty(makeIFileFlag)
    makeIFileFlag = 0;
end

if ~exist('anatSeriesNames','var') || isempty(anatSeriesNames)
    anatSeriesNames = []; % flag to check for each dir
elseif isequal(anatSeriesNames,0)
    anatSeriesNames = {'Localizer' 'Inplane' 'SS'};
end

if iscell(dirs)
    for i = 1:length(dirs)
        SetupRawDir(dirs{i},anatSeriesNames,makeIFileFlag);
    end
    return
end

callingDir = pwd;

cd(dirs);

% make the Raw dir and subdirs
if ~exist('Raw','dir') || ~exist('Raw/Anatomy','dir') ...
    || ~exist('Raw/Pfiles','dir')
    fprintf('Making Raw directory and subdirs...\n');
%     unix('mkdir Raw Raw/Anatomy Raw/Pfiles');
    mkdir('Raw');
    mkdir('Raw','Anatomy');
    mkdir('Raw','Pfiles');
end

% get list of anatomical series dirs
anatSeries = dir('0*');
if ~isempty(anatSeries)
    isdir = [anatSeries.isdir];
    names = {anatSeries.name};
    for i = 1:length(names)
        nums(i) = str2num(names{i});
    end
    isnum = ismember(nums,(1:99));
    nums = nums(isnum==1);
    names = names(isnum==1);
    anatSeries = anatSeries(isdir==1 & isnum==1);
end

% move anat series to Raw/Anatomy/
fprintf('Moving anatomical series dirs to Raw/Anatomy...\n');
for i = 1:length(anatSeries);
%     cmd = sprintf('mv %s Raw/Anatomy/',anatSeries(i).name);
%     unix(cmd);
    movefile(anatSeries(i).name, 'Raw/Anatomy');
end

% make sure we have a list of names for anat series
if isempty(anatSeriesNames)
    for i = 1:length(anatSeries);
        msg = sprintf('Enter name for series %i [enter to leave as is]: ',nums(i));
        anatSeriesNames{i} = input(msg,'s');
    end
elseif isequal(anatSeriesNames,0)
    anatSeriesNames = {'Localizer' 'Inplane' 'SS'};
    anatSeriesNames(end+1:length(anatSeries)) = '';
end

% rename anat series
for i = 1:length(anatSeries)
    if ~isempty(anatSeriesNames{i})
%         cmd = sprintf('mv Raw/Anatomy/%s Raw/Anatomy/%s',...
%                        anatSeries(i).name,anatSeriesNames{i});
%         unix(cmd);
        cd Raw/Anatomy
        movefile(anatSeries(i).name, anatSeriesNames{i});
        cd ../..
    end
end

% get list of Pfiles, move to Raw/Pfiles
pfiles = dir('P*.7*');
pnames = {pfiles.name};
fprintf('Moving Pfiles and Pmags to Raw/Pfiles...\n');
for i = 1:length(pnames)
%     cmd = sprintf('mv %s Raw/Pfiles/',pnames{i});
%     unix(cmd);
    movefile(pnames{i}, 'Raw/Pfiles/');
end

% move .img files (from rtfmri) to Raw/Pfiles/imgFiles
imgfiles = dir('P*.img');
if ~isempty(imgfiles)
    fprintf('Making Raw/Pfiles/imgFiles and moving .img files there...\n');
%     unix('mkdir Raw/Pfiles/imgFiles');
    mkdir('Raw/Pfiles', 'imgFiles');
    for i = 1:length(imgfiles)
%         cmd = sprintf('mv %s Raw/Pfiles/imgFiles/',imgfiles(i).name);
%         unix(cmd);
        movefile(imgfiles(i).name, 'Raw/Pfiles/imgFiles/');
    end
end

% get list of E-file headers, compare to pfile names
% (we want to store 'junk' e-files that lack corresponding
% p-files in Raw/Pfiles/extraEfiles
efiles = dir('E*.7');
if ~isempty(efiles)
    enames = {efiles.name};
    for i = 1:length(enames)
        enums(i) = str2num(enames{i}(12:16));
    end
    for i = 1:length(pnames)
        pnums(i) = str2num(pnames{i}(2:6));
    end
    pnums = unique(pnums);
    ind = ismember(enums,pnums);
    goodEfiles = find(ind==1);
    extraEfiles  = find(ind==0);

    % move 'good' efiles to Raw/Pfiles
    for i = goodEfiles
%         cmd = sprintf('mv %s Raw/Pfiles/',enames{i});
%         unix(cmd);
        movefile(enames{i}, 'Raw/Pfiles');
    end

    % move 'extra' efiles to Raw/Pfiles/extraEfiles
    for i = extraEfiles
          if ~exist('Raw/Pfiles/extraEfiles', 'dir')
              mkdir('Raw/Pfiles/', 'extraEfiles');
          end
%         cmd = sprintf('mv %s Raw/Pfiles/extraEfiles/',enames{i});
%         unix(cmd);
          movefile(enames{i}, 'Raw/Pfiles/extraEfiles');
    end    
end

% read the first I-file found to get exam #
fprintf('Trying to get exam #...');
try
    tmp = dir('Raw/Anatomy');
    pth = fullfile('Raw','Anatomy',tmp(3).name);
    tmp = dir(fullfile(pth,'I*'));
    [img hdr] = ReadMRImage(fullfile(pth,tmp(1).name));
%     cmd = sprintf('echo %i >Raw/examNum.txt',...
%                    hdr.exam(1).ex_no);
%     unix(cmd);
    fid = fopen('Raw/examNum.txt', 'w');
    fprintf(fid, '%s', num2str(hdr.exam(1).ex_no));
    fclose(fid);
    fprintf('succeeded.\n');
catch
    fprintf('Couldn''t get exam #\n');
end

% convert DICOM to Genesis I-file, if selected
if makeIFileFlag==1 && isunix
    dcm2genPath = fullfile(RAID,'dataTools','dcm2gen');
    cd('Raw/Anatomy');
    subdirs = dir;
    subdirs = subdirs([subdirs.isdir]==1);
    for i = 1:length(subdirs)
        cmd = sprintf('%s %s/*',dcm2genPath,subdirs(i).name);
        unix(cmd);
    end
end

cd(callingDir);

status = 1;

return

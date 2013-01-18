function [magFiles, eFiles, magSeqNums, eSeqNums] = mrInitMagFiles(pfDir)
% [magFiles, eFiles, magSeqNums, eSeqNums] = 
%       SortMagFiles(magFiles,eFiles,magSeqNums,eSeqNums,pfDir);
%
% sort Pmags and Efiles by date, instead of Pfile # --
% sometimes it wraps around 640000 to 0000. Returns full paths to each
% mag file and e-file header.
%
% (This also takes account of scans that start a day 
% early and go past midnight.)
%
% ras, 05/07 -- imported into mrVista2 repository from 'newestMagFile' and
% 'SortMagFiles'. * STILL IN PROGRESS. *
if notDefined('pfDir'), 
	% try Raw/Pfiles first, if that doesn't work use the current dir
	pfDir = fullfile(pwd, 'Raw', 'Pfiles'); 
	if ~exist(pfDir, 'dir')
		pfDir = pwd;
	end
end

callingDir = pwd;
cd(pfDir);

% get list of E-files first
eFiles = dir(fullfile(pfDir,'E*P*.7'));
eFiles = {eFiles.name};

% get efile numbers
eSeqNums = [];
for i = 1:length(eFiles)
    eSeqNums(i) = str2num(eFiles{i}(end-6:end-2));
end

% get list of mag files
magFiles = dir(fullfile(pfDir,'P*.7.mag'));
magFiles = {magFiles.name};

% get mag nums
magSeqNums = [];
for i = 1:length(magFiles)
    magSeqNums(i) = str2num(magFiles{i}(2:6));
end

% find seq nums with both mag files and e files
[goodNums Imag Ie] = intersect(magSeqNums, eSeqNums);
eFiles = eFiles(Ie);
magFiles = magFiles(Imag);

nFiles = length(magFiles);

for i = 1:nFiles
    hdr = ReadEfileHeader(eFiles{i});
    times{i} = hdr.time;
    dates{i} = hdr.date;
end

% parse dates/times into years, months, etc...
% perhaps overkill, but it allows for scans
% that go past midnight, etc.
for i = 1:nFiles
    yr = 2000 + str2num(dates{i}(7:8));
    mo = str2num(dates{i}(1:2));
    dt = str2num(dates{i}(4:5));
    hr = str2num(times{i}(1:2));
    mi = str2num(times{i}(4:5));
    [yr mo dt hr mi]; % debug
    datenums(i) = datenum(yr, mo, dt, hr, mi, 0);
end

[datenums iSort] = sort(datenums);
magFiles = magFiles(iSort);
magSeqNums = magSeqNums(iSort);
eFiles = eFiles(iSort);
eSeqNums = eSeqNums(iSort);

% convert file names to full paths
for i = 1:nFiles
	magFiles{i} = fullfile(pfDir, magFiles{i});
	eFiles{i} = fullfile(pfDir, eFiles{i});
end

cd(callingDir);

return
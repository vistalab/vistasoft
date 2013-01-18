function [fileList, eFileList, seqNums, eSeqNums] = ...
    SortMagFiles(fileList,eFileList,seqNums,eSeqNums,pfDir);
% [fileList, eFileList, seqNums, eSeqNums] = 
%       SortMagFiles(fileList,eFileList,seqNums,eSeqNums,pfDir);
%
% sort Pmags and Efiles by date, instead of Pfile # --
% sometimes it wraps around 640000 to 0000.
%
% (This also takes account of scans that start a day 
% early and go past midnight.)
%
% ras, 08/04
callingDir = pwd;
cd(pfDir);

nFiles = length(fileList);

for i = 1:nFiles
    hdr = ReadEfileHeader(eFileList{i});
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
    datenums(i) = datenum(yr,mo,dt,hr,mi,0);
end

[datenums iSort] = sort(datenums);
fileList = fileList(iSort);
seqNums = seqNums(iSort);
eFileList = eFileList(iSort);
eSeqNums = eSeqNums(iSort);

cd(callingDir);

return

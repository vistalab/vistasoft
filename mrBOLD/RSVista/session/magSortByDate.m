function [fileList, eFileList] = magSortByDate(fileList,eFileList,pfDir);
% sort Pmags and Efiles by date, instead of Pfile # --
% sometimes it wraps around 640000 to 0000.
% 
% [fileList, eFileList] = magSortByDate(fileList,eFileList,[pfDir]);
%
% fileList: list of P*.7.mag files.
% eFileList: list of corresponding E-file headers.
%
% This also takes account of scans that start a day 
% early and go past midnight.
%
% ras, 08/04 -- imported into mrVista 2, 09/05.
if notDefined('pfDir'), pfDir = pwd; end

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
eFileList = eFileList(iSort);

cd(callingDir);

return

function [date timeVec] = parsePmagDate(date,time);
% parse the Pmag header format for a date + time, into a string
% format, and a vector [yr mo dt hr min sec] format.
% Usage: [dateStr dateVec] = parsePmagDate(date,time);
% ras, 07/05.
% ras, 06/07: updated to read the apparently newer date format.
mo = str2num(date(1:2));
dt = str2num(date(4:5));
yr = 2000 + str2num(date(7:8));
hr = str2num(time(1:2));
min = str2num(time(4:5));
sec = 0;

timeVec = [yr mo dt hr min sec];
date = datestr(timeVec);

return
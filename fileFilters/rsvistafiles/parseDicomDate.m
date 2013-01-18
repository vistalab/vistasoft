function [date timeVec] = parseDicomDate(date, time);
% parse DICOM header format for a date + time, into a string
% format, and a vector [yr mo dt hr min sec] format.
% Usage: [dateStr dateVec] = parsePmagDate(date,time);
% ras, 10/07.
yr = str2num(date(1:4));
mo = str2num(date(5:6));
dt = str2num(date(7:8));

if notDefined('time')
	hr = 0; 
	min = 0;
	sec = 0;
else
	% TODO: figure out the time format
	hr = 0; 
	min = 0;
	sec = 0;
end

timeVec = [yr mo dt hr min sec];
date = datestr(timeVec);

return
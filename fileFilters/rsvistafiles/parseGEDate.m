function dateVec = parseGEDate(date);
% Parse a GE header-format date integer into a vector of format
% [year month date hour min sec].
% Usage: dateVec = parseGEDate(date);
% ras, 07/05.
date = num2str(date(:)');
if length(date)>=14
    % newer format containing year specification
    dateVec(1) = str2num(date(1:4));
    dateVec(2) = str2num(date(5:6));
    dateVec(3) = str2num(date(7:8));
    dateVec(4) = str2num(date(9:10));
    dateVec(5) = str2num(date(11:12));
    dateVec(6) = str2num(date(13:14));
elseif length(date)>=10
    % older format, w/o year specified
    dateVec(1) = 1900;
    dateVec(2) = str2num(date(1:2));
    dateVec(3) = str2num(date(3:4));
    dateVec(4) = str2num(date(5:6));
    dateVec(5) = str2num(date(7:8));
    dateVec(6) = str2num(date(9:10));
else
   dateVec = [1900 0 0 0 0 0];
end

return
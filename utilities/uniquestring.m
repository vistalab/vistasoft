function [uniqueStrings] = uniquestring(inputCell)
% Usage: [uniqueStrings] = uniquestring(inputCell)
%
% inputCell   cell        Cell array of strings which contains more duplicate
%                       strings.
% Example:
% inputCell = [{'c'};{'a'};{'a'};{'b'};{'a'};{'b'};{'c'};{'d'}]
% [uniqueStrings] = uniquestring(inputCell);
% Result: uniqueStrings = [{'c';'a';'b';'d'}]
%
% Based on rm_duplicate
%**************************************************************************
%   $Origin:   Matlab 6 release: R13                                      *
%**************************************************************************
%   $Author: davie $                                              *
%   $Date: 2008/06/25 02:05:17 $                                      *
%   $Version: 1.0   $                                                     *
%
% Useful if you're using reading in something with a lot of text (e.g., xls
% spreadsheet) 
%
% Hacked by DY 06/2008

if nargin < 1 || nargin > 1
    error('uniquestring: Wrong number of arguments.');
end
if ~iscell(inputCell)
    error('uniquestring: Wrong type of arguments.');
end
auxName=inputCell;
LON = length(inputCell);
uniqueStrings=[];
for i=1:LON
    curentName=inputCell(i);
    sameStr=strcmp(auxName,curentName);
    LSS = length(sameStr);
    countOne=0;
    indexOne=[];
    for j=1:LSS
        if isequal(sameStr(j),1)
            indexOne=[indexOne;j];
            countOne=countOne+1;
        end
    end
    if countOne>=1
        uniqueStrings=[uniqueStrings;auxName(indexOne(1))];
        for k=length(indexOne):-1:1
            auxName(indexOne(k))=[];
        end
    end
end
uniqueStrings;

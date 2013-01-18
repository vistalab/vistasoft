function [data, colNames] = readTab(fileName, delim, headerRowFlag)
%
% out = readTab(fileName, [delim], [headerRowFlag])
%
% Extracts data columnwise from a delim-separated file.
% Default delimiter is '\t' (tab-delimited). delim can also be a list of
% chars, any of which will be used as a delimiter (e.g. '\t ,')
% If headerRowFlag is true (the default), then the first row is read as
% pure text and returned separately in colNames. 
%
% For many tasks, this is better than matlab's 'dlmread' 
% because the data do not have to be numeric. They will be
% stuffed into a cell array. Anything that looks like a
% numeric value will be converted to a numeric.  
%
% Input:  fileName
%         delim: delimiter character (optional- defaults to '\t'- a tab)
%         headerRowFlag
%
% Output:   
%   data:       a numRows-1 X numCols cell array with the data.
%   colNames:   a 1 X numColumns cell array with the data from
%               the first line. They are assumed to be strings- 
%               no numeric conversion.
%               
% HISTORY:
%
%   2001.09.27 Bob Dougherty (bobd@stanford.edu): wrote it
% 

if(~exist('delim','var') | isempty(delim))
    delim = '\t';
end
if(~exist('headerRowFlag','var') | isempty(headerRowFlag))
    headerRowFlag = 1;
end

% Interpret the delimiter 
delim = sprintf(delim);

% Read the column names (the first line in the file)
fh = fopen(fileName, 'r');
colNames = {};
if(headerRowFlag)
    lineBuffer = fgetl(fh);
    while(~isempty(lineBuffer))
        [token, lineBuffer] = strtok(lineBuffer, delim);
        % Strip the leading and trailing " that some spreadsheets like to
        % insert around strings.
        if(token(1)=='"' & token(end)=='"'), token = token(2:end-1); end
        colNames{end+1} = token;
    end
end
% read the rest of the file
data = {};
while(~feof(fh))
    %d = cell(1, n);
    itemNum = 1;
    lineBuffer = fgetl(fh);
    while(~isempty(lineBuffer))
        [token, lineBuffer] = strtok(lineBuffer, delim);
        if(~isempty(token))
          if(isnan(str2double(token)))
            % Strip the leading and trailing "
            if(token(1)=='"' & token(end)=='"'), token = token(2:end-1); end
            d{itemNum} = token;
          else
            d{itemNum} = str2double(token);
          end
          itemNum = itemNum+1;
        end
    end
    data(end+1,:) = d;
end

fclose(fh);
return;

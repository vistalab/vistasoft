function [behaveData, colNames, subCodeList, subYearList] = dtiGetBehavioralData(subCodeList, behaveDataFile)
%
% [behaveData, colNames, subCodeList, subYearList] = dtiGetBehavioralData([subCodeList=findSubjects], [behaveDataFile='/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv'])
%
% The longitudinal reading study has a large set of behavioral data for
% year one.  These are stored in a .csv (comma separated value) file,
% readable and writable by Excel.
%
% This routine retrieves the data for the subjects listed in the cell array
% subCodeList.
%
% The default behavioral data file is
% '//white.stanford.edu/biac2-wandell2/data/reading_longitude/read_behav_measures.csv';
% 
% The return is a matrix, behaveData, with a row for each subject and a
% column for each behavioral variable.  The names of the behavioral
% variables are in colNames (another cell array).
%
% HISTORY:
% 2005.02.11 RFD: wrote it.

if(~exist('subCodeList','var') || isempty(subCodeList))
    subCodeList = findSubjects;
end
if(~exist('behaveDataFile','var') || isempty(behaveDataFile))
    behaveDataFile = '/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv';
    if(ispc)
        behaveDataFile = ['//white.stanford.edu/' behaveDataFile];
    end
end

n = length(subCodeList);
% convert a list of subject files to the respective subject codes (the
% first 2-3 letters of the filename).
yr = zeros(1,n);
for(ii=1:n)
    s = subCodeList{ii};
    if(~isempty([strfind(s,filesep) strfind(s,'\') strfind(s,'/') strfind(s,'0')]))
        [p,s,e] = fileparts(s);
        us = findstr('0',s);
        subCodeList{ii} = s(1:us(1)-1);
        yr(ii) = str2double(s(us(1):us(1)+1));
    end
end

% The first year's data collection was in 2004, so yr-3 will turn '04' into
% 1, '05' into 2, etc.
yr(yr>0) = yr(yr>0)-3;

[behDataRaw,colNamesRaw] = readTab(behaveDataFile,',',1);
behDataRaw(:,1) = deblank(behDataRaw(:,1));
colNames = colNamesRaw(2:end);
colNames = strtrim(colNames);
behaveData = repmat(NaN, n, length(colNames));
for(ii=1:n)
    tmp = strmatch(subCodeList{ii}, behDataRaw(:,1),'exact');
    if(~isempty(tmp) && length(tmp)==1)
        for(jj=1:size(behaveData,2))
            curYr = regexp(colNames{jj},'.*\.(\d)$','tokens');
            % Assign a NaN if this is data for a different year
            if(~isempty(curYr)&&~isempty(curYr{1})&&str2double(curYr{1})~=yr(ii))
                behaveData(ii,jj) = NaN;
            else
                if(isnumeric(behDataRaw{tmp,jj+1}))
                    behaveData(ii,jj) = behDataRaw{tmp,jj+1};
                else
                    % Check for the 'missing data' symbol.
                    if(strcmp('.',behDataRaw{tmp,jj+1}))
                        behaveData(ii,jj) = NaN;
                    else
                        behaveData(ii,jj) = str2num(behDataRaw{tmp,jj+1});
                    end
                end
            end
        end
    else
        disp([num2str(length(tmp)) ' matches found for ' subCodeList{ii} '; no data assigned.']);
    end
end
if(any(yr>0))
    subYearList = yr;
else
    subYearList = [];
end
return;

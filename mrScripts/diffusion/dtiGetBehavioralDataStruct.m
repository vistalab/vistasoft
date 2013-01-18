function behaveData = dtiGetBehavioralDataStruct(subCodeList, behaveDataFile, dataDirList)
%
% behaveData = dtiGetBehavioralDataStruct([subCodeList=findSubjects], [behaveDataFile=''], [dataDirList=[]])
%
% The longitudinal reading study has a large set of behavioral data for
% year one.  These are stored in a .csv (comma separated value) file,
% readable and writable by Excel.
%
% This routine retrieves the data for the subjects listed in the cell array
% subCodeList and returns them in a convenient struct.
%
% See dtiGetBehavioralData for the default behavioral data file.
%
% HISTORY:
% 2009.02.06 RFD: wrote it.

if(~exist('subCodeList','var'))
    subCodeList = [];
end
if(~exist('behaveDataFile','var'))
    behaveDataFile = [];
end
if(~exist('dataDirList','var'))
    dataDirList = [];
end

[bd,colNames,sc,sy] = dtiGetBehavioralData(subCodeList,behaveDataFile);
varNames = colNames;
for(ii=1:numel(varNames))
    for(jj=1:4)
        ind = strfind(varNames{ii},'.');
        if(~isempty(ind)), varNames{ii} = varNames{ii}(1:ind-1); end
    end
end
varNames = unique(varNames);
clear behaveData;
subs = unique(sc);
for(ii=1:numel(sc))
    if(~isempty(dataDirList))
        behaveData(ii).dataDir = dataDirList{ii};
    end
    behaveData(ii).sc = sc{ii};
    behaveData(ii).year = sy(ii);
    for(jj=1:numel(varNames))
        col = strmatch(sprintf('%s.%d',varNames{jj},sy(ii)),colNames,'exact');
        if(isempty(col))
            % A few vars don't have a '.Y'
            col = strmatch(sprintf('%s',varNames{jj}),colNames,'exact');
        end
        if(~isempty(col) && numel(col)==1)
            fname = strrep(varNames{jj}, ' ', '_');
            fname = regexprep(fname, '\-|\(|\)|\=', '');
            behaveData(ii).(fname) = bd(ii,col);
        end
    end
end

return;
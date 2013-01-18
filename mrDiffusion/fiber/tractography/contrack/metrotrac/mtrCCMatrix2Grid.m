function [ccGrid] = mtrCCMatrix2Grid(ccMatrix,paramData,paramNames)

%% Assume each name is *kSmooth_#smooth_kLength_#len_kMidSD_#mid* and stored in
%% paramData.  Grid will be returned in the following format:
%%
%% row 1: #smooth, #len, #mid, corr
%% row 2: #smooth, #len, #mid, corr

filenames = {};
ccGrid = [];
for nn = 1:length(paramData)
    %% XXX Remove weird filename
    if( isstr(paramData(nn).name) )
        filenames{end+1} = paramData(nn).name;
        ccGrid(end+1,1) = ccMatrix(nn,1);
    end
end

ccGrid = [mtrFilenames2Paramlist(filenames,paramNames) ccGrid];
%ccGrid(:,4) = ccMatrix(:,1);


function paramlist = mtrFilenames2Paramlist(filenames,paramnames)
%% Assume each name is *kSmooth_#smooth_kLength_#len_kMidSD_#mid* and stored in
%% paramData.  Grid will be returned in the following format:
%%
%% row 1: #smooth, #len, #mid
%% row 2: #smooth, #len, #mid
%% 
%% ex: paramnames = {'kLength' 'kSmooth' 'kMidSD'};

paramlist = zeros(length(filenames),length(paramnames));
for nn = 1:length(filenames)
    for pp = 1:length(paramnames)
        paramlist(nn,pp) = mtrFilename2Param(filenames{nn},paramnames{pp});
    end
end

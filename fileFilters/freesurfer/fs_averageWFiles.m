function [meanWVals, stdWVals]=fs_averageWFiles(wFileList)
% [meanWVals, stdWVals]=fs_averageWFiles(wFileList)
% function meanWVals=fs_averageWFiles(wFileList)
% Loads in each w file specified in the (cell array) list
% and averages the values in those files (the 'w's )
% Checks along the way that all the files are the same size. 
% Returns the mean and std of the files
% Uses Darren Weber's EEG Toolbox
% ARW 041905
if (ieNotDefined('wFileList'))
    error ('You must enter a list of ''w'' files');
end

if (iscell(wFileList))
    nFiles=length(wFileList);
else
    nFiles=1;
end

if nFiles<2
    error('You must supply at least two files to average');
end

% Load in the first file
[w,v] = freesurfer_read_wfile(wFileList{1});
disp(wFileList{1});
disp(length(w))

nPoints=length(v)


% Pre-allocate an array
dataArray=zeros(nPoints,nFiles);
dataArray(:,1)=w;

for thisFile=2:nFiles
    disp(wFileList{thisFile});
    [w,v]=freesurfer_read_wfile(wFileList{thisFile});
    disp(length(w))
    nPoints=length(v)
    dataArray(:,thisFile)=w;
end

% Perform ops across the arrays.Note the sneaky gotcha with std. What are
% you thinking of mathworks?
meanWVals=mean(dataArray,2);
stdWVals=std(dataArray,0,2);

        

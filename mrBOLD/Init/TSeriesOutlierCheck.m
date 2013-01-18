function TSeriesOutlierCheck(dataType, scans, criterion);
%
% TSeriesOutlierCheck(<dataType='Original'>, <scans=all>, <zitFiles>);
% 
% = or =
%
% TSeriesOutlierCheck(<dataType='Original'>, <scans=all>, <threshold>);
%
% Checks for outlier frames in Inplane TSeries. If outlier frames are 
% found, offers the option to replace the outlier frames with the 
% average of the surrounding frames. 
% 
% The criterion for finding outliers can be specified in one of two ways:
% (1) 'zits' files, or (2) a standard deviation threshold from the mean.
%
% 'zits' files are text files created at the Lucas Center for reporting
% outlier voxels (of the form 'P*.7.zits'). If these are provided, will 
% read these files to find the outlier points. 
%
% If a standard deviation is provided, will look for frames whose mean is 
% greater than <threshold> standard deviations from the mean. If the third 
% argument is unspecified, will set a threshold of 2 std dev.
%
% This function needs to be run from a session's home directory.
%
% *** STILL BEING WRITTEN ***
%
% ras, 04/2006.
if notDefined('dataType'),  dataType = 'Original';       end
if notDefined('criterion'), criterion = 2;               end
if notDefined('scans'),    
    % take all
    scans = length(dir(fullfile(pwd, 'Inplane', dataType, 'TSeries', 'Scan*')));
end

if isstr(criterion) | iscell(criterion)
    % zits files specified: read through them
    
else
    % std dev threshold specified
    
end



return

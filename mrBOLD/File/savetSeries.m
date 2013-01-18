function savetSeries(tSeries,vw,scan,slice)
%
% function savetSeries(tSeries,vw,scan,slice)
%
% This function should be called everytime you save a tSeries.
% Makes the tSeries directory and scan subdirectory if they don't already exist.
%
% tSeries: matrix of N time samples by M pixels
% vw, scan, & slice: Used only to determine the full path for the tSeries file.
%
% djh, 2/17/2001
tseriesdir = tSeriesDir(vw, 1);
scandir = ['Scan',num2str(scan)];
if ~exist(fullfile(tseriesdir,scandir),'dir')
    mkdir(tseriesdir,scandir);
end
pathStr = fullfile(tseriesdir,scandir,['tSeries',num2str(slice)]);

% ras 03/07: trying again, now single-precision. 
tSeries = single(tSeries); %#ok<NASGU>

%disp(['Saving: ',pathStr]);
save(pathStr,'tSeries');

verbose = prefsVerboseCheck;
if verbose > 1		% starting to use graded levels of feedback
	fprintf('Saved time series %s. (%s)\n', pathStr, datestr(now));
end

return
function savetSeries(tSeries,vw,scan,slice,nii)
%
% function savetSeries(tSeries,vw,scan,slice,[nii])
%
% This function should be called everytime you save a tSeries.
% Makes the tSeries directory and scan subdirectory if they don't already exist.
% 
% Nifti functionality has been added. In the directory
% '[sessionDir]/[dataTYPE]/TSeries/tSeriesScan[Scan#]Slice[Slice#].nii.gz'
%
% tSeries: matrix of N time samples by M pixels
% vw, scan, & slice: Used only to determine the full path for the tSeries file.
%
% djh, 2/17/2001
tseriesdir = viewGet(vw,'tSeriesDir', 1);
if ~exist(fullfile(tseriesdir),'dir')
    mkdir(tseriesdir);
end

viewType = viewGet(vw,'View Type');

if strcmp(viewType,'Inplane')
    
    pathStr = fullfile(tseriesdir,['tSeriesScan',num2str(scan),'Slice',num2str(slice),'nii.gz']);
    
    %We now have a path to save the nifti to, let's make a nifti!
    if ~exist('var',nii)
        % We have no Nifti, we need to create our own
        % We can take the data from loadtSeries
        [~,nii] = loadtSeries(vw,scan,slice);
        
        % Now we need to change the data, the dimensions and the filepath
        % to reflect the new data that was passed in the tSeries
        
        
        
    end
    
    niftiWrite(nii,pathStr);
    
    verbose = prefsVerboseCheck;
    if verbose > 1		% starting to use graded levels of feedback
        fprintf('Saved time series %s. (%s)\n', pathStr, datestr(now));
    end
    
elseif strcmp(viewType,'Gray')
    
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
    
else
    error('When calling savetSeries, we are using an incorrect viewType');
    
end %if

return
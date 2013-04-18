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
mrGlobals;

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
        
        % Let's first reshape the data into the proper size
        
        size = viewGet(vw,'Functional Slice Dim');
        newtSeries = zeros(size,size(tSeries,3),size(tSeries,1));
        keepFrames = ones(size, 2);
        for slice = 1:size(tSeries,3)
            newtSeries(:,:,slice,:) = reshape(tSeries,size);
        end %for
        
        
        %Now let's update the nifti
        dim = size(newtSeries);
        nii = niftiSet(nii,'Dim',dim);
        nii = niftiSet(nii,'Data',newtSeries);
    end %if
    
	nii = niftiSet(nii,'F Name',pathStr);

    niftiWrite(nii,pathStr);

    %Let's also make sure that the dataTYPES are updated properly
    %First, check if this datatype exists
    %Then, check if this scan exists
    %Then, change the path for this scan to the new path
    
    %This is the same code as in duplicateDataType
    curDt = viewGet(vw,'Cur Dt');
    if ~existDataType(curDt)
        newName = [];
        dlg = 'Please give a new name for the new datatype';
        while isempty(newName);
            newName = inputdlg(dlg,'Name new datatype');
            if iscell(newName) && ~isempty(newName);
                newName = deblank(newName{1}); % remove possible blanks
                if existDataType(newName);
                    dlg = 'What you just input is already in dataTYPES. Try again !!!';
                    newName = []; disp(['Warning: ',dlg]);
                end
            else
                dlg = 'You MUST give a NEW name for the new datatype !!!';
                disp(['Warning: ',dlg]);
            end %if
        end %while
        addDataType(newName);
    end %if

    numScans = dtGet(dataTYPES(curDt),'N Scans');
    
    if numScans < scan
        for newScan = (numScans+1):(scan-numScans)
             %Copy over the scan information from the previous scan
             vw = initScan(vw,curDt,newScan);
        end %for
    end %if
    
    dataTYPES = dtSet(dataTYPES(curDt),'Inplane Path',pathStr,scan);
    dataTYPES = dtSet(dataTYPES(curDt),'Size',dim,scan);

    %Add in keepFrames information
    dataTYPES = dtSet(dataTYPES(curDt),'Keep Frames',keepFrames,scan);
    
    verbose = prefsVerboseCheck;
    if verbose > 1		% starting to use graded levels of feedback
        fprintf('Saved time series %s. (%s)\n', pathStr, datestr(now));
    end
    
else strcmp(viewType,'Gray')
    
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
       
end %if

return
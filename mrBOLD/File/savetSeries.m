function savetSeries(tSeries,vw,scan,slice,nii)
% Save time series to a nifti file
%
%   savetSeries(tSeries,vw,scan,[slice],[nii])
%
% This function should be called everytime you save a tSeries. Makes the
% tSeries directory and scan subdirectory if they don't already exist.
% 
% Nifti functionality has been added. In the directory
% '[sessionDir]/[dataTYPE]/TSeries/tSeriesScan[Scan#]Slice[Slice#].nii.gz'
%
% tSeries: matrix of N time samples by M pixels
% vw, scan, & slice: Used only to determine the full path for the tSeries file.
%
% djh, 2/17/2001
mrGlobals;

if notDefined('scan'),  scan  = viewGet(vw, 'curScan'); end
if notDefined('slice'), slice = viewGet(vw, 'curSlice'); end

viewType = viewGet(vw,'View Type');

if strcmp(viewType,'Inplane')
    
    tseriesdir = viewGet(vw,'tSeriesDir', 1);
    
    if ~exist(fullfile(tseriesdir),'dir')
        mkdir(tseriesdir);
    end

    pathStr = fullfile(tseriesdir,['tSeriesScan',num2str(scan),'.nii.gz']);
    
    %Let's also make sure that the dataTYPES are updated properly
    %First, check if this datatype exists
    %Then, check if this scan exists
    %Then, change the path for this scan to the new path
    
    %This is the same code as in duplicateDataType
    curDt = viewGet(vw,'Cur Dt');
    if curDt > numel(dataTYPES)
        newName = [];
        dlg = 'Please give a new name for the new datatype';
        while isempty(newName)
            newName = inputdlg(dlg,'Name new datatype');
            if iscell(newName) && ~isempty(newName)
                newName = deblank(newName{1}); % remove possible blanks
                if existDataType(newName)
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
    
    %We now have a path to save the nifti to, let's make a nifti!
    if ~exist('nii','var')
        % We have no Nifti, we need to create our own
        % We can take the data from loadtSeries
        [~,nii] = loadtSeries(vw,scan,slice);
        
        % Now we need to change the data, the dimensions and the filepath
        % to reflect the new data that was passed in the tSeries
        
        % Let's first reshape the data into the proper size
        
        sizeDim = viewGet(vw,'Functional Slice Dim');
        totalSize = [size(tSeries,1),sizeDim,size(tSeries,3)];
        keepFrames = zeros(numScans, 2);
        keepFrames(1:numScans,2) = -1;
        newtSeries = reshape(tSeries,totalSize);
        newtSeries = permute(newtSeries, [2 3 4 1]); %Put the time at the end
        %Now let's update the nifti
        dim = size(newtSeries);
        nii = niftiSet(nii,'Dim',dim);
        nii = niftiSet(nii,'Data',newtSeries);
        
    else %if
        dim = niftiGet(nii, 'dim');
    end
    
    
    %Now we need to add another dimension to the pixdim if it only has 3
    if numel(niftiGet(nii,'Pix Dim')) < numel(dim)
        %Add another pixdim
        nii = niftiSet(nii, 'Pix Dim',[niftiGet(nii,'Pix Dim') 1]);
    end

    
	nii = niftiSet(nii,'File Path',pathStr);


    
    niftiWrite(nii,pathStr);
    
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Inplane Path',pathStr,scan);
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Size',dim(1:2),scan);

    %Add in keepFrames information
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Keep Frames',keepFrames,scan);
    
    verbose = prefsVerboseCheck;
    if verbose > 1		% starting to use graded levels of feedback
        fprintf('Saved time series %s. (%s)\n', pathStr, datestr(now));
    end %if
    
    %Save the new dataTypes variable back to the overall session.
    saveSession;
 
else

    tseriesdir = tSeriesDir(vw, 1);
    scandir = ['Scan',num2str(scan)];
    if ~exist(fullfile(tseriesdir,scandir),'dir')
        mkdir(tseriesdir,scandir);
    end
    pathStr = fullfile(tseriesdir,scandir,['tSeries',num2str(slice)]);    

    if strcmp(viewType,'Flat')
        % In the flat view, we will be getting multiple slices, so go
        % through each slice and save down the tSeries
        % We may sometimes encounter the case where we have 3 or 4
        % dimensions, and we want to save them all. We need to account for
        % that:
        
        numEle = numel(size(tSeries));
        numSlices = size(tSeries,numEle);
        
        if numEle == 4
            
            for i = 1:numSlices
                pathStr = fullfile(tseriesdir,scandir,['tSeries',num2str(i)]);
                tSeriesTmp = tSeries(:,:,i,:); %The slices will be on the 3rd dimension
                
                tSeriesTmp = single(tSeriesTmp);
                
                %disp(['Saving: ',pathStr]);
                save(pathStr,'tSeriesTmp');
            end %for
            
        elseif numEle ==3
            
            for i = 1:numSlices
                pathStr = fullfile(tseriesdir,scandir,['tSeries',num2str(i)]);
                tSeriesTmp = tSeries(:,:,i);
                
                tSeriesTmp = single(tSeriesTmp);
                
                %disp(['Saving: ',pathStr]);
                save(pathStr,'tSeriesTmp');
            end %for
            
        else
            %We don't know what to do
            error('Incorrect number of elements in tSeries.');
        end %if
        
    else
        %This is what happens in the Gray view, since only 1 slice
        tSeries = single(tSeries); %#ok<NASGU>
        
        %disp(['Saving: ',pathStr]);
        save(pathStr,'tSeries');
    end %if
    
    verbose = prefsVerboseCheck;
    if verbose > 1		% starting to use graded levels of feedback
        fprintf('Saved time series %s. (%s)\n', pathStr, datestr(now));
    end %if
       
end %if

return
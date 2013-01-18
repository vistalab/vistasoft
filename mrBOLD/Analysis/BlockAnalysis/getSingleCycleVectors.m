function singleCycleVectors=getSingleCycleVectors(view,scan,coords)
% singleCycleVectors=getSingleCycleVectors(view,scan,coords)
%
% PURPOSE: Extract single cycles from a single scan
%         For each cycle, compute the FFT and returns
%         the (complex) first harmonic (the second entry in the FFT)
%       If no coords list is given , we compute for the entire set of
%       voxels.
% AUTHORS ARW, TCF wade@ski.org
% DATE $date$
% NOTES:

mrGlobals;
  
if (ieNotDefined('view'))
    error('You must supply a view- i.e. INPLANE{1} or something');
end

% These should be updated to viewGet calls.
if ieNotDefined('scan'), scan = getCurScan(view); end

nCycles = numCycles(view,scan);
frameRate = getFrameRate(view,scan);
nFrames = numFrames(view,scan);
framesPerCycle=nFrames/nCycles;

% If we were passed a set of coords, we only work on that set.
% Otherwise, we work on the entire data set. We have different
% code paths for these two conditions.

if (ieNotDefined('coords'))
    % No coords passed - work on the entire data set:
    
    % Find out how many slices in this view. Then loop over all slices
    % calling 'loadTSeries' : this returns the tSeries data for
    % each voxel in the slice. 
    % Then we do chopping up and vector extraction
    % to generate a 4D (y by x by nSlices by nCycles) matrix that we return
    
    % pre-allocate the matrix 
    

    currentDataType=view.curDataType;
    dt=dataTYPES(currentDataType);
    blockSize=dt.scanParams(scan).cropSize;
    nSlices=length(dt.scanParams(scan).slices);
    singleCycleVectors=zeros(blockSize(1)*blockSize(2),nSlices,nCycles);
    

    for iSlice = 1:nSlices
        
        % For each slice...        
        % tSeries = loadtSeries(view,scan,iSlice);    
        view=percentTSeries(view,scan,iSlice,[]);
        tSeries=view.tSeries;
        
        bad = isnan(tSeries);
        tSeries(bad) = 0;
    
        % Now resize the tSeries
        % Tseries comes in as a  2D thing: nFrames*(y*x)
        sizeTSeries=size(tSeries);
        % Resize it to a 3D thing
        tSeries=reshape(tSeries,framesPerCycle,nCycles,sizeTSeries(2));
        
        % Now do the FFT down the first dimension
        tSeries=fft(tSeries);
        % Now pull out the 2nd row
        tSeries=squeeze(tSeries(2,:,:));
        % Shift the dimensions so that nCycles is at the end
        tSeries=shiftdim(tSeries,1);

        singleCycleVectors(:,iSlice,:)=tSeries;
         
    end % next slice
else
        [tSeries, subCoords] = getTseriesOneROI(view,coords,scan,1);

        % Now resize the tSeries
          
        tSeries=tSeries{1};
        sizeTSeries=size(tSeries)
        % Resize it to a 3D thing
        tSeries=reshape(tSeries,framesPerCycle,nCycles,sizeTSeries(2));
        
        % Now do the FFT down the first dimension
        tSeries=fft(tSeries);
        % Now pull out the 2nd row
        tSeries=squeeze(tSeries(2,:,:));
        % Shift the dimensions so that nCycles is at the end
        %tSeries=shiftdim(tSeries,1);

        singleCycleVectors=tSeries;
end

return;

 
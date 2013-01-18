function outMap=computeCorrelationMap(view,scan,timeSeries,normalizeFlag)
% outMap=computeCorrelationMap(view,scan,timeSeries,normalizeFlag)
% Computes a parameter map that is the cross correlation of each voxel (in
% the inplance view - for the current dt and specified scan with the reference
% timeSeries.
%
% The procedure happens slice-by-slice and (normalized) cross correlation
% is computed in the Fourier domain to speed things up.
% The thing returned is the COMPLEX map of the zero-th lag.
% You can do abs(map)
% ARW 103106: Wrote it.
% 

% Check the inputs
if (ieNotDefined('view'))
    error('You must supply an INPLANE view');
end
if (ieNotDefined('scan'))
    error('You must supply a scan index');
end
if (ieNotDefined('timeSeries')) 
    error('You must supply a reference time series');
end
if (ieNotDefined('normalizeFlag'))
    warning('Doing a normalized cross correlation by default');
    normalizeFlag=1;
end

% Pre-allocate the output
dataSize=viewget(view,'datasize');
outMap=zeros(dataSize(1),dataSize(2),dataSize(3));

nSlices=dataSize(3);
nTRs=viewget(view,'nframes');

% Check the reference tSeries
timeSeries=timeSeries(:);
if length(timeSeries)~=nTRs
    error ('The reference time series is a different length to the data');
end
disp(scan);

% We're going to do the xcorr in fourier space     
% That means that we need to pre-compute the fft of the ref tSeries
% and then make a matrix..

% Always remove the mean 
timeSeries=timeSeries-mean(timeSeries(:));

    
fRefTSeries=fft(timeSeries(:));
fRefTSeries=conj(fRefTSeries(:));  %Compute the complex conjugate here so that we get xcorr in Fourier space

if (normalizeFlag) % Ensure max corr is 1
    fRefTSeries=fRefTSeries./sqrt(sum(abs(fRefTSeries(:)).^2));
end

nVoxPerSlice=dataSize(1)*dataSize(2); % Compute the number of voxels in the slice
FFT_tSeriesMatrix=repmat(fRefTSeries,1,nVoxPerSlice); % Make an array of identical fourier transforms of the input to speed multiplication. Freq goes down

for thisSlice=1:nSlices % loop over slices

    % Get the tSeries data for this slice
    thisTSeries=loadtSeries(view, scan,thisSlice);
    
    % Remove the mean
    thisTSeries=thisTSeries-repmat(mean(thisTSeries),nTRs,1);
    
    % We can do the normXCorr right away
    FFT_thisTSeries=fft(thisTSeries);
    
    if (normalizeFlag) % Normalize the power. Check this - there might be an additional factor of nframes in the final result
        FFT_thisTSeries=FFT_thisTSeries./repmat(sqrt(sum(abs(FFT_thisTSeries).^2)),nTRs,1);   
    end
    
    xcorrTSeries=FFT_thisTSeries.*(FFT_tSeriesMatrix); % Complex conjugate of the reference already computed 
    
    i_xcorr=ifft(xcorrTSeries); % Do the ifft to get the cross correlation
    compData=i_xcorr(1,:); % Take the zero-th lag. This assumes that there are no lagged copies of the signal.
    
    % Re-shape so that you can place it directly into a parameter map.
    outMap(:,:,thisSlice)=reshape(compData,dataSize(1),dataSize(2));
    
end

    
    
    
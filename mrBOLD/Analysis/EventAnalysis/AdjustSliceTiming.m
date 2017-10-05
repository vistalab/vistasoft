function vw = AdjustSliceTiming(vw, scans, typeName, slices)
% Correct the time series for slice timing and number-of-interleaves
%
%   vw = AdjustSliceTiming(vw, scans, typeName, slices)
%
% vw:       The INPLANE view. 
% scans:    a vector of scans that should have their timing adjusted. 
%           scans = 0, adjust all of the scans
% typeName: The function creates a new dataTYPE containing the new data.  
%           The default typeName is 'Timed'
% slices:   Array of integers - the slices to correct. 
%           Default is 1:viewGet('numSlices')
%
% Example:
%   junk = AdjustSliceTiming(INPLANE{1}, 1, [], []);
%
% AS  - 04/13: Since this is purely for inplane views, change functionality
% to new savetSeries functionality
% MBS - 02/08: generalized to arbitrary slice ordering
% Rory, 07/07: vw made an input parameter. Returns  vw as well.
% Rory, 01/06: adjusted so that the input and output scan numbers don't
% have to match; will append new time-corrected scans to an existing data
% type.
% Ress, 02/05 - wrote it
%  

if notDefined('vw'),        vw = getCurView;                    end
if notDefined('scans'),     scans = er_selectScans(vw);         end
if notDefined('typeName'),  typeName = 'Timed';                 end
if notDefined('slices'),	slices = 1:viewGet(vw,'numSlices');	end

nSlices = length(slices);

% select all scans in data type
if isequal(scans, 0), scans = 1:viewGet(vw, 'numScans'); end

mrGlobals;
srcDt = viewGet(vw, 'curDataType');

% Set up new datatype for timing correction:
hiddenView = initHiddenInplane;
if ~existDataType(typeName), addDataType(typeName); end
hiddenView = selectDataType(hiddenView, existDataType(typeName));


deltaFrame = sessionGet(mrSESSION,'interFrameTiming',scans(1));
refSlice   = sessionGet(mrSESSION,'refSlice',scans(1));
sliceOrder = sessionGet(mrSESSION,'sliceOrder',scans(1));

if isempty(sliceOrder)
    % GUI to  get the slice ordering from the user
    % sliceOrder = [ 2 4 6 8 1 3 5 7 9 10 11 12 14 16 18 20 13 15 17 19];
    str = sprintf('Slice order (%d).  Use brackets [ 3 1 2 5 4 6 8 7 9 10 12 14 11 13 15 ] ',nSlices);
    sliceOrder = ieReadNumber(str);
    if isempty(sliceOrder), disp('User canceled'); return; 
    elseif length(sliceOrder) ~= nSlices
            error('Incorrect slice order.  Expected %d slices. Canceling',nSlices);
    end
    mrSESSION = sessionSet(mrSESSION,'sliceOrder',sliceOrder,1);
    saveSession;
end

% Create the vector of frame adjustments for each of the slices.
for ii=1:nSlices
    thisSlice = find(sliceOrder  == ii);
    frameAdjustment(ii) = deltaFrame*(thisSlice - refSlice);
end

for ii = 1:length(scans)
    scan = scans(ii);
    
    % initialize a slot for the new scan
    hiddenView = initScan(hiddenView, typeName, [], {srcDt scan});
    outScan = viewGet(hiddenView, 'numScans'); % # of scan in the new data type
            
    % main loop: loop across slices, doing spline interpolation
    wH = mrvWaitbar(0, ['Adjusting scan ' int2str(scan)]);
    iS = 0;
    
    tsFull = [];
    numDim = 0;
    
    [~, nii] = loadtSeries(vw, scan);
    tSeries = double(niftiGet(nii, 'data'));
    tSeries = permute(tSeries, [4, 1, 2, 3]);
    tSeries = reshape(tSeries, size(tSeries,1), [], size(tSeries,4));
    for slice=slices
        iS = iS + 1;
        %ts = loadtSeries(vw, scan, slice);
        ts = tSeries(:,:,slice);
        if slice ~= refSlice
            % frameAdjustment = deltaFrame*(refSlice - slice);
            ts = mrSliceTiming(ts,frameAdjustment(slice),'spline');           
        end
        numDim = numel(size(ts));
        tsFull = cat(numel(size(ts)) + 1, tsFull, ts);
        mrvWaitbar(iS/length(slices), wH);
    end
    if numDim == 3
        tsFull = reshape(tsFull,[1,2,4,3]); %flip time and slices
    end %if
    savetSeries(tsFull, hiddenView, outScan);
    close(wH);
end

saveSession;

return

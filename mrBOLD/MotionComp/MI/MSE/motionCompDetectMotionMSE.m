function [MSE, sequences, indexes, mx, sds, mn, sd] = motionCompDetectMotionMSE(view,ROI,scans,plotMSE,histogramClip)

%    [MSE, sequences, indexes, mx, sds, mn, sd] = motionCompDetectMotionMSE(view, [ROI], [scans], [plotMSE], [histogramClip])
% 
% gb 01/26/05
%
% Remove outliers within a scan and returns an array 'sequences' whose rows
% are the sequences between the outliers. The error computed is a Mean
% Squared Error.
%
% Input arguments :
%       - view : current inplane
%       - ROI : Region of interest where the error has to be computed
%           Default = ones
%       - scans : scans to analyse. 
%           Default = all scans
%       - plotMSE : indicates if the user wants a plot of the MSE error.
%       Should be the value '1' if so.
%           Default = 1
%       - histogramClip : sets the clipping value of the histogram
%           Default = 0.9
% 
% It returns :
%       - MSE = normalized squared sum of the difference of two
%       consecutive frames
%       - sequences = array representing the resulting sequences between the outliers
%       - indexes = indexes correponding to the outliers
%       - mx = maximum of MSE
%       - sds = array representing the standard deviations of each sequence
%       - mn = mean of MSE after having been clipped
%       - sd = standard deviation of MSE after having been clipped


% Initializes arguments and variables
if ieNotDefined('histogramClip')
    histogramClip = .9;
end

if ieNotDefined('scans')
    scans = selectScans(view);
end

if ieNotDefined('ROI')
    ROI = '';
end

if ieNotDefined('resize')
    resize = 0;
end

% Starts the main calculation
% For each scan, it computes the difference between the first frame
% of this scan and the last frame of the preceding scan before the error
% between consecutive frames.

MSE = [];
lastFrame = 0;
h = mrvWaitbar(0,'Computing Mean Squared Error...');

for scan = scans
           
    mrvWaitbar((scan - 1)/scans(end),h,['Computing Mean Squared Error for scan ' num2str(scan)]);
       
    % Loads the tSeries
    clear tSeriesAllSlices;
    tSeriesAllSlices = motionCompLoadImages(view,scan);
    nFrames  = size(tSeriesAllSlices,1);
    nVoxelsX = size(tSeriesAllSlices,2);
    nVoxelsY = size(tSeriesAllSlices,3);
    nSlices  = size(tSeriesAllSlices,4);
    
    % Computes the Mean Squared Error when changing scans
    firstFrame = tSeriesAllSlices(1,:,:,:);
    
    if isequal(lastFrame,0)
        MSE = [MSE;0];
    else
        MSE = [MSE;motionCompMSE(firstFrame,ROI,lastFrame)];
    end
    
    lastFrame = tSeriesAllSlices(nFrames,:,:,:);
    
    % Computes the difference between two consecutive frames
    tSeriesAllSlices = diff(tSeriesAllSlices,1,1);

	% Computes the Mean Square Error
	MSE = [MSE;motionCompMSE(tSeriesAllSlices,ROI)];
    
end
    
mrvWaitbar(1,h);

% Clips the histogram to calculate the mean and the standard deviation
% of MSE without taking into account the outliers
histClip = mrAnatHistogramClip(MSE,0,histogramClip,0);

% Computes the mean and the standard deviation of the clipped MSE
mn = mean(histClip);
sd =  std(histClip);

% Finds the outliers. Are considered outliers all the values above the mean
% + two standard deviations
indexes = (find(MSE > mn + 2*sd));
mx = max(MSE);

% Finds the resulting sequences between the outliers.
sequences = horzcat([1;indexes + 2],[indexes - 2;nFrames - 1]);
sequences = sequences(find(sequences(:,2) - sequences(:,1) > 5),:);

% Computes all the standard deviations
sds = zeros(size(sequences,1),1);
for i = 1:size(sequences,1)
    sds(i) = std(MSE(sequences(i,1):sequences(i,2)));
end

% Plots the curves
if ieNotDefined('plotMSE')
    plotMSE = 0;
end

if plotMSE > 0
    figure
    title(['MSE for ' view.sessionCode ]); 
    
    plot(MSE)
    hold on
    plot(1:length(MSE),mn*ones(1,length(MSE)),'-.')
    plot([1 length(MSE)],[mn + 2*sd, mn + 2*sd],'r')
    
    % Another measure can be used. Sometimes we can assume that the signal
    % is equally distributed around its mean. The explicit measure is :
    % mn + (mn - min(MSE))
    %
    % plot([1 length(MSE)],[2*mn - min(MSE),2*mn - min(MSE)],'black')
   
    for scanIndex = 1:(length(scans) - 1)
        plot([nFrames*scanIndex nFrames*scanIndex],[min(MSE) mx],'-.','Color','m');
    end
    
end

close(h)
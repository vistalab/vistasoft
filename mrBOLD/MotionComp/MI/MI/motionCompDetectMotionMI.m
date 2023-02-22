function [MI, sequences, indexes, mini, sds, mn, sd] = motionCompDetectMotionMI(view,ROI,scans,plotMI,histogramClip)

%    [MI, sequences, indexes, mini, sds, mn, sd] = motionCompDetectMotionMI(view, [ROI], [scans], [plotMI], [histogramClip])
% 
% gb 01/31/05
%
% Remove outliers within a scan and returns an array 'sequences' whose rows
% are the sequences between the outliers. The error computed is based on
% mutual information.
%
% Input arguments :
%       - view : current inplane
%       - ROI : Region of interest where the error has to be computed
%           Default = ones
%       - scan : scan to analyse. 
%           Default = current scan
%       - plotMI : indicates if the user wants a plot of the Mutual Information.
%       Should be the value '1' if so.
%           Default = 1
%       - histogramClip : sets the clipping value of the histogram
%           Default = 0.1
% 
% It returns :
%       - MI = Mutual Information between consecutive frames
%       - sequences = array representing the resulting sequences between the outliers
%       - indexes = indexes corresponding to the outliers
%       - mini = minimum of MI
%       - sds = array representing the standard deviations of each sequence
%       - mn = mean of MSE after having been clipped
%       - sd = standard deviation of MSE after having been clipped

global dataTYPES

% Initializes arguments and variables
if ieNotDefined('histogramClip')
    histogramClip = .1;
end

if ieNotDefined('scans')
    scans = selectScans(view);
end

if ieNotDefined('ROI')
    ROI = '';
end

curDataType = viewGet(view,'currentdatatype');
MI = [];
lastFrame = 0;
h = mrvWaitbar(0,'Computing Mutual Information...');

for scan = scans
       
    mrvWaitbar((scan - 1)/scans(end),h,['Computing Mutual Information for scan ' num2str(scan)]);
    
    clear tSeriesAllSlices;
	
	tSeriesAllSlices = motionCompLoadImages(view,scan);
	nFrames = size(tSeriesAllSlices,1);
    nSlices = size(tSeriesAllSlices,4);

    % Computes the Mutual Information when changing scans
    firstFrame = tSeriesAllSlices(1,:,:,:);
    if isequal(lastFrame,0)
        MI = [MI;0];
    else
        MI = [MI;motionCompMI(firstFrame,ROI,lastFrame)];
    end
    lastFrame = tSeriesAllSlices(nFrames,:,:,:);    
    
    % Computes the Mutual Information
	MI = [MI;motionCompMI(tSeriesAllSlices,ROI)];
    
end
mrvWaitbar(1,h)

MI(1) = MI(2);

% Clips the histogram to calculate the mean and the standard deviation
% of MI without taking into account the outliers
histClip = mrAnatHistogramClip(MI,histogramClip,1,0);

% Computes the mean and the standard deviation of the clipped MI
mn = mean(histClip);
sd =  std(histClip);

% Finds the outliers. Are considered outliers all the values above the mean
% - two standard deviations
indexes = (find(MI < mn - 2*sd));
mini = min(MI);

% Finds the resulting sequences between the outliers.
sequences = horzcat([1;indexes + 2],[indexes - 2;nFrames - 1]);
sequences = sequences(find(sequences(:,2) - sequences(:,1) > 5),:);

% Computes all the standard deviations
sds = zeros(size(sequences,1),1);
for i = 1:size(sequences,1)
    sds(i) = std(MI(sequences(i,1):sequences(i,2)));
end

% Plots the curves
if ieNotDefined('plotMI')
    plotMI = 0;
end

if plotMI > 0
    figure
    title(['MI for ' view.sessionCode]); 
    
    plot(MI)
    hold on
    plot(1:length(MI),mn*ones(1,length(MI)),'-.')
    plot([1 length(MI)],[mn - 2*sd, mn - 2*sd],'r')
    
    % Another measure can be used. Sometimes we can assume that the signal
    % is equally distributed around its mean. The explicit measure is :
    % mn - (max(MI) - mn)
    %
    % plot([1 nFrames],[2*mn - max(MI),2*mn - max(MI)],'black')
    
    for scanIndex = 1:(length(scans) - 1)
        plot([nFrames*scanIndex nFrames*scanIndex],[mini max(MI)],'-.','Color','m');
    end
end

close(h);
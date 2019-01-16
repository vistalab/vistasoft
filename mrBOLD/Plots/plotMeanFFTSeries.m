function data = plotMeanFFTSeries(vw,scanNum,plotFlag)
%
%    data = plotMeanFFTSeries(vw,[scan],[plotFlag=1])
% 
% Plots the mean of the amplitude spectrum of the FFT of the individual
% tSeries for the current scan, By averaging the amplitude spectra, instead
% of the time series, we ignore phase differences.
%
% The mean is taken across all pixels (in all slices) in the current ROI.
%
% plotFlag: flag indicating whether to plot the data (1) or not (0). If
% not, will just return the FFT data in the data struct without plotting.
% If it plots, will create a new graph window. [default: 1, plot]
%
% Programming Note
%   The amp is computed in slightly different ways in mrROIstats and these
%   plotting routines (usually by only a very small amount). These amp
%   values are computed in the corAnal and the ones in the plotMeanFFTSeries
%   are computed on the fly from the time series.  These can differ because
%   one is 
%   mean(amp) = mean(abs(fft(tseries))) (mrROIStats)
%               abs(fft(mean(tseries))) (plotMeanFFTSeries)
%
%   This is a potential problem.  When writing up results, make sure that
%   you specify the formula you used properly.
% plotFlag: flag indicating how to present the data:
%   0: no plots, just return the data structure
%   1: plot data in new graph window
%   2: plot data in current graph window
%   3 (or any other value): plot in current axes (allows for plotting in
%   subplots)
%
% 2003.06.11 BW, AB, wrote it based on plotFFTSeries
%
% 2005.02.17 AB added plotFlag: if plotFlag ==0, then no plots appear, but 
%   just returns data structure.
% 2005.04.04 AB added sections to transfer ROI to INPLANE from gray of flat
% so that plots could be made from the gray and flat views as well as from
% inplane.
if notDefined('scanNum'),  scanNum = getCurScan(vw); end
if notDefined('plotFlag'), plotFlag = 1; end

% Special case: if this is a FLAT view, auto-xform the ROI to INPLANE and
% plot the time series from the INPLANE. (This is because we don't have an
% agreed-upon way of xforming time series to FLAT). Otherwise, we proceed
% on the current view.
if isequal(vw.viewType, 'Flat')
	data = flat2ipPlotMeanTSeries(vw, scanNum, 'meanfft');
	return
end

nCycles   = viewGet(vw, 'num cycles' ,scanNum);
maxCycles = round(viewGet(vw, 'num frames',scanNum)/2); % number of frequencies to plot

% Load up the time series for this view.  Should we check whether it is
% already loaded?
ROIcoords   = viewGet(vw, 'ROI coordinates');
tSeriesROI  = voxelTSeries(vw, ROIcoords, scanNum);
framesToUse = viewGet(vw, 'frames to use', scanNum);
tSeriesROI  = tSeriesROI(framesToUse,:);
% Calulate the FFT for each pixel.  The tSeriesROI is nTimes x nVoxels
absFFT  = 2*abs(fft(tSeriesROI)) / size(tSeriesROI,1);
meanFFT = mean(absFFT,2);

% Set up data 
x= 1:maxCycles;
y =meanFFT(2:maxCycles+1);

data.x = x(1:maxCycles);
data.y  =  y(1:maxCycles);

%Calculate Z-score
% Compute the mean and std of the non-signal amplitudes.  Then compute the
% z-score of the signal amplitude w.r.t these other terms.  This appears as
% the Z-score in the plot.  This measures how many standard deviations the
% observed amplitude differs from the distribution of other amplitudes.
lst = true(size(x));
lst(nCycles) = 0;
data.zScore = (y(nCycles) - mean(y(lst))) / std(y(lst));

%% Plots
if plotFlag == 0
    % just return data structure
    return
elseif plotFlag == 1
    newGraphWin;
elseif plotFlag == 2
    selectGraphWin;
else
    % plot in current axes
end
    
% header
ROIname = vw.ROIs(vw.selectedROI).name;
headerStr = ['Mean Amp Spectrum, ROI ',ROIname,', scanNum ',num2str(scanNum)];
set(gcf,'Name',headerStr);

% plot it
plot(x,y,'bo','LineWidth',2);
hold on
if nCycles>1
    plot(x(1:nCycles-1),y(1:nCycles-1),'b','LineWidth',2)
    plot(x(nCycles-1:nCycles+1),y(nCycles-1:nCycles+1),'r','LineWidth',2)
    plot(x(nCycles+1:maxCycles),y(nCycles+1:maxCycles),'b','LineWidth',2)
else
    plot(x,y,'b','LineWidth',2)
end
hold off

% Ticks
fontSize = 14;
xtick=nCycles:nCycles:(maxCycles+1);
set(gca,'xtick',xtick);
set(gca,'FontSize',fontSize)
xlabel('Cycles per scan','FontSize',fontSize)
ylabel('Percent modulation','FontSize',fontSize) 
grid on

%Z-score
str = sprintf('Z-score %0.2f',data.zScore);
text(max(x)*0.82,max(y)*0.78,str);

%Put data in gca
set(gca,'UserData',data);

return;
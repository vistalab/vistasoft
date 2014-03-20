function data = plotFFTSeries(vw,scanNum,plotFlag)
% Plots the FFT of the tSeries for the current scan
%
%    plotFFTSeries(vw,[scanNum],[plotFlag])
%
% The fft is the average across all pixels (in all slices) in the current
% ROI. 
%
% If you change this function make parallel changes in:
%   plotMeanTSeries, plotMultipleTSeries, plotMultipleFFTSeries.
%   mrROIStats computes the amplitude in a slightly different way.  So be
%   alert that there can be differences.  See the comments below.
%
% 7/2001, djh, updated to 3.0
%
% Programming Note
%   The amp is computed in slightly different ways in mrROIstats and these
%   plotting routines (usually by only a very small amount).
%   These amp values are computed in mrInitRet and the ones in the
%   plotMeanFFTSeries are computed on the fly from the time series.  These
%   can differ because one is
%   mean(amp) = mean(abs(fft(tseries))) (mrROIStats)
%               abs(fft(mean(tseries))) (plotMeanFFTSeries)
%   This is a potential problem.  When writing up results, make sure that
%   you specify the formula you used properly.
% 2005.02.17 AB added plotFlag: if plotFlag ==0, then no plots appear, but
%   just returns data structure. Also now returns data.
% 2005.04.04 AB added sections to transfer ROI to INPLANE from gray of flat
% so that plots could be made from the gray and flat views as well as from
% inplane.
global FLAT
global VOLUME
global selectedVOLUME
global INPLANE
global selectedINPLANE
if notDefined('scanNum'),  scanNum = getCurScan(vw); end
if notDefined('plotFlag'), plotFlag = 1; end
nCycles = viewGet(vw,'num cycles', scanNum);
maxCycles = round(viewGet(vw, 'num frames',scanNum)/2); % number of frequencies to plot
%%Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
switch vw.viewType
    case {'Volume' 'Gray'}   %%%For ROIs in Gray view - xform to inplane
        selectedVOLUME = viewSelected('volume');
        % We used to have only time series data in the INPLANE
        % representation.  But as computers got bigger and we averaged
        % across sessions, we now have time series sometimes only in the
        % Gray, not in the INPLANE.  So here we have to figure out whether
        % we try to get the GRAY time series of the INPLANE time series.
        
        %initiate and / or select INPLANE window
        if isempty(INPLANE),
            INPLANE{1} = initHiddenInplane;
            INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
            selectedINPLANE = 1;
        else
            selectedINPLANE = viewSelected('inplane');
        end
        % Set the Inplane scan number and datatype to match the Volume view.
        curDataType = viewGet(VOLUME{selectedVOLUME},'datatypenumber');
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scanNum);
        %Transfer current VOLUME ROI to INPLANE
        INPLANE{selectedINPLANE} = vol2ipCurROI(vw,INPLANE{selectedINPLANE});
    case {'Flat'} %%%For ROIs in Flat view - xform to inplane
        selectedFLAT = viewSelected('flat');
        %initiate and / or select VOLUME and INPLANE windows
        if isempty(VOLUME),
            VOLUME{1} = initHiddenGray;
            VOLUME{1} = viewSet(VOLUME{1},'name','hidden');
            selectedVOLUME = 1;
        else
            selectedVOLUME = viewSelected('volume');
        end
        if isempty(INPLANE),
            INPLANE{1} = initHiddenInplane;
            INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
            selectedINPLANE = 1;
        else
            selectedINPLANE = viewSelected('inplane');
        end
        % Set the Inplane scan number and datatype to match the Flat view.
        %         curScan =     viewGet(FLAT{selectedFLAT},'currentscan');
        curDataType = viewGet(FLAT{selectedFLAT},'datatypenumber');
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scanNum);
        %Transfer current FLAT ROI to INPLANE
        INPLANE{selectedINPLANE} = flat2ipCurROI(vw,INPLANE{selectedINPLANE},VOLUME{selectedVOLUME});
    case {'Inplane'}   %%%For ROIs in INPLANE view - select inplane
        selectedINPLANE = viewSelected('inplane');
end
% Copied from plotMeanTSeries.m - this functionality is probably needed in
% a bunch of places, and we should write it as a mrGet call and not have it
% in separate locations.
try
  ROIcoords = getCurROIcoords(INPLANE{selectedINPLANE});
  tSeries   = meanTSeries(INPLANE{selectedINPLANE},scanNum,ROIcoords);
  % nFrames = length(tSeries);
catch ME
    warning(ME.identifier, ME.message)
  % if that does not work try in the volume
  try
    ROIcoords = getCurROIcoords(VOLUME{selectedVOLUME});
    tSeries   = meanTSeries(VOLUME{selectedVOLUME},scanNum,ROIcoords);
   %  nFrames = length(tSeries);
  catch ME
    rethrow(ME);
  end;
end;

% restrict the tseries to the appropriate frames
framesToUse = viewGet(vw, 'frames to use');
tSeries = tSeries(framesToUse);

% Calulate the FFT;  At one point RS made these single precision, I think.  (BW)
absFFT   = 2*abs(fft(tSeries)) / length(tSeries);
% angleFFT = angle(fft(tSeries));
% Set up data
x = (1:maxCycles);
y = absFFT(2:maxCycles+1);
data.x = x(1:maxCycles);
data.y = y(1:maxCycles);
data.nCycles = nCycles;
% Z-score
% Compute the mean and std of the non-signal amplitudes.  Then compute the
% z-score of the signal amplitude w.r.t these other terms.  This appears as
% the Z-score in the plot.  This measures how many standard deviations the
% observed amplitude differs from the distribution of other amplitudes.
lst = logical(true(size(x)));
lst(nCycles) = 0;
data.zScore = (y(nCycles) - mean(y(lst))) / std(y(lst));
% plot it
if plotFlag == 1
    newGraphWin
	% header
    ROIname = vw.ROIs(vw.selectedROI).name;
    headerStr = ['FFT of mean tseries, ROI ',ROIname,', scan ',num2str(scanNum)];
    set(gcf,'Name',headerStr);
	% Graph
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
    % Z-score
    str = sprintf('Z-score %0.2f',data.zScore);
	% Problem when y is single.  RS did this to the data at some point
    % I think we are heading back to doubles, though. - BW
    text(max(x)*0.82,double(max(y))*0.78,str);  
    % Save the data in gca('UserData')
    set(gca,'UserData',data);
end
return;

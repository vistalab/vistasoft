function view = plotMultipleFFTSeries(view,scan)
% function view = plotMultipleFFTSeries(view,[scan])
%
% plots FFT of tSeries for multiple ROIs simultaneously
%
% If you change this function make parallel changes in:
%   plotMeanTSeries, plotMultipleTSeries, plotFFTTseries
%
% 11/22/98 rmk
% 7/2001, djh, updated to 3.0
% 2005.04.04 AB added sections to transfer ROI to INPLANE from gray of flat
% so that plots could be made from the gray and flat views as well as from
% inplane.

global FLAT
global selectedFlat
global VOLUME
global selectedVOLUME
global INPLANE
global selectedINPLANE


%set up scan parameters
if ieNotDefined('scan'),  scan = getCurScan(view); end
nCycles = numCycles(view,scan);
frameRate = getFrameRate(view,scan);
nFrames = numFrames(view,scan);
maxCycles = round(nFrames/3); % number of frequencies to plot

% Select ROIs
nROIs=size(view.ROIs,2);
roiList=cell(1,nROIs);
for r=1:nROIs
    roiList{r}=view.ROIs(r).name;
end
selectedROIs = find(buttondlg('ROIs to Plot',roiList));
nROIs=length(selectedROIs);
if (nROIs==0)
    error('No ROIs selected');
end

%%Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
switch view.viewType
case {'Volume' 'Gray'}   %%%For ROIs in Gray view - xform to inplane
    
    selectedVOLUME = viewSelected('volume'); 
    
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
    INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scan);
    
    %Transfer current VOLUME ROI to INPLANE
    for i = 1: nROIs
        view = selectROI(view,selectedROIs(i));
        INPLANE{selectedINPLANE} = vol2ipCurROI(view,INPLANE{selectedINPLANE});
    end

    
case {'Flat'} %%%For ROIs in Flat view - xform to inplane
    
    selectedFLAT = viewSelected('flat'); 
    
    %initiate and / or select VOLUME and INPLANE windows
    if isempty(VOLUME), 
        VOLUME{1} = initHiddenGray;
        VOLUME{1} = viewSet(VOLUME{1},'name','hidden');
        selectedVOlUME = 1;
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
    INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scan);
    
    %Transfer current FLAT ROI to INPLANE
    for i = 1: nROIs
        view = selectROI(view,selectedROIs(i));
        INPLANE{selectedINPLANE} = flat2ipCurROI(view,INPLANE{selectedINPLANE},VOLUME{selectedVOLUME});
    end
    
case {'Inplane'}   %%%For ROIs in INPLANE view - select inplane
    selectedINPLANE = viewSelected('inplane'); 
end

% Compute meanTSeries for each ROI
ROIcoords = cell(1,nROIs);
for r=1:nROIs
    ROIcoords{r}=INPLANE{selectedINPLANE}.ROIs(selectedROIs(r)).coords;
end

tSeries = meanTSeries(INPLANE{selectedINPLANE},scan,ROIcoords);
if ~iscell(tSeries)
    tmp{1}=tSeries;
    tSeries=tmp;
end

% Compute FFT of each mean tseries
for r=1:nROIs
    absFFT{r}=2*abs(fft(tSeries{r})) / length(tSeries{r});
end

% Plot it

% selectGraphWin
newGraphWin

headerStr = ['FFT scan ',num2str(scan)];
set(gcf,'Name',headerStr);

% pre-compute the y axis limits
maxY=0;
for t=1:nROIs
    if max((absFFT{t}(2:maxCycles+1)))>maxY
        maxY=max(absFFT{t}(2:maxCycles+1));
    end
end
maxY=ceil(maxY+(maxY/5))


for r=1:nROIs
    
    subplot(nROIs,1,r);
    x= [1:maxCycles];
    y =[absFFT{r}(2:maxCycles+1)];
    plot(x(1:nCycles-1),y(1:nCycles-1),'b','LineWidth',2)
    hold on
    plot(x(nCycles-1:nCycles+1),y(nCycles-1:nCycles+1),'r','LineWidth',2)
    plot(x(nCycles+1:maxCycles),y(nCycles+1:maxCycles),'b','LineWidth',2)
    plot(x,y,'bo','LineWidth',2);
    hold off
    
    fontSize = 14-nROIs+1;
    if (fontSize<6) 
        fontSize=6;
    end
    
    xtick=nCycles:nCycles:(maxCycles+1);
    set(gca,'xtick',xtick);
    set(gca,'FontSize',fontSize)
    if (r==nROIs) % Only lable the bottom graph
        xlabel('Cycles per scan','FontSize',fontSize)
    end
    
    ylabel('Percent modulation','FontSize',fontSize) 
    title(view.ROIs(r).name);
    grid on
    title(view.ROIs(selectedROIs(r)).name);
    grid on
    set(gca,'YLim',[-maxY,maxY]);
    %Save the data in gca('UserData')
    data.x = x(1:maxCycles);
    data.y  =  y(1:maxCycles);
    set(gca,'UserData',data);    
end



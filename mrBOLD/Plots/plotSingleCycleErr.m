function [status data] = plotSingleCycleErr(vw,scan)
%Plot the time series data of a single cycle.
%
%  status = plotSingleCycle(vw,[scan]) 
%
% All cycles (blocks) in a scan are collapsed into one cycle. This is meant
% to be somthing like the average over repetitions in the scan. The mean is
% plotted with standard error bars. 
%
% When called from the GRAY/VOLUME or FLAT views, the ROIs are converted to
% INPLANE to retrieve the time series.
%
% Example:
%   plotSingleCycleErr(INPLANE{1},1)
%
%  JW: 6/26/08 added parameter settings for Volume when viewtype is flat.
%   When in flat view, tseries is obtained from Inplanes, but if tseries 
%   does not exist in Inplanes, then it is gotten from Volume. 

mrGlobals;

global FLAT
global VOLUME
global selectedVOLUME
global INPLANE
global selectedINPLANE

% Normal status is OK
status = 1;

% These should be updated to viewGet calls.
if ieNotDefined('scan'), scan = viewGet(vw,'curScan'); end

% SOD: by default both "block" params and "event" params are assigned
% (mrInitRet), effectively always stopping this function. So I
% removed it.
%dt = dataTYPES(viewGet(vw,'curdt'));
%aType = dtGet(dt,'eventorblock',scan);
%if isequal(aType,'event'), 
%    disp('No single cycle plot for event analysis'); 
%    status = 0;  % False status
%    return;
%end


% Get coranal parameters
nCycles        = viewGet(vw, 'num cycles', scan);
frameRate      = viewGet(vw, 'frame rate', scan);
framesToUse    = viewGet(vw, 'frames to use', scan);
nFrames        =length(framesToUse);
framesPerCycle = nFrames/nCycles;

%Specifics for Flat, Gray, or Inplane views - xform ROI to INPLANE view
switch vw.viewType
    case {'Volume' 'Gray'}   %%%For ROIs in Gray view - xform to inplane
        % If the data do not exist in the inplane try getting the data from the
        % gray view directly.

        %initiate and / or select INPLANE window
        if isempty(INPLANE),
            INPLANE{1} = initHiddenInplane;
            INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
            selectedINPLANE = 1;
        else
            selectedINPLANE = viewSelected('inplane');
        end

        % Set the Inplane scan number and datatype to match the Volume view.
        try
            curDataType = viewGet(vw,'datatypenumber');
            INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
            INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scan);

            %Transfer current VOLUME ROI to INPLANE
            INPLANE{selectedINPLANE} = vol2ipCurROI(vw,INPLANE{selectedINPLANE});
        catch ME
            warning(ME.identifier, ME.message)
        end;

    case {'Flat'} % For ROIs in Flat view - xform to inplane

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
        curDataType = viewGet(FLAT{selectedFLAT},'datatypenumber');

        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
        INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scan);

        %JW: Set the Volume scan number and datatype to match the Flat view.
        VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'datatypenumber',curDataType);
        VOLUME{selectedVOLUME} = viewSet(VOLUME{selectedVOLUME},'currentscan',scan);


        % Transfer current FLAT ROI to INPLANE
        INPLANE{selectedINPLANE} = flat2ipCurROI(vw,INPLANE{selectedINPLANE},VOLUME{selectedVOLUME});
        % JW: Transfer current FLAT ROI to Volume
        VOLUME{selectedVOLUME} = flat2volCurROI(vw,VOLUME{selectedVOLUME});

    case {'Inplane'}   %%%For ROIs in INPLANE view - select inplane
        selectedINPLANE = viewSelected('inplane');
end

% Compute the mean tSeries
% If this does not work try getting the data from the volume view:
try
    ROIcoords = getCurROIcoords(INPLANE{selectedINPLANE});
    tSeries = meanTSeries(INPLANE{selectedINPLANE},scan,ROIcoords);
catch ME
    warning(ME.identifier, ME.message)
    try
        ROIcoords = getCurROIcoords(VOLUME{selectedVOLUME});
        tSeries = meanTSeries(VOLUME{selectedVOLUME},scan,ROIcoords);
    catch ME
        warning(ME.identifier, ME.message)
        return
    end;
end;
tSeries = tSeries(framesToUse, :);
%Compute the average single cycle
multiCycle  = reshape(tSeries,framesPerCycle,nCycles);
singleCycle = mean(multiCycle, 2);
singleCycleStdErr = (std(multiCycle,[],2)/sqrt(nCycles));
singleCycle(end+1)=singleCycle(1);
singleCycleStdErr(end+1)=singleCycleStdErr(1);
framesPerCycle=framesPerCycle+1;

% Plotting section 
newGraphWin;

fontSize = 14; 
t = linspace(0,(framesPerCycle-1)*frameRate,framesPerCycle)';

ROIname = vw.ROIs(vw.selectedROI).name;
headerStr = ['Mean Cycle, ROI ',ROIname,', scan ',num2str(scan)];

set(gcf,'Name',headerStr);
hh = errorbar(t,singleCycle,singleCycleStdErr,'k');

set(hh,'LineWidth',4); hold on
h2=plot(t(end),singleCycle(end),'xk');
hold off;

set(h2,'Color',[0.5 0.5 0.5]); set(h2,'LineWidth',8);

% nTicks = size(tSeries,1);
xtick = (0:frameRate:framesPerCycle*frameRate);

set(gca,'xtick',xtick)
set(gca,'FontSize',fontSize)
xlabel('Time (sec)','FontSize',fontSize) 
ylabel('Percent modulation','FontSize',fontSize) 
set(gca,'XLim',[0,framesPerCycle*frameRate]);
grid on

%Save the data in gca('UserData')
data.x = t;
data.y = singleCycle;
data.e = singleCycleStdErr;
set(gca,'UserData',data);


return;

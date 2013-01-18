function view = plotMeanChopTseries(view, designMatrix, roiCoords)
%
% view = plotMeanChopTseries(view, designMatrix, roiCoords)
%
% Will prompt for a design matrix if it doesn't exist or is empty. Will use
% coords from the current ROI if not specified.
% 
% HISTORY
% 2004.03.02 Written by Bob and Michal.
%

designMatrix = getDesignMatrix(view);

nScans = numScans(view);
normalizeMethod = 0; % 0=mean removal, 1=epoch-based
numPreFrames = 2; 
numPostFrames = 2;
numConditions = length(designMatrix);

if(~exist('roiCoords','var') | isempty(roiCoords))
    roiCoords = getCurROIcoords(view);
end

numCycles = zeros(1,numConditions);
for(scanNum = 1:nScans)
    % The fourth arg is a flag to get the raw tseries (no mean removal, no
    % detrend)
    if(normalizeMethod==0)
        roiTseries = getTseriesOneROI(view, roiCoords, scanNum, 0);
    else
        roiTseries = getTseriesOneROI(view, roiCoords, scanNum, 1);
    end
    for(condNum=1:numConditions)
        % Find the selected frames for this condition and this scan.
        frameList = designMatrix(condNum).scanFrames(designMatrix(condNum).scanFrames(:,1)==scanNum, 3)>0;
        if(any(frameList>0))
            numCycles(condNum) = numCycles(condNum)+1;
            tseriesCond{condNum,numCycles(condNum)} = roiTseries{1}(frameList,:);
            preFrames = find(frameList)-numPreFrames;
            preFrames(preFrames<1) = 1;
            preCond{condNum,numCycles(condNum)} = roiTseries{1}(preFrames,:);
            postFrames = find(frameList)+numPostFrames;
            postFrames(postFrames>size(roiTseries{1},1)) = size(roiTseries{1},1);
            postCond{condNum,numCycles(condNum)} = roiTseries{1}(postFrames,:);
        end
        %if(~all(isfinite(postCond{condNum}(:)))) keyboard; end
    end
end
for(condNum=1:length(designMatrix))
    switch(normalizeMethod)
        case 0
            % Normalization & trend removal done above
        case 1
            normVal{condNum} = repmat(mean(preCond{condNum}),size(tseriesCond{condNum},1),1);
            for(condNum=1:length(designMatrix))
                tseriesCond{condNum} = (tseriesCond{condNum} - normVal{condNum}) ./ normVal{condNum} .* 100;
                preCond{condNum} = (preCond{condNum} - normVal{condNum}) ./ normVal{condNum} .* 100;
                postCond{condNum} = (postCond{condNum} - normVal{condNum}) ./ normVal{condNum} .* 100;
            end
        otherwise
            disp([mfilename ': unrecognized normalizeMethod.']);
    end
end

% FIX ME! We assume the frame rate is the same for all scans!
scanNum = 1;
frameRate = getFrameRate(view,scanNum);
nCycles = numCycles(view,scanNum);
%frameRate = getFrameRate(view,scanNum);
nFrames = numFrames(view,scanNum);
framesPerCycle = nFrames/nCycles+numPreFrames+numPostFrames;

selectGraphWin;
r = ceil(sqrt(length(designMatrix)));
c = ceil(length(designMatrix)/r);
maxModulation = 0;
for(condNum=1:length(designMatrix))
    tSeries = [mean([preCond{condNum}],2); mean([tseriesCond{condNum}],2); mean([postCond{condNum}],2)];
    multiCycle  = reshape(tSeries,framesPerCycle,length(tSeries)/framesPerCycle);
    singleCycle = mean(multiCycle')';
    curMax = max(abs(singleCycle));
    if(curMax>maxModulation) maxModulation = curMax; end
    singleCycleStdErr = (std(multiCycle')/sqrt(nCycles))';
    
    % plot it
    ax(condNum) = subplot(r,c,condNum);
    fontSize = 14;
    t = linspace(-numPreFrames*frameRate, (nFrames/nCycles+numPostFrames-1)*frameRate, framesPerCycle)';
    
    ROIname = view.ROIs(view.selectedROI).name;
    headerStr = ['Mean Cycle, ROI ',ROIname];
    
    set(gcf,'Name',headerStr);
    hh = errorbar(t,singleCycle,singleCycleStdErr,'k');
    set(hh,'LineWidth',4);
    nTicks = size(tSeries,1);
    xtick = [-numPreFrames*frameRate:frameRate:(nFrames/nCycles+numPostFrames)*frameRate];
    
    set(gca,'xtick',xtick)
    set(gca,'FontSize',fontSize)
    xlabel('Time (sec)','FontSize',fontSize) 
    ylabel('Percent modulation','FontSize',fontSize) 
    set(gca,'XLim',[-numPreFrames*frameRate,(nFrames/nCycles+numPostFrames)*frameRate]);
    grid on
    title(designMatrix(condNum).conditionName);
    
    %Save the data in gca('UserData')
    data.x = t;
    data.y = singleCycle;
    data.e = singleCycleStdErr;
    set(gca,'UserData',data);
end

for(ii=1:length(ax))
    set(ax(ii),'YLim',[-maxModulation,maxModulation]);
end
return;

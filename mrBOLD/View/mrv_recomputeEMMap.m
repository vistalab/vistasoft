function view=recomputeEMMap(view)
% function view=recomputeEMMap(view)
% Recomputes the co, amp and ph maps in the current view based on data held
% in the emStruct structure. This is part of VOLUME
% The emStruct structure contains
% inverse, mesh2Gray, emData, map, FTMap
% emData in turn is a cell array containing sensor-level data.
% The current scan determines the emData cell.
% The current setting of analysisDomain determines the domain we're in
% (time or frequency)
% The current setting of datavals slider tells us which time point or
% frequency set we're going to use.
mrGlobals;

if (ieNotDefined('view'))
    error('You must pass in a view');
end

if (~strcmp(view.viewType,'generalGray'))
    error('View type must be ''generalGray''');
end

% The map and FFTMap were computed when we changed scanNum. We assume that
% they are good

dataValIndex=viewGet(view,'dataValIndex');
curScan=viewGet(view,'currentScan');
curDataType=viewGet(view,'currentDataType');


% Get the domain
if (strcmp(viewGet(view,'analysisDomain'),'time'))
    % We are working in the time domain.

    % For now, we only accept a vector array of time points (no averaging
    % across multiple time points)
    thisTimePoint=dataTYPES(curDataType).generalAnalysisParams(curScan).temporalAnalysis(dataValIndex);
    thisSlice=view.emStruct.map(thisTimePoint,:); % This thing should be 1xnMeshNodes
else
    % Working in the frequency domain. We may have more than one
    % component to sum. See emse_mapMultipleToMLR
    if (~iscell(dataTYPES(curDataType).generalAnalysisParams(curScan).frequencyAnalysis))

        thisFreqPoint=dataTYPES(curDataType).generalAnalysisParams(curScan).frequencyAnalysis(dataValIndex);
        thisSlice=abs(view.emStruct.FTmap(thisFreqPoint,:)); % This thing should be 1xnMeshNodes
        thisPhase=angle(view.emStruct.FTmap(thisFreqPoint,:));
    else
        % It's a cell array. That means that we could have a set of
        % frequencies that we have to RMS average.
        % = sqrt(sum(components squared ))
        thisFreqSet=dataTYPES(curDataType).generalAnalysisParams(curScan).frequencyAnalysis{dataValIndex};
        thisSliceSet=view.emStruct.FTmap(thisFreqSet(:),:)+1;   % *** NOTE. We add the one to take care of the fact that the first element in the FT is the mean. 
                                                                %   When we ask for frequency '1' we usually want the first
                                                                %   harmonic. Which is index 2. 
        if (length(thisFreqSet(:))>1)
            thisSlice=sqrt(sum(abs(thisSliceSet).^2)); % The abs is not required of course. But it makes it explicit
        else
            thisSlice=abs(thisSliceSet); % The abs is not required of course. But it makes it explicit
        end

        size(thisSlice)
        disp(thisFreqSet)

    end
end

grayToVertexMap=view.emStruct.grayToVertexMap; % You don't have to have a mesh loaded. But you will have needed one at some point..

% Okay - data stored in a. Map to positions stored in vertexGrayMap

grayToVertexMap(find(grayToVertexMap==0))=1; % This is not quite right. We should do something smarter like just not setting these vals.
thisGrayMap=thisSlice(double(grayToVertexMap)); % This is where we transfer data from thisMap to the cell array.
view.map{curScan}=thisGrayMap;

% Null the other map entries for the moment. We can eventually set ph (for
% single frequencies at least...)

nPoints=length(view.coords);

nullEntry=ones(1,nPoints);
view.co{curScan}=nullEntry;
view.ph{curScan}=nullEntry;

% We can set the view.curDataValIndex to the current numbernow. This should
% already have been done in refreshView but it doesn't hurt to do it again
% (in case we've been called from elsewhere)

view=viewSet(view,'dataValIndex',dataValIndex);
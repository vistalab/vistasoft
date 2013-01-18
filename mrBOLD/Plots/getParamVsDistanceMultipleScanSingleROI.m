function [distanceList,parameterData]=getParamVsDistanceMultipleScanSingleROI(flatView, plotParam, scanList,grayView,ROIcoords, binsize)
%
%   [distanceList,parameterList]=plotParamVsDistanceSingleScan(view,plotParam, scanList,grayView,roiList binsize); 
%  
%Author: Wandell
%Purpose:
%   Plot the values of various parameters for data on a line ROI
%
%History: 04 12 17 MMS (mark@ski.org) took the function plotParamVsDistanc
%and changed it.
%It plots in mm now, based on Bob's measureCorticalDistanceBins
%function. These changes are mostly after line 50
% 082305: Wade : Minor changes. 
% So this function  returns data for a SINGLE roi and MULTIPLE scans
% This is because computing the distances for each ROI is expensive but
% extracting the params for each ROI is fast.
% We don't do any plotting here - just pass back the data.

fontSize = 14;
if nargin<4 
    binsize=4;
end

if ~strcmp(flatView.viewType,'Flat')
    error('plotParamVsPosition only applies to line ROIs in the Flat view');
end

switch plotParam
    case 'Phase',
        paramName = 'ph';
    case 'Amplitude',
        paramName = 'amp';
    case 'Co',
        paramName = 'co';
    case 'ProjAmp',
        error('Not yet implemented');
end

if (ieNotDefined('ROIcoords'))
    disp('Using current ROI coords');
    ROIcoords = getCurROIcoords(flatView);
end

if (ieNotDefined('binsize'))
    disp('Using default binsize:2');
    binsize=2;
end

if(exist('scanList','var'))
    if isempty(scanList)
        scanList = selectScans(flatView,'Select Scans');
    else
        for thisScan=1:length(scanList)
            subdata(:,thisScan) = getCurDataROI(flatView, paramName, scanList(thisScan), ROIcoords)';
        end
    end
    
else
    scanNum = getCurScan(flatView);
    subdata = getCurDataROI(flatView, paramName, scanNum, ROIcoords);
end

% the original function now plots the data using  plot(1:size(ROIcoords,2),subdata)
%here come the changes to plot the parameter versus distance instead of
%number of coords in the ROI

%measure the length getting some binnodes back 
[totaldist bin]=measureCorticalDistanceBins(flatView,ROIcoords,binsize,grayView);

% in the bin variable you get the skipped nodes (or ROIcoords) for every shortcut the measuring algo took
% so we estimate intermediate distances for each skipped nodes
distanceList(1)=0;
nodes=[];

[flatNodeIndices, volNodeIndices, flatNodeDist, slice] = roi_getFlatNodes(flatView, ROIcoords, 1, grayView);

for ii=2:length(bin)
    steps=length(bin(ii-1).allNodes);
    dist=bin(ii).distToPrev;
    lastDistance=distanceList(length(distanceList));
    vekt=lastDistance:(dist/steps):dist+lastDistance;
    distanceList=cat(2,distanceList,vekt(2:steps+1));
    nodes=cat(2,nodes,bin(ii-1).allNodes); % here I make a list of every node "considered" this will get necessary soon...
end

%and now the last node. We have to put it into the list of nodes
nodes=cat(2,nodes,bin(length(bin)).binEdgeNode); 
%Well a little troubel:    bin("last").allNodes     are not considered.
%it appears to me, they are not realy shortcutted like the onee in the
%other bins, but are simply left out in the fuction  "measureCorticalDistanceBins"
% So they are left out here to.

% We have less nodes than we had flat-ROIcoords (some we miss at the end 
%- others we miss because sometimes two Flat flat-ROIcoord refer to the same
% "volNodeIndices" and are therefore estimated at the same position.
%  Therefor the data has to bee resoreted
for ii=1:length(nodes)
    a=nodes(ii);
    b=find(ismember(cell2mat(volNodeIndices),a));
    index(ii)=b(1); %if it is present more than once just take the first one...
end %this will give us an indexing list which also does some resorting ...

for thisScan=1:length(scanList)
parameterData(1:length(nodes),thisScan)=subdata(index,thisScan);
end

%Be aware! This has some consequences!!!!!!! 
%This does a resorting of the roi based on their proximity in the 3 dimensional space of the 
%flat mesh! while the values in "subdata" are sorted by the apperance of
%the dots in the variable "ROIcoords" - wheather their arrangemant 
%makes sense or not (sometimes it does sometime maybe not!!!) in this
%"resortedData" they are in the order the measure param versus distance
%function decides (and it does this according to their 3d-distance). 


return;


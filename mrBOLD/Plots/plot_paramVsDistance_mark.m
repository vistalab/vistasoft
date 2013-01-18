function [DistanceVekt,resortedData]=plotParamVsDistance_mark(view, plotParam, scanList,grayView, binsize); 
% [DistanceVekt,resortedData]=plotParamVsDistance_mark(view, plotParam, scanList,grayView, binsize); 
%   
%   Example:  plotParamVsPosition( INPLANE{1}, 'co'); 
%   Normally set up from plotMenu callback
%
%Author: Wandell
%Purpose:
%   Plot the values of various parameters for data on a line ROI
%
%History: 04 12 17 MMS (mark@ski.org) took the function plotParamVsDistanc
%and changed it.
%It plots in mm now, based on Bob's measureCorticalDistanceBins
%function. These changes are mostly after line 50

if nargin<4 
    binsize=4;
end

if ~strcmp(view.viewType,'Flat')
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

selectGraphWin
fontSize = 14;

ROIcoords = getCurROIcoords(view);

if(exist('scanList','var'))
    if isempty(scanList)
        scanList = selectScans(view,'Select Scans');
    else
        for ii=1:length(scanList)
            subdata(:,ii) = getCurDataROI(view, paramName, scanList(ii), ROIcoords)';
        end
    end
    
else
    scanNum = getCurScan(view);
    subdata = getCurDataROI(view, paramName, scanNum, ROIcoords);
end

% the original function now plots the data using  plot(1:size(ROIcoords,2),subdata)
%here come the changes to plot the parameter versus distance instead of
%number of coords in the ROI

%measure the length getting some binnodes back 
[totaldist bin]=measureCorticalDistanceBins(view,ROIcoords,binsize,grayView);

% in the bin variable you get the skipped nodes (or ROIcoords) for every shortcut the measuring algo took
% so we estimate intermediate distances for each skipped nodes
DistanceVekt(1)=0;
nodes=[];

[flatNodeIndices, volNodeIndices, flatNodeDist, slice] = roi_getFlatNodes(view, ROIcoords, 1, grayView);



for ii=2:length(bin)
    steps=length(bin(ii-1).allNodes);
    dist=bin(ii).distToPrev;
    lastDistance=DistanceVekt(length(DistanceVekt));
    vekt=lastDistance:(dist/steps):dist+lastDistance;
    DistanceVekt=cat(2,DistanceVekt,vekt(2:steps+1));
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



resortedData(1:length(nodes))=subdata(index);
%Be aware! This has some consequences!!!!!!! 
%This does a resorting of the roi based on their proximity in the 3 dimensional space of the 
%flat mesh! while the values in "subdata" are sorted by the apperance of
%the dots in the variable "ROIcoords" - wheather their arrangemant 
%makes sense or not (sometimes it does sometime maybe not!!!) in this
%"resortedData" they are in the order the measure param versus distance
%function decides (and it does this according to their 3d-distance). 


%now plotting distance versus data
plot(DistanceVekt',resortedData)
set(gca,'FontSize',fontSize)
xlabel('ROI mm')
ylabel(plotParam)
set(gca,'UserData',subdata);
headerStr = sprintf('Parameter: %s. Line ROI ',plotParam);
set(gcf,'Name',headerStr);
grid on

return;




% Debug
view = FLAT{1};
plotParam = 'Amplitude';
plotParam = 'Co';
plotParam = 'Phase';
plotParam = 'ProjAmp';

scanList = [1 2];
plotParamVsPosition( view, plotParam, scanList); 

% How to commit this file.
baseDir = 'g:\VISTASOFT\mrLoadRet-3.0';
respositoryName = 'VISTASOFT';
fname = {'plotParamVsPosition.m'};
cvsAddNewFiles(baseDir,fname,respositoryName);
function [fgArray, cmatrix]=dtiConnectMultipleROIs(handles, options, minDist, roiArray, fg)

%[fgArray, cmatrix]=dtiConnectMultipleROIs(handles, [options], [minDist], roiArray, fg)

%Connect multiple ROIs: choose a set of ROIs and a fiber group and obtain fiber groups connecting your ROIs in pairwise fashion. 
% If you pass all the other required arguments, you can leave handles empty.

%Return an NROIsxNROIs array of fiber groups connecting the respective ROIs, and a connectivity matrix cmatrix. 

%Options
%{'and'} [default]: pairwise connections between ROIs
%{'and', 'endpoints'}: pairwise connections such that the pathways terminate within the ROIS
%{'not'}: fgs exclusively connecting to each ROI but NOT any other ROI

%TODO: cmatrix: a structure with measures more than fiber count, but fiber
%properties, and a corresponding get-routine to extract simple networks for
%a given measure of interest. 
%Problem: If a couple of ROIs are sufficiently close to each other, some fibers will turn up in the list of connections to both. 

%ER wrote it 11/2009
global withinConnectivity;
withinConnectivity=1; %Connectivity mode; within network vs. base out-of-network. 


if ~exist('minDist', 'var')||isempty(minDist)
    minDist=.89;
end

if ~exist('options', 'var') || isempty(options)
    options={'and'}; 
end

if strmatch('not', options)
    options={'and'};
    withinConnectivity=0; 
end
    
if(~isempty(strmatch('split', lower(options)))) | ~isempty((strmatch('div', lower(options)))) | ~isempty((strmatch('both_endpoints', lower(options))))
error('The only valid options are <and> (default and required) and <endpoints>. Exiting function.') 
end

if (~exist('fg', 'var')||isempty(fg)) 
fg=handles.fiberGroups(handles.curFiberGroup);
end

if (~exist('roiArray', 'var')||isempty(roiArray)) 
    if ~isempty(handles)
sList = dtiSelectROIs(handles);
    
        if ~isempty(sList)
        roiArray=handles.rois(sList); 
        else
        disp('Load ROIs ... canceled.');
        return;
        end
    else
    
    return;
    end
end

if length(roiArray)<=1
    return
end

%Create an empty array to initialize
fgArray = struct(fg);
names = fieldnames(fg); 
for name=2:length(names)
fgArray.(names{name})=[];
end
cmatrix=0;

%display('Creating allBlobsRoi'); 
allBlobsRoi=dtiNewRoi('all Blobs'); 

for roiID=1:length(roiArray)
allBlobsRoi = dtiMergeROIs(allBlobsRoi,roiArray(roiID));
end
    
fgTheseBlobs = dtiIntersectFibersWithRoi([], [], [], allBlobsRoi, fg); fgTheseBlobs.name=fg.name;
[fgArray, cmatrix]=computeFgConnectingArray(handles, options, minDist, roiArray, fgTheseBlobs);
   
end

function [fgArray, cmatrix]=computeFgConnectingArray(handles, options, minDist, roiArray, fg)
global withinConnectivity

%Create an empty array to initialize
fgArray = struct(fg);
names = fieldnames(fg); 
for name=2:length(names)
fgArray.(names{name})=[];
end
     
cmatrix=0; 
if withinConnectivity==1
fprintf(1, 'Computing an array of fiber groups connecting %d ROIs in a pairwise fashion \n', length(roiArray));
else
    fprintf(1, ' Extracting fibers exclusively connecting to each of  %d ROI but NOT any other ROI \n', length(roiArray));
end
    
cmatrix=zeros(length(roiArray)); 

for ii=1:length(roiArray)
for jj=ii+1:length(roiArray)
    fprintf(1, 'Connecting ROIs %d and %d : ', ii, jj); 
	[fgiiRoi] = dtiIntersectFibersWithRoi(handles, options, minDist, roiArray(ii), fg);
    if isempty(fgiiRoi.fibers)
       fprintf(1, '\n'); 
       cmatrix(ii, 1:length(roiArray))=0;
        break
    end
    if withinConnectivity==0
        cmatrix(ii)= length(fgiiRoi.fibers);
        fgArray(ii)=fgiiRoi;
    break
    end
    
	[fgArray(ii, jj)] = dtiIntersectFibersWithRoi(handles, options, minDist, roiArray(jj), fgiiRoi);
    %fgArray(ii, jj).colorRgb=(roiArray(ii).color+roiArray(jj).color)./2;%%Make the color of the connecting patch average of the ROI colors? 
    fprintf(1, '%d fibers \n', length(fgArray(ii, jj).fibers)); 
    cmatrix(ii, jj)= length(fgArray(ii, jj).fibers); 
end
end

end

% 
% To save 
% fgnew=dtiNewFiberGroup; 
% fgnew.subgroup=[]; fgInd=0; 
% for ii=1:length(roiArray)
% for jj=ii:length(roiArray)
% if ~isempty(fgArray(ii, jj).fibers)
%     fgInd=fgInd+1; 
%     fgnew.fibers=vertcat(fgnew.fibers, fgArray(ii, jj).fibers); 
%     fgnew.subgroup=horzcat(fgnew.subgroup, repmat(fgInd, [1 length(fgArray(ii, jj).fibers)])); 
%     fgnew.subgroupNames(fgInd)=fgArray;
% end
% end
% end
% 
% dtiWriteFiberGroup(fgnew, outFgName);
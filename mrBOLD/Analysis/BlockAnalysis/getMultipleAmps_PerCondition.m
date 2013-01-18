function data=getMultipleAmps_PerCondition(view,selectedROIs,projPhase)
%function data=getMultipleAmps_PerCondition(view,selectedROIs)
% Returns the same data as you would get from plotMultileAmps_PerCondition.
%
%Reference scan is the current scan
mrGlobals;

refScan = getCurScan(view);
if (ieNotDefined('selectedROIs'))
    % Select ROIs
    nROIs=size(view.ROIs,2);
    roiList=cell(1,nROIs);
    for r=1:nROIs
        roiList{r}=view.ROIs(r).name;
    end


    selectedROIs = find(buttondlg('ROIs to Plot',roiList));
end

nROIs=length(selectedROIs);
if (nROIs==0)
    error('No ROIs selected');
end

if (ieNotDefined('projPhase'))
    projPhase=NaN;
end




nscans = numScans(view);
ROIamps=zeros(nscans,nROIs);
ROIseZ=zeros(nscans,nROIs);
ROImeanPhs=zeros(nscans,nROIs);


for r=1:nROIs

    n=selectedROIs(r);
    view = selectROI(view,n); % is there another way?
    [meanAmps,meanPhs,seZ] = vectorMeans(view);
    ROIamps(:,r)=meanAmps(:);
    ROIseZ(:,r)=seZ(:);
    ROImeanPhs(:,r)=meanPhs(:);
    xstr{r}=int2str(r);
    roiName{r}=view.ROIs(selectedROIs(r)).name;
    fprintf(['\n#%d :',roiName{r}],r);

end

if (~isnan(projPhase))
    ROIprojAmp=ROIamps.*(cos(projPhase-ROImeanPhs));
    data.projAmp=ROIprojAmp;
end

data.amps =ROIamps;
data.seZ= ROIseZ;
data.meanPhs= ROImeanPhs;
data.nROIs=nROIs;
data.ROIname=roiName;
return;

function thresholdedData = ff_thresholdRMData(rm,h)

% take a set of rm data for an roi across subjects and return only the
% voxel data which satisfy thresholds
% want to remove subjects which  have no data if they have no voxels above
% threshold to keep nans and empty matrices from crashing other functions
goodsubs = 1;

%     loop across subjects and get data from rm struct you just loaded
for r=1:length(rm)
    
    %     get index to values satisfying thresholds
    indx = 1:length(rm{r}.co);
    %     threshold by coherence
    coindx = find(rm{r}.co>=h.threshco);
    %     good voxels by coherence
    indx = intersect(indx,coindx);
    % threshold by ecc
    eccindx = intersect(find(rm{r}.ecc>=h.threshecc(1)),...
        find( rm{r}.ecc<=h.threshecc(2)));
    %     goodvoxels by eccentricity
    indx = intersect(indx,eccindx);
    %     good voxels by sigma
    sigindx = intersect(find(rm{r}.sigma1>=h.threshsigma(1)),...
        find(rm{r}.sigma1<=h.threshsigma(2)));
    
    indx = intersect(indx,sigindx);
    
    
    %     store thresholded data if there are more than minimum number of
    %     voxels
    if length(indx)>h.minvoxelcount
        thresholdedData{goodsubs}.name = rm{r}.name;
        thresholdedData{goodsubs}.vt = rm{r}.vt;
        %get shortened session name:  sad little hack
        if length(rm{r}.session)<10
            thresholdedData{goodsubs}.session = rm{r}.session(7:end);
        else
            thresholdedData{goodsubs}.session=rm{r}.session(7:9);
        end
        thresholdedData{goodsubs}.coords   = rm{r}.coords(indx);
        thresholdedData{goodsubs}.indices  = rm{r}.indices(indx);
        thresholdedData{goodsubs}.co       = rm{r}.co(indx);
        thresholdedData{goodsubs}.sigma1   = rm{r}.sigma1(indx);
        thresholdedData{goodsubs}.sigma2   = rm{r}.sigma2(indx);
        thresholdedData{goodsubs}.theta    = rm{r}.theta(indx);
        thresholdedData{goodsubs}.beta     = rm{r}.beta(indx);
        thresholdedData{goodsubs}.x0       = rm{r}.x0(indx);
        thresholdedData{goodsubs}.y0       = rm{r}.y0(indx);
        thresholdedData{goodsubs}.ph       = rm{r}.ph(indx);
        thresholdedData{goodsubs}.ecc      = rm{r}.ecc(indx);
        thresholdedData{goodsubs}.subject  = rm{r}.subject; 
        
        %     increment counter of subjects with data
        goodsubs=goodsubs+1;
    end
end



return



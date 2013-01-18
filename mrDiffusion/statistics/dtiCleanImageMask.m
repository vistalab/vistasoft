function mask = dtiCleanImageMask(mask, smoothKernel, fillHolesFlag, maskThreshold, clusterThresh)
% 
% newMask = dtiCleanImageMask(mask, [smoothKernel=3], [fillHolesFlag=1], [maskThreshold=0.5], [clusterThresh=1])
%
% Cleans up a 3d voxel mask (binary image) by filling holes, removing all
% satellites and (optionally) smoothing.
%
% smoothKernel defines the size of the convolution kernel (in voxels). Set
% to 0 for no smoothing. Can be a 1x3 (eg. [6,6,4] or a scalar for a
% symmetric kernel. Defaults to [5,5,5].
%
% If fillHolesFlag is set to 0, holes will not be filled. 
%
% With smoothKernel ~=0, if maskThreshold>0.5, the image will be eroded and
% if maskThreshold<0.5 the image will be dilated. 
%
% if clusterThresh==1, then all but the single largest object will
% be removed. If this is 0, no satellite removal will be done. If this is
% >1, then only satellites with a voxel-count smaller than this will be
% removed. E.g., clusterThresh=100 will remove any satellites
% smaller than 100 voxels. Note that the largest object (even if it is
% smaller than clusterThresh) is always retained.
%
% HISTORY:
% 2004.01.06 RFD wrote it.
% 2004.12.01 RFD changed smooth3 to the faster dtiSmooth3.

if(~exist('smoothKernel','var') || isempty(smoothKernel))
    smoothKernel = 3;
end
removeSatellites = 1;
dilate = 0;
if(~exist('fillHolesFlag','var') || isempty(fillHolesFlag))
    fillHolesFlag = 1;
elseif(iscell(fillHolesFlag)||ischar(fillHolesFlag))
    flags = lower(fillHolesFlag);
    fillHolesFlag = 0;
    removeSatellites = 0;
    if(~isempty(strmatch('fillhole',flags))), fillHoles = 1; end
    if(~isempty(strmatch('removesat',flags))), removeSatellites = 1; end
end
if(~exist('maskThreshold','var') || isempty(maskThreshold))
    maskThreshold = 0.5;
end
if(~exist('clusterThresh','var') || isempty(clusterThresh))
    clusterThresh = 1;
end
if(~exist('bwlabeln','file'))
    warning('No image processing toolbox- skipping satellite removal and hole filling.');
    iptb = 0;
else
    iptb = 1;
end
mask = double(mask);
if(iptb)
    if(removeSatellites)
        mask = satelliteRemoval(mask, clusterThresh);
    end
    % Fill cavities
    if(fillHolesFlag), mask = imfill(mask,'holes'); end
end
if(sum(smoothKernel(:)~=0))
    % Smooth then repeat the satelite removal and filling
    mask = dtiSmooth3(double(mask), smoothKernel);
    mask = double(mask>maskThreshold);
    if(iptb)
        if(removeSatellites)
            mask = satelliteRemoval(mask, clusterThresh);
        end
        if(fillHolesFlag), mask = imfill(mask,'holes'); end
    end
end
return;

function mask = satelliteRemoval(mask, clusterThresh)
    if(clusterThresh>0)
        % Find all the objects (separate clusters of 26-connected voxels)
        [imgLabel,numObjects] = bwlabeln(mask, 26);
        % Remove satellites
        if(numObjects>1)
            % Find the largest object and assume everything else is a satellite.
            % we skip the first bin, since it is full of all the zeros
            [imgHist,labelNum] = hist(imgLabel(imgLabel(:)>0),1:numObjects);
            objectLabel = labelNum(imgHist==max(imgHist));
            mask = imgLabel==objectLabel(1);
            if(clusterThresh>1)
                objectLabel = labelNum(find(imgHist>=clusterThresh));
                mask = mask|ismember(imgLabel,objectLabel);
            end
            clear imgHist labelNum;
        end
    end
return;

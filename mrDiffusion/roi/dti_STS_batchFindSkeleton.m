%% dti_STS_batchFindSkeleton
%
% Script for processing dti data from the STS_Project
% This batch script will:
% (1). Create a skeleton of the Border ROI (created using dtiFindBorderBetweenRois)
% by finding a line that runs along the center of mass of the ROI 
% (the average X and Z points along every Y point).
% (2). Create a fiber that joins the skeleton points together
% (3). Resamples the skeleton fiber so that nodes (1-N) are evenly spaced
% along the length of the fiber
% (4). Draws ROI spheres of a given size at each specified node point
%
% (Batch script incorporating dtiFindRoiSkeleton and dtiFiberResample functions written by ER)
%
% HISTORY:  03/2010 AK wrote it
%
%% Set Directory Structure and Subject info

baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = {'dti_y1'};
subs =  {'lj0'};
dtDir = 'dti06trilinrt';


% Parameters
borderROI = 'border1015to1030'; % ROI to be resampled into ROI nodes
numNodes = 10; %number of nodes along the skeleton fiber
radius = 5; %size of ROI sphere
gradmap = colormap(jet);


%%
%%************************************
% Do not edit below
%%************************************
if numNodes<=64
    for ii = 1:numel(subs)

        for jj = 1:numel(dtiYr)

            fprintf(1, 'Working on subject %s, year %s \n', subs{ii}, dtiYr{jj});

            sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
            if ~isempty(sub) % If there is no data for dtiYr{kk}, skip.
                subDir = fullfile(baseDir,dtiYr{jj},sub.name);
                dt6Dir = fullfile(subDir,dtDir);
                dt6File = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat
                roiDir = fullfile(dt6Dir, 'ROIs'); 
                fibersDir = fullfile(dt6Dir, 'fibers'); 
                borderCoordsRoiFile = fullfile(roiDir, borderROI);
                skeletonRoiFile = fullfile(roiDir, [borderROI '_skel.mat']); 
                skeletonRoiFiber = fullfile(fibersDir, [borderROI '_skel.mat']); 
                skeletonRoiFiberResampled = fullfile(fibersDir, [borderROI '_skel_resampled.mat']); 
                borderCoordsRoi = dtiReadRoi(borderCoordsRoiFile);
                skeletonRoi = dtiFindRoiSkeleton(dtiRoiClean(borderCoordsRoi, [], {'fillHoles', 'dilate'}), 2);
                dtiWriteRoi(skeletonRoi, skeletonRoiFile);
                
                newFiber = dtiNewFiberGroup([borderROI '_skel.mat']); 
                newFiber.fibers{1} = skeletonRoi.coords';
                dtiWriteFiberGroup(newFiber, skeletonRoiFiber); 
                fiber = newFiber.fibers{1};
                fiber_r = dtiNewFiberGroup([borderROI '_skel_resampled.mat']);
                fiber_r.fibers{1} = dtiFiberResample(fiber, numNodes, 'N');
                dtiWriteFiberGroup(fiber_r, skeletonRoiFiberResampled); 
                
               % *** Show plot of the resampled fiber compared to the original fiber (
               % figure; plot3(fiber_r.fibers{1}(1,:),fiber_r.fibers{1}(2,:),fiber_r.fibers{1}(3,:),'ro-', ...
               % fiber(1,:),fiber(2,:),fiber(3,:),'bx--');
               % legend('Resampled', 'Original');
            end

            
            for roiID=1:numNodes
                centerCoord = fiber_r.fibers{1}(:, roiID);
                color=gradmap(roiID*floor(size(gradmap, 1)/(numNodes-1))-floor(size(gradmap, 1)/(numNodes-1))+1, :); % forms the color
                rois{roiID}=dtiNewRoi(['Node ' num2str(roiID)], color, dtiBuildSphereCoords(centerCoord, radius));
                % == Here goes dtiIntersectFibersWithRoi with arguments wholeBrainFG
                % and rois{roiID}
                dtiWriteRoi(rois{roiID}, fullfile(roiDir, ['lSTSnode' num2str(roiID)])); %write them out
            end
        end
    end
else
    display('Only up to 64 color are supported, hence you have to choose <=64 nodes');
end
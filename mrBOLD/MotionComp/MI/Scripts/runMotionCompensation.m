function runMotionCompensation(view,scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear,glmIndex,consError)
%
%   gb 05/17/05
%
% runMotionCompensation(view,scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear,glmIndex,consError)
%
% Runs the motion compensation algorithm and the glm if needed (if glmIndex > 0)
% Also creates a movie of the 18th slice of the mean maps 

global dataTYPES

view = motionCompMutualInfMeanInit(view,scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear);

if ~ieNotDefined('ROI')
    ROIname = ['ROI_' newDataType];
end

% Runs the GLM
if glmIndex
    er_runSelxavgBlock(view,intersect(union(baseScan,scans),1:6),1);
end

% Creates the movie of the mean maps
motionCompMeanMovie(view);



function  tSeries=doTemporalNormalization(tSeries)
%
% tSeries=doTemporalNormalization(tSeries);
% Author: ARW 
% Date:   032803
% Purpose:
% Performs temporal normalization on a slice by slice basis: 
% Scales each frame so that it has the same mean intensity as the first one
% JW, 1.2.2011: changed mean to nanmean in case there are any NaNs in the
%               data

%[~,voxelsPerFrame] = size(tSeries);

% Mean of each frame
meanTSerFrames = nanmean(tSeries,2);

fprintf(1,'Mean tseries value of the first frame %.05f\n',meanTSerFrames(1));

% Replace repmat with bsxfun, and allow for the possibility that we have
% multiple slices
% tSeries=(tSeries./repmat(meanTSerFrames,1,voxelsPerFrame))*meanTSerFrames(1);
tSeries = bsxfun(@rdivide, tSeries, meanTSerFrames);
tSeries = bsxfun(@times, tSeries, meanTSerFrames(1,1,:));



return;

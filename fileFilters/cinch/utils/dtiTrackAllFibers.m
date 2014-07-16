function vectorRgb = dtiTrackAllFibers(samplingRateMm, dataDirectory, faThresh, faTrackThresh, exclusionRoi)
%
% Track all fibers for a particular subject. These are stored in one
% massive data file in the specified path.
%  
%   dtiTrackAllFibers([samplingRateMm=2], [dataDirectory],
%   [faMaskThresh=0.25], [faTrackThresh=0.15], [exclusionRoi=[]], [hemisphere='both'])
%
%  samplingRateMm: the grid resolution for seed points, in millimeters.
%  Default is 2 mm.
%
%  dataDirectory: the path to the directory containing the tensors.nii.gz
%  file. If unspecified, a directory selection dialog will pop up.
%
%  
% Author: DA

if(~exist('samplingRateMm','var')||isempty(samplingRateMm))
    samplingRateMm = 2;
end;
if(~exist('dataDirectory','var') || isempty(dataDirectory))
    dataDirectory = uigetdir('', 'Set subject bin directory');
    if(isnumeric(dataDirectory)), disp('dtiTrackAllFibers canceled.'); return; end
end;
if(~exist('faThresh','var')||isempty(faThresh))
    faThresh = 0.25;
end
if(~exist('faTrackThresh','var')||isempty(faTrackThresh))
    faTrackThresh = 0.15;
end
if(~exist('exclusionRoi','var'))
    exclusionRoi = [];
end
if(~isempty(exclusionRoi))
  if(~isstruct(exclusionRoi))
	exclusionRoi = dtiReadRoi(exclusionRoi);
  end
end

disp ('Loading tensors...');

opts.stepSizeMm = 1;
opts.faThresh = faTrackThresh;
opts.lengthThreshMm = 30;
opts.angleThresh = 50;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0];

dt6 = niftiRead(fullfile(dataDirectory,'tensors.nii.gz'));
% check for the new NIFTI-compliant 5d format
if(dt6.ndim>4)
  % Convert from the 5d, lower-tri row order NIFTI tensor format
  % (Dxx Dxy Dyy Dxz Dyz Dzz) to our 4d tensor format (Dxx Dyy Dzz Dxy Dxz Dyz).
  dt6.data = double(squeeze(dt6.data(:,:,:,1,[1 3 6 2 4 5])));
end
if(exist(fullfile(dataDirectory,'brainMask.nii.gz')))
  mask = niftiRead(fullfile(dataDirectory,'brainMask.nii.gz'));
  for(ii=1:6)
	tmp = dt6.data(:,:,:,ii);
	tmp(~mask.data) = 0;
	dt6.data(:,:,:,ii) = tmp;
  end
  clear tmp mask;
end

% Create WM ROIs
[vec,val] = dtiEig(dt6.data);
fa = dtiComputeFA(val);
fa(fa>1) = 1; fa(fa<0) = 0;
if(nargout>0)
  img = abs(squeeze(vec(:,:,:,[1 2 3],1)));
  img(isnan(img)|img<0) = 0;
  img(img>1) = 1;
  for(ii=1:3) img(:,:,:,ii) = img(:,:,:,ii).*fa; end
  vectorRgb = niftiGetStruct(single(img),dt6.qto_xyz);
  clear img;
end
clear vec val;

samplingRateVox = samplingRateMm./dt6.pixdim;

% first create an enormous array of seeds and figure out which ones fall
% within the masked region:

xSeed = 1:samplingRateVox(1):size(dt6.data,1);
ySeed = 1:samplingRateVox(2):size(dt6.data,2);
zSeed = 1:samplingRateVox(3):size(dt6.data,3);

mask = fa>=faThresh;
midline = mrAnatXformCoords(dt6.qto_ijk,[0 0 0]);

[xIndex, yIndex, zIndex] = ind2sub ([size(xSeed,2), size(ySeed,2), size(zSeed,2)], ...
                                    find (mask (round(xSeed), round(ySeed), round(zSeed))));

pathsFilename = fullfile(dataDirectory, sprintf('all_paths_%dmm.pdb',samplingRateMm));

dtiWritePDBHeader (dt6.qto_xyz, pathsFilename);

fileOffsets = [];

% track in index blocks of width XX:
xStepSize = 10;
nFibers = 0;
for xIter = 1:xStepSize:size(xIndex,1)
    xRange = find (xIndex >= xIter & xIndex < xIter+xStepSize);
    seeds = [xSeed(xIndex(xRange)); ySeed(yIndex(xRange)); zSeed(zIndex(xRange))]';
    acpcSeeds = mrAnatXformCoords(dt6.qto_xyz, seeds);
    seedIndices = [xIndex(xRange), yIndex(xRange), zIndex(xRange)];
    if (isempty(seeds))
        continue;
    end;
    [fg, opts, kept] = dtiFiberTrackWrapper(dt6.data, seeds, dt6.pixdim(1:3), dt6.qto_xyz, ['FG'], opts);                   
    if (size(fg.fibers,1) == 0)
        continue;
    end;
    if(~isempty(exclusionRoi))
       fg = dtiIntersectFibersWithRoi([], {'not'}, [], exclusionRoi, fg);
    end
    nFibers = nFibers + length(fg.fibers);
    newOffsets = dtiAppendPathwaysToPDB (fg, pathsFilename);
    fileOffsets = [fileOffsets newOffsets];
    clear fg;   
end


dtiAppendFileOffsetsToPDB (fileOffsets, pathsFilename);

return;

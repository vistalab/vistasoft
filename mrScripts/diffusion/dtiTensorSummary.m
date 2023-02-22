% dtiTensorSummary
% 
% Compute a summary file with FA, MD, valid data mask, eigenvalues,
% eigenvectors, and other interesting features of the tensor data for all
% of the spatially normalized subjects used to make an atlas.  This summary
% file creates the atlas data, really.
%
% The tensor summary file is stored in the data with the spatially
% normalized individual subjects (in the atlas directory, usually called
% warp3 and average in some way that we plan to standardize).
%
% For the moment, tensorSumFile is the variable used by this script to
% specify the full path where the data are written.
%
% Used in dtiEpilepsy
% Could be useful other times
%

fprintf('Computing tensor summary file %s\n',tensorSumFile);

% Find the spatially normalized subjects from the individual subjects used
% to create the atlas.  These subjects are in the average directory
% (avgdir).  This only needs to be computed once.
snFiles = findSubjects(avgdir, '*_sn*',{});
N = length(snFiles);
disp(['Loading ' snFiles{1} '...']);
dt = load(snFiles{1});

% Initialize space for the data.  First the 6 entries of the diffusion
% tensor.  Read the first subject and this sets up the sizes.
allDt6 = zeros([size(dt.dt6) N]);
allDt6(:,:,:,:,1) = dt.dt6;

% Now, the B0 data for the first subject.
meanB0 =  double(dt.b0);
%mask = allDt6(:,:,:,1,1)>0;

% Now add the remaining subjects
for(ii=2:N)
    disp(['Loading ' snFiles{ii} '...']);
    dt = load(snFiles{ii});
    dt.dt6(isnan(dt.dt6)) = 0;
    allDt6(:,:,:,:,ii) = dt.dt6;
    meanB0 = meanB0 + double(dt.b0);
    %mask = mask & allDt6(:,:,:,1,ii)>0;
end
meanB0 = meanB0./N;

% This is the DT mask which thresholds on the B0 image.  If the mask is 1,
% you are in the valid portion of the data set (i.e., where there are valid
% DT data).
mask = (meanB0 > 250) & all(squeeze(allDt6(:,:,:,1,:)),4)>0;

% Compute the tensor eigenvector and eigenvalues
allDt6_ind = dtiImgToInd(allDt6, mask);
[eigVec, eigVal] = dtiEig(allDt6_ind);
eigVal(eigVal<0) = 0;

% Compute the fractional anisotropy
[faImg,mdImg] = dtiComputeFA(eigVal);
fa.mean = mean(faImg,2);
fa.stdev = std(faImg,0,2);
fa.n = N;

% Compute the mean diffusivity
md.mean  = mean(mdImg,2);
md.stdev = std(mdImg,0,2);
md.n = N;
clear faImg mdImg;

% Compute the log(Tensor) that we use in the statistics
eigVal = log(eigVal);
allDt6_ind = dtiEigComp(eigVec, eigVal);
clear eigVec eigVal;
[logTensor.mean, logTensor.stdev, logTensor.n] = dtiLogTensorMean(allDt6_ind);
clear allDt6_ind;

% Add some notes about when this was computed and save
notes.createdOn = datestr(now);
notes.sourceDataDir = avgdir;
notes.sourceDataFiles = snFiles;
save(tensorSumFile,'fa','md','logTensor','meanB0','mask','notes');

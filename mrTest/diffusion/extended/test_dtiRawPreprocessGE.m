function val = v_dtiRawPreprocessGE()
% Validate dti raw preprocessing of GE data
%
%    val = v_dtiRawPreprocessGE()
%
% This function checks that the average FA and B0 values resulting from
% dtiRawPreprocess are consistent with the expected value on different
% platforms (LINUX, WINDOWS, etc.).
%
% Requires vistadata and vistasoft on your path. The directory
% vistadata/diffusion/dtiRawPreprocess/GE contains all the necessary data
% files.
% 
% This function does the following:
%
% (1) run dtiRawPreprocess on the files in the raw folder. This will align to the T1 and
% create a B0, BVECS and FA values (it creates more stuff but we only focus on these for the moment).
%
% (2) Show a montage of Alignment i.e., the T1 and DTI overalyed. Check for LR flips and correct alignment. 
%  
% (3) Compute FA, Mean diffusivity, radial diffusivity nd Axial diffusivity 
%     across the brain and check the value obtained on different
%     platforms. THis will be done using: [fa,md,rd,ad] = dtiComputeFA(eigVal)
%
% (5) Load the stored FA, MD, RD, AD for the whole brain in:
%     GE/storedMeanDiffusionVals.mat
%     
% (6) Recompute them from the data
% 
% (7) Compute the difference between the stored and the recomputed ones.
%
% Example:
%  This function is meant to be called by mrvValidate, which will 
% compute the difference between the stored values and the re-computed
% values.
%
%   mrvValidate([],[], 'v_dtiRawPreprocessGE');
%
% See also: mrvValidateAll.m
%   
% FP and MP 7/6/2011
% Copyright Stanford team, mrVista, 2011
 
% This function takes too long to run. We want validation functions to be
% fast (say, less than 10 s). this one takes minutes to hours to run.
%
val = [];
return;

%% Get the data pathdata path
% Changing the last parameter and the function name changes
% scanner type (e.g., Siemens)
dataDir = fullfile(mrvDataRootPath,'diffusion','dtiRawPreprocess','GE');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Run Preprocess
% setting clobber to 'always', so that output files will be silently replaced.
dtiRawPreprocess('raw/dti_g87_b1000.nii.gz', 't1.nii.gz',[],[],'always'); 

%% Show alignment to t1
% this was automatically computed by dtiRawPreprocess.m
imshow(imread('dti40trilin/t1pdd.png')); 

%% Compute mean FA, RD, MD, AD values and check them with the stored one.

% load the stored values
% by convention mrvValidate.m loads up a storedVals data file
% with the same name of the validate function thta uses it 
thisfunction = mfilename;
load(fullfile(mrvDataRootPath,'validate',[thisfunction(3:end),'.mat']));

% load the dti file.
dt = dtiLoadDt6('dti40trilin/dt6.mat');

% extract the eigen values.
eigVal = dt.dt6;

% compute the fractional, mean, radial and axial diffusivity
[fa,md,rd,ad] = dtiComputeFA(eigVal);

% compute the mean across the whole brain
val.fa = nanmean(fa(:));
val.md = nanmean(md(:));
val.rd = nanmean(rd(:));
val.ad = nanmean(ad(:));

% mrvValidate will use the output of this function to compare the
% recomputed values to the stored values.
% fr example doing something like this:
%
% check the computed with the stored values
% val.faErr = diff([mean_fa,meanVals.fa]);
% val.mdErr = diff([mean_md,meanVals.md]);
% val.rdErr = diff([mean_rd,meanVals.rd]);
% val.adErr = diff([mean_ad,meanVals.ad]);
%
% show results on matlab output
% errFields = fields(val);
% meanFields = fields(meanVals);
% for i = 1:length(fields(val))
%  fprintf('[%s] Error in ''%s'': %2.8f\n',mfilename, meanFields{i}, val.(errFields{i}));
% end

%% go back to the original directory, done!
cd(curDir)

return





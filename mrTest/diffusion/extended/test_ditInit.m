function val = v_dtiInit
% Validate dti raw preprocessing of GE data
%
%    val = v_dtiInit()
%
% This script takes a very long time to run and should not be used as part
% of the usual unit testing.  LM Perry is thinking about shortening this.
% And we should be writing other test_dtiXXXX scripts for unit testing.
%
% This function checks that the average FA and B0 values resulting from
% dtiRawPreprocess are consistent with the expected value on different
% platforms (LINUX, WINDOWS, etc.).
%
% Requires vistadata and vistasoft on your path. The directory
% fullfile(mrvDataRootPath,'validate','dwi') contains all the necessary
% data files.
% 
% This function does the following:
%
% (1) run dtiInit on the files in the raw folder. This will align to the T1
%     and create a B0, BVECS and FA values (it creates more stuff but we
%     only focus on these for the moment).
%
% (2) Show a montage of Alignment i.e., the T1 and DTI overalyed. Check for
%     LR flips and correct alignment. 
%  
% (3) Compute FA, Mean diffusivity, radial diffusivity nd Axial diffusivity 
%     across the brain and check the value obtained on different
%     platforms. THis will be done using: [fa,md,rd,ad] = dtiComputeFA(eigVal)
%
% (5) Load the stored FA, MD, RD, AD for the whole brain in:
%     'dwi/storedValues.mat'
%     
% (6) Recompute them from the data
% 
% (7) Compute the difference between the stored and the recomputed ones.
% 
% (8) Remove the data that was created by this code if there is not a
%     significant difference in the computed values. 
%
% Example:
%  This function was meant to be called by mrvValidate, which will 
%  compute the difference between the stored values and the re-computed
%  values.
%
%   mrvValidate([],[], 'test_dtiInit');
%
% See also: mrvValidateAll.m
%   
% Adapted from v_dtiRawPreprocessGE 
% 
% (C) Stanford VISTA, 2011
% 
% 
%%
% This function takes a while to run. We want validation functions to be
% fast. Here we warn the user that this test will take a while and confirm
% that they want to continue. 

prompt = 'You are about to process DWI data - this will take ~1hr to run. Do you want to continue?';
resp = questdlg(prompt,'Confirm','Yes','Cancel','Cancel');
if(strcmp(resp,'Cancel'))
    disp('canceled.');
    assertEqual(0,1,'NOTICE: test_dtiInit.m was canceled by the user.');
    return;
end


%% Get the data pathdata path
dataDir = fullfile(mrvDataRootPath,'validate','dwi');
rawDwi  = fullfile(mrvDataRootPath,'validate','dwi','raw','dti.nii.gz');
t1      = fullfile(mrvDataRootPath,'validate','dwi','t1.nii.gz');


%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);


%% Run Preprocess
% setting clobber to 'always' = 1, so that output files will be silently
% replaced.
params  = dtiInitParams('phaseEncodeDir',2,'clobber',1); 
dt6File = dtiInit(rawDwi,t1,params);


%% Show alignment to t1
% This is automatically computed by dtiRawPreprocess.m
t1pdd = fullfile(mrvDirup(dt6File),'t1pdd.png');
imshow(imread(t1pdd),'InitialMagnification','fit'); 


%% Compute mean FA, RD, MD, AD values and check them with the stored one.

% Load the stored values
ref = load(fullfile(dataDir,'test_dtiInit.mat'));

% Load the dt6 file.
dt = dtiLoadDt6(dt6File);

% Extract the eigen values.
eigVal = dt.dt6;

% Compute the fractional, mean, radial and axial diffusivity
[fa,md,rd,ad] = dtiComputeFA(eigVal);

% Compute the mean across the whole brain
val.fa = nanmean(fa(:));
val.md = nanmean(md(:));
val.rd = nanmean(rd(:));
val.ad = nanmean(ad(:));


%% Test the results

% Check the mean FA
assertEqual(ref.val.fa, val.fa);
% Check the mean MD
assertEqual(ref.val.md, val.md);
% Check the mean RD
assertEqual(ref.val.rd, val.rd);
% Check the mean AD
assertEqual(ref.val.ad, val.ad);


%% Go back to the original directory, done!
% 
cd(curDir)

return







%% This is to save a new mat file with the values.
% save('test_dtiInit.mat','val');


%% old code
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







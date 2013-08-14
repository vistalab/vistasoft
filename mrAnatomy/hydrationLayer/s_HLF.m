%% Script to illustrate the computation of the hydration layer fraction.
%  s_HLF
%
% For reference see:
%


%% Load and align the data
%
dataDir = 'C:\u\brian\Matlab\mrDataExample\hydrationLayer';
refIm = 't1.nii.gz';
rawDir = 'raw';

% 1 for trilinear, 7 for b-spline
interp = 7; 
if(interp==1), outDirName = 'trilin';
else           outDirName = 'bsplin'; end

% Fit method:
%   'f' for fminsearch
%   'l' for lsqnolin
%   'pf','pl' for parallel
% versions with disttoolbox
% What is disttoolbox?
fitMethod = 'ls';
outMontage = ['./wst1.png'];

outBaseName = outDirName;
outFile = fullfile(dataDir,[outBaseName '_aligned.mat']);
if(exist(outFile,'file'))
    disp(['Loading aligned data from ' outFile '...']);
    load(outFile);
else
    outDir = dataDir;
    % Load all the series in the struct 's'
    s = dicomLoadAllSeries(rawDir);
    ref = niftiRead(refIm);
    %mmPerVox = ref.pixdim(1:3);
    mmPerVox = [0.9 0.9 0.9];
    % Align all the series to this subject's reference volume
    [s,xform,alignInds] = relaxAlignAll(s,ref,mmPerVox,true,interp);
    s = s(alignInds);
    save(outFile,'s', 'xform', 'dataDir', 'refIm', 'outDir', 'mmPerVox');
end

% Drop the first measure- too much motion
s = s(2:end);

outDir = fullfile(outDir, [outDirName fitMethod(end)]);
if(~exist(outDir,'dir')), mkdir(outDir); end

%
% Sort out image types
%
sequenceNames = {s(:).sequenceName};
spgrInds = false(size(sequenceNames));

% find series that are *either* SPGR or FSPGR
spgrInds(strmatch('3DGRASS',sequenceNames)) = 1;
spgrInds(strmatch('EFGRE3D',sequenceNames)) = 1;

tiInds = spgrInds & [s(:).inversionTime]>0;
t1Inds = spgrInds & ~tiInds;

% Mean image, use only t1Inds to calculate it
mn = mean(cat(4,s([2,4,5]).imData),4);
[brainMask,checkSlices] = mrAnatExtractBrain(mn, mmPerVox, 0.40);
%brainMask = dtiCleanImageMask(brainMask,3,1,.2);
%brainMask = dtiCleanImageMask(mrAnatHistogramClip(mn,0.3,0.9)>0.4,10,1,.3);
brainMask(any(cat(4,s(t1Inds).imData)<=0,4)) = 0;

tr = [s(t1Inds).TR];
if(~all(tr==tr(1))), error('TR''s do not match!'); end
tr = tr(1);

flipAngles = [s(t1Inds).flipAngle];

% compute t1 with no b1 bias correction
[t1,gPD_T2s] = relaxFitT1(cat(4,s(t1Inds).imData),flipAngles,tr);
t1(~brainMask) = 0; gPD_T2s(~brainMask) = 0;
dtiWriteNiftiWrapper(single(t1), xform, fullfile(outDir,'T1_nob1.nii.gz'));
dtiWriteNiftiWrapper(single(pd), xform, fullfile(outDir,'gPD_T2s_nob1.nii.gz'));

%% Compute a b1 map using the DESPOT1-HIFI method
%b1Map = 1.0;
if(~exist(fullfile(outDir,'b1.nii.gz')))
    b1Map = relaxFitDespoT1(s, brainMask);
    dtiWriteNiftiWrapper(single(b1Map), xform, fullfile(outDir,'b1.nii.gz'));
else
    ni = niftiRead(fullfile(outDir,'b1.nii.gz'));
    b1Map = double(ni.data);
end

[t1,gPD_T2s] = relaxFitT1(cat(4,s(t1Inds).imData),flipAngles,tr,b1Map);
t1(~brainMask) = 0; gPD_T2s(~brainMask) = 0;
t1(t1>5) = 5;

dtiWriteNiftiWrapper(single(t1), xform, fullfile(outDir,'T1.nii.gz'));
dtiWriteNiftiWrapper(single(gPD_T2s), xform, fullfile(outDir,'gPD_T2s.nii.gz'));

% Compute R1
t1(t1>3) = 3;
t1(brainMask & t1<0.5) = 0.5;
r1 = zeros(size(t1));
r1(brainMask) = 1./t1(brainMask);
dtiWriteNiftiWrapper(single(r1), xform, fullfile(outDir,'R1.nii.gz'));

% FSL commands
% fast R1.nii.gz
% run_first_all -b -i R1.nii.gz -o first

%% GridFit to the gPDt2* image the T2* in neglected hopefully with good reason
[PDc CoilG]=BaisGridFit(t1,PD,xform,outDir);

%% Final HLF computation
mField = 3;
[HLF,Wf] = hlfCompute(t1,pd,xform,outDir,mField)


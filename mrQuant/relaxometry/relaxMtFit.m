function relaxMtFit(dataDir,outDir,voxRange)
%
% relaxMtFit(dataDir,outDir,voxRange)
%
% Calculates the k and f maps using the MT TOF sequence.
%
% See Yarnykh & Yuan (2004). Cross-relaxation imaging reveals
% detailed anatomy of white matter fiber tracts in the human
% brain. Neuroimage, 23(1):409-24. (PMID: 15325389)
%
% KEY DEPENDENCIES:
% lorentzian.m, relaxMtFitFunc.m
%
% SEE ALSO:
% relaxPreprocess.m to get raw DICOM data into the right format for
% this function.
%
% HISTORY:
% 2006.02.19 Nikola Stikov wrote it.
% 2007.01.?? NS recoded it to use lsqnonlin
% 2007.02.27 RFD rewrote the loop structure and data format.
% 2007.03.02 RFD slight performance enhancements. Also renamed
% several functions and added them all to the mrDiffusion
% repository.
%

if(~exist('dataDir','var')|isempty(dataDir))
  dataDir = pwd;
end

if(~exist('outDir','var')|isempty(outDir))
  outDir = dataDir;
end

if(~exist('voxRange','var')|isempty(voxRange))
  voxRange = '';
end

if(~exist(outDir,'dir'))
  mkdir(outDir);
end

disp(['Loading data from ' dataDir '...']);

ni = niftiRead(fullfile(dataDir,'T1.nii.gz'));
T1 = ni.data;
xform = ni.qto_xyz;
clear ni;
nz = T1>0;

if(exist(fullfile(dataDir,'brainMask.nii.gz'),'file'))
  ni = niftiRead(fullfile(dataDir,'brainMask.nii.gz'));
  brainMask = ni.data==1;
  clear ni;
else
  brainMask = nz;
end

%ni = niftiRead(fullfile(dataDir,'PD.nii.gz'));
%PD = ni.data;

ni = niftiRead(fullfile(dataDir,'S0.nii.gz'));
S0 = ni.data;
clear ni;

d = dir(fullfile(dataDir,'MT_*.nii.gz'));
delta = zeros(1,length(d));
for(ii=1:length(d))
  ni = niftiRead(fullfile(dataDir,d(ii).name));
  MT(:,:,:,ii) = ni.data;
  clear ni;
  % TODO: fix this crude hack. Maybe store offset freqs in nifti header?
  delta(ii) = sscanf(d(ii).name,'MT_%dkHz.nii.gz') ;
end
delta = delta'*1e3; % offset frequencies, in Hz

iterMax = 50; %maximum number of iterations allowed

sz = size(brainMask);

% Clip T1 and PD to reasonable values
% Tissue       T1 (s)          T2 (ms)        PD*
% CSF        0.8 - 20        110 - 2000    70 - 230
% White	    0.76 - 1.08       61 - 100 	   70 - 90
% Gray      1.09 - 2.15       61 - 109     85 - 125
% Meninges   0.5 - 2.2        50 - 165      5 - 44
% Muscle    0.95 - 1.82       20 - 67      45 - 90
% Adipose    0.2 - 0.75       53 - 94      50 - 100
% (PD values are based on PD=111 for 12mM aqueous NiCl2)
% (From http://www.cis.rit.edu/htbooks/mri/chap-8/chap-8.htm#8.7 )
% Our PDs seem to be scaled by 50 or so???
T1(T1<0.01) = 0.01;
T1(T1>10) = 10;
%PD(PD<0) = 0;
%PD(PD>12000) = 12000;

R1 = zeros(size(T1)); R1(nz) = 1./T1(nz);
%if(~exist(fullfile(dataDir,'R1.nii.gz'),'file'))
%  dtiWriteNiftiWrapper(single(R1),xform,fullfile(dataDir,'R1.nii.gz'));
%end

% Tidy-up the brain mask a bit
%brainMask(PD<1000|PD>10000|T1<0.2|T1>2|S0<20) = 0;
brainMask(T1<0.2|T1>2|any(MT==0,4)) = 0;

% RFD: empirically, [1 .08] is the median for brain tissue
x0 = [1 .08];
%x0 = [2.4, .10]'; %this is our initial guess, bese [3.4, .15]'

lb = [.1 .03]; % [k f]
ub = [5 .28];

t_m = 8e-3; %bese 8e-3
t_s = 5e-3; %bese 5e-3
t_r = 19e-3; %bese 19e-3
T2_B = 11e-6;
% Where does this come from? Should we estimate it from the data?
w1rms = 2400; % omega-1 RMS

for ii = 1:length(delta)
    W_B(ii) = pi*(w1rms^2)*lorentzian (delta(ii), T2_B);
end;

options = optimset('LevenbergMarquardt','on', 'Display', 'off');

% FOR DEBUGGING:
%showMontage(brainMask);

brainInds = find(brainMask);
numVoxelsPerUpdate = 10000;
nVoxAll = length(brainInds);
for(ii=1:size(MT,4))
  tmpVol = MT(:,:,:,ii);
  tmpMT(ii,:) = tmpVol(brainInds);
end
clear tmpVol;
MT = tmpMT;
clear tmpMT;
R1 = R1(brainInds);
S0 = S0(brainInds);

f = zeros(1,nVoxAll); 
k = zeros(1,nVoxAll);
gof = zeros(1,nVoxAll);
totalSecs = 0;
if(~isempty(voxRange))
  if(any(voxRange<0))
	doVox = [floor(nVoxAll*voxRange(1))+1:ceil(nVoxAll*voxRange(2))];
  else
	doVox = [max(1,voxRange(1)):min(nVoxAll,voxRange(2))];
  end
  fprintf('Processing voxels %d - %d...\n', doVox(1), doVox(end));
else
   doVox = [1:nVoxAll];
   fprintf('Processing all %d voxels...\n',nVoxAll);
end

% What we compute here is actually W_F./R1_F. R1_F is computed in
% the fit function, but we precompute the rest out here to save a
% few cpu cycles in the loop below.
W_F = (w1rms./(2*pi*delta)).^2/.055;

warning off;
nVox = doVox(end)-doVox(1);
tmp = zeros(size(brainMask));
tmpName = tempname
tic;
for(ii=doVox)
  if(mod(ii,numVoxelsPerUpdate)==0)
    prevSecs = toc;
    totalSecs = totalSecs+prevSecs;
    secsPerVox = totalSecs./(ii-doVox(1));
    estTime = secsPerVox*(doVox(end)-ii);
    if(estTime>5400) estTime=estTime./3600; estTimeUnits='hours';
    elseif(estTime>90) estTime=estTime./60; estTimeUnits='minutes';
    else estTimeUnits='seconds'; end
    fprintf('Processed %d of %d voxels- %0.1f %s remaining (%0.3f secs per vox)...\n',ii-doVox(1),nVox,estTime,estTimeUnits,secsPerVox);
	tmp(brainInds) = f;
    m = makeMontage(tmp,[1:5:size(tmp,3)]);
	m = uint8(round(m./max(f).*255));
	imwrite(m,['/home/bob/public_html/f.png']);
	save(tmpName,'k','f','gof','voxRange','xform');
    tic;
  end
  
  % Some voxels produce a "Input to EIG must not contain NaN
  % or Inf" error in lsqnonl in. Tweaking the bounds or
  % starting estimate can fix it sometimes, but they are
  % probably junk voxels anyway, so we'll catch and skip them.
  try
    %[x, resnorm, residual, exitflag, output] = lsqnonlin(@(x) relaxMtFitFunc(x, MT(:,ii), W_B, W_F, T2_B, R1(ii), S0(ii), t_m, t_s, t_r), x0, lb, ub, options); %bese j-12;
    [x, resnorm, exitflag] = fminsearch(@(x) relaxMtFitFuncLs(x, MT(:,ii), W_B, W_F, T2_B, R1(ii), S0(ii), t_m, t_s, t_r), x0, options);
    if(exitflag>0)
      k(ii) = x(1);
      f(ii) = x(2);
      gof(ii) = resnorm;
    else
      gof(ii) = NaN;
    end
  catch
    % Leave the fit values at zero.
  end
end
warning on;

fprintf('Finished processing %d slices (%d voxels) in %0.1f seconds.\n\n',sz(3),nVox,totalSecs);

if(isempty(voxRange))
   outName = '';
else
   outName = sprintf('%0.2f-%0.2f',voxRange(1),voxRange(2));
end
im=zeros(size(brainMask)); im(brainInds) = f; f = im;
im=zeros(size(brainMask)); im(brainInds) = k; k = im;
im=zeros(size(brainMask)); im(brainInds) = gof; gof = im;
try
   dtiWriteNiftiWrapper(single(f),xform,fullfile(outDir,[outName 'f.nii.gz']));
   dtiWriteNiftiWrapper(single(k),xform,fullfile(outDir,[outName 'k.nii.gz']));
   dtiWriteNiftiWrapper(single(gof),xform,fullfile(outDir,[outName 'gof.nii.gz']));
catch
   outName = tempname
   save(outName,'k','f','gof','voxRange','xform');
end
% FOR DEBUGGING:
keyboard;
return;

function relaxDespoT1Preprocess(s, outDir, mtOffsetFreqs, excludeScans, refImg)
%
% relaxPreprocess(dataDir, outDir, mtOffsetFreqs, excludeScans, refImg)
% 
% This file computes the T1 map (in seconds) of data obtained using
% the TOF sequence. Also saved are:
%   S0: unsaturated reference map
%   PD: a map that includes spin-density (M0), scanner scaling constant
%       (G), and T2*: PD = M0 * G * exp(-TE / T2*).
%
% SEE ALSO:
% 
% relaxAlignRefToAnat.m to align the reference image output by this
% function to a structural anatomy template image. 
% 
% relaxMtFit.m to fit the f and k maps to the output of this function.
%
% HISTORY:
% 2007.02.?? Nikola Stikov wrote it.
% 2007.03.01 RFD: restructured the code and added auto-detection of
% most scan params.


if(~exist('s','var')||isempty(s))
  s = fullfile(pwd,'raw');
end
if(~exist('outDir','var')||isempty(outDir))
  outDir = pwd;
end
if(~exist('mtOffsetFreqs','var')||isempty(mtOffsetFreqs))
  mtOffsetFreqs = [3 6 9 12];
  warning('Auto-detection of the mtOffsetFreqs is not implemented- using defaults.');
end
if(~exist('excludeScans','var')||isempty(excludeScans))
  excludeScans = [];
end
if(~exist('refImg','var')||isempty(refImg))
  refImg = 't1.nii.gz';
end

tr_inv = 700;
%tr_inv = 500;

showFigs = false;

if(ischar(s))
  s = dicomLoadAllSeries(s);
end

% Exclude scans that don't match most scans imSize
% $$$ for(ii=1:length(s))
% $$$   sz(ii) = prod(size(s(ii).imData));
% $$$ end
% $$$ badScans = find(sz~=median(sz));
% $$$ if(~isempty(badScans))
% $$$   disp(['Adding ' num2str(badScans) ' to exclude list due to size mis-match.']);
% $$$   excludeScans = [excludeScans badScans];
% $$$ end

%% Apply exclusion list
%
if(~isempty(excludeScans))
  s(excludeScans) = [];
end

if(showFigs)
  for(ii=1:length(s))
	showMontage(s(ii).imData);
	set(gcf,'name',[s(ii).seriesDescription '(' num2str(s(ii).seriesNum) ')']);
  end
end

%
% Sort out image types
%
seqenceNames = {s(:).sequenceName};
spgrInds = false(size(seqenceNames));
spgrInds(strmatch('3DGRASS',seqenceNames)) = 1;
fspgrInds = false(size(seqenceNames));
fspgrInds(strmatch('EFGRE3D',seqenceNames)) = 1;
goodInds = spgrInds | fspgrInds;
mtInds = [s(:).mtOffset]~=0 & spgrInds;
S0Inds = ~mtInds & spgrInds;
refInds = ~mtInds & ~S0Inds & fspgrInds;
tiInds = refInds & [s(:).inversionTime]>0;
t1Inds = refInds & ~tiInds;

% Figure out matrix size and inversion time
matSz = vertcat(s(t1Inds).acqMatrix);
acqMat = min(matSz(:,2))
allInversionTimes = [s(tiInds).inversionTime];
inversionTimes = unique(allInversionTimes);
% *** FIXME: deal with multiple inversion times!
ti = inversionTimes(1)

[s,xform] = relaxAlignAll(s, refImg);

%% Process the T1 relaxometry scans
%

meanOfT1s = mean(cat(4,s(refInds).imData),4);
showMontage(meanOfT1s);
[brainMask,checkSlices] = mrAnatExtractBrain(meanOfT1s,[],0.25);
%figure;image(checkSlices);
clear checkSlices;

% We save as we go
%xform = s(t1Inds(1)).imToScanXform;
dtiWriteNiftiWrapper(uint8(brainMask), xform, fullfile(outDir,'brainMask'));
dtiWriteNiftiWrapper(meanOfT1s, xform, fullfile(outDir,'ref'));
clear meanOfT1s;

tiInds = find(tiInds);
%for(ii=1:length(inversionTimes))
  tiFa = s(tiInds(allInversionTimes==ti)).flipAngle*pi/180;
  tiIm = mean(cat(4,s(tiInds(allInversionTimes==ti)).imData),4);
%  dtiWriteNiftiWrapper(ti, xform, fullfile(outDir,sprintf('TI_%02dms',inversionTimes(ii))));
%end

% Maybe save the aligned data here?
% save aligned s xform spgrInds fspgrInds t1Inds tiInds brainMask

allFlipAngles = [s(:).flipAngle];
flipAngles = unique(allFlipAngles(t1Inds));
%for(ii=1:length(flipAngles))
  %t1 = s(big&t1Inds&allFlipAngles==flipAngles(ii)).imData;
  %dtiWriteNiftiWrapper(t1, xform,fullfile(outDir,sprintf('T1_%02ddeg_256',flipAngles(ii))));
  %t1 = s(sm&t1Inds&allFlipAngles==flipAngles(ii)).imData;
  %dtiWriteNiftiWrapper(t1, xform,fullfile(outDir,sprintf('T1_%02ddeg_192',flipAngles(ii))));
%end

%% Process MT scans
%

%% Find and save the S0 map
%
n = sum(S0Inds);
if(n>0)
   if(n>1) 
      fprintf('Averaging %d S0 maps...\n',n);
      im = mean(cat(4,s(S0Inds).imData),4);
   else
	  im = s(S0Inds).imData;
   end
   disp('Saving S0 map...');
   dtiWriteNiftiWrapper(im, xform, fullfile(outDir,'S0'));
   clear im;
end

mtInds = find(mtInds);
nMt = numel(mtInds);
if(nMt>0)
  mtOffsets = unique(mtOffsetFreqs);
  for(ii=1:length(mtOffsets))
    mt = mean(cat(4,s(mtInds(mtOffsetFreqs==mtOffsets(ii))).imData),4);
    dtiWriteNiftiWrapper(mt, xform, fullfile(outDir,sprintf('MT_%02dkHz',mtOffsets(ii))));
  end
  clear mt;
end

%% Perform the T1 fitting procedure

%acqInds = [0 0 0 0 0 0 1 1 0 0 0 1 0];

for ii=1:length(flipAngles)
  curInd = t1Inds&allFlipAngles==flipAngles(ii);
  t1Data{ii} = s(curInd).imData;
  te(ii) = s(curInd).TE;
  tr(ii) = s(curInd).TR;
  alpha(ii) = s(curInd).flipAngle*pi/180;
end

t1Data{ii+1} = tiIm;

% This is the initial guess
x0 = [1000 50000 1]';

for(ii=1:numel(t1Data))
  brainMask = brainMask&t1Data{ii}>0;
end

brainInds = find(brainMask);
t1 = zeros(size(brainMask));
ro = zeros(size(brainMask));
k = zeros(size(brainMask));
err = zeros(size(brainMask));
converged = false(size(brainMask));
opt = optimset('Display','off');
n = numel(brainInds);
disp('Fitting model (SLOW!)...');
tic;
for(ii=1:n)
  bi = brainInds(ii);
  if(mod(ii,50000)==0) 
	fprintf('Finished %d of %d voxels in %0.1f min...\n',ii,n,toc/60);
	tmp = makeMontage(t1,[1:5:size(t1,3)]);
	tmp = tmp./1000;
	tmp(tmp<0)=0; tmp(tmp>5)=5; tmp=uint8(round(tmp./5.*255));
	imwrite(tmp,'/home/bob/public_html/t1.png');
  end
  for(jj=1:numel(t1Data)) dat(jj) = double(t1Data{jj}(bi)); end
  [tmp,fval,stat] = fminsearch(@(x) relaxDespoT1Err(x, dat, te, tr, ti, tiFa, alpha, tr_inv), x0, opt);
  t1(bi) = tmp(1);
  ro(bi) = tmp(2);
  k(bi) = tmp(3);
  err(bi) = fval;
  converged(bi) = stat==1;
end
fprintf('\nElapsed time: %0.1f min.\n',toc/60);
 
t1 = t1./1000; % this is because the mtfit wants T1 in seconds
t1(t1>5) = 5; t1(t1<0) = 0;
ro(ro>100000) = 100000;
k(k>10) = 10;

fname = sprintf('_%dacqmat_%dinvtime',acqMat,ti);
dtiWriteNiftiWrapper(t1,xform,fullfile(outDir,['T1' fname]));
dtiWriteNiftiWrapper(ro,xform,fullfile(outDir,['PD' fname]));
dtiWriteNiftiWrapper(k,xform,fullfile(outDir,['flipAngleCorrection' fname]));
dtiWriteNiftiWrapper(err,xform,fullfile(outDir,['err' fname]));
dtiWriteNiftiWrapper(uint8(converged),xform,fullfile(outDir,['converged' fname]));

showMontage(t1,[7:60],[],round(256.*[.2 .8; .1 .9]));
mrUtilPrintFigure(fullfile(outDir,'T1.png'),gcf,120);
showMontage(ro,[7:60],[],round(256.*[.2 .8; .1 .9]));
mrUtilPrintFigure(fullfile(outDir,'PD.png'),gcf,120);
showMontage(k,[7:60],[],round(256.*[.2 .8; .1 .9]));
mrUtilPrintFigure(fullfile(outDir,'flipAngleCorrection.png'),gcf,120);

return;

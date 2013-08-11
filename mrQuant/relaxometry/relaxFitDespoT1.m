function flipBias = relaxFitDespoT1(s,mask)
%
% flipBias = relaxFitDespoT1(s, brainMask)
% 
%
% SEE ALSO:
% 
%
% HISTORY:
% 2007.09.14 Nikola and Bob wrote it.


%%
% Do the full Deoni model fit on low-res data and fit a smooth template to the flip
% angle correction map.

%
% Sort out image types
%
seqenceNames = {s(:).sequenceName};
fspgrInds = false(size(seqenceNames));
fspgrInds(strmatch('EFGRE3D',seqenceNames)) = 1;
tiInds = fspgrInds & [s(:).inversionTime]>0;
t1Inds = fspgrInds & ~tiInds;

allFlipAngles = [s(:).flipAngle]*pi/180;
t1Fa = allFlipAngles(t1Inds);
tiFa = allFlipAngles(tiInds);
te = [s(t1Inds).TE];
tr = [s(t1Inds).TR];
ti = s(tiInds).inversionTime;

% Set the tr of the inversion pulses for the IR-Prep scan
%tr_inv = 700;
% Deoni's method for computing tr_inv:
tr_inv = ti + 64*s(tiInds).TR;

reductionIter = 3;

% Undersample data for initial Deoni model fit
lresMask = single(mask);
for(ii=1:reductionIter)
   lresMask = GPReduce(lresMask);
end
lresMask = lresMask>0.5;
brainInds = find(lresMask);
lresData = zeros(numel(brainInds),sum(t1Inds|tiInds));
t1IndList = find(t1Inds);
for(ii=1:length(t1IndList))
   tmpIm = double(s(t1IndList(ii)).imData);
   for(jj=1:reductionIter)
      tmpIm = GPReduce(tmpIm);
   end
   lresData(:,ii) = tmpIm(brainInds);
end
% add the IR-prep data to the end
tmpIm = double(s(tiInds).imData);
for(jj=1:reductionIter)
   tmpIm = GPReduce(tmpIm);
end
lresData(:,end) = tmpIm(brainInds);

%%
% Now, fit the model
%
lresT1 = zeros(size(lresMask));
lresRo = zeros(size(lresMask));
lresK = zeros(size(lresMask));
lresErr = zeros(size(lresMask));
lresConverged = zeros(size(lresMask),'uint8');
%opt = optimset('Display','off');
opt = optimset('LevenbergMarquardt','on', 'Display', 'off');
n = numel(brainInds);
% This is the initial guess
x0 = [1000 5e4 1]';
lb = [100 1e3 0.8]';
ub = [3000 1e6 1.2];
disp('Fitting Deoni model (SLOW!)...');
tic;
progStep = round(n/10);
for(ii=1:n)
  if(mod(ii,progStep)==0) 
    fprintf('Finished %d of %d voxels in %0.1f min (%0.1f%%)...\n',ii,n,toc/60,ii/n*100);
  end
  %[tmp,fval,stat] = fminsearch(@(x) relaxDespoT1Err(x, lresData(ii,:), te, tr, ti, tiFa, t1Fa, tr_inv), x0, opt);
  [tmp,fval,resid,stat] = lsqnonlin(@(x) relaxDespoT1ErrLs(x, lresData(ii,:), te, tr, ti, tiFa, t1Fa, tr_inv), x0, lb, ub, opt);
  lresResid(ii,:) = resid;
  lresT1(brainInds(ii)) = tmp(1);
  lresRo(brainInds(ii)) = tmp(2);
  lresK(brainInds(ii)) = tmp(3);
  lresErr(brainInds(ii)) = fval;
  lresConverged(brainInds(ii)) = stat==1;
end
fprintf('\nElapsed time: %0.1f sec.\n',toc);
% fill out non-brain regions of k with the k value from the closest
% voxel. We simply find the x,y,z of brain and non-brain voxels and
% then use nearpoints to pair each non-brain voxel with the closest
% (Euclidian distance) brain voxel.
[bx,by,bz] = ind2sub(size(lresMask),brainInds);
bxyz = [bx';by';bz'];
clear bx by bz;
nonBrainInds = find(~lresMask);
[nbx,nby,nbz] = ind2sub(size(lresMask),nonBrainInds);
nbxyz = [nbx';nby';nbz'];
clear nbx nby nbz;
% Rather than take the single nearest, we'll take the mean of the 2
% nearst brain voxels.
iter = 3;
lresK(nonBrainInds) = 0;
for(ii=1:iter)
  closestInd = nearpoints(nbxyz,bxyz);
  for(jj=1:3) bxyz(jj,closestInd) = -999; end
  lresK(nonBrainInds) = lresK(nonBrainInds)+lresK(brainInds(closestInd));
end
lresK(nonBrainInds) = lresK(nonBrainInds)./iter;
clear closestInd nonbrainInds nbxyz bxyz;
lresKSm = smooth3(lresK,'gaussian',[3 3 3]);

flipBias = lresKSm;
for(jj=1:reductionIter)
   flipBias = GPExpand(flipBias);
end
npad = (size(flipBias)-size(mask))/2;
flipBias = flipBias(1+floor(npad(1)):end-ceil(npad(1)),1+floor(npad(2)):end-ceil(npad(2)),1+floor(npad(3)):end-ceil(npad(3)));
flipBias(~mask) = 1;

return;



brainInds = find(mask);
n = numel(brainInds);


%theta = [s(:).flipAngle].*pi/180 .* flipBias;
theta = [s(t1Inds).flipAngle].*pi/180;
% All TR's should be the same!
TR = s(1).TR;
nT1 = numel(theta);

%% DEONI T1 FIT USING FIXED K
%
%
data = zeros(n,sum(t1Inds|tiInds));
for(ii=1:length(t1IndList))
   tmpIm = double(s(t1IndList(ii)).imData);
   data(:,ii) = tmpIm(brainInds);
end
% add the IR-prep data to the end
tmpIm = double(s(tiInds).imData);
data(:,end) = tmpIm(brainInds);

T1_img = zeros(size(mask));
Ro_img = zeros(size(mask));
K_img = zeros(size(mask));
Err = zeros(size(mask));
Converged = zeros(size(mask),'uint8');
opt = optimset('Display','off');
% This is the initial guess
x0 = [1000 5e4 1]';
lb = [100 1e4 0.9]';
ub = [3000 1e5 1.1];
disp('Fitting Deoni model (SLOW!)...');
progStep = round(n/1000);
saveStep = round(n/10);
tmpFile = '/tmp/relaxFitDespoT1';
tic;
for(ii=1:n)
  if(mod(ii,progStep)==0) 
    fprintf('Finished %d of %d voxels in %0.1f min (%0.1f%%)...\n',ii,n,toc/60,ii/n*100);
  end
  if(mod(ii,saveStep)==0) 
    save(tmpFile, 'mask','T1_img','Ro_img','K_img','Err','Converged');
  end
  % We should fix our mask so that this doesn't happen...
  if(any(data(ii,:)==0)) continue; end
  [tmp,fval,stat] = fminsearch(@(x) relaxDespoT1Err(x, data(ii,:), te, tr, ti, tiFa, t1Fa, tr_inv, k_full(brainInds(ii))), x0(1:2), opt);
  %[tmp,fval,stat] = lsqnonlin(@(x) relaxDespoT1Err(x, data(ii,:), te, tr, ti, tiFa, t1Fa, tr_inv), x0, lb, ub, opt);
  T1_img(brainInds(ii)) = tmp(1);
  Ro_img(brainInds(ii)) = tmp(2);
  %K_img(brainInds(ii)) = tmp(3);
  Err(brainInds(ii)) = fval;
  Converged(brainInds(ii)) = stat==1;
end
fprintf('\nElapsed time: %0.1f sec.\n',toc);

clear data;

%% LINEAR T1 FIT
%
% Fit a line to the data in each voxel to estimate T1.
% We'll use an eigenvector formulation since we already have a 
% vectorized eigenvector decompostion coded up.

% Build a matrix M where M = [x1-x0 y1-y0; x2-x0 y2-y0; ... xn-x0 yn-y0]. 
% To make it work with ndfun, we need to reshape things a bit.
M = zeros(nT1,2,n);
for(ii=1:nT1)
  correctedFlip = theta(ii).*k_full(brainInds);
  %correctedFlip = theta(ii);
  M(ii,1,:) = abs(s(t1IndList(ii)).imData(brainInds)./tan(correctedFlip));
  M(ii,2,:) = abs(s(t1IndList(ii)).imData(brainInds)./sin(correctedFlip));
end
M0 = mean(M,1);
for(ii=1:size(M,1))
  M(ii,:,:) = M(ii,:,:) - M0;
end
% The best-fitting line is the eigenvector corresponding to
% the largest eigenvalue of eig(M'*M):
[vec,val] = ndfun('eig',ndfun('mult',permute(M,[2 1 3]),M));
% The slope (m) of the line is simply the ratio of y to x and the
% intercept (b) is y-m*x
% Note that the eigenvalues from ndfun are sorted in descending
% order, opposite from Matlab's 'eig'.
m = vec(2,1,:)./vec(1,1,:);
b = M0(:,2,:)-m.*M0(:,1,:);

% *** CHECK THIS
%m(m<=0) = NaN;
m = abs(m);

T1 = (-TR/1000)/log(m);
% Clip to plausible values
T1(isnan(T1)|T1<0.1) = 0.1;
T1(T1>5) = 5;

PD = b./(1-m);
PD(PD>5e5) = 5e5;
T1_img = zeros(size(mask));
T1_img(brainInds) = T1;
PD_img = zeros(size(mask));
PD_img(brainInds) = PD;
dtiWriteNiftiWrapper(single(T1_img), xform, fullfile(outDir,'T1.nii.gz'));
dtiWriteNiftiWrapper(single(PD_img), xform, fullfile(outDir,'PD.nii.gz'));
dtiWriteNiftiWrapper(single(k_full), xform, fullfile(outDir,'K.nii.gz'));

if(0)
% Test the two methods on a single voxel:
x=74;y=128;z=100;
for(ii=1:length(t1IndList)), data(ii)=double(s(t1IndList(ii)).imData(y,x,z)); end
data(:,end+1) = double(s(tiInds).imData(y,x,z));
[tmp,fval,stat] = fminsearch(@(x) relaxDespoT1Err(x, data, te, tr, ti, tiFa, t1Fa, tr_inv), x0, opt);
vT1 = tmp(1)/1000; vRo = tmp(2); vK = tmp(3);
fa = theta.*vK;
dx = abs(data(1:4)./tan(fa));
dy = abs(data(1:4)./sin(fa));
p = polyfit(dx,dy,1);
lT1 = (-TR/1000)/log(p(1));
lRo = p(2);
end

if(0)
% compare wm/gm
wm = niftiRead('whiteMatterMask.nii.gz');
wm = uint8(wm.data);
wm(wm==3) = 16;
wm(wm==1) = 48;
t1=niftiRead('T1.nii.gz');
v=uint8(wm); v(v>0)=16; 
gm_nodes = grow_gray(v,5);
gm = zeros(size(v));
gm(sub2ind(size(v),gm_nodes(1,:),gm_nodes(2,:),gm_nodes(3,:))) = 1;
figure;
subplot(2,1,1);
hist(t1.data(wm(:)==16),100);
subplot(2,1,2); 
hist(t1.data(gm(:)==1),100);
end

if(0)
%% Process the MT scans
%
dataDir = '/biac3/wandell4/data/relaxometry/mbs071211';
ref = '/biac3/wandell4/data/reading_longitude/dti_adults/mbs040503/t1/t1.nii.gz';
outDir = dataDir;

% Load all the series in the struct 's'
s = dicomLoadAllSeries(fullfile(dataDir,'raw'));

% Align all the series to this subject's reference volume
[s,xform,alignInds] = relaxAlignAll(s,ref);

% Find the MT offset scans (based on the series description text) and save
% them out. The S0 is an "MT" scan with an offset of 0.
for(ii=1:alignInds)
  tok = regexp(s(ii).seriesDescription,'_(\d*)kH','tokens');
  mtDelta = str2double(tok{1});
  if(mtDelta==0)
	fname = fullfile(outDir,'S0');
  else
	fname = fullfile(outDir,sprintf('MT_%02dkHz',mtDelta));
  end
  dtiWriteNiftiWrapper(s(ii).imData, xform, fname);
end
end


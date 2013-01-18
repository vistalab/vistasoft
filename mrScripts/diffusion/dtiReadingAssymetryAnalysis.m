addpath('/home/bob/matlab/stats/');
[f,sc] = findSubjects('','_dt6',{'es041113','tk040817'});
N = length(f);
outDir = '/teal/scr1/dti/assymetry';

h=figure(99);
pause(0.5);

for(ii=1:N)
  disp(['Computing assymetry maps for ' sc{ii} '...']);
  roiPath = fullfile(fileparts(f{ii}), 'ROIs');
  dt = load(f{ii});
  % *** TO DO: we could find the optimal mid-sagittal split by
  % coregistering the two halves to minimize error.
  cc(ii) = dtiReadRoi(fullfile(roiPath,'CC_FA'));
  ccMean = mean(cc(ii).coords);
  midSag = inv(dt.xformToAcPc)*[ccMean 1]';
  midSag = round(midSag(1));
  [eVec,eVal] = dtiSplitTensor(dt.dt6);
  pdd = squeeze(eVec(:,:,:,[1 2 3],1));
  clear eVec;
  fa = dtiComputeFA(eVal);
  clear eVal;
  b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.995);
  
  sz = size(fa);
  nLR = 40;
  [X,Y,Z] = ndgrid([1:midSag-1], [1:sz(2)], [1:sz(3)]);
  leftInds = sub2ind(sz, X(:), Y(:), Z(:));
  [X,Y,Z] = ndgrid([midSag+1:sz(1)], [1:sz(2)], [1:sz(3)]);
  rightInds = sub2ind(sz, X(:), Y(:), Z(:));
  n = length(leftInds)/3;
  for(jj=1:3)
    tmp = pdd(:,:,:,jj);
    lpdd(:,:,:,jj) = reshape(tmp(leftInds), nLR, sz(2), sz(3));
    rpdd(:,:,:,jj) = reshape(tmp(rightInds), nLR, sz(2), sz(3));
  end
  lfa = reshape(fa(leftInds), nLR, sz(2), sz(3));
  rfa = reshape(fa(rightInds), nLR, sz(2), sz(3));
  lb0 = reshape(b0(leftInds), nLR, sz(2), sz(3));
  rb0 = reshape(b0(rightInds), nLR, sz(2), sz(3));
  
  % Mirror-flip the left-right axis for the righ hemi
  rfa = flipdim(rfa,1);
  rb0 = flipdim(rb0,1);
  rpdd = flipdim(rpdd,1);
  % For Vectors, we might want to flip the vector direction about the midline
  %rpdd(:,:,:,1) = -rpdd(:,:,:,1);
  %rpdd(:,:,:,2) = -rpdd(:,:,:,2);
  
  mask = zeros(sz);
  delta = lb0>0.1 & lfa>0.05 & rb0>0.1 & rfa>0.05;
  delta = dtiCleanImageMask(delta, 7);
  mask(leftInds) = delta;
  mask(rightInds) = flipdim(delta,1);
 
  % compute angle difference between left/right PDD
  delta = acos(dot(lpdd, rpdd, 4));
  delta = reshape(delta, nLR, sz(2), sz(3));
  pdd = zeros(sz);
  pdd(leftInds) = delta;
  pdd(rightInds) = flipdim(delta,1);
  pdd(~mask) = 0;
  %figure(h);subplot(3,1,1);
  %imagesc(makeMontage(pdd,[20:60]));colormap(hot);axis image;colorbar;title(sc{ii});
  
  delta = acos(dot(abs(lpdd), abs(rpdd), 4));
  delta = reshape(delta, nLR, sz(2), sz(3));
  abspdd = zeros(sz);
  abspdd(leftInds) = delta;
  abspdd(rightInds) = flipdim(delta,1);
  abspdd(~mask) = 0;
  
  fa(:) = 0;
  delta = lfa-rfa;
  fa(leftInds) = delta;
  fa(rightInds) = flipdim(delta,1);  

  b0(:) = 0;
  delta = lb0-rb0;
  b0(leftInds) = delta;
  b0(rightInds) = flipdim(delta,1); 
  
  % Spatially normalize the symetry maps
  sn = dt.t1NormParams(2).sn;
  tMm = sqrt(sum(sn.VG(1).mat(1:3,1:3).^2));
  tOrig  = sn.VG.mat\[0 0 0 1]';
  tOrig  = tOrig(1:3)';
  bb = [-tMm .* (tOrig-1) ; tMm.*(sn.VG(1).dim(1:3)-tOrig)];
  og  = -tMm .* tOrig;
  M1  = [tMm(1) 0 0 og(1) ; 0 tMm(2) 0 og(2) ; 0 0 tMm(3) og(3) ; 0 0 0 1];
  outMmPerVox = [2 2 2];
  of  = -outMmPerVox.*(round(-bb(1,:)./outMmPerVox)+1);
  M2  = [outMmPerVox(1) 0 0 of(1) ; 0 outMmPerVox(2) 0 of(2) ; 0 0 outMmPerVox(3) of(3) ; 0 0 0 1];
  d.inMat = inv(sn.VG(1).mat*inv(M1)*M2);
  dField = mrAnatSnToDeformation(sn, dt.mmPerVox, bb);
  d.deformX = dField(:,:,:,1);
  d.deformY = dField(:,:,:,2);
  d.deformZ = dField(:,:,:,3);
  clear dField;
  d.outMat = inv(dt.xformToAcPc);
  [npdd,xf] = mrAnatResliceSpm(pdd, d, bb, dt.mmPerVox, [1 1 1 0 0 0], 0);
  npdd(isnan(npdd)) = 0;
  [nabspdd,xf] = mrAnatResliceSpm(abspdd, d, bb, dt.mmPerVox, [1 1 1 0 0 0], 0);
  nabspdd(isnan(nabspdd)) = 0;
  [nfa,xf] = mrAnatResliceSpm(fa, d, bb, dt.mmPerVox, [1 1 1 0 0 0], 0);
  nfa(isnan(nfa)) = 0;
  [nb0,xf] = mrAnatResliceSpm(b0, d, bb, dt.mmPerVox, [1 1 1 0 0 0], 0);
  nb0(isnan(nb0)) = 0;
  [nmask,xf] = mrAnatResliceSpm(mask, d, bb, dt.mmPerVox, [1 1 1 0 0 0], 0);
  nmask(isnan(nmask)) = 0;
  figure(h);subplot(2,2,1);
  imagesc(makeMontage(npdd,[20:60]));colormap(hot);axis image;colorbar;
  figure(h);subplot(2,2,2);hist(npdd(logical(nmask(:)>=0.5)),100);
  title(sprintf('%0.2f', mean(npdd(logical(nmask(:)>=0.5)))));
  figure(h);subplot(2,2,3);
  imagesc(makeMontage(nabspdd,[20:60]));colormap(hot);axis image;colorbar;
  figure(h);subplot(2,2,4);hist(nabspdd(logical(nmask(:)>=0.5)),100);
  title(sprintf('%0.2f', mean(nabspdd(logical(nmask(:)>=0.5)))));
  refresh(h);;
  save(fullfile(outDir,[sc{ii} '_assymMaps']), 'pdd', 'abspdd', 'fa', 'b0', 'mask', ...
       'npdd', 'nabspdd', 'nfa', 'nb0', 'nmask');
  % Save as analyze?
end

am = load(fullfile(outDir,[sc{1} '_assymMaps']));
sz = size(am.nfa);
pdd = zeros([sz N]);
apdd = zeros([sz N]);
fa = zeros([sz N]);
b0 = zeros([sz N]);
mnMask = ones(sz);
mask = zeros([sz N]);
for(ii=1:N)
  disp(['Loading assymetry maps for ' sc{ii} '...']);
  am = load(fullfile(outDir,[sc{ii} '_assymMaps']));
  % wrap to 0-pi/2, since the PDD is sign-invariant.
  wrapThese = am.npdd>pi/2;
  am.npdd(wrapThese) = am.npdd(wrapThese)-pi/2;
  pdd(:,:,:,ii) = am.npdd;
  apdd(:,:,:,ii) = am.nabspdd;
  b0(:,:,:,ii) = am.nb0;
  fa(:,:,:,ii) = am.nfa;
  %pdd(:,:,:,ii) = dtiSmooth3(am.npdd,3);
  %apdd(:,:,:,ii) = dtiSmooth3(am.nabspdd,3);
  %b0(:,:,:,ii) = dtiSmooth3(am.nb0,3);
  %fa(:,:,:,ii) = dtiSmooth3(am.nfa,3);  
  mask(:,:,:,ii) = am.nmask;  
  mnMask = mnMask & am.nmask>0.5;
end
mnB0 = mean(b0,4);
sdB0 = std(b0,0,4)+0.00000001;
zB0 = mnB0./sdB0;
mnFa = mean(fa,4);
sdFa = std(fa,0,4)+0.00000001;
zFa = mnFa./sdFa;
mnPdd = mean(pdd,4);
sdPdd = std(pdd,0,4)+0.00000001;
zPdd = mnPdd./sdPdd;
mnAPdd = mean(apdd,4);
sdAPdd = std(apdd,0,4)+0.00000001;
zPdd = mnPdd./sdPdd;
figure(50);imagesc(makeMontage(mnPdd,[20:60]));axis image;colorbar;title('mean PDD');
figure(51);imagesc(makeMontage(sdPdd,[20:60]));axis image;colorbar;title('stdev PDD');
figure(52);imagesc(makeMontage(zPdd,[20:60]));axis image;colorbar;title(['zPDD']);
figure(53);imagesc(makeMontage(zFa,[20:60]));axis image;colorbar;title('zFA');
figure(54);imagesc(makeMontage(zB0,[20:60]));axis image;colorbar;title(['zB0']);

[behData,colNames] = dtiGetBehavioralData(sc);
behIndex = 6;

figure;hist(pdd(mask(:)>=0.5),100);
title(sprintf('Delta PDD (mean=%0.3f)', mean(pdd(mask(:)>=0.5))));

totalAssym = zeros(1,N);
for(ii=1:N)
  tmp = pdd(mask(:,:,:,ii)>=0.5);
  totalAssym(ii) = mean(tmp);
end

% Compute correlations

%symZ = (apdd-repmat(mnAPdd, [1 1 1 N]))./repmat(sdAPdd,[1 1 1 N]);
symZ = (pdd-repmat(mnPdd, [1 1 1 N]))./repmat(sdPdd,[1 1 1 N]);
%symZ = (fa-repmat(mnFa, [1 1 1 N])) ./ repmat(sdFa, [1 1 1 N]);
%symZ = (b0-repmat(mnB0, [1 1 1 N])) ./ repmat(sdB0, [1 1 1 N]);
beh = behData(:,behIndex);
mnBeh = mean(beh);
sdBeh = std(beh);
behZ = (beh-mnBeh) ./ sdBeh;
r = zeros(size(mnPdd));
for(ii=1:N)
    r = r + symZ(:,:,:,ii).*behZ(ii);
end
r = r./(N-1);
r(~mnMask) = 0;

% compute Fischer's z': Z = 0.5*(log(1+r)-log(1-r));
% std err of Fishcer's z is 1/sqrt(n-3)
Z = 0.5*(log((1+r)./(1-r)));
df = N-3;
p = erfc((abs(Z)*sqrt(df))/sqrt(2));
%p = normpdf(Z,0,1/sqrt(df))
pn = -log10(p);
pn(pn>10) = 10;

%figure;hist(Z(mnMask(:)),100);
%title(sprintf('Fischer''s z (mean=%0.3f)', mean(Z(mnMask(:)))));

q = 0.2;
p_sorted = sort(p(mnMask(:)));
numP = length(p_sorted);
I = [1:numP]'./numP*q;
cVID = 1;
pID = p_sorted(max(find(p_sorted<=I/cVID)));
%cVN = sum(1./(1:numP));
%pN = p_sorted(max(find(p_sorted<=I/cVN)));
%H = fdrEmpDistr(Z(:), .01);
%H0 = fdrTheoNull(H, 't', df);
%[thr, fdrCurve] = fdrThresh({'FDR',1}, H, H0, 0.1);
%pThresh = spm_P_FDR(Z(:),[df],'Z',1,p_sorted);
pn(~mnMask) = 0;
figure;imagesc(makeMontage(pn,[20:60]));axis image;colorbar;

% There is an assymetry/PA correlation at image coord [15 41 31]
% (acpc coord [-51 -39 1]) which is on the posterior inferior 
% temporal gyrus. Fiber tracking shows this region as clearly part 
% of the arcuate, connecting MTG with frontal (language?) regions.

return;

% MTG location:
c = [15 41 31]; % acpc = [-51 -39 1]
% lateral occipital location:
%c = [27 20 36];
% ILF:
c = [60 47 28]; % acpc = [38 -26 -5];
for(behIndex=1:length(colNames))
  assymIndex = squeeze(b0(c(1), c(2), c(3), :));
  gv = ~isnan(behData(:,behIndex)) & ~isnan(assymIndex);
  [s.p,s.r,s.df] = statTest(assymIndex(gv), behData(gv,behIndex), 'r');
  if(s.p<0.0001) sig='***';
  elseif(s.p<0.001) sig='**';
  elseif(s.p<0.01) sig='*';
  else sig=''; end
  msg = sprintf('%s %s (r=%0.2f, p=%0.5f, df=%d)', sig, colNames{behIndex}, s.r, s.p, s.df);
  disp(msg);
end
behIndex = 6;
figure; scatter(assymIndex, behData(:,behIndex));
title(msg);

%txform = eye(4); txform(4,1:3) = [-81 -121 -61]';
txform = dt.xformToAcPc;
upsamp = 1;
imPerRow = 7;
firstIm = 20;
sp=ginput(1)./upsamp;y=mod(sp(1),sz(2));x=mod(sp(2),sz(1));z=floor(sp(2)/sz(1))*imPerRow+floor(sp(1)/sz(2))+firstIm;c=round([x y z]);acpc=mrAnatXformCoords(txform,c);
fprintf(['motage coords = [%0.1f %0.1f]; Image coords = [%0.1f %0.1f ' ...
'%0.1f]; AcPc coords = [%0.1f %0.1f %0.1f]\n'], sp, x, y, z, acpc);


%Threshold probs
p_norm = -log10(p);
p_norm = p_norm./max(p_norm(:));
p_norm = round(p_norm*255+1);

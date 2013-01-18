function [f,k,s0,gof] = relaxFitMtDist(data,delta,t1,s0,tr,flipAngle,brainMask,fitMethod,outMontage)
%
% [f,k,s0,gof] = relaxFitMtDist(data,delta,t1,s0,tr,flipAngle,brainMask,fitMethod,outMontage)
% 
% Computes a nonlinear fit of the bound-pool (f) map.
%
% Returns:
%
% SEE ALSO:
% 
% relaxFitT1.m to fit the t1 and pd maps used by this function.
%
% HISTORY:
% 2008.02.26 RFD: wrote it.

if(~exist('fitMethod','var')||isempty(fitMethod))
    fitMethod = 'fmin';
end
if(lower(fitMethod(1))=='p')
    fitMethod = fitMethod(2:end);
    useParfor = true;
else
    useParfor = false;
end
fitMethod = lower(fitMethod(1));

if(~exist('outMontage','var')||isempty(outMontage))
    outMontage = 'f.png';
end

flipAngle = flipAngle*pi/180;
tr = tr/1000;
sz = size(data);

% disp('smoothing s0 map...');
% deltaT = 1/44;
% kappa = 200;
% s0 = dtiSmoothAnisoPM(s0, 4, deltaT, kappa, 1, [1 1 1]);
% 
%disp('smoothing MT measurments...');
%kappa = 50;
%for(ii=1:sz(4))
%    data(:,:,:,ii) = dtiSmoothAnisoPM(data(:,:,:,ii), 2, deltaT, kappa, 1, [1 1 1]);
%end

brainInds = find(brainMask);
numVoxelsPerUpdate = 16000;
nVoxAll = length(brainInds);
for(ii=1:size(data,4))
  tmpVol = data(:,:,:,ii);
  tmpMT(ii,:) = tmpVol(brainInds);
end
clear tmpVol;
data = tmpMT;
clear tmpMT;
r1 = 1./t1(brainInds);
s0 = s0(brainInds);

f = zeros(1,nVoxAll); 
k = zeros(1,nVoxAll);
gof = zeros(1,nVoxAll);
totalSecs = 0;

tmpImg = zeros(sz(1:3));
tmpName = tempname
nSteps = ceil(nVoxAll/numVoxelsPerUpdate);
totalTime = 0;
tic;
for(ii=1:nSteps)
    if(useParfor), matlabpool; end
    curInd = (ii-1)*numVoxelsPerUpdate+1;
    endInd = min(curInd+numVoxelsPerUpdate,nVoxAll);
    [tf,tk,tgof] = relaxFitMt(data(:,curInd:endInd),delta,r1(curInd:endInd),s0(curInd:endInd),tr,flipAngle,fitMethod,useParfor);
    prevSecs = toc;
    totalTime = totalTime+prevSecs;
    f(curInd:endInd) = tf;
    k(curInd:endInd) = tk;
    gof(curInd:endInd) = tgof;
    secsPerVox = prevSecs/(endInd-curInd+1);
    estTime = secsPerVox*(nVoxAll-endInd);
    if(estTime>5400) estTime=estTime./3600; estTimeUnits='hours';
    elseif(estTime>90) estTime=estTime./60; estTimeUnits='minutes';
    else estTimeUnits='seconds'; 
    end
    fprintf('Processed %d of %d voxels- %0.1f %s remaining (%0.3f secs per vox)...\n',endInd,nVoxAll,estTime,estTimeUnits,secsPerVox);
    tmpImg(brainInds) = f;
    m = makeMontage(tmpImg);
    if(max(f)>0), m = m./max(f); end
    m = uint8(round(m.*255));
    imwrite(m,outMontage);
    save(tmpName,'k','f','gof','brainMask');
    tic;
    if(useParfor), matlabpool close; end
end
fprintf('Processed %d voxels in %0.2f hours.\n',totalTime/3600);

% f = vertcat(tf);
% k = vertcat(tk);
% gof = vertcat(tgof);

im=zeros(size(brainMask)); im(brainInds) = f; f = im;
im=zeros(size(brainMask)); im(brainInds) = k; k = im;
im=zeros(size(brainMask)); im(brainInds) = gof; gof = im;
im=zeros(size(brainMask)); im(brainInds) = s0; s0 = im;

return;

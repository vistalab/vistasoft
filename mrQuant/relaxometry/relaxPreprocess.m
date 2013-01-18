function relaxPreprocess(dataDir, outDir, mtOffsetFreqs, excludeScans)
%
% relaxPreprocess(dataDir, outDir, mtOffsetFreqs, excludeScans)
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


if(~exist('dataDir','var')||isempty(dataDir))
  dataDir = fullfile(pwd,'raw');
end
if(~exist('outDir','var')||isempty(outDir))
  outDir = fileparts(dataDir);
  if(isempty(outDir)) outDir = pwd; end
end
if(~exist('mtOffsetFreqs','var')||isempty(mtOffsetFreqs))
  mtOffsetFreqs = [];
  error('Auto-detection of the mtOffsetFreqs is not implemented yet!');
end
if(~exist('excludeScans','var')||isempty(excludeScans))
  excludeScans = [];
end

showFigs = false;

s = dicomLoadAllSeries(dataDir);

% Exclude scans that don't match most scans imSize
for(ii=1:length(s))
  sz(ii) = prod(size(s(ii).imData));
end
badScans = find(sz~=median(sz));
if(~isempty(badScans))
  disp(['Adding ' num2str(badScans) ' to exclude list due to size mis-match.']);
  excludeScans = [excludeScans badScans];
end

%% Apply exclusion list
%
if(~isempty(excludeScans))
  s(excludeScans) = [];
end

if(showFigs)
    for(ii=1:length(s))
        showMontage(s(ii).imData);
        set(gcf,'name',[s(ii).desc '(' num2str(s(ii).seriesNum) ')']);
    end
end

% Align all the images
disp('Aligning all series to the first...');
bb = [1 1 1; size(s(1).imData)];
for(ii=2:length(s))
    xform = mrAnatRegister(s(ii).imData,s(1).imData);
    s(ii).imData =  mrAnatResliceSpm(s(ii).imData, xform, bb, [1 1 1], [7 7 7 0 0 0], 0);
    s(ii).imData(isnan(s(ii).imData)|s(ii).imData<0) = 0;
end

%% Process the T1 relaxometry scans
%
t1Inds = find([s.mtOffset]==0);
nT1 = length(t1Inds);

meanOfT1s = mean(cat(4,s(t1Inds).imData),4);
%showMontage(mn);
[brainMask,checkSlices] = mrAnatExtractBrain(meanOfT1s,[],0.25);
%figure;image(checkSlices);

% We save as we go
xform = s(t1Inds(1)).imToScanXform;
dtiWriteNiftiWrapper(uint8(brainMask), xform, fullfile(outDir,'brainMask'));
dtiWriteNiftiWrapper(meanOfT1s, xform, fullfile(outDir,'ref'));
clear meanOfT1s;

brainInds = find(brainMask);
nVox = length(brainInds);

%% Process MT scans
%
% For these, we average multiple repeats/
mtInds = find([s.mtOffset]~=0);
nMt = length(mtInds);

% for(ii=1:length(mtInds)), for(jj=1:length(mtInds))
% 	rms(ii,jj) = sqrt(mean((s(mtInds(ii)).imData(brainInds)-s(mtInds(jj)).imData(brainInds)).^2));
% end, end
mtOffsets = unique(mtOffsetFreqs);
for(ii=1:length(mtOffsets))
    mt = mean(cat(4,s(mtInds(mtOffsetFreqs==mtOffsets(ii))).imData),4);
    dtiWriteNiftiWrapper(mt, xform, fullfile(outDir,sprintf('MT_%02dkHz',mtOffsets(ii))));
end
clear mt;

theta = [s(t1Inds).flipAngle]*pi/180;
x = zeros(nVox,nT1);
y = zeros(nVox,nT1);
for(ii=1:nT1)
  y(:,ii) = abs(s(t1Inds(ii)).imData(brainInds)./sin(theta(ii)));
  x(:,ii) = abs(s(t1Inds(ii)).imData(brainInds)./tan(theta(ii)));
end

% Following is a slow loop. Can it be vectorized?
disp('Fitting T1 estimates for each voxel (SLOW!)');
t1 = zeros(nVox,1);
tic;
for(ii=1:nVox)
  if(mod(ii,20000)==0)
    fprintf('  Processed %d of %d voxels (%0.1f %%) in %0.1f secs...\n',ii,nVox,ii/nVox*100,toc);
  end
  if(max(y(ii,:)>0.001))
    d = polyfit (x(ii,:), y(ii,:), 1);
    t1(ii) = d(1);
  end
end

% Why do an abs here? All the negative values seem to be junk.
%t1 = abs(t1);
t1(t1<0) = NaN;
T1 = (-log(t1)/20e-3).^-1;
% Clip to plausible values
T1(isnan(T1)|T1<0.2) = 0.2;
T1(T1>20) = 20;
% Get a PD map for each flip angle
PDmap = zeros(nVox,nT1);
for(ii=1:nT1)
  PDmap(:,ii) = s(t1Inds(ii)).imData(brainInds)./sin(theta(ii)).*((1-cos(theta(ii)).*t1)./(1-t1));
end
% Could do least squares for better PDmap?
PD = mean(PDmap,2);
% WARNING: following clip values are empirically determined with no
% theoretical basis!
PD(PD<0) = 0;
PD(PD>12000) = 12000;

% compute the S0 for the flip angle used in the MT scans
theta = s(mtInds(1)).flipAngle*pi/180;
S0 = PD.*sin(theta).*(1-exp(-32e-3./T1))./(1-cos(theta).*exp(-32e-3./T1));

im=zeros(size(brainMask)); im(brainInds) = T1; T1 = im;
im=zeros(size(brainMask)); im(brainInds) = PD; PD = im;
im=zeros(size(brainMask)); im(brainInds) = S0; S0 = im;

dtiWriteNiftiWrapper(T1, xform, fullfile(outDir,'T1'));
dtiWriteNiftiWrapper(PD, xform, fullfile(outDir,'PD'));
dtiWriteNiftiWrapper(S0, xform, fullfile(outDir,'S0'));

return;

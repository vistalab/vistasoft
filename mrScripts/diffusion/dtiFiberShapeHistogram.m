
%fg=dtiReadFibers('leftOcc'); 
dt=load('as050307_dt6.mat');

b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.99);
fa = dtiComputeFA(dt.dt6);
wm = dtiCleanImageMask(fa>0.15 & b0>(0.3*max(b0(:))));
[xc,yc,zc] = ind2sub(size(wm),find(wm));
[cl,cp,cs]=dtiGetValFromTensors(dt.dt6,[xc,yc,zc],[],'shapes','nearest');

bins = [0:.005:1];

hcl = hist(cl,bins);
hcp = hist(cp,bins);
hcs = hist(cs,bins);

figure;bar(bins,hcl);
figure;bar(bins,hcp);
figure;bar(bins,hcs);

thresh = 0.20;

hclInd = cumsum(hcl)>=sum(hcl)*thresh;
clThresh = bins(min(find(hclInd)))
hcpInd = cumsum(hcp)>=sum(hcp)*thresh;
cpThresh = bins(min(find(hcpInd)))
hcsInd = cumsum(hcs)>=sum(hcs)*thresh;
csThresh = bins(min(find(hcsInd)))

% Fiber-based analysis
val=dtiGetValFromFibers(dt.dt6,fg,inv(dt.xformToAcPc),'shapes','nearest');
hcl = 0; hcp = 0;
for(ii=1:length(val))
  hcl = hcl+hist(val{ii}(2:end-1,1),bins)./fgLen(ii);
  hcp = hcp+hist(val{ii}(2:end-1,2),bins)./fgLen(ii);
end


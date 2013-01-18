subDir = '/biac2/wandell2/data/reading_longitude/dti/';
[subFiles,subCodes] = findSubjects([subDir '*'], '_dt6', {'es041113','tk040817'});
[behData,colNames] = dtiGetBehavioralData(subCodes);
addpath('/home/bob/matlab/stats');
leftHanders = [5,30,38,52]; % am, md, pf, vt

groupDir = '/biac2/wandell2/data/reading_longitude/dtiGroupAnalysis';
N = length(subFiles);

fname = '/teal/scr1/dti/readingRoiAnalysis/faSum.mat';
load(fname);
if(~exist('fa1','var')|isempty(fgFa))
  opts.stepSizeMm = 1;
  opts.faThresh = 0.20;
  opts.lengthThreshMm = [40 40];
  opts.angleThresh = 30;
  opts.wPuncture = 0.2;
  opts.whichAlgorithm = 1;
  opts.whichInterp = 1;
  opts.seedVoxelOffsets = [0.25 0.75];
  fa1 = zeros(76,106,N);
  fa2 = fa1; b01 = fa1; b02 = fa1;
  for(ii=1:N)
    f = subFiles{ii};
    sc = subCodes{ii};
    dt = load(f,'dt6','xformToAcPc','mmPerVox','b0');
    dt.b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.995);
    ac = mrAnatXformCoords(inv(dt.xformToAcPc),[0 0 0]);
    fa1(:,:,ii) = flipud(squeeze(dtiComputeFA(dt.dt6(floor(ac(1)),:,:,:)))');
    fa2(:,:,ii) = flipud(squeeze(dtiComputeFA(dt.dt6(ceil(ac(1)),:,:,:)))');
    b01(:,:,ii) = flipud(squeeze(dt.b0(floor(ac(1)),:,:,:))');
    b02(:,:,ii) = flipud(squeeze(dt.b0(ceil(ac(1)),:,:,:))');
    cc(ii) = dtiReadRoi(fullfile(subDir,sc,'ROIs','CC_FA'));
    fg = dtiFiberTrack(dt.dt6, cc(ii).coords, dt.mmPerVox, dt.xformToAcPc, ...
                       [sc '_CC_40'], opts);
    fgFa{ii} = dtiGetValFromFibers(dt.dt6, fg, inv(dt.xformToAcPc),'fa');
    fgB0{ii} = dtiGetValFromFibers(dt.b0, fg, inv(dt.xformToAcPc),'b0');
    seeds{ii} = fg.seeds;
  end
  xformToAcPc = dt.xformToAcPc;
  mmPerVox = dt.mmPerVox;
  save(fname, 'mmPerVox','xformToAcPc','seeds','fgFa','fgB0','cc','fa1','fa2','b01','b02');
end


segRange = [0,1/5; 1/5,1/3; 1/3,2/3; 2/3,1]; 
seg(1).name = 'Splenium';
seg(2).name = 'Isthmus';
seg(3).name = 'Body';
seg(4).name = 'Genu/Rostrum';
numSegs = length(seg);
mnFa = repmat(NaN,numSegs, N);
mnB0 = repmat(NaN,numSegs, N);
mxFa = repmat(NaN,numSegs, N);
mxB0 = repmat(NaN,numSegs, N);
fiberSteps = 0; % <1 means use the image data directly
for(ii=1:N)
  % Extract a section of this fiber, staring at the middle (end/2),
  % since that should be the mid-sag plane.
  s = round(mrAnatXformCoords(inv(xformToAcPc), seeds{ii}))-1;
  s(:,3) = size(fa1,1)-s(:,3);
  for(jj=1:length(fgFa{ii}))
    fgFaSection{ii}(jj) = mean(fgFa{ii}{jj}(round([end/2-fiberSteps:end/2+fiberSteps])));
    fgB0Section{ii}(jj) = mean(fgB0{ii}{jj}(round([end/2-fiberSteps:end/2+fiberSteps])));
  end
  ap = seeds{ii}(:,2);
  si = seeds{ii}(:,3);
  % Divide the CC into sections along A-P axis
  ccPost = min(ap);
  ccLen = max(ap)-min(ap);
  for(jj=1:numSegs)
    curSeg = ap>=ccPost+ccLen*segRange(jj,1) & ap<ccPost+ccLen*segRange(jj,2);
    %curSeg = ap>=apRange(1)+apStep*(jj-1) & ap<apRange(1)+apStep*jj;
    seg(jj).ind{ii} = curSeg;
    if(fiberSteps<1)
      segInds = sub2ind(size(fa1), s(curSeg,3), s(curSeg,2), repmat(ii,sum(curSeg),1));
      mnFa(jj,ii) = mean([fa1(segInds);fa2(segInds)]);
      mnB0(jj,ii) = mean([b01(segInds);b02(segInds)]);
      mxFa(jj,ii) = max([fa1(segInds);fa2(segInds)]);
      mxB0(jj,ii) = max([b01(segInds);b02(segInds)]);
      miB0(jj,ii) = min([b01(segInds);b02(segInds)]);
    else
      mnFa(jj,ii) =  mean(fgFaSection{ii}(seg(jj).ind{ii}));
      mnB0(jj,ii) =  mean(fgB0Section{ii}(seg(jj).ind{ii}));
      mxFa(jj,ii) =  max(fgFaSection{ii}(seg(jj).ind{ii}));
      mxB0(jj,ii) =  max(fgB0Section{ii}(seg(jj).ind{ii}));
      miB0(jj,ii) =  min(fgB0Section{ii}(seg(jj).ind{ii}));
    end
  end
end

%
% FIGURES
%
behInd = [2 8 9 13];
behName = strrep(colNames,' ','_');
figDir = '/home/bob/2005_Reading_DTI_Dougherty/figs/';
for(ii=1:length(behInd))
  ind = behInd(ii);
  y = behData(:,ind)';
  for(segNum = 1:numSegs)
    x = mnFa(segNum,:);
    gv = ~isnan(x)&~isnan(y);
    figure;
    %subplot(ceil(numSegs/2),2,segNum);
    set(gca,'FontSize',18);
    plot(x(gv), y(gv), 'ko');
    yLim = get(gca,'YLim');
    axis([.4 .8 yLim]);
    set(get(gca,'Children'),'MarkerSize',6,'LineWidth',2);
    xlabel(['Mean FA']); ylabel(colNames{ind});
    fit = polyfit(x(gv), y(gv), 1);
    fitX = [min(x(gv)) max(x(gv))];
    fitY = fit(1).*fitX + fit(2);
    line(fitX, fitY,'Color','k','LineWidth',2);
    fp = get(gcf,'Position'); set(gcf,'Position',[fp(1:2) 400 325]);
    figCleanAndSave(gcf,fullfile(figDir,sprintf('seg%dFA_%s_step%d.png',segNum,behName{ind},fiberSteps)));
  end
end


%behInd = [2:10,18,22:23,27,29];
behInd = [1:length(colNames)];
ncols = ceil(sqrt(length(behInd)));
nrows = ceil(length(behInd)/ncols);
%behInd = 6; % 6=PA
figs = false;

%
% SUMMARY TABLE
%
%fid = 1; % 1=console
fid = fopen('//home/bob/2005_Reading_DTI_Dougherty/table1_sum.csv','a');
fprintf(fid, '\nmean FA (fiberSteps = %d)\n',fiberSteps);
for(segNum = 1:numSegs)
  fprintf(fid, ',Segment %d (%s)',segNum, seg(segNum).name);
end
for(ii=1:length(behInd))
  ind = behInd(ii);
  y = behData(:,ind)';
  fprintf(fid, '\n%s', colNames{ind});
  for(segNum = 1:numSegs)
    x = mnFa(segNum,:);
    gv = ~isnan(x)&~isnan(y);%y~=76;
    % sub 48 is somewhat of an outlier- try it w/o them or gv(leftHanders) = 0;
    [p, r, df] = statTest(x(gv), y(gv), 'r');
    if(p<0.005) sig='***'; elseif(p<0.01) sig='**'; 
    elseif(p<0.05) sig='*'; else sig=''; end
    fprintf(fid, ',%0.3f%s', r, sig);
  end
end
fclose(fid);

x = behData(:,2);
y = mnFa(1,:)';
pf = polyfit(x,y,1);
% Compute the predicted FA based on age
py = x*pf(1)+pf(2);
figure;plot(x,y,'k.',x,py,'r-');
x = behData(:,8); % pa=8
[p, r, df] = statTest(x, y, 'r')
[p, r, df] = statTest(x, y-py, 'r')


segNum = 1;
y = mnFa(segNum,:)';
x = [behData(:,6) behData(:,2)];
[b,bint,residuals] = regress(y, [behData(:,2) ones(size(behData(:,2)))]);
[p, r, df] = statTest(behData(:,6), residuals, 'r');

stats = regstats(y,x,'linear',{'fstat','tstat','rsquare','beta'});
stepwise(x,y);

%
% DETAIL TABLE
%
fid = fopen('//home/bob/2005_Reading_DTI_Dougherty/table1.csv','a');
fprintf(fid, '\nmean FA (fiberSteps = %d)\n',fiberSteps);
for(segNum = 1:numSegs)
  fprintf(fid, ',Segment %d (%s),,',segNum, seg(segNum).name);
end
for(ii=1:length(behInd))
  ind = behInd(ii);
  y = behData(:,ind)';
  fprintf(fid, '\n%s', colNames{ind});
  for(segNum = 1:numSegs)
    x = mnFa(segNum,:);
    gv = ~isnan(x)&~isnan(y);
    [p, r, df] = statTest(x(gv), y(gv), 'r');
    fprintf(fid, ',%0.3f,%0.5f,%d', r, p, df);
  end
end
fclose(fid);


x = (mnB0(1,:)+mnB0(2,:))/2;
figure(77);
for(ii=1:length(behInd))
  ind = behInd(ii);
  y = behData(:,ind);
  yName = colNames{ind};
  gv = [1:N];
  [p, r, df] = statTest(x(gv), y(gv), 'r');
  fprintf('B0 vs. %s: r^2=%0.3f, r=%0.3f (p=%0.5f; df=%d)\n', yName, r.^2, r, p, df);
  subplot(4,3,ii);
  plot(x(gv), y(gv), '.');
  xlabel(['Mean B0 (' seg(segNum).name ')']); ylabel(yName);
  title(sprintf('r^2=%2.0f%%, r=%0.2f (p=%0.4f)', r.^2*100, r, p));
end

paScore = zeros(1,N);
paScore(behData(:,6)<=90) = -1;
paScore(behData(:,6)>=110) = 1;
x = mnFa(1,:);
figure(78);
y = paScore;
yName = 'PA Score';
gv = ~isnan(x)&~isnan(y);
[p, r, df] = statTest(x(gv), y(gv), 'r');
if(p<0.01) sig='***'; elseif(p<0.05) sig='**'; elseif(p<0.1) sig='*'; else sig=''; end
fprintf('%sFA vs. %s: r^2=%0.3f, r=%0.3f (p=%0.5f; df=%d)\n', sig, yName, r.^2, r, p, df);
plot(x(gv), y(gv), '.');
xlabel(['Mean FA (' seg(segNum).name ')']); ylabel(yName(1:min(end,15)));
title(sprintf('r^2=%2.0f%%, r=%0.2f (p=%0.4f)', r.^2*100, r, p));


%max(seeds{ii}) - min(seeds{ii})
sz = [50 25];
im = zeros([sz,N]);
tmp = zeros(sz);
[pa,ind] = sort(behData(:,8));
xo = 25; yo = 4;
for(ii=[1:N])%ind')
  tmp(:) = 0;
  s = round(seeds{ii}./2);
  ind = sub2ind(sz, s(:,2)+xo, s(:,3)+yo);
  tmp(ind) = 1;
  ind = sub2ind(sz, s(seg(1).ind{ii},2)+xo, s(seg(1).ind{ii},3)+yo);
  tmp(ind) = 2;
  im(:,:,ii) = tmp;
end
figure; imagesc(makeMontage(flipdim(permute(im,[2,1,3]),1))); 
axis equal tight off; colormap([0,0,0;0,0,1;1 0 0;0 1 0;1 1 0]);


for(ii=[1:N])
  ccArea(ii) = prod(size(cc(ii).coords));
end
[p, r, df] = statTest(ccArea, y, 'r');
figure;
plot(ccArea, y, '.');
xlabel('CC Area'); ylabel(yName);
title(sprintf('r=%0.3f (p=%0.4f)', r, p));


pa = behData(:,8);
pa(isnan(pa)) = mean(pa(~isnan(pa)));
[pa,paSort] = sort(pa);
sz = [25 50];
fa = zeros([sz,N]);
xo = 31; yo = 26;
[X,Y] = meshgrid([xo:xo+49],[yo:yo+24]);
ind = sub2ind(size(fa1), Y, X);
for(ii=1:N)
  s = round(mrAnatXformCoords(inv(xformToAcPc), seeds{paSort(ii)}))-1;
  spl = seg(1).ind{paSort(ii)};
  tmp1 = fa1(:,:,paSort(ii));
  tmp2 = fa2(:,:,paSort(ii));
  %tmp1 = b01(:,:,paSort(ii));
  %tmp2 = b02(:,:,paSort(ii));
  s(:,3) = size(tmp1,1)-s(:,3);
  %indSpl = sub2ind(size(tmp1), s(spl,3), s(spl,2));
  indSpl = sub2ind(size(tmp1), s(seg(1).ind{paSort(ii)},3), s(seg(1).ind{paSort(ii)},2));
  tmp = (tmp1+tmp2)/2;
  tmp(indSpl) = tmp(indSpl)*3;
  mf(ii) = mean(tmp(indSpl));
  fa(:,:,ii) = tmp(ind)./3;
end
%fa(fa<0.5)=0.5;
%fa = (fa-0.5)*2;
figure; image(uint8(makeMontage(fa)*255+0.5));
axis equal tight off; colormap(gray(256));

ind = 6;
y = behData(paSort,ind);
yName = colNames{ind};
[p, r, df] = statTest(x, y, 'r');
fprintf('FA vs. %s: r=%0.3f (p=%0.5f; df=%d)\n', yName, r, p, df);

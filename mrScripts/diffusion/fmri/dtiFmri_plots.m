fontName = 'Helvetica'; %'Comic Sans MS';
fontSize = 18;
lineSize = 3;
leftPhaseLabels  = ['R-HM'; ' UVM'; 'L-HM'; ' LVM'; 'R-HM'];
rightPhaseLabels = ['L-HM'; ' LVM'; 'R-HM'; ' UVM'; 'L-HM'];
rlPhaseLabels = [' HM'; 'UVM'; ' HM'; 'LVM'; ' HM'];
fname = '/home/bob/matlabFigsNew/all';

dataDir = '/home/bob/matlabFigs';
dataFiles = dir(fullfile(dataDir, '*.mat'));
dataFiles = {dataFiles(:).name};
for(ii=1:length(dataFiles))
    d{ii} = load(fullfile(dataDir, dataFiles{ii}));
end

subs = [1:length(d)];
nbins = 20;

allFigs = 0;
coThresh = 0.20;
for(ii=1:length(d))
    fiberEndptCoordX = [d{ii}.d.roiCoords(3,1:2:end); d{ii}.d.roiCoords(3,2:2:end)];
    swapThese = diff(fiberEndptCoordX)<0;
    fiberEndptPh = [d{ii}.d.ph(1:2:end); d{ii}.d.ph(2:2:end)];
    tmp = fiberEndptPh(1,swapThese);
    fiberEndptPh(1,swapThese) = fiberEndptPh(2,swapThese);
    fiberEndptPh(2,swapThese) = tmp;
    goodVals = isfinite(fiberEndptPh(1,:)) & isfinite(fiberEndptPh(2,:)) & d{ii}.d.co(1:2:end)>coThresh & d{ii}.d.co(2:2:end)>coThresh;
    fiberEndptPh = fiberEndptPh(:,goodVals);
    
    allPh = d{ii}.l.ph;
    goodVals = isfinite(allPh) & d{ii}.l.co>coThresh;
    allPh = allPh(goodVals);
    if(allFigs), figure; subplot(3,2,1); hist(allPh,nbins); title('left'); end;
    cxPh = exp(sqrt(-1)*allPh);
    centerPh = mean(cxPh);
    mnLeftPh{ii} = complexPh2PositiveRad(mean(cxPh));
    allLeftPhCentered{ii} = angle(cxPh/centerPh);
    if(allFigs),subplot(3,2,3); hist(allLeftPhCentered{ii},nbins); set(gca, 'XLim', [-pi, pi]); end;
    fiberLeftPhCentered{ii} = angle(exp(sqrt(-1)*fiberEndptPh(1,:))/centerPh);
    if(allFigs), subplot(3,2,5); hist(fiberLeftPhCentered{ii},nbins); set(gca, 'XLim', [-pi, pi]); end;
    
    allPh = d{ii}.r.ph;
    goodVals = isfinite(allPh) & d{ii}.r.co>coThresh;
    allPh = allPh(goodVals);
    if(allFigs), subplot(3,2,2); hist(allPh,nbins); title('right'); end;
    cxPh = exp(sqrt(-1)*allPh);
    centerPh = mean(cxPh);
    mnRightPh{ii} = complexPh2PositiveRad(mean(cxPh));
    allRightPhCentered{ii} = angle(cxPh/centerPh);
    if(allFigs), subplot(3,2,4); hist(allRightPhCentered{ii},nbins); set(gca, 'XLim', [-pi, pi]); end;
    fiberRightPhCentered{ii} = angle(exp(sqrt(-1)*fiberEndptPh(2,:))/centerPh);
    if(allFigs), subplot(3,2,6); hist(fiberRightPhCentered{ii},nbins); set(gca, 'XLim', [-pi, pi]); end;
end

all = [allRightPhCentered{subs}];
fiber = [fiberRightPhCentered{subs}];

%[p,t,df] = statTest(all, fiber, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(all,nbins);
[y,x] = hist(all,nbins);
gauss=@(p, x, y)sqrt(sum((y-(p(2)*normpdf(x, p(3), p(1)))).^2))
[p,f] = fminsearch(gauss, [0.5,sum(y)/3,0], [], x, y);
xp = linspace(-pi, pi, 100);
yp = p(2)*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi,pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel','');
pos = get(gca,'YLim');
%text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnLeftPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiber,nbins);
[y,x] = hist(fiber,nbins);
yp = sum(y)/3*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XTickLabel','');
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', rightPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_right.png']);

all = [allLeftPhCentered{subs}];
fiber = [fiberLeftPhCentered{subs}];

[p,t,df] = statTest(all, fiber, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(all,nbins);
[y,x] = hist(all,nbins);
[p,f] = fminsearch('gaussFun', [0.5,sum(y)/3,0], [], x, y);
xp = linspace(-pi, pi, 100);
yp = p(2)*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi,pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel','');
pos = get(gca,'YLim');
%text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnLeftPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiber,nbins);
[y,x] = hist(fiber,nbins);
yp = sum(y)/3*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize);
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', leftPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_left.png']);


all = [[allLeftPhCentered{subs}] -[allRightPhCentered{subs}]];
fiber = [[fiberLeftPhCentered{subs}] -[fiberRightPhCentered{subs}]];

%[p,t,df] = statTest(all, fiber, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(all,nbins);
[y,x] = hist(all,nbins);
[p,f] = fminsearch('gaussFun', [0.5,sum(y)/3,0], [], x, y);
xp = linspace(-pi, pi, 100);
yp = p(2)*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi,pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel','');
pos = get(gca,'YLim');
%text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnLeftPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiber,nbins/2);
[y,x] = hist(fiber,nbins/2);
yp = sum(y)/1.75*normpdf(xp, p(3), p(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize);
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', rlPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_l+r.png']);

function err = gaussFun(p, x, y)
yp = p(2)*normpdf(x, p(3), p(1));
err = sqrt(sum((y-yp).^2));
return;

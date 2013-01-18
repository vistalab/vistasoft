% lw=load('wandell_fixed_19991208_V3A-V7_dti_leftOccFG+Splenium_wedge_dat');
% lr=load('wandell_fixed_19991208_V3A-V7_dti_leftOccFG+Splenium_ring_dat');
% rw=load('wandell_fixed_19991208_V3A-V7_dti_rightOccFG+Splenium_wedge_dat');
% rr=load('wandell_fixed_19991208_V3A-V7_dti_rightOccFG+Splenium_ring_dat');
mkdir(tempdir, 'matlabFigs');
baseDir = fullfile(tempdir, 'matlabFigs');
disp(['figures will be saved in ' baseDir]);
scanNames = {'wedge','ring'};
scanNum = 1;

nbins = 20;
coThresh = 0.2;
fontName = 'Helvetica'; %'Comic Sans MS';
fontSize = 18;
leftPhaseLabels  = ['R-HM'; ' LVM'; 'L-HM'; ' UVM'; 'R-HM'];
rightPhaseLabels = ['L-HM'; ' UVM'; 'R-HM'; ' LVM'; 'L-HM'];
rlPhaseLabels = [' HM'; 'UVM'; ' HM'; 'LVM'; ' HM'];

volView = getSelectedVolume;
d.roiCoords = getCurROIcoords(volView);
% We get the last coord, which is the left-right axis (lower = left)
% The following will swap coordinate pairs so that the left-most coord
% is always first.
fiberEndptCoordX = [d.roiCoords(3,1:2:end); d.roiCoords(3,2:2:end)];
swapThese = diff(fiberEndptCoordX)<0;
tmp = fiberEndptCoordX(1,swapThese);
fiberEndptCoordX(1,swapThese) = fiberEndptCoordX(2,swapThese);
fiberEndptCoordX(2,swapThese) = tmp;
subName = mrSESSION.subject;
[junk,sessionCode] = fileparts(pwd);
roiName = volView.ROIs(viewGet(volView, 'selectedROI')).name;

fname = fullfile(baseDir, [subName '_' sessionCode '_' roiName '_' scanNames{scanNum}]);
d.co = getCurDataROI(volView,'co',scanNum,d.roiCoords);
d.ph = getCurDataROI(volView,'ph',scanNum,d.roiCoords);

fiberEndptPh = [d.ph(1:2:end); d.ph(2:2:end)];
tmp = fiberEndptPh(1,swapThese);
fiberEndptPh(1,swapThese) = fiberEndptPh(2,swapThese);
fiberEndptPh(2,swapThese) = tmp;
goodVals = isfinite(fiberEndptPh(1,:)) & isfinite(fiberEndptPh(2,:)) & d.co(1:2:end)>coThresh & d.co(2:2:end)>coThresh;
fiberEndptPh = fiberEndptPh(:,goodVals);
% figure; 
% subplot(1,2,1); scatter(fiberEndptPh(1,:), fiberEndptPh(2,:));
% title(roiName);
% subplot(1,2,2); hist(fiberEndptPh');

% Get data from entire occ lobe (eg. create a 60mm radius disk ROI
% centered in the calcarine- call the left 'allLeft' and the right
% 'allRight'.)

%Process left hemisphere
volView = getSelectedVolume;
roiNum = strmatch('allleft',lower({volView.ROIs(:).name}));
l.roiCoords = volView.ROIs(roiNum).coords;
l.co = getCurDataROI(volView,'co',scanNum,l.roiCoords);
l.ph = getCurDataROI(volView,'ph',scanNum,l.roiCoords);
allLeftPh = l.ph;
goodVals = isfinite(allLeftPh) & l.co>coThresh;
allLeftPh = allLeftPh(goodVals);
%figure; hist(allLeftPh',nbins);
cxPhLeft = exp(sqrt(-1)*allLeftPh);
centerPh = mean(cxPhLeft);
mnLeftPh = complexPh2PositiveRad(mean(cxPhLeft));
allLeftPhCentered = angle(cxPhLeft/centerPh);
fiberLeftPhCentered = angle(exp(sqrt(-1)*fiberEndptPh(1,:))/centerPh);

[p,t,df] = statTest(allLeftPhCentered, fiberLeftPhCentered, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(allLeftPhCentered,nbins);
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi, pi], 'XTickLabel','');
pos = get(gca,'YLim');
text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnLeftPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiberLeftPhCentered,nbins);
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi, pi], 'XTickLabel','');
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', leftPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_left.png']);

% Process the right
volView = getSelectedVolume;
roiNum = strmatch('allright',lower({volView.ROIs(:).name}));
r.roiCoords = volView.ROIs(roiNum).coords;
r.co = getCurDataROI(volView,'co',scanNum, r.roiCoords);
r.ph = getCurDataROI(volView,'ph',scanNum, r.roiCoords);
allRightPh = r.ph;
goodVals = isfinite(allRightPh) & r.co>coThresh;
allRightPh = allRightPh(goodVals);
%figure; hist(allRightPh',nbins);
cxPhRight = exp(sqrt(-1)*allRightPh);
centerPh = mean(cxPhRight);
mnRightPh = complexPh2PositiveRad(mean(cxPhRight));
allRightPhCentered = angle(cxPhRight/centerPh);
fiberRightPhCentered = angle(exp(sqrt(-1)*fiberEndptPh(2,:))/centerPh);

[p,t,df] = statTest(allRightPhCentered, fiberRightPhCentered, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(allRightPhCentered,nbins);
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi, pi], 'XTickLabel','');
pos = get(gca,'YLim');
text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnRightPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiberRightPhCentered,nbins);
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi, pi], 'XTickLabel','');
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', rightPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_right.png']);


% Combine left and right
all = [[allLeftPhCentered] -[allRightPhCentered]];
fiber = [[fiberLeftPhCentered] -[fiberRightPhCentered]];

[p,t,df] = statTest(all, fiber, 't');
figure; set(gcf,'Position', [7, 50, 500, 700]);
subplot(2,1,1); hist(all,nbins);
[y,x] = hist(all,nbins);
[params,f] = fminsearch('gaussFun', [0.5,sum(y)/3,0], [], x, y);
xp = linspace(-pi, pi, 100);
yp = params(2)*normpdf(xp, params(3), params(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize, 'XLim', [-pi,pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel','');
pos = get(gca,'YLim');
%text(-pi*.9,pos(2)*.9,['Mean phase = ' num2str(mnLeftPh,'%0.1f rad')]);
title(sprintf('t=%0.2f (p=%0.4f, df=%d)', t, p, df));
subplot(2,1,2); hist(fiber,nbins/2);
[y,x] = hist(fiber,nbins/2);
yp = sum(y)/1.75*normpdf(xp, params(3), params(1));
hold on; plot(xp,yp,'r-','LineWidth',3); hold off;
set(gca, 'fontName', fontName, 'fontSize', fontSize);
set(gca, 'XLim', [-pi, pi], 'XTick', [-pi, -pi/2, 0, pi/2, pi], 'XTickLabel', rlPhaseLabels);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r120', [fname '_l+r.png']);

save([fname '.mat'], 'd', 'l', 'r', 'coThresh');

% set(gcf, 'PaperPositionMode', 'auto');
% print(gcf, '-dpng', '-r120', '/tmp/bw_right_wedge.png']);
%print(gcf, '-depsc', '-tiff', [fileName '_scatter.eps']);

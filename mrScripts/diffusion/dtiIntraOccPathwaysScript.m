% Intra-occipital analys script

figDir = '/home/bob/research/papers/dti/intrahemiOccipitalPathways';
sub = 'mbs_right';

% Get Ring data
d = dtiXformGetMrVistaDataForFibers(guidata(2),getSelectedGray,1);
n = length(d.co)/2;
coThresh = 0.2;
gv = d.co(1:2:end-1)>coThresh & d.co(2:2:end)>coThresh;
x = d.ph(1:2:end-1); x = x(gv);
y = d.ph(2:2:end);   y = y(gv);
x = x+rand(size(x))*0.1;
y = y+rand(size(y))*0.1;
[p,r,df] = statTest(x, y, 'r');
figure; scatter(x, y);
h=line([0,2*pi],[0,2*pi],'color','k','LineStyle',':');
title(sprintf('r=%0.2f, r^2=%0.3f (p=%0.4f; df=%d)',r,r^2, p, df));
xlabel('First Endpoint Phase (rad)');
ylabel('Second Endpoint Phase (rad)');
figCleanAndSave(gcf, fullfile(figDir,[sub '_ring_phaseScatter']));

figure; hist([x y],6);
xlabel('Ring Phase (rad)');
ylabel('Fiber Endpoint Count');
a = axis; axis([0 2*pi 0 a(4)]);
figCleanAndSave(gcf, fullfile(figDir,[sub '_ring_phaseHist']));

% Get Wedge data
%hmPhase = 3.85; %left HM
hmPhase = 0.71; %right HM
d = dtiXformGetMrVistaDataForFibers(guidata(2),getSelectedGray,2);
n = length(d.co)/2;
coThresh = 0.2;
gv = d.co(1:2:end-1)>coThresh & d.co(2:2:end)>coThresh;
x = d.ph(1:2:end-1); x = x(gv);
y = d.ph(2:2:end);   y = y(gv);
x = x+rand(size(x))*0.1;
y = y+rand(size(y))*0.1;
[p,r,df] = statTest(x, y, 'r');
figure; scatter(x, y);
line([0,2*pi],[0,2*pi],'color','k','LineStyle','-');
title(sprintf('r=%0.2f, r^2=%0.3f (p=%0.4f; df=%d)',r,r^2, p, df));
xlabel('First Endpoint Phase (rad)');
ylabel('Second Endpoint Phase (rad)');
figCleanAndSave(gcf, fullfile(figDir,[sub '_wedge_phaseScatter']));


figure; hist([x y],20);
a = axis; axis([0 2*pi 0 a(4)]);
line([hmPhase hmPhase], [0 a(4)],'color','r','LineStyle','-');
text(hmPhase, a(4)-a(4)/20, 'HM','color','r');
xlabel('Wedge Phase (rad)');
ylabel('Fiber Endpoint Count');

figCleanAndSave(gcf, fullfile(figDir,[sub '_wedge_allPhaseHist']));
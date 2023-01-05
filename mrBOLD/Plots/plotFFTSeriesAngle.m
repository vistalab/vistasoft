function plotFFTSeriesAngle(view,scan)
%
% plotFFTSeriesAngle(view,[scan])
% 
% Plots the FFT of the tSeries for the current scan, averaging across
% all pixels (in all slices) in the current ROI.

if ~exist('scan','var')
    scan = getCurScan(view);
end
scan = getCurScan(view);
nCycles = numCycles(view,scan);
maxCycles = round(numFrames(view,scan)/3); % number of frequencies to plot

% Compute the mean tSeries
if view.selectedROI
  ROIcoords = getCurROIcoords(view);
else
  myErrorDlg('No current ROI');
end
tSeries = meanTSeries(view,scan,ROIcoords);

% Calulate the FFT;
absFFT=2*abs(fft(tSeries)) / length(tSeries);
angleFFT=angle(fft(tSeries));

% Header
ROIname = view.ROIs(view.selectedROI).name;
headerStr = ['Mean tSeries, ROI ',ROIname,', scan ',num2str(scan)];
set(gcf,'Name',headerStr);

% plot it
x= [1:maxCycles];
y1 =[absFFT(2:maxCycles+1)];
y2 =[angleFFT(2:maxCycles+1)];

subplot(2,1,1);
plot(x(1:nCycles-1),y1(1:nCycles-1),'b','LineWidth',2)
hold on
plot(x(nCycles-1:nCycles+1),y1(nCycles-1:nCycles+1),'r','LineWidth',2)
plot(x(nCycles+1:maxCycles),y1(nCycles+1:maxCycles),'b','LineWidth',2)
plot(x,y1,'bo','LineWidth',2);
hold off

% Ticks
fontSize = 14;
xtick=nCycles:nCycles:(maxCycles+1);
set(gca,'xtick',xtick);
set(gca,'FontSize',fontSize)
xlabel('Cycles per scan','FontSize',fontSize)
ylabel('Percent modulation','FontSize',fontSize) 
grid on

% plot the phase as well
subplot(2,1,2);

plot(x(1:nCycles-1),y2(1:nCycles-1),'b','LineWidth',2)
hold on
plot(x(nCycles-1:nCycles+1),y2(nCycles-1:nCycles+1),'r','LineWidth',2)
plot(x(nCycles+1:maxCycles),y2(nCycles+1:maxCycles),'b','LineWidth',2)
plot(x,y2,'bo','LineWidth',2);
hold off
% Ticks
fontSize = 14;
xtick=nCycles:nCycles:(maxCycles+1);
set(gca,'xtick',xtick);
set(gca,'FontSize',fontSize)
xlabel('Cycles per scan','FontSize',fontSize)
ylabel('Phase','FontSize',fontSize) 
grid on

% Save the data in gca('UserData')
data.x = x(1:maxCycles);
data.y1  =  y1(1:maxCycles);
data.y2 = 	y2(1:maxCycles);

set(gca,'UserData',data);




function plotCortmagResults(cortMag, showPredicted)
% function plotCortmagResults(cortMag, [showPredicted])
%
if(~exist('showPredicted','var')) showPredicted = 1; end

nROIs = length(cortMag.bins);
pX = ceil(sqrt(nROIs));
pY = ceil(nROIs/pX);
xLower = 0;
xUpper = 100;
yLower = -pi;
yUpper = 4*pi;
for ii=1:nROIs
   mnPh = complexPh2PositiveRad(cortMag.meanPh{ii});
   %mnPh = unwrapPhases(mnPh);
   % plot unshifted data
   uDist = cortMag.corticalDist{ii}-cortMag.distanceShift(ii);
   figure(100);
   subplot(pX,pY,ii);
   plot(uDist,mnPh,'-o');
   set(gca,'xlim',[xLower xUpper]);
   set(gca,'ylim',[yLower yUpper]);
   str = sprintf('ROI %.0f',ii); 
   title(str);
%    figure(99);
%    hold on;
%    plot(uDist,(mnPh-cortMag.fovealPhase)/(2*pi)*cortMag.stimulusRadius,'o');
%    hold off;
   %pause
end

figure(101); 
%newGraphWin;
symbolString = 'b.';
errorbar(cortMag.allCorticalDist10deg, cortMag.allStimDeg, cortMag.allStimDegSE, symbolString);

% The predicted exponential CMF curve, when the distances have
% been adjusted so that 0 means 10 deg, is:
%
d = sort(cortMag.allCorticalDist10deg);

if showPredicted
    predictedDeg = exp(d*cortMag.fitParms.dScale + log(10));
    hold on; plot(d,predictedDeg,'k-.'); hold off
    cortMag.predictedDeg = predictedDeg;
end

% Guesses about the window parameters
%
xLower = min(cortMag.allCorticalDist10deg);
xUpper = max(cortMag.allCorticalDist10deg);
%xUpper = 15;
yLower = -4;
yUpper = 1.1*cortMag.stimulusRadius;

set(gca,'xlim',[xLower xUpper]);
set(gca,'ylim',[yLower yUpper]);
set(gca,'xtick',round([xLower:5:xUpper]),'ytick',[yLower:4:yUpper])

% Place the resulting data in the figure for later plotting
set(gca,'UserData',cortMag);
disp('Data stored in plot- retrieve it with: cortMag=get(gca,''UserData'')');

subject = eval('cortMag.subject','');
dataType = eval('cortMag.dataType','');
flatDir = eval('cortMag.subdir','');
title([subject,' (',cortMag.hemisphere,',',dataType,',',flatDir,'): ',...
      'dScale=',num2str(cortMag.fitParms.dScale),'  ',...
      'dShift=',num2str(cortMag.fitParms.dShift),'  ',...
      'foveaPh=',num2str(cortMag.fitParms.fovealPhase)]);
%plot(cortMag.allCorticalDist, complexPh2PositiveRad(cortMag.allMeanPh),'x');
return;
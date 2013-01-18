%addpath /white/u2/bob/matlab/stats/
volView = getSelectedVolume;

%baseDir = '/home/bob/research/papers/dti/callosal_areaMaps/matlabFigs';
mkdir(tempdir, 'matlabFigs');
baseDir = fullfile(tempdir, 'matlabFigs');
disp(['figures will be saved in ' baseDir]);
[junk,sessionCode] = fileparts(pwd);
fileNameBase = fullfile(baseDir, [mrSESSION.subject '_' sessionCode]);
fileName = [fileNameBase '_' volView.ROIs(viewGet(volView, 'selectedROI')).name];
labelX = 'Left phase (rad)';
labelY = 'Right phase (rad)';
% axisLim = [-2*pi, 2*pi, -2*pi, 2*pi];
% tick = [-3*pi/2, -pi, -pi/2, 0, pi/2, pi, 3*pi/2];
% tickLabel = ['   ';'-pi';'   ';' 0 ';'   ';' pi';'   '];
eccenDeg = [0, pi/2, pi, 3*pi/2, 4*pi/2]/(2*pi) * 16;
axisLim = [-pi/2, 5*pi/2, -pi/2, 5*pi/2];
tick = [0, pi/2, pi, 3*pi/2, 4*pi/2];
tickLabel = [' 0  ';'    ';' pi ';'    ';'2 pi'];
scanNames = {'wedge','ring'};
coThresh = 0.25;
paperFigs = 0;
if(paperFigs)
    fontName = 'Helvetica';
    fontSize = 12;
    markSize = 9;
    markColor = 'k';
    lineWidth = 2;
    lineColor = 'k';
else
    fontName = 'Comic Sans MS';
    fontSize = 16;
    markSize = 12;
    markColor = 'r';
    lineWidth = 3;
    lineColor = 'b';
end
generalNotes = '';
roiCoords = getCurROIcoords(volView);
% We get the last coord, which is the left-right axis (lower = left)
% The following will swap coordinate pairs so that the left-most coord
% is always first.
fiberEndptCoordX = [roiCoords(3,1:2:end); roiCoords(3,2:2:end)];
swapThese = diff(fiberEndptCoordX)<0;
tmp = fiberEndptCoordX(1,swapThese);
fiberEndptCoordX(1,swapThese) = fiberEndptCoordX(2,swapThese);
fiberEndptCoordX(2,swapThese) = tmp;
for(scanNum=1:2)
    co = getCurDataROI(volView,'co',scanNum,roiCoords);
    ph = getCurDataROI(volView,'ph',scanNum,roiCoords);
    fiberEndptPh = [ph(1:2:end); ph(2:2:end)];
    tmp = fiberEndptPh(1,swapThese);
    fiberEndptPh(1,swapThese) = fiberEndptPh(2,swapThese);
    fiberEndptPh(2,swapThese) = tmp;
    goodVals = isfinite(fiberEndptPh(1,:)) & isfinite(fiberEndptPh(2,:)) & co(1:2:end)>coThresh & co(2:2:end)>coThresh;
    fiberEndptPh = fiberEndptPh(:,goodVals);
    % Null hypothesis test
    fiberEndptPh(2,:) = fiberEndptPh(2,randperm(length(fiberEndptPh(2,:))));
    % Unwrap phases
    if(strcmpi(scanNames{scanNum}, 'wedge'))
    else
        labelX = 'Left Eccentricity (deg)';
        labelY = 'Right Eccentricity (deg)';
        tickLabel = num2str(eccenDeg');
        d = diff(fiberEndptPh);
        unwrapThese = d>pi & fiberEndptPh(2,:)>3*pi/2;
        fiberEndptPh(1,unwrapThese) = fiberEndptPh(2,unwrapThese)+2*pi;
        unwrapThese = d<-pi & fiberEndptPh(1,:)>3*pi/2;
        fiberEndptPh(2,unwrapThese) = fiberEndptPh(2,unwrapThese)+2*pi;        
    end
    x = squeeze(fiberEndptPh(1,:));
    y = squeeze(fiberEndptPh(2,:));
    %[p, r, df] = statTest(x, y, 'r'); rsq = r^2;
    %fit = polyfit(x, y, 1)
    [b,bint,r,rint,s]=regress(y',[x',ones(size(y'))]);
    fitX = [min(x),max(x)];
    fitY = fitX.*b(1) + b(2);
    p = s(3); rsq = s(1); f = s(2);
    if(paperFigs)
        if(scanNum==1) fh = figure; else figure(fh); end
        set(fh,'Position',[6, 33, 400, 820]);
        subplot(2,1,scanNum);
    else
        fh = figure;
        set(fh,'Position',[7, 50, 400, 430]);
    end
    axes;
    line([axisLim(1),axisLim(2)], [axisLim(3),axisLim(4)], 'Color', 'k', 'LineWidth', 1);
    hold on;
    h = scatter(x, y, markColor);
    hold off;
    set(gca, 'fontName', fontName);
    set(gca, 'fontSize', fontSize);
    xlabel(labelX, 'fontName', fontName, 'fontSize', fontSize, 'fontWeight','normal');
    ylabel(labelY, 'fontName', fontName, 'fontSize', fontSize, 'fontWeight','normal');
    axis(axisLim);
    set(gca, 'XTick', tick);
    set(gca, 'YTick', tick);
    set(gca, 'XTickLabel', tickLabel);
    set(gca, 'YTickLabel', tickLabel);
    set(h, 'MarkerSize', markSize); set(h, 'LineWidth', lineWidth);
    lineH = line(fitX, fitY, 'Color', lineColor, 'LineWidth', lineWidth);
    if(p<0.0001)
        title(sprintf('%s: R^2=%0.4f (p<0.0001)', scanNames{scanNum}, rsq));
    else
        title(sprintf('%s: R^2=%0.4f (p=%0.4f)', scanNames{scanNum}, rsq, p));
    end
    if(~paperFigs)
        pos = get(fh, 'Position');
        set(gca, 'Units', 'pixels');
        %[left bottom width height]
        set(gca, 'Position', [70,70,pos(3)-90,pos(3)-90]);
        set(fh, 'PaperPositionMode', 'auto');
        %print(fh, '-dpng', '-r120', [fileName '_' scanNames{scanNum} '_scatter.png']);
    end

    notes = [sprintf('coThresh=%0.3f; ', coThresh) generalNotes];
    %save([fileName '_' scanNames{scanNum} '_dat.mat'], 'fiberEndptPh', 'co', 'ph', 'roiCoords', 'notes');
end

if(paperFigs)
    set(fh, 'PaperPositionMode', 'auto');
    print(fh, '-depsc', '-tiff', [fileName '_scatter.eps']);
end
refresh;

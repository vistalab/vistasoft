load /biac1/wandell/docs/2005_NYAS_DTI_Dougherty/convergeAnalysis/convergeDataSum.mat
% The convergence data have been summarized by doing the following for all
% left fibers and all right fibers:
% - load the CC ROI and use this to find the user-defined mid-sagittal plane.
% - for each fiber, find the point that falls nearest to one of the CC ROI
% points.
%
% fiberCoord is an NSubjects x 2 {left,right} cell array.  The cells
% contain the coordinates of each fiber at the position within that fiber
% closest to the mid-sagittal plane. These are the (y,z) coordinates
% (mid-sagittal has x = 0). 
%

% fiberCoord now contains 12 different regions
fiberCoord = fiberCoord(:,[1,7]);

numSubjects = size(fiberCoord,1);

% Create a grid that conceptually is on the mid-sagittal plane.  Each
% subject will has a left and right grid.  We will combine the grids from
% different subjects by translating them to co-register at the center of
% mass of the fiber positions for the left and right (jointly) in that
% subject.
gridSpace = 0.5;   % Millimeters
gridSize = 15;    % Endpoints of the grid in millimeters
meanShiftFlag = false;

if(meanShiftFlag) figName = 'meanShift';
else figName = 'unshifted'; end

% This is the distance from a grid cell center to a corner (hypotenuse)
maxDistSq = 2*(gridSpace/2)^2;
xSamples = [-gridSize:gridSpace:gridSize];
ySamples = [-gridSize:gridSpace:gridSize];
[gridX,gridY] = ndgrid(xSamples,ySamples);
gridPoints = [gridX(:) gridY(:)];
z = ones(size(gridX(:)));

% For each subject, and then for all subjects, we count the number of
% fibers in each grid cell (i.e., bin).
allLeftDensity = zeros(size(gridX));
allRightDensity = zeros(size(gridX));
for(ii=1:numSubjects)
    
    % We arrange the left and right grids 
    leftDensity = zeros(size(gridX));
    rightDensity = zeros(size(gridX));
    left = [fiberCoord{ii,1}];  
    right = [fiberCoord{ii,2}];
    
    % Convert the x,y coords to a mean-centered coordinate system so that
    % all subjects will fit on the same grid. It might be interesting to
    % see how well the splenium aligns across subjects using this method.
    meanCoord = mean([left;right]);
    if(meanShiftFlag)
        left(:,1) = left(:,1)   - meanCoord(1); left(:,2) = left(:,2)-meanCoord(2);
        right(:,1) = right(:,1) - meanCoord(1); right(:,2) = right(:,2)-meanCoord(2);
        meanShift(:,ii) = meanCoord(:);
    else
        left(:,1) = left(:,1)   - (-36); left(:,2) = left(:,2)  - 11;
        right(:,1) = right(:,1) - (-36); right(:,2) = right(:,2) - 11;
    end

    % For each fiber point, find the nearest grid point.
    [leftNearest, bestSqDist] = nearpoints([left ones(size(left(:,1)))]', [gridPoints z]');
    if(max(bestSqDist)>maxDistSq) warning(sprintf('grid may be too small! (%0.3f)',max(bestSqDist))); end
    
    % Count how many fibers are in each grid cell
    for(jj=1:length(leftNearest))
        leftDensity(leftNearest(jj)) = leftDensity(leftNearest(jj))+1;
    end
    
    % Do it again for the right
    [rightNearest, bestSqDist] = nearpoints([right ones(size(right(:,1)))]', [gridPoints z]');
    if(max(bestSqDist)>maxDistSq) warning(sprintf('grid may be too small! (%0.3f)',max(bestSqDist))); end
    for(jj=1:length(rightNearest))
        rightDensity(rightNearest(jj)) = rightDensity(rightNearest(jj))+1;
    end
    
    % Analyze cells that are non-zero in one hemi *or* the other.  Cells
    % that are 0 in both are fine, and uninteresting ... but they do
    % support the model.
    nz = (leftDensity>0) | (rightDensity>0);
    ld = leftDensity(nz);
    rd = rightDensity(nz);
    
    
    % Compute the correlation coefficient between the two spatial
    % densities.
    [r,p] = corrcoef(ld,rd); r = r(2); p = p(2); df = length(ld)-2;
    msg = sprintf('(%d): r^2=%0.2f (p=%0.4f, df=%d)',  ii, r^2, p, df);
    disp(msg);
    
%     if(r^2<.10)
%         figure;subplot(3,1,1);scatter(ld,rd); title(msg);
%         subplot(3,1,2);imagesc(leftDensity);axis equal tight;colormap(hot);colorbar
%         subplot(3,1,3);imagesc(rightDensity);axis equal tight;colormap(hot);colorbar
%     end
    allLeftDensity = allLeftDensity+leftDensity;
    allRightDensity = allRightDensity+rightDensity;
    
    %
    crit = 5;
    leftOverlap = zeros(size(leftDensity));
    leftOverlap(leftDensity > crit) = 1;
    rightOverlap = zeros(size(rightDensity));
    rightOverlap(rightDensity > crit) = 1;
    overlapArea = sum( leftOverlap(:) .* rightOverlap(:));
    meanArea = (sum(leftOverlap(:)) + sum(rightOverlap(:)))/2;
    overlapIndex(ii) = overlapArea/meanArea;
    
end

nz = allLeftDensity>0 | allRightDensity>0;
ld = allLeftDensity(nz);
rd = allRightDensity(nz);
binArea = gridSpace^2;
ld = ld/binArea;
rd = rd/binArea;

[r,p] = corrcoef(ld,rd); r = r(2); p = p(2); df = length(ld)-2;
msg = sprintf('Total: r^2=%0.2f (p=%0.4f, df=%d)', r^2, p, df);
disp(msg);
maxVal = ceil(max([ld; rd])/1000)*1000;

figure(1); clf
scatter(ld,rd,'k.'); 
set(gca,'FontSize',18)
xlabel('Left fiber density (fibers/mm^2)'); ylabel('Right fiber density (fibers/mm^2)'); 
%  rd = ld*s
%  pinv(ld)*rd = s
slope = pinv(ld)*rd;
regLineHandle = line([0,maxVal], [0,slope*maxVal]); 
set(regLineHandle,'color','k','LineStyle','-','LineWidth',1)
unitLineHandle = line([0,maxVal], [0,maxVal]); 
set(unitLineHandle,'color','k','LineStyle',':','LineWidth',1)
if(maxVal>4000)
    set(gca,'xtick',[0:2000:maxVal],'ytick',[0:2000:maxVal]);
else
    set(gca,'xtick',[0:1000:maxVal],'ytick',[0:1000:maxVal]);
end
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r200', [figName '_scatter.png']);
print(gcf, '-deps', '-tiff', [figName '_scatter.eps']);
% title(msg);
fprintf('Bin area = %.3f (mm^2)\n',gridSpace^2)

maxDensity = round(max([allLeftDensity(:);allRightDensity(:)])./100).*100;
tickSpace = 5;
gridColor = 0.7*[1 1 1];
xtick = [0:tickSpace:max(xSamples)]; xtick = [-1*fliplr(xtick(2:end)), xtick];
ytick = [0:tickSpace:max(ySamples)]; ytick = [-1*fliplr(ytick(2:end)), ytick];


figure(7); clf
colormap(gray(256));
image(repmat([0:255], 10, 1));
axis equal tight;
linspace(0,maxDensity,10);
set(gca,'xtick',linspace(1,256,5),'ytick',[],'FontSize',14);
set(gca,'xticklabel',round(linspace(0,maxDensity,5)./10).*10,'yticklabel',[]);
pos = get(gcf,'Position');
set(gcf,'Position',[pos(1) pos(2) 600 70], 'PaperPositionMode', 'auto');
set(gca,'Position',[0.04 0.1 0.90 0.95])
print(gcf, '-dpng', '-r90', [figName '_densityLegend.png']);

figure(8); clf
colormap(gray(256));
image(xSamples,ySamples,uint8(allLeftDensity'./maxDensity.*255+0.5));
axis equal tight xy;
grid on
set(gca,'xtick',xtick,'ytick',ytick)
set(gca,'Xcolor',gridColor,'Ycolor',gridColor);
set(gca,'xticklabel',[],'yticklabel',[]);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r90', [figName '_allLeftDensity.png']);
%print(gcf, '-deps', '-tiff', [figName '_allLeftDensity.eps']);

figure(9); clf
colormap(gray(256));
image(xSamples,ySamples,uint8(allRightDensity'./maxDensity.*255+0.5));
axis equal tight xy;
grid on
set(gca,'xtick',xtick,'ytick',ytick)
set(gca,'Xcolor',gridColor,'Ycolor',gridColor);
set(gca,'xticklabel',[],'yticklabel',[])
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r90', [figName '_allRightDensity.png']);
%print(gcf, '-deps', '-tiff', [figName '_allRightDensity.eps']);

%figure; mesh(allLeftDensity); hold on; mesh(-1*allRightDensity);

figure; hist(overlapIndex)


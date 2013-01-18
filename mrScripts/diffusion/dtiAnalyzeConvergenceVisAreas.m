load convergeDataSum.mat
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

numSubjects = size(fiberCoord,1);

% Create a grid that conceptually is on the mid-sagittal plane.  Each
% subject will has a left and right grid.  We will combine the grids from
% different subjects by translating them to co-register at the center of
% mass of the fiber positions for the left and right (jointly) in that
% subject.
gridSpace = .5;   % Millimeters
gridSize = 11;    % Endpoints of the grid in millimeters
meanShiftFlag = true;
merge = true;
useNormedCoords = true;
doScatter = true;
tickSpace = 5;
% the threshold to be applied to the mean CC image.
if(useNormedCoords)
    ccThresh = [20 20];
else
    ccThresh = [7 7];
end
gridColor = 0.5*[1 1 1];
cm = gray(256); cm = flipud(cm);

if(meanShiftFlag) figName = 'meanShift';
else figName = 'unshifted'; end
if(useNormedCoords) figName = [figName '_norm']; end

if(merge)
  % merge the two dorsal and two ventral areas
  for(ii=1:numSubjects)
    fiberCoord{ii,3} = [fiberCoord{ii,3}; fiberCoord{ii,4}];
    fiberCoord{ii,4} = [fiberCoord{ii,5}; fiberCoord{ii,6}];
    fiberCoord{ii,5} = fiberCoord{ii,7};
    fiberCoord{ii,6} = fiberCoord{ii,8};
    fiberCoord{ii,7} = [fiberCoord{ii,9}; fiberCoord{ii,10}];  
    fiberCoord{ii,8} = [fiberCoord{ii,11}; fiberCoord{ii,12}];
    normFiberCoord{ii,3} = [normFiberCoord{ii,3}; normFiberCoord{ii,4}];
    normFiberCoord{ii,4} = [normFiberCoord{ii,5}; normFiberCoord{ii,6}];
    normFiberCoord{ii,5} = normFiberCoord{ii,7};
    normFiberCoord{ii,6} = normFiberCoord{ii,8};
    normFiberCoord{ii,7} = [normFiberCoord{ii,9}; normFiberCoord{ii,10}];  
    normFiberCoord{ii,8} = [normFiberCoord{ii,11}; normFiberCoord{ii,12}];
  end
  fiberCoord = fiberCoord(:,1:8);
  normFiberCoord = normFiberCoord(:,1:8);
  nAreas = size(fiberCoord,2)/2;
  areaNames = {'all','LO','Dorsal','Ventral'};
else
  nAreas = size(fiberCoord,2)/2;
  areaNames = {'all','LO','dorsal','V12d','V12v','ventral'};
end

% This is the distance from a grid cell center to a corner (hypotenuse)
maxDistSq = 2*(gridSpace/2)^2;
xSamples = [-gridSize:gridSpace:gridSize];
ySamples = [-gridSize/2:gridSpace:gridSize];
[gridX,gridY] = ndgrid(xSamples,ySamples);
gridPoints = [gridX(:) gridY(:)];
z = ones(size(gridX(:)));

% For each subject, and then for all subjects, we count the number of
% fibers in each grid cell (i.e., bin).
allLeftDensity = zeros([size(gridX),nAreas]);
allRightDensity = zeros([size(gridX),nAreas]);
allCC = zeros([size(gridX)]);
for(ii=1:numSubjects)
  if(useNormedCoords)
    meanCoord = mean(vertcat(normFiberCoord{ii,:}),1);
  else
    meanCoord = mean(vertcat(fiberCoord{ii,:}),1);
  end
  meanShift(:,ii) = meanCoord(:);
  if(useNormedCoords)
      cc = normCcCoord{ii};
  else
      cc = ccCoord{ii}; 
  end
  if(meanShiftFlag)
    % The cc ROI points are shifted by 1/2 mm relative to fiber points
    cc(:,1) = cc(:,1)-(meanCoord(1)-0.5); cc(:,2) = cc(:,2)-(meanCoord(2)+0.5);
  else
    cc(:,1) = cc(:,1)-(-36-0.5); cc(:,2) = cc(:,2)-(11+0.5);
  end
  [ccNearest, bestSqDist] = nearpoints([cc ones(size(cc(:,1)))]', [gridPoints z]');
  for(jj=1:length(ccNearest))
    if(bestSqDist(jj)<=maxDistSq)
      allCC(ccNearest(jj)) = allCC(ccNearest(jj))+1;
    end
  end
  for(areaNum=1:nAreas)
    % We arrange the left and right grids 
    leftDensity = zeros(size(gridX));
    rightDensity = zeros(size(gridX));
    if(useNormedCoords)
      left = [normFiberCoord{ii,areaNum}];
      right = [normFiberCoord{ii,areaNum+nAreas}];
    else
      left = [fiberCoord{ii,areaNum}];
      right = [fiberCoord{ii,areaNum+nAreas}];
    end
    
    % Convert the x,y coords to a mean-centered coordinate system so that
    % all subjects will fit on the same grid. It might be interesting to
    % see how well the splenium aligns across subjects using this method.
    if(meanShiftFlag)
      if(~isempty(left))
        left(:,1) = left(:,1)   - meanCoord(1); left(:,2) = left(:,2)-meanCoord(2);
      end
      if(~isempty(right))
        right(:,1) = right(:,1) - meanCoord(1); right(:,2) = right(:,2)-meanCoord(2);
      end
    else
      left(:,1) = left(:,1)   - (-36); left(:,2) = left(:,2)  - 11;
      right(:,1) = right(:,1) - (-36); right(:,2) = right(:,2) - 11;
    end
    
    % For each fiber point, find the nearest grid point.
    if(~isempty(left))
      [leftNearest, bestSqDist] = nearpoints([left ones(size(left(:,1)))]', [gridPoints z]');
      %if(max(bestSqDist)>maxDistSq) warning(sprintf('grid may be too small! (%0.3f)',max(bestSqDist))); end
      % Count how many fibers are in each grid cell
      for(jj=1:length(leftNearest))
        if(bestSqDist(jj)<=maxDistSq)
          leftDensity(leftNearest(jj)) = leftDensity(leftNearest(jj))+1;
        end
      end
    end
    
    % Do it again for the right
    if(~isempty(right))
      [rightNearest, bestSqDist] = nearpoints([right ones(size(right(:,1)))]', [gridPoints z]');
      %if(max(bestSqDist)>maxDistSq) warning(sprintf('grid may be too small! (%0.3f)',max(bestSqDist))); end
      for(jj=1:length(rightNearest))
        if(bestSqDist(jj)<=maxDistSq)
          rightDensity(rightNearest(jj)) = rightDensity(rightNearest(jj))+1;
        end
      end
    end
    
    % Analyze cells that are non-zero in one hemi *or* the other.  Cells
    % that are 0 in both are fine, and uninteresting ... but they do
    % support the model.
    nz = (leftDensity>0) | (rightDensity>0);
    ld = leftDensity(nz);
    rd = rightDensity(nz);
    
    if(~isempty(left) & ~isempty(right))
      % Correlation between the two spatial densities.
      [r,p] = corrcoef(ld,rd); r = r(2); p = p(2); df = length(ld)-2;
      msg = sprintf('(%d): r^2=%0.2f (p=%0.4f, df=%d)',  ii, r^2, p, df);
      %disp(msg);
    end
    
%     if(r^2<.10)
%         figure;subplot(3,1,1);scatter(ld,rd); title(msg);
%         subplot(3,1,2);imagesc(leftDensity);axis equal tight;colormap(hot);colorbar
%         subplot(3,1,3);imagesc(rightDensity);axis equal tight;colormap(hot);colorbar
%     end
    allLeftDensity(:,:,areaNum) = allLeftDensity(:,:,areaNum)+leftDensity;
    allRightDensity(:,:,areaNum) = allRightDensity(:,:,areaNum)+rightDensity;
    
    %
    crit = 5;
    leftOverlap = zeros(size(leftDensity));
    leftOverlap(leftDensity > crit) = 1;
    rightOverlap = zeros(size(rightDensity));
    rightOverlap(rightDensity > crit) = 1;
    overlapArea = sum( leftOverlap(:) .* rightOverlap(:));
    meanArea = (sum(leftOverlap(:)) + sum(rightOverlap(:)))/2;
    overlapIndex(ii,areaNum) = overlapArea/meanArea;
    end
end

meanCC = blur(allCC);
figure(88);
imagesc(xSamples,ySamples,meanCC'); axis equal tight xy; colormap(flipud(gray(256)));
set(gca,'xtick',xtick,'ytick',ytick)
set(gca,'XColor',gridColor,'YColor',gridColor);
set(gca,'xticklabel',[],'yticklabel',[]);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r200', [figName '_cc.png']);
print(gcf, '-deps', '-tiff', [figName '_cc.eps']);
mrUtilMakeColorbar(cm, round(linspace(0,max(meanCC(:)),4)), 'Point Density', [figName '_ccLegend'], 87);

nz = allLeftDensity>0 | allRightDensity>0;
binArea = gridSpace^2; fprintf('Bin area = %.3f (mm^2)\n',binArea);

maxAllDensity = round(max(max([allLeftDensity(:,:,1);allRightDensity(:,:,1)]))./100).*100;
maxAreasDensity = round(max(max(max([allLeftDensity(:,:,2:end);allRightDensity(:,:,2:end)])))./100).*100;
cbLabel = round(linspace(0,maxAllDensity./binArea,4)./10).*10;
mrUtilMakeColorbar(cm, cbLabel, 'Fiber Density (fibers/mm^2)', [figName '_AllLegend'], 98);
cbLabel = round(linspace(0,maxAreasDensity./binArea,4)./10).*10;
mrUtilMakeColorbar(cm, cbLabel, 'Fiber Density (fibers/mm^2)', [figName '_AreaLegend'], 99);

xtick = [0:tickSpace:max(xSamples)]; xtick = [-1*fliplr(xtick(2:end)), xtick];
ytick = [0:tickSpace:max(ySamples)]; ytick = [-1*fliplr(ytick(2:end)), ytick];
for(areaNum=1:nAreas)
  if(areaNum==1) maxDensity = maxAllDensity;
  else maxDensity = maxAreasDensity; end
  fn = [areaNames{areaNum} '_' figName];
  figNum = (areaNum-1)*4+1;
  ld = allLeftDensity(:,:,areaNum); ld = ld(nz(:,:,areaNum));
  rd = allRightDensity(:,:,areaNum); rd = rd(nz(:,:,areaNum));
  ld = ld./binArea;
  rd = rd./binArea;
  [r,p] = corrcoef(ld,rd); r = r(2); p = p(2); df = length(ld)-2;
  msg = sprintf('%s total: r^2=%0.2f (p=%0.4f, df=%d)', areaNames{areaNum}, r^2, p, df);
  disp(msg);
  
  figure(figNum); clf
  colormap(cm);
  image(xSamples,ySamples,uint8(allLeftDensity(:,:,areaNum)'./maxDensity.*255+0.5));
  axis equal tight xy;
  hold on; contour(xSamples,ySamples,meanCC',ccThresh,'k-'); hold off;
  grid on
  set(gca,'xtick',xtick,'ytick',ytick)
  set(gca,'Xcolor',gridColor,'Ycolor',gridColor);
  set(gca,'xticklabel',[],'yticklabel',[]);
  set(gcf, 'PaperPositionMode', 'auto');
  print(gcf, '-dpng', '-r90', [fn '_allLeftDensity.png']);
  print(gcf, '-deps', '-tiff', [fn '_allLeftDensity.eps']);
  
  figure(figNum+1); clf
  colormap(cm);
  image(xSamples,ySamples,uint8(allRightDensity(:,:,areaNum)'./maxDensity.*255+0.5));
  axis equal tight xy;
  hold on; contour(xSamples,ySamples,meanCC',ccThresh,'k-'); hold off;
  grid on
  set(gca,'xtick',xtick,'ytick',ytick)
  set(gca,'Xcolor',gridColor,'Ycolor',gridColor);
  set(gca,'xticklabel',[],'yticklabel',[])
  set(gcf, 'PaperPositionMode', 'auto');
  print(gcf, '-dpng', '-r90', [fn '_allRightDensity.png']);
  print(gcf, '-deps', '-tiff', [fn '_allRightDensity.eps']);

  if(doScatter)
    figure(figNum+2); clf
    scatter(ld,rd,'k.'); 
    set(gca,'FontSize',18)
    xlabel('Left fiber density (fibers/mm^2)'); ylabel('Right fiber density (fibers/mm^2)'); 
    %  rd = ld*s
    %  pinv(ld)*rd = s
    maxAxisVal = ceil(max([ld; rd])/1000)*1000;
    slope = pinv(ld)*rd;
    regLineHandle = line([0,maxAxisVal], [0,slope*maxAxisVal]); 
    set(regLineHandle,'color','k','LineStyle','-','LineWidth',1)
    unitLineHandle = line([0,maxAxisVal], [0,maxAxisVal]); 
    set(unitLineHandle,'color','k','LineStyle',':','LineWidth',1)
    if(maxAxisVal>4000)
      set(gca,'xtick',[0:2000:maxAxisVal],'ytick',[0:2000:maxAxisVal]);
    else
      set(gca,'xtick',[0:1000:maxAxisVal],'ytick',[0:1000:maxAxisVal]);
    end
    set(gcf, 'PaperPositionMode', 'auto');
    print(gcf, '-dpng', '-r200', [fn '_scatter.png']);
    print(gcf, '-deps', '-tiff', [fn '_scatter.eps']);
  end
  pause(2);
end

% Compute r^2 matrix
clear rmat pmar;
for(ii=1:nAreas)
  for(jj=1:nAreas)
    ld = allLeftDensity(:,:,ii);
    rd = allRightDensity(:,:,jj);
    nz = ld>0 | rd>0;
    ld = ld(nz);
    rd = rd(nz);
    [r,p] = corrcoef(ld,rd); r = r(2); p = p(2); df = length(ld)-2;
    msg = sprintf('left %s vs. right %s: r^2=%0.2f (p=%0.4f, df=%d)', areaNames{ii}, areaNames{jj}, r^2, p, df);
    %disp(msg);
    rmat(ii,jj) = r^2;
    pmat(ii,jj) = p;
  end
end
csvwrite([figName '_rsqMatrix.csv'], rmat);

clear maxAllAreasDensity;
allAreasDensity = allLeftDensity+allRightDensity;
for(ii=[1:size(allDensity,3)])
  maxAllAreasDensity(ii) = max(max(allAreasDensity(:,:,ii)));
end

lineWidth = 2;
axisSamp = [min(xSamples),max(xSamples),min(ySamples),max(ySamples)];

figure(45);clf;
clevel = repmat(maxAllAreasDensity'.*0.5,1,2); c = [0 0 0];
contour(xSamples,ySamples,meanCC',ccThresh,'k-'); hold on;
axis equal tight xy;
contour(xSamples,ySamples,allAreasDensity(:,:,2)',clevel(2,:),':','LineWidth',lineWidth,'LineColor',c);
contour(xSamples,ySamples,allAreasDensity(:,:,3)',clevel(3,:),'-','LineWidth',lineWidth,'LineColor',c);
contour(xSamples,ySamples,allAreasDensity(:,:,4)',clevel(4,:),'--','LineWidth',lineWidth,'LineColor',c);
axis(axisSamp);
grid on;
set(gca,'xtick',xtick,'ytick',ytick)
set(gca,'XColor',gridColor,'YColor',gridColor);
set(gca,'xticklabel',[],'yticklabel',[]);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r200', [figName '_contour.png']);
print(gcf, '-deps', '-tiff', [figName '_contour.eps']);

% Do another, this time using a single absolute contour threshold rather
% than a separatate threshhold for each.
figure(46);clf;
contour(xSamples,ySamples,meanCC',ccThresh,'k-'); hold on;
axis equal tight xy;
contour(xSamples,ySamples,allAreasDensity(:,:,2)',clevel(4,:),':','LineWidth',lineWidth,'LineColor',c);
contour(xSamples,ySamples,allAreasDensity(:,:,3)',clevel(4,:),'-','LineWidth',lineWidth,'LineColor',c);
contour(xSamples,ySamples,allAreasDensity(:,:,4)',clevel(4,:),'--','LineWidth',lineWidth,'LineColor',c);
axis(axisSamp);
grid on;
set(gca,'xtick',xtick,'ytick',ytick)
set(gca,'XColor',gridColor,'YColor',gridColor);
set(gca,'xticklabel',[],'yticklabel',[]);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r200', [figName '_contourAbsolute.png']);
print(gcf, '-deps', '-tiff', [figName '_contourAbsolute.eps']);

%figure; mesh(allLeftDensity); hold on; mesh(-1*allRightDensity);

%figure; hist(overlapIndex)


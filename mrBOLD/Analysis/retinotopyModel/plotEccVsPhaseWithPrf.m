function plotEccVsPhaseWithPrf(view, prf_size,fieldRange,method)
%
% plotEccVsPhaseWithPrf(view, prf_size,fieldRange)
% prf_size=0: plot pRF center, 1: use pRF size
%
% Before you run this script, you have to load 'variance explained', 'eccentricity',
% 'polar-angle' and 'prf size' into 'co', 'map', 'ph' and 'amp' fields, respectively
%
% 08/02 KA wrote

if ieNotDefined('view'), error('View must be defined.'); end
if ieNotDefined('prf_size'), prf_size = 1;  end % deg
if ieNotDefined('fieldRange'), fieldRange = 20;  end % deg
if ieNotDefined('method'), method = 'sum';  end % deg

curScan = getCurScan(view);

% try,
%     rmFile   = viewGet(v,'rmFile');
%     rmParams = viewGet(v,'rmParams');
% catch,
%     error('Need retModel information (file)');
% end
%
% view.co = rmGet(rmData.model{1},'co');


% Get selpts from current ROI
if view.selectedROI,
   ROIcoords = getCurROIcoords(view);
   ROIname = view.ROIs(view.selectedROI).name;
   % Get co and ph (vectors) for the current scan, within the
   % current ROI.
   %
   % We assume that you loaded the pRF
   % model and eccentricity will be stored in the map-field.
   co = getCurDataROI(view,'co',curScan,ROIcoords);
   ecc = getCurDataROI(view,'map',curScan,ROIcoords);
   ph = getCurDataROI(view,'ph',curScan,ROIcoords);
   amp = getCurDataROI(view,'amp',curScan,ROIcoords);
end

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = sum(isnan(co));
if NaNs
    myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
    notNaNs = ~isnan(co);
    co = co(notNaNs);
    ph = ph(notNaNs);
    ecc = ecc(notNaNs);
end

% Read cothresh and phWindow from the slide bars, and get indices
% of the co and ph vectors that satisfy the cothresh and phWindow.
%
cothresh = getCothresh(view);
eccthresh = getMapWindow(view);
eccthresh = eccthresh(2);
% if strcmp(view.ui.mapMode.clipMode,'auto')
%     eccthresh = 14;
% else
%     eccthresh = view.ui.mapMode.clipMode(2);
% end
coIndices = co>cothresh & ecc<=eccthresh;

% Pull out co and ph for desired pixels
subCo =   co(coIndices);
subPh =   ph(coIndices);
subEcc = ecc(coIndices);
subSize = amp(coIndices);

% selectGraphWin;

figure
% Window header
headerStr = ['Eccentricity vs. phase, ROI ',ROIname,', scan ',num2str(curScan)];
set(gcf,'Name',headerStr);

% Plot it
fontSize = 14;
symbolSize = 4;

% polar plot
subX = subEcc.*cos(subPh);
subY = subEcc.*sin(subPh);

% polar plot params
params.grid = 'on';
params.line = 'off';
params.gridColor = [0.6,0.6,0.6];
params.fontSize = fontSize;
params.symbol = 'o';
params.size = symbolSize;
params.color = 'w';
params.fillColor = 'w';
params.maxAmp = eccthresh;
params.ringTicks = (0:eccthresh);

% Use 'polarPlot' to set up grid'
% clf
% polarPlot(0,params);

% t = linspace(0,2*pi,100);
% finish plotting it
% for i=1:size(subX,2)
% %     patch(subX(i)+subAmp(i)*sin(t),subY(i)+subAmp(i)*cos(t),[1-subCo(i) 1-subCo(i) 1-subCo(i)])
% %     patch(subX(i)+subAmp(i)*sin(t),subY(i)+subAmp(i)*cos(t),[1-subCo(i) 1-subCo(i) 1-subCo(i)])
%     h=plot(subX(i),subY(i),'o','MarkerSize',symbolSize*2*subAmp(i)/mean(subAmp),'Color',[1-subCo(i) 1-subCo(i) 1-subCo(i)]);
%     set(h,'MarkerFaceColor',[1-subCo(i) 1-subCo(i) 1-subCo(i)])
% end
% hold off

%
sampleRate = 0.2; % Deg
x = (-fieldRange:sampleRate:fieldRange);
y = x;
[X,Y] = meshgrid(x,y);
%sigma = 5;  % Deg
%rf = rfGaussian2d(X,Y,sigma);

RF_sum=zeros(size(X));
RF_weight = 0;
if prf_size==0
   subSize=ones(size(subSize))*0.5;
end

% different methods of combining them. They are all scaled between 0 and 1.
switch lower(method)
    % METHOD 1: sum everything
    case {'sum','add'}
        for i=1:size(subX,2)
            RF_sum = RF_sum+rfGaussian2d(X,Y,subSize(i),subSize(i),0, subX(i),subY(i))*subCo(i);
            RF_weight = RF_weight + subCo(i);
        end
        % normalize between 0 and 1
        RF_sum = RF_sum./RF_weight;

    % METHOD 2: 
    case {'max','profile'}
        for i=1:size(subX,2)
            RF_sum = max(RF_sum,rfGaussian2d(X,Y,subSize(i),subSize(i),0, subX(i),subY(i))*subCo(i));
        end
        

    % METHOD 3: probability summation (TO DO)
    otherwise
        error('Unknown method %s',method)
end

% for i=1:size(X,1)
%     for j=1:size(X,2)
%         if X(i,j)^2+Y(i,j)^2>15^2
%             RF_sum(i,j)=NaN;
%         end
%     end
% end

hold on
imagesc(X(1,:),Y(:,1),flipud(RF_sum));axis equal
t = 0:.01:2*pi;
polar(t,ones(size(t))*5,'w')
polar(t,ones(size(t))*10,'w')
polar(t,ones(size(t))*15,'w')
polar(t,ones(size(t))*20,'w')
plot([0 0],[-fieldRange fieldRange],'w')
plot([-sqrt(fieldRange^2/2) sqrt(fieldRange^2/2)],[-sqrt(fieldRange^2/2) sqrt(fieldRange^2/2)],'w')
plot([-fieldRange fieldRange],[0 0],'w')
plot([-sqrt(fieldRange^2/2) sqrt(fieldRange^2/2)],[sqrt(fieldRange^2/2) -sqrt(fieldRange^2/2)],'w')
xlim([-fieldRange fieldRange])
ylim([-fieldRange fieldRange])
caxis([0 1]);


% Save the data in gca('UserData')
data.co = co;
data.ph = ph;
data.subCo = subCo;
data.subPh = subPh;
set(gca,'UserData',data);

return;
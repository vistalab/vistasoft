function hrfData = hrfSearchFit(view)
% hrfSearchFit - find optimal HRF parameters for every voxel
%
% hrfData = hrfSearchFit(view);
% 
% 2007/01 SOD: wrote it.

warning off MATLAB:divideByZero;

%-----------------------------------
% input handling
% If view is empty try getting data from figure. Set view=[] so we
% can use this distinction throughout.
%-----------------------------------
figuredata = [];
if ieNotDefined('view'),   
  fprintf('[%s]:WARNING:No view struct',mfilename);
  view = [];
  try
    figuredata = get(gca,'UserData');
    % remove extra point
    figuredata.x = figuredata.x(1:end-1);
    figuredata.y = figuredata.y(1:end-1);
    figuredata.e = figuredata.e(1:end-1);
  catch %#ok<CTCH>
    error('No view struct nor figure data.');
  end;
end;

%-----------------------------------
% now loop over slices
% but initiate stuff first
%-----------------------------------
if ~isempty(view),
  loopSlices = 1:viewGet(view,'nSlices');
else
  loopSlices = 1;
end;
numSlices  = numel(loopSlices);

%--- parameters for search fit (fminsearch)
if isempty(figuredata),
  searchOptions.TolX    = 1e-2;
  searchOptions.MaxIter = 50;
  searchOptions.Display = 'none';
  searchOptions.tolFun  = 1e-2;
else
  searchOptions.TolX    = 1e-6;
  searchOptions.MaxIter = 200;
  searchOptions.Display = 'none';
  searchOptions.tolFun  = 1e-6;  
end;
cothresh              = 0.3;
if ~isempty(view),
  scan = viewGet(view, 'curScan');
end;

%--- defaults
wHRF = {'boynton','twogammas'};
%hrfDefaults = {[1 6.2 0.1]',[6.8 10.6 13.2 10.7 0.6]'};
hrfDefaults = {[1.68 3 2.05]',[5.4 5.2 10.8 7.35 0.35]'};
% get corresponding coherence map
if ~isempty(view),
  coData = viewGet(view,'co');
  coData = coData{scan};
else
  coData = 1;
end;

% data to be collected
boyntonData = zeros(prod(size(coData,1),size(coData,2)),3); 
boyntonPeak{1} = zeros(size(coData)); 
boyntonFWHM{1} = zeros(size(coData)); 
twogammasData = zeros(prod(size(coData,1),size(coData,2)),5); 
twogammasPeak{1} = zeros(size(coData)); 
twogammasFWHM{1} = zeros(size(coData)); 

%--- upsample
% typically TR=1.5 sec, we will estimate a 1 sec hrf
if ~isempty(view),
  nFrames = numFrames(view,scan)./numCycles(view,scan);
  tr      = viewGet(view,'tr',scan);
else
  nFrames = numel(figuredata.y);
  tr      = mean(diff(figuredata.x));
end;
% we will only process time curves that peak somewhere in the beginning. We
% use a sinewave not to be too selective on which voxels to include and 
% not to bias the end results.
sinewave = sin((0:nFrames-1)'./(nFrames-1).*2*pi);
if ~isempty(figuredata),
    % upsample to data every 0.25 sec
    upsample = tr/0.25;
    tics     = zeros(nFrames.*upsample,1);
    %tics(1:4:2*upsample) = 1;        % model a response every second
    tics(1:upsample:2*upsample) = 1;  % model a response every 1.5 sec
    tr       = tr./upsample;
else
    upsample = 1;
    tics     = zeros(nFrames.*upsample,1);
    tics(1)  = 1;
end;
estDC = [true true];

% go loop over slices
tic;fprintf(1,'[%s]:Processing',mfilename);drawnow;
for slice=loopSlices,
  % get data
  if ~isempty(view),
      tcData = getData(view,scan,slice);
      % threshold voxels
      t=rmGLM(tcData,sinewave);
      keep = find(t>=1.96); % significant correlation with sinewave
  else
      tcData = figuredata.y(:);
      tcData = tcData - mean(tcData([end-[0 1]]));
      figuredata.y = tcData;
      % we keep all data in the figure
      keep = 1;
      %wData  = normimage(1./blurtic(figuredata.e',3),[0 1]);
      %wData  = blurtic(1./figuredata.e',3).*abs(blurtic(figuredata.y',3));
  end;
  tcRSS = sum(tcData.^2);
  fprintf(1,'(%d):',numel(keep));drawnow;
  % now loop over voxels
  counter = 0;
  for m=1:numel(keep),  
    if floor((m/numel(keep))*10)>counter,
        counter=counter+1;
        fprintf('.');drawnow;
    end;
    n = keep(m);
    for ii=1:2,
      outParams = fminsearch(@(x) hrfFit(x,tcData(:,n),tics,tr,wHRF{ii},tcRSS(n),upsample,estDC(ii)),...
                             hrfDefaults{ii},searchOptions);
      % compute peak and fwhm
      [tmp1,tmp2,tmp3,specs]=rfConvolveTC(tics,tr,wHRF{ii},outParams);
      
      % store 
      [i,j] = ind2sub(size(coData(:,:,1)),n);
      if ii==1,
        boyntonPeak{1}(i,j,slice) = specs.timeToPeak; 
        boyntonFWHM{1}(i,j,slice) = specs.fwhm; 
        boyntonData(n,:) = outParams;
      else
        twogammasPeak{1}(i,j,slice) = specs.timeToPeak; 
        twogammasFWHM{1}(i,j,slice) = specs.fwhm; 
        twogammasData(n,:) = outParams;
      end; 
    end;
  end;
  fprintf(1,'|');drawnow;
end;
fprintf(1,'Done[%.1f].\n',toc./60);drawnow;

% save
if ~isempty(view),
  save
  pathStr = dataDir(view);
  map = boyntonPeak; mapName = 'boyntonPeak';
  save(fullfile(pathStr,mapName),'map','mapName');
  map = boyntonFWHM; mapName = 'boyntonFWHM';
  save(fullfile(pathStr,mapName),'map','mapName');
  map = twogammasPeak; mapName = 'twogammasPeak';
  save(fullfile(pathStr,mapName),'map','mapName');
  map = twogammasFWHM; mapName = 'twogammasFWHM';
  save(fullfile(pathStr,mapName),'map','mapName');
else
  d=figuredata;    
  d.x = d.x +mean(diff(d.x))./2;
  % save
  [pa fi]=fileparts(pwd);
  save(fullfile(pa,fi,sprintf('%s-hrfest',fi)));
  for n=1:2,
    figure;
    if n==1, outParams = boyntonData;disp(outParams);
    else    outParams = twogammasData;disp(outParams);
    end;
    % 3 sec
    [design,tmp2,tmp3,specs]=rfConvolveTC(tics,tr,wHRF{n},outParams);
    if estDC(n),
        design = [design ones(numel(design),1)];
    end;
    [t,df,RSS,B] = rmGLM(d.y(:),design(upsample/2:upsample:end,:));
    design = design*B;
    % 1 sec
    tics2 = zeros(size(tics));tics2(1)=1;
    [design2]=rfConvolveTC(tics2,tr,wHRF{n},outParams);
    if estDC(n),
        design2 = [design2 ones(numel(design2),1)];
    end;
    design2 = design2*B;
    
    if estDC(n);
        design  = design - B(2);
        design2 = design2 - B(2);
        d.y     = d.y - B(2);
    end;
    
    errorbar(d.x,d.y,d.e,'ko:','MarkerFaceColor',[0 0 0]);
    errorbar(d.x,d.y,d.e,'ko','MarkerFaceColor',[0 0 0]);
    hold on;
    plot((0:numel(design)-1).*tr,design,'k');
    plot((0:numel(design2)-1).*tr,design2,'k--');
    %axis([floor(min(d.x)) ceil(max(d.x)) -1 2.5]);
    axis([floor(min(d.x)) ceil(max(d.x)) -1 2]);
    set(gca,'YTick',(-2:5),'XTick',(0:5:30));
    %grid on;
    % axis off;
    plot([-50 50],[0 0],'k:');
    xlabel('time (sec)');
    ylabel('BOLD signal change (%)');
    
    r = corrcoef(d.y,design(upsample/2:upsample:end,1));
    title(sprintf(['%s: t=%.4f; peak=%.2fsec; ' ...
                          'fwhm=%.2fsec; var. exp.=%.1f'],...
                          wHRF{n},t,specs.timeToPeak,specs.fwhm,...
                          (r(1,2).^2).*100));
                      
  end;
end;
  
  
return;



%-----------------------------------------
function data=getData(view,scan,slice)
% get data
data = loadtSeries(view,scan,slice);
% convert to % BOLD
dc   = ones(size(data,1),1)*mean(data);
data = ((data./dc) - 1) .*100;
% average repeats
data = rmAverageTime(data,numCycles(view,scan));
% find zero
z    = ones(size(data,1),1)*mean(data([size(data,1)-[0 1]],:));
data = data - z;
return
%-----------------------------------------



%-----------------------------------------
function rss=hrfFit(params,data,tics,tr,wfit,rawrss,upsample,estDC)

% assign maximal rss
rss = 100;

% no negative params
if sum(params<=0), return; end; 

% two gamma fit?
twogamma = numel(params)==5;

% positive peak first for two gammas
if twogamma,
    if params(3)<params(1), return; end;
end

try
    % accuracy of penalizing factors
    acc = 0.005;
    
    % get HRF
    design = rfConvolveTC(tics,tr,wfit,params');
    
    % finish HRF at the end close to the start
    if abs(design(end))>acc, return; end;
    % penalize a second peak
    if twogamma, 
        % get diff (approximate derivative)
        d = diff(design);
        
        % are there two rising slopes
        if any(diff(find(d>acc))-1)
            % two gamma function should end with a rising slope
            % (ie no two positive peaks), because we are looking at the slope
            % we increase the accuracy

            if find(d>acc/20,1,'last') < find(d<-acc/20,1,'last'),
                return;
            end
        end
    end;

    if upsample~=1,
        design = design(floor(upsample./2)+1:upsample:end);
    end;
    if estDC,
        design = [design ones(size(design))];
    end
    % GLM fit
    b = pinv(design)*data;
    % no negative fits
    b(1) = abs(b(1));
    % compute rss
    rss = norm(data - design*b).^2;
    % normalize
    rss = rss./rawrss.*100;
end;
return;
%-----------------------------------------

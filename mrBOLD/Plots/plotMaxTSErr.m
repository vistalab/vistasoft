function plotMaxTSErr(view,scan)
%
% plotMaxTSErr(view,[scan])
% 
% Plots the max tSeries diff for the current scan and current
% slice.  This should give a correlate of motion artifact.
%
% If you change this function make parallel changes in:
%   plotResidualError
%
% djh, 2/2001. rmse instead of var, conver to 3.0

if ~exist('scan','var')
   scan = getCurScan(view);
end

slices = sliceList(view,scan);
nSlices = length(slices);
nFrames = numFrames(view,scan);
nCycles = numCycles(view,scan);
frameRate = getFrameRate(view,scan);

% Load tSerises 
% Load tSeries and compute max frame-to-frame difference
waitHandle = mrvWaitbar(0,'Loading tSeries and computing max frame-to-frame difference.  Please wait...');
vres = zeros(nSlices,nFrames);
for slice=slices
   mrvWaitbar(slice/nSlices);
   tSeries = loadtSeries(view,scan,slice);
   for frame=1:nFrames-1
      vres(slice,frame) = max(tSeries(frame,:)-tSeries(frame+1,:));
   end
end
close(waitHandle)

% max across slices
vres = max(vres);

% dont plot anything for the last frame (otherwise it would be 0)
vres(nFrames)=NaN;

% plot it
selectGraphWin;
fontSize = 14;
headerStr = ['Max frame-to-frame difference, scan: ',num2str(scan)];
set(gcf,'Name',headerStr);
x = 1:nFrames;
plot(x,vres,'-b','LineWidth',2)
set(gca,'FontSize',fontSize)
set(gca,'XLim',[0,nFrames]);
xlabel('Frame number','FontSize',fontSize) 
ylabel('Difference (raw intensity units)','FontSize',fontSize) 

% Save the data in gca('UserData')
data.frameNumbers = x;
data.tSeries  =  vres;
set(gca,'UserData',data);


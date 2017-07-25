function view = plotResidualError(view,scan,baseFrame)
%
% view = plotResidualError(view,scan,[baseFrame])
%
% Plots the rmse between each frame and a baseFrame
%
% If you change this function make parallel changes in:
%   plotMaxTSErr
%
% djh, 2/2001. rmse instead of var, conver to 3.0

if ~exist('scan','var')
   scan = getCurScan(view);
end
if ~exist('baseFrame','var')
   baseFrame=1;
   %baseFrame=nFrames;
end

slices = sliceList(view,scan);
nSlices = length(slices);
nFrames = numFrames(view,scan);

% Load tSerises and compute RMSE slice by slice
waitHandle = mrvWaitbar(0,'Loading tSeries and computing RMSE.  Please wait...');
vres = zeros(nSlices,nFrames);
for slice=slices
   mrvWaitbar(slice/nSlices);
   tSeries = loadtSeries(view,scan,slice);
   for frame=1:nFrames
      vres(slice,frame) = sqrt(mse(tSeries(frame,:),tSeries(baseFrame,:)));
   end
end
close(waitHandle)

% mean across slices
vres = mean(vres);

% dont plot anything for the base frame (otherwise it would be 0)
vres(baseFrame)=NaN;

% plot it
selectGraphWin;
fontSize = 14;
set(gcf,'Name',['RMSE, scan: ',num2str(scan),', baseframe:',int2str(baseFrame)]);
x = 1:nFrames;
plot(x,vres,'-b','LineWidth',2)
set(gca,'FontSize',fontSize)
set(gca,'XLim',[0,nFrames]);
xlabel('Frame number','FontSize',fontSize) 
ylabel('RMSE (raw intensity units)','FontSize',fontSize) 

% Save the data in gca('UserData')
data.frameNumbers = x;
data.tSeries  =  vres;
set(gca,'UserData',data);

return

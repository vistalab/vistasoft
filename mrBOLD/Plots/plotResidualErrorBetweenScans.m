function plotResidualErrorBetweenScans(view,scan,frameNum)
%
% plotResidualErrorBetweenScans(view,[scan],[frameNum])
%
% Plots the rmse between a single frame from each scan.
%
% If you change this function make parallel changes in:
%   plotMaxTSErr
%
% 2004.06.22 RFD & MBS wrote it.

if ~exist('scan','var')
    % Use all the scans
    nScans = numScans(view);
    scan = 1:nScans;
else
    nScans = length(scan);    
end
if ~exist('frameNum','var')
   frameNum = 1;
end

slices = sliceList(view,scan(1));
nSlices = length(slices);
% Load tSerises and compute RMSE slice by slice

err = zeros(nScans,nSlices);

waitHandle = mrvWaitbar(0,['Loading tSeries for reference scan. Please wait...']);
for slice=slices
    mrvWaitbar(slice/nSlices);
    tSeries = loadtSeries(view,scan(1),slice);
    refScan(slice,:) = tSeries(frameNum,:);
end
close(waitHandle);

for ii=2:length(scan)
    thisScan = scan(ii);
    waitHandle = mrvWaitbar(0,['Loading tSeries for scan',int2str(ii),' Please wait...']);
    for slice=slices
        mrvWaitbar(slice/nSlices);
        tSeries = loadtSeries(view,thisScan,slice);
        err(ii,slice) = sqrt(mse(tSeries(frameNum,:),refScan(slice,:)));
    end
    close(waitHandle);
end

% plot it
selectGraphWin;
fontSize = 14;
set(gcf,'Name',['RMSE between scans (',num2str(scan),') frame:',int2str(frameNum)]);
imagesc(err');
colorbar;
colormap hot;

set(gca,'FontSize',fontSize)

ylabel('Slice number','FontSize',fontSize) 
xlabel('Scan number','FontSize',fontSize) 

% Save the data in gca('UserData')
data.tSeries  =  err;
set(gca,'UserData',data);

return

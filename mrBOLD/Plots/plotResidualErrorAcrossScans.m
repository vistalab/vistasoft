function view = plotResidualErrorAcrossScans(view,scan,baseFrame)
%
% view = plotResidualError(view,scan,[baseFrame])
%
% Plots the rmse between each frame and a baseFrame
%
% If you change this function make parallel changes in:
%   plotMaxTSErr
%
% djh, 2/2001. rmse instead of var, conver to 3.0
% arw, 08.20.02 . This version shows the error across all the scans listed in 'scan'
% Useful for identifying bad scans in a large set.
% It should also work with 1 scan
% $Date: 2004/06/24 20:53:36 $
% $Author: bob $

if ~exist('scan','var')
    % Use all the scans
    nScans=numScans(view);
    scan=1:nScans;
else
    nScans=length(scan);    
end
if ~exist('baseFrame','var')
   baseFrame=1;
   %baseFrame=nFrames;
end

slices = sliceList(view,scan(1));
nSlices = length(slices);
nFrames = numFrames(view,scan(1));

% Load tSerises and compute RMSE slice by slice

vres = zeros(nScans,nSlices,nFrames);
counter=1;
for thisScan=scan
    waitHandle = mrvWaitbar(0,['Loading tSeries for scan',int2str(thisScan),' Please wait...']);
   for slice=slices
    mrvWaitbar(slice/nSlices);
    tSeries = loadtSeries(view,thisScan,slice);
     for frame=1:nFrames
          vres(counter,slice,frame) = sqrt(mse(tSeries(frame,:),tSeries(baseFrame,:)));
        end
    end
    counter=counter+1;
    %disp(counter);
    
    close(waitHandle);
end



% mean across slices
vres = squeeze(mean(vres,2));

% dont plot anything for the base frame (otherwise it would be 0)
vres(baseFrame)=NaN;

% plot it
selectGraphWin;
fontSize = 14;
set(gcf,'Name',['RMSE, scan: ',num2str(scan),', baseframe:',int2str(baseFrame)]);
x = 1:nFrames;
imagesc(vres);
colorbar;
colormap hot;

set(gca,'FontSize',fontSize)

xlabel('Frame number','FontSize',fontSize) 
ylabel('Scan number','FontSize',fontSize) 

% Save the data in gca('UserData')
data.frameNumbers = x;
data.tSeries  =  vres;
set(gca,'UserData',data);

return

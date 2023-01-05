function view = revertMotionComp(view,scanNum)
%
% view = revertMotionComp(view,scanNum)
%
% Moves origTSeries file back to tSeries, for specified scan.
% scanNum defaults to current scan.  Clears view.tSeries field.
%
% djh, 4/15/99

if ~exist('scanNum','var')
   scanNum = getCurScan(view);
end

% Path to tSeries files
dirPathStr = fullfile(dataDir(view),'TSeries',['Scan',num2str(scanNum)]);

for sliceNum = sliceList(view,scanNum)
   
   % File names
   fileName = fullfile(dirPathStr,['tSeries',num2str(sliceNum),'.mat']);
   origFileName = fullfile(dirPathStr,['origTSeries',num2str(sliceNum),'.mat']);
  
   % Warning if origTSeries file doesn't exist.
   if ~exist(origFileName,'file')
      disp([origFileName ' does not exist.  Not reverting.']);
   else
      disp(['Reverting ' origFileName ' to ' fileName]);
      % Copy origTSeries.mat to tSeries.mat
      status = copyfile(origFileName,fileName);
      if (~status) | (~exist(fileName,'file'))
         myErrorDlg([origFileName ' could not be copied to ' fileName]);
      end
      % Delete origTSeries.mat
      delete(origFileName);
      if exist(origFileName,'file')
         myErrorDlg([origFileName ' could not be deleted.']);
      end
   end
end

% Clear view.tSeries
view.tSeries = [];
view.tSeriesScan = NaN;
view.tSeriesSlice = NaN;

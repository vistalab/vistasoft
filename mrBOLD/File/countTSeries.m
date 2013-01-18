function  numTSeries = countTSeries(view)
%numTSeries = countTSeries(view)
%
%Counts the tSeries
%
% 12.22.98 RFD: changed countFiles to work with new tSeries format ('.dat')
%				It should still work with old-style '.mat' tSeries files too.

if exist('view','var')
    subdir = view.subdir;
else
    subdir = 'Inplane';
end

[numScans,scanDirList] = countDirs('Scan*',tSeriesDir(view));
for scan=1:numScans
    dirPathStr = fullfile(tSeriesDir(view),scanDirList{scan});
    numTSeries(scan) = countFiles('tSeries*',dirPathStr);
end

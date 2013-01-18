function M = newestScanMovie(slice, scans, fps);
%
% M = newestScanMovie([slice=middle], [scans=1], [framesPerSec=24]);
% 
% play a movie of the most recent scan for realtime.
%
% slice: which slice to show [default: middle slice]
%
% scans: which scanned to show, indexed in order of most
% recent created. E.g., scans==1 [default] shows the most 
% recent scan, scans==[1 2 3] shows the most recent 3 scans,
% and scans==[3] shows the third most recent scan.
%
% framesPerSec: frames per second to show the movie. [Default is 24].
%
% Returns M, the movie object created by tSeriesMovie.
%
% ras, 08/05
if notDefined('scans'), scans = 1;    end
if notDefined('fps'), fps = 24;    end

% this is for rtviz:
pFileDir = '/lcmr3/mrraw';

% if it's not there, maybe we're trying to run this in 
% a session directory?
if ~exist(pFileDir,'dir')
    pFileDir = fullfile(pwd,'Raw','Pfiles');
end

% finally, try curr directory
if ~exist(pFileDir,'dir')
    tst = dir(fullfile(pwd,'P*.7.mag'));
    if ~isempty(tst)
        pFileDir = pwd;
    else
        error('Couldn''t find any PFiles!');
    end
end

% get mag file paths for specified scans
[ignore, magList, eFileList] = newestMagFile(pFileDir);
magList = fliplr(magList);
eFileList = fliplr(eFileList);
magList = magList(scans);
eFileList = eFileList(scans);
for i = 1:length(magList)
    magList{i} = fullfile(pFileDir,magList{i});
end

if ieNotDefined('slice')
    % figure out middle slice
    hdr = rtReadEfileHeader(magList{1});
    slice = round(length(hdr.slices)/2);
    fprintf('Showing movie for slice %i\n',slice);
end

data = [];
for i = 1:length(scans)
    data = cat(4,data,readMagFile(magList{scans(i)},slice));
end
data = permute(data,[1 2 4 3]);

% use a histogram-based threshold to look nice
data = histoThresh(data);

M = mplay(data, fps);
M.play;

return


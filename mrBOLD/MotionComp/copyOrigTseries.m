function copyOrigTseries(view,scanList);
%
% copyOrigTseries(view,scans);
%
% Copies [scan]/tSeries*.mat to [scan]/origTseries*.mat.
% Prompt user if any of the origTseries files already exist
%
% djh, 3/2001, updated to mrLoadRet 3
global HOMEDIR
% Loop through scans & slices, checking if any origTseries files already exist
found = 0;
for scan = scanList
    % Path to tSeries files
    dirPathStr = fullfile(tSeriesDir(view),['Scan',num2str(scan)]);
    for slice = sliceList(view,scan)
        % fileNames
        fileName = fullfile(dirPathStr,['tSeries',num2str(slice),'.mat']);
        origFileName = fullfile(dirPathStr,['origTSeries',num2str(slice),'.mat']);
        % Error if tSeries is in old format (.mat)
        if ~exist([fileName],'file')
            myErrorDlg(['TSeries file ' fileName ...
                    'does not exist.  Perhaps tSeries is in .dat format (use convertDatToMat)']);
        end
        % set found=1 if origTseries already exists
        if exist(origFileName,'file')
            found = 1;
        end
    end
end
% Warn if origTSeries file already exists.
if found
    quest = strvcat(['Backup copy of original tSeries files already exist.']...
        ,' ', 'If you continue, the current tSeries WILL BE OVERWRITTEN. Do you want to continue?');
    resp = questdlg(quest, 'WARNING');
    if ~strcmp(resp,'Yes')
        error('Aborted');
    end
    return
end
% Loop through scans & slices again, doing the copy
for scan = scanList    % Path to tSeries files
    dirPathStr = fullfile(tSeriesDir(view),['Scan',num2str(scan)]);
    for slice = sliceList(view,scan)
        % fileNames
        fileName = fullfile(dirPathStr,['tSeries',num2str(slice),'.mat']);
        origFileName = fullfile(dirPathStr,['origTSeries',num2str(slice),'.mat']);
        disp(['Copying ' fileName ' to ' origFileName]);
        % Copy original tSeries in origTSeries.dat
        status = copyfile(fileName,origFileName);
        % Error if copy failed
        if (~status) | (~exist(origFileName,'file'))
            myErrorDlg([fileName ' could not be copied to ' origFileName]);
        end
    end
end
        
return

% Debug/test
loadSession
hiddenIP = initHiddenInplane;
copyOrigTseries(hiddenIP,1,1);

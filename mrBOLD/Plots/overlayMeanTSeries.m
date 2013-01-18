function h = overlayMeanTSeries(view,scan1,scan2);
%  h = overlayMeanTSeries(view,[scan1,scan2]);
%
% Provides an interface for viewing mean tSeries on top of one
% another.Created for the purpose of seeing if movement occurred.
% 
% scan1 and scan2 are the two tSeries to compare. Will compute the
% mean (all slices), and overlay them. They default to the first
% and last scan in the current data type.
%
% If either scan1 or scan2 is entered as 0, this will cause
% a dialog to be brought up to get the scan numbers.
%
% written 06/17/04 ras.
if ieNotDefined('scan1')
    scan1 = 1;
end

if ieNotDefined('scan2')
    dt = viewGet(view,'curdt');
    global dataTYPES;
    scan2 = length(dataTYPES(dt).scanParams);
end

slices = 1:numSlices(view);

if scan1==0 | scan2==0
    % get the scan nums with a dialog
    prompt = {'First Scan:','Second Scan:'};
    dlgTitle = 'Overlay Mean functionals from which scans?';
    defaults = {'1' '2'};    
    answer = inputdlg(prompt,dlgTitle,1,defaults);
    scan1 = str2num(answer{1});
    scan2 = str2num(answer{2});
end

hbox = msgbox('Getting mean tSeries to overlay...');

mapPath = fullfile(dataDir(view),'meanMap.mat');

if ~exist(mapPath,'file')
    % compute the mean map
    mrGlobals;
    loadSession;
    hI = initHiddenInplane;
    hI = computeMeanMap(hI,0);
    clear hI;
end

load(mapPath,'map');

firstScan = map{scan1};
lastScan = map{scan2};

name1 = sprintf('tSeries Scan %i',scan1);
name2 = sprintf('tSeries Scan %i',scan2);

overlayMaps(view,firstScan,lastScan,1,name1,name2);

close(hbox);

return

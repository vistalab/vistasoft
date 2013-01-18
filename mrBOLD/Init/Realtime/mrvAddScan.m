function mrvAddScan(annotation,magNum,parfile,nCycles,skipFrames,nFrames);
%
% mrvAddScan([annotation],[magNum],[parfile],[nCycles],[skipFrames],[nFrames]);
%
% Add a single scan to the Original data type of a mrVista session,
% run a mean map and cor anal for that scan, and create/update an
% inplane montage view.
%
% annotation: text description of the scan.
% magNum: P-file name or number. E.g., 'P51200.7.mag', or just 51200. 
%         Automatically zero pads, so 512 will be parsed as P00512.7.mag.
%         If omitted, looks for most recently-created mag file.
% parfile: parfile to assign to scan, if any. (For event-related analyses)
% nCycles: # of cycles in scan, for corAnal. [Default 8]
% skipFrames: # of frames at the beginning of the scan to keep. [Default 0]
% nFrames: # of frames, after the skipped frames, to keep. [Default 96]
%
% ras 03/05.
if ieNotDefined('parfile'),     parfile = '';                   end
if ieNotDefined('nCycles'),     nCycles = 8;                    end
if ieNotDefined('skipFrames'),  skipFrames = 6;                 end
if ieNotDefined('nFrames'),     nFrames = 96;                   end

% allow character inputs:
if ischar(nCycles), nCycles = str2num(nCycles);                 end
if ischar(skipFrames), skipFrames = str2num(skipFrames);        end
if ischar(nFrames), nFrames = str2num(nFrames);                 end

mrGlobals;

% this option is good for rtviz only!:
magDir = '/lcmr3/mrraw';

if ieNotDefined('magNum')
    magFile = newestMagFile(magDir);
else
    if isnumeric(magNum)
        % convert to char
        magNum = sprintf('%05.0d',magNum);
    elseif length(magNum) < 5
        % zero pad
       for i = 1:5-length(magNum)
           magNum = ['0' magNum];
       end
    end
    magFile = fullfile(magDir,sprintf('P%s.7.mag',magNum));
end

% sessDir = pwd; 
% cd(sessDir);

% here do stuff to verify that a session
% exists, initializing if possible, and
% loading mrGlobals
if ~exist('mrSESSION.mat','file')
    rtNewSession;
end

% find most recent mag file

% hack:
hdr = rtReadEfileHeader(magFile);
nSlices = length(hdr.slices);

% newestScanMovie;

% now get the new scan and add it to the session:
% (junk the first half cycle -- Junjie's stuff):
scan = rtGetFunctionals(magFile,skipFrames,nFrames,nCycles,annotation);

% default annotation
if ieNotDefined('annotation'),  annotation=sprintf('Scan%i',scan);  end

% assign the parfile
dataTYPES(1).scanParams(scan).parfile = parfile;
saveSession;

if isempty(getSelectedInplane)
    global INPLANE 
    INPLANE = cell(0);
    mrVista montage;
    set(gcf,'Name','mrv T * U * R * B * O * !!!!');
    INPLANE{end} = getSelectedInplane;
else
    initScanSlider(INPLANE{end});
end

INPLANE{end} = computeCorAnal(INPLANE{end},numScans(INPLANE{end}),1);
% INPLANE{end} = computeMeanMap(INPLANE{end},numScans(INPLANE{end}),1);
% INPLANE{end} = loadCorAnal(INPLANE{end}); % refresh
INPLANE{end} = loadParameterMap(INPLANE{end},'Inplane/Original/meanMap.mat');
refreshScreen(INPLANE{end});

return

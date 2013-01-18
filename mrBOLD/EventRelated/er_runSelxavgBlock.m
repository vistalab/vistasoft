function view = er_runSelxavgBlock(view,scans,useDefaults);
% view = er_runSelxavgBlock(view,scans,[useDefaults]);
% 
% Provides an interface to run er_selxavg (selxavg, applying a GLM) for
% block-design data.
%
%
% useDefaults: if 1, doesn't prompt user but uses default
% values and just runs GLM. Good for scripting.
%
% 04/02 ras: wrote it.
global dataTYPES HOMEDIR;
if notDefined('view'),     view = getSelectedInplane;           end
if notDefined('scans'),     scans = er_getScanGroup(view);      end
if notDefined('useDefaults'),    useDefaults = 0;               end

if scans(1)==0 % flag to select with prompt
    [scans, ok] = er_selectScans(view,'Apply GLM to which scans?');
    if ~ok  return;     end     % exit gracefully if cancelled
elseif scans(1)==-1 % flag to use scan group
    [scans, dt] = er_getScanGroup(view);
    view.curDataType = dt;
end

% PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params = er_getParams(view, scans(1));
detrend = dataTYPES(view.curDataType).blockedAnalysisParams(scans(1)).detrend;
TR = dataTYPES(view.curDataType).scanParams(scans(1)).framePeriod;
nSlices = numSlices(view);
seriesDir = dataTYPES(view.curDataType).name;
% we'll save all files in the Inplane/[datatype]/TSeries/Scan[#] directory of the 1st selected scan
scan = scans(1); 
scanDir = ['Scan' num2str(scan)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set up an input dialog to get params %%%%%%%%%%%%%%%%%%%
if useDefaults==0
    prompt = {...
         'Detrend option (same as for dataTYPES):',...
         'Highpass filter cutoff (Hz) (if detrend option=1):',...
         'Time window of hemodynamic response (secs):',...
         'Fitted gamma function delta:',...
         'Fitted gamma function tau:',...
         'Number of frames to skip at beginning of tSeries:',...
         'Analysis Name (optional, will backup results if entered):',...
         };
    defaults = {num2str(detrend),'60','22','1.25','2.5','0' ''};
    AddOpts.Resize = 'on';
    AddOpts.Interpreter = 'tex';
    AddOpts.Interpreter = 'Normal';
    answer = inputdlg(prompt,'Apply GLM...',1,defaults);
    if isempty(answer)      return;     end   % exit gracefully if cancel
else
    answer = {num2str(detrend), '60', '22', '1.25', '2.5', '0', ''};
end

% parse the answer returned from the dialog %%%%%%%%%%%%%%
detrend = str2num(answer{1});
switch detrend
    case 0, detrendOpt = ''; % no detrend
    case 1,                  % highpass detrend 
        period = answer{2};
        detrendOpt = ['-highpass, ' period];
    case 2, detrendOpt = ''; % quartic trend removal
    case -1, detrendOpt = '-detrend, ';
    otherwise, detrendOpt = '';
end   
twOpt = ['-timewindow, ' answer{3}];
gdelta = str2num(answer{4});
gtau = str2num(answer{5});
nskip = str2num(answer{6});
analName = answer{7};

% run selxavg for these scans %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% build up a cell of options 'opts' for the command (see er_selxavg)
if detrendOpt ~= 0
    opts = sprintf(['%s, %s, -gammafit, %f, %f, '...
                   '-TR, %i, -TER, %i, -nskip, %i, -fwhm, 0, -saveover'],...
                    detrendOpt, twOpt, gdelta, gtau, TR, TR, nskip);
else
    opts = sprintf(['%s, -gammafit, %f, %f, '...
                   '-TR, %i, -TER, %i, -nskip, %i, -fwhm, 0, -saveover'],...
                    twOpt, gdelta, gtau, TR, TR, nskip);
end                 
opts = explode(', ', opts);

for s = 1:length(scans)
    scanPath = fullfile(tSeriesDir(view), ['Scan' num2str(scans(s))])
    
    view.curDataType
    scans(s)
    dataTYPES(view.curDataType).scanParams(scans(s)).parfile
    parfile = dataTYPES(view.curDataType).scanParams(scans(s)).parfile;
    parPath = fullfile(parfilesDir(view), parfile);
    tmp = sprintf('-i, %s, -p, %s', scanPath, parPath);
    opts = [opts explode(', ',tmp)];
end

scanPath = fullfile(tSeriesDir(view), ['Scan' num2str(scans(1))]);
tmp = sprintf('-o, %s', scanPath);
opts = [opts explode(', ', tmp)];

% remove blanks from options
for i = 1:length(opts)
    while isspace(opts{i}(1))
        opts{i} = opts{i}(2:end);
    end
end

% call the selxavg command
er_selxavg(opts);

% we may need to pad the omnibus map to the right # of scans
if scans(1) < numScans(view)
    if length(scans)==1
        a = num2str(scans(1));
        mapPath = fullfile(dataDir(view),['omnibus_scan' a]);
    else
        a = num2str(scans(1)); b = num2str(scans(end));
        mapPath = fullfile(dataDir(view),['omnibus_scans' a 'to' b]);
    end
    load(mapPath);
    map{numScans(view)} = [];
    save(mapPath,'map','-append');
end

% also, for flat level views, need to reshape the 
% omnibus into the proper format
if isequal(view.viewType,'Flat')
    if length(scans)==1
        a = num2str(scans(1));
        mapPath = fullfile(dataDir(view),['omnibus_scan' a]);
    else
        a = num2str(scans(1)); b = num2str(scans(end));
        mapPath = fullfile(dataDir(view),['omnibus_scans' a 'to' b]);
    end
    load(mapPath);
    map{scans(1)} = flatLevelIndices2Coords(view,map{scans(1)});
    save(mapPath,'map','-append');
end

% if an analysis name is entered, backup the 
% GLM results in an analysis dir (allowing multiple
% sortings of the same data): 
if ~isempty(analName) & isunix % unix only right now
    analDir = fullfile(dataDir(view),'GLM Analyses');
    
    if ~exist(analDir,'dir')
        cd(dataDir(view));
        unix('mkdir GLM\ Analyses');
        cd(HOMEDIR);
    end
    
    cd(analDir);
    unix(['mkdir ' analName]);
    cd(HOMEDIR);
    
    srcPattern = fullfile(scanPath,'hAvg*.mat');
    tgtDir = fullfile(analDir,analName);
    cmd = sprintf('cp %s %s',srcPattern,tgtDir);
    unix(cmd);
    
    srcPattern = fullfile(scanPath,'h.dat');
    cmd = sprintf('cp %s %s',srcPattern,tgtDir);
    unix(cmd);
    
    srcPattern = fullfile(scanPath,'X.mat');
    cmd = sprintf('cp %s %s',srcPattern,tgtDir);
    unix(cmd);    
end

return

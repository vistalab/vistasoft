function vw = removeScan(vw, scan, dt, delTSeries)
%
% vw = removeScan(vw, [scan], [dataType], [delTSeries]);
%
% Remove a scan from a mrVista session.
%
% This code removes the references to a scan (in a 
% data type other than 'Original') in dataTYPES, loads
% any existing corAnal and parameter maps, shifting the
% map assignments correspondingly. If the delTSeries
% flag is set to 1, it also tries to delete the tSeries
% files themselves.
% 
% Obviously, you should BE CAREFUL when invoking this command.
%
%
% ras, 09/2005.
if notDefined('vw'),   vw   = getSelectedInplane;           end
if notDefined('scan'), scan = viewGet(vw, 'current scan');  end
if notDefined('dt'),   dt   = viewGet(vw,'curdt');          end
if notDefined('delTSeries'), delTSeries=1;                  end
mrGlobals;

% make sure we have both a name and # for the data type
if ischar(dt), dt=existDataType(dt); end
dtName = viewGet(vw, 'dt name'); 

% always prompt first
q=sprintf('Are you sure you want to delete %s scan %i?',dtName,scan);
resp=questdlg(q,'DELETE SCAN','Yes','No','Cancel','No');
if ~isequal(resp,'Yes'), disp('Aborted Scan Delete.'); return; end

% check that we can delete the scan: we need to either be deleting
% the last scan in a data type or else have a unix platform (to
% use the 'mv' command to rename later tSeries directories to the
% proper name):
nScans = length(dataTYPES(dt).scanParams); %#ok<*NODEF>
if ~(scan==nScans | isunix)
    error('Sorry, can only remove the last scan in a data type on non-unix machines.')
end

% put up a message box
hmsg=msgbox(sprintf('Deleting %s scan %i...',dtName,scan));

% remove references to the scan in dataTYPES
keep = setdiff(1:nScans,scan);
dataTYPES(dt).scanParams = dataTYPES(dt).scanParams(keep);
dataTYPES(dt).blockedAnalysisParams = dataTYPES(dt).blockedAnalysisParams(keep);
dataTYPES(dt).eventAnalysisParams = dataTYPES(dt).eventAnalysisParams(keep);
saveSession;
disp('Updated dataTYPES to omit scan.')

% get set of data directories for all existing data types
% keep results in dataDirs variable
dataDirs = {};
cd(HOMEDIR);
viewTypes = {'Inplane' 'Volume' 'Gray'};
flatCheck=[dir(fullfile(HOMEDIR,'Flat*')) dir(fullfile(HOMEDIR,'flat*'))];
for i = 1:length(flatCheck)
    if flatCheck(i).isdir
        viewTypes{end+1} = flatCheck(i).name;
    end
end

for i = 1:length(viewTypes)
    testDir = fullfile(HOMEDIR,viewTypes{i},dtName);
    if exist(testDir,'dir'), dataDirs{end+1}=testDir;  end
end

% if corAnal exists, load it up and remove reference for this scan
for i = 1:length(dataDirs)
    corAnalFile = fullfile(dataDirs{i},'corAnal.mat');
    if exist(corAnalFile,'file')
        load(corAnalFile,'amp','co','ph')
        amp = amp(keep);
        co = co(keep);
        ph = ph(keep);
        save(corAnalFile,'amp','co','ph','-append');
    end
end
disp('Updated corAnal files.')

% check for parameter maps in each data dir
for i = 1:length(dataDirs)
    cd(dataDirs{i});
    check = what;
    fileList = setdiff(check.mat,'corAnal.mat');
    for j = 1:length(fileList)
        % if it's a map file, it'll have a map variable
        test = load(fileList{j});
        if isfield(test,'map') && length(test.map) >= scan
            map = test.map(keep); %#ok<NASGU>
            save(fileList{j},'map','-append');
        end
    end
end
disp('Updated parameter map files.')

cd(HOMEDIR);

% delete tSeries files if selected
if delTSeries==1
	% remove the tSeries directory for each view
	for ii = 1:length(dataDirs)
		tsDir = fullfile(dataDirs{ii}, 'TSeries', sprintf('Scan%i', scan));
		if exist(tsDir, 'dir')
			rmdir(tsDir, 's');	% remove subdirectories as well
		end
	end
	
	% if there are later scans in the data type, shift them back by 1
	for s = scan:length(keep)
		tsDir = fullfile(dataDirs{ii}, 'TSeries', sprintf('Scan%i', s));
		tgtDir = fullfile(dataDirs{ii}, 'TSeries', sprintf('Scan%i', s-1));
		for ii = 1:length(dataDirs)
			if exist(tsDir, 'dir')
				movefile(tsDir, tgtDir, 'f');
			end
		end
	end
end

% close the message box and finish
close(hmsg); 
fprintf('Finished deleting %s scan %i.\n',dtName,scan);

%% update GUI
if isfield(vw, 'ui')
	if vw.curDataType==dt && vw.curScan > viewGet(vw, 'number of scans')
		vw = selectDataType(vw, vw.curDataType); % this resets scan slider		
        vw = viewSet(vw, 'current scan', viewGet(vw, 'number of scans'));
	end
	setDataTypePopup(vw);
	vw = refreshScreen(vw);
end

if (isempty(dataTYPES(dt).scanParams)), removeDataType(dataTYPES(dt).name); end

return

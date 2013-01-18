function view = importScans(view, srcSession, srcDt, srcScans, tgtDt);
% Import gray/volume tSeries, maps, corAnals, and params from a source
% session into the current session.
%
% view = importScans(<view>, <srcSession, srcDt, srcScans>, <tgtDt>);
%
% If any of the source arguments are unspecified, will prompt for them;
% if the target data type isn't specified, will import into the view's
% current data type. The view defaults to the selected gray view.
%
% ras, 01/06.
mrGlobals;

if notDefined('view'),  view = getSelectedGray;      end

if ~ismember(view.viewType, {'Volume' 'Gray'})
    error('Sorry, only Volume/Gray Views for now.')
end

if notDefined('srcSession')
    studyDir = fileparts(HOMEDIR);
    srcSession = selectSessions(studyDir,1);
    srcSession = srcSession{1};
end

% load source mrSESSION file
src = load(fullfile(srcSession,'mrSESSION.mat'));

if notDefined('srcDt')
    % select from src session's data types
    names = {src.dataTYPES.name};
    [srcDt, ok] = listdlg('PromptString','Import from which data type?',...
        'ListSize',[400 600],...
        'SelectionMode','single',...
        'ListString',names,...
        'InitialValue',1,...
        'OKString','OK');
    if ~ok, return; end
end

% make sure specification format is clear:
% srcDt will refer to the data type name, and
% srcDtNum will be the numeric index into dataTYPES:
if ~isnumeric(srcDt)
    srcDtNum = existDataType(srcDt, src.dataTYPES);
else
    srcDtNum = srcDt;
    srcDt = src.dataTYPES(srcDtNum).name;
end

% error check: the source data type should exist
if srcDtNum==0
    error(sprintf('Data type %s doesn''t exist.',srcDt))
end

if notDefined('srcScans')
    % select from src session/dt's scans
    src = load(fullfile(srcSession,'mrSESSION.mat'));
    names = {src.dataTYPES(srcDtNum).scanParams.annotation};
    for i = 1:length(names)
        names{i} = sprintf('Scan %i: %s',i,names{i});
    end
    [srcScans, ok] = listdlg('PromptString','Import which scans?',...
        'ListSize',[400 600],...
        'SelectionMode','multiple',...
        'ListString',names,...
        'InitialValue',1,...
        'OKString','OK');
    if ~ok, return; end
end

if notDefined('tgtDt')
    % get from dialog
    dlg(1).fieldName = 'existingDt';
    dlg(1).style = 'popup';
    dlg(1).string = 'Target Data Type for imported scans?';
    dlg(1).list = {dataTYPES.name 'New Data Type (named below)'};
    dlg(1).value = view.curDataType;

    dlg(2).fieldName = 'newDtName';
    dlg(2).style = 'edit';
    dlg(2).string = 'Name of new data type (if making a new one)?';
    dlg(2).value = '';

    [resp, ok] = generalDialog(dlg, 'Import Scans');
    if ~ok, return; end

    if ismember(resp.existingDt, {dataTYPES.name})
        tgtDt = resp.existingDt;
    else
        tgtDt = resp.newDtName;
    end
    %
    %     q = {'Name of the data type in which to save imported data?'};
    %     def = {['Imported_' srcDt]};
    %     resp = inputdlg(q, mfilename, 1, def);
    %     tgtDt = resp{1};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Loop: Loop across scans %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
srcDir = fullfile(srcSession, view.viewType, srcDt);
nScans = length(srcScans);

for i = 1:nScans
    fprintf('\n\n\nImporting %s %s %s %i\n', srcSession, view.viewType, ...
        srcDt, srcScans(i));

    %%%%%(1) Import tSeries
    try
        view = importTSeries(view, srcSession, srcDt, srcScans(i), tgtDt);
	catch
		close( findobj('Tag', 'TMWWaitbar') )
        disp(lasterr)
        q = sprintf(['%s tSeries for %s %s %i not found. We can ' ...
            'initialize a blank scan and xform the corAnal / ' ...
            'maps if you like, or we can cancel. ' ...
            'What shall we do? '], view.viewType, srcSession, ...
            srcDt, srcScans(i));
        resp = questdlg(q, mfilename, 'Keep going', 'Skip This Scan', ...
            'Cancel', 'Cancel');
        if isequal(resp, 'Keep going'),
            srcParams = src.dataTYPES(srcDtNum);
            view = initScan(view, tgtDt, [], {srcParams srcScans(i)});
        else
            error('tSeries not imported; user aborted');
        end
    end

    % select the latest scan in the tgt data type for the maps
    view = setCurScan(view, numScans(view));


    %%%%%(2) Import corAnal fields
    try
        view = importCorAnal(view, srcSession, srcDt, srcScans(i));
    catch
        disp(lasterr)
    end

    %%%%%(3) Find and import any parameter maps
    w = dir(fullfile(srcDir, '*.mat'));
    matFiles = {w.name};
    matFiles = setdiff(matFiles, 'corAnal.mat');
    for j = 1:length(matFiles)
        try
            pth = fullfile(srcDir, matFiles{j});
            % load(pth, 'map', 'mapName');
            view = importMap(view, pth, srcScans(i));
        catch
            % don't worry if we can't import the map, or if it's not a map
            fprintf('Couldn''t import %s, scan %i --\n', pth, srcScans(i));
            disp(lasterr)            
        end
    end

    %%%%%(4) Find and import any parfiles
    try

        params = src.dataTYPES(srcDtNum).scanParams(srcScans(i));
        if isfield(params, 'parfile') & ~isempty(params.parfile)
            srcPar = fullfile(srcSession, 'Stimuli', 'parfiles', params.parfile);
            if exist(srcPar, 'file')
                tgtPar = fullfile(parfilesDir(view), params.parfile);
                copyfile(srcPar, tgtPar);
                fprintf('Copied %s to %s\n', srcPar, tgtPar);
            end

        end
        
    catch
        disp('Couldn''t copy parfiles from source session.')
    
    end % try

end

fprintf('\n\nDone importing scans. \n')


return

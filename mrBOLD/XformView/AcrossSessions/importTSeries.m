function view = importTSeries(view, srcSession, srcDt, srcScans, tgtDt, copyParFile);
%
% view = importTSeries(<view>, <srcSession, srcDt, srcScans, tgtDt, copyStim>);
%
% AUTHOR: rory
% PURPOSE:
% Import tSeries from an external source session into
% the current session/view. Currently gray/volume view only.
% Data needs to come from the same subject/segmentation.
%
% The way this works is, the new data are imported into
% a data type <by default named 'Imported-[name of source data type]'.>
% The prescriptions/gray coordinates between the source
% and target sessions may be different -- here's how we
% deal with each of the three possibilities:
%   1) data in source and target sessions: great, keep this data
%   2) data in source, but not target session: this is lost.
%   3) data (coords) in target, but no data from that coordinate
%      in source: assigned NaNs.
% To deal with the lost data in 2, you can use createCombinedSession,
% that will cover all the coordinates across several sessions.
%
% ARGUMENTS:
% view: view from target session, which will receive the
% imported scans. <Default: currently selected gray view.>
%
% srcSession: path to the source session, from which to
% take the imported scans.
% <Default: prompt user.>
%
% srcDt: data type (name or number) from which to take scans.
% <Default: prompt user.>
%
% srcScans: list of scans to take. <Default: prompt user.>
%
% tgtDt: name of target data type in which to save the tSeries.
% Will append the imported data to the end of this data type.
% <Default: 'Imported_[source dt name]'.>
%
% copyParFile: 1 = copy parfile from source to Stimuli directory in target
% directory
%
%
% ras 03/05
% remus 11/07 (copyParFile flag & duplication of mrSESSION.functional info)
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

if ~exist ('copyParFile')
    copyParFile = 0;
end

verbose = prefsVerboseCheck;

fprintf('\t***** Importing tSeries from %s *****\n',srcSession);

% load source coords, find indices of those
% coordinates contained within view's coords
disp('Checking source and target coordinates...')
srcCoordsFile = fullfile(srcSession, view.viewType, 'coords.mat');
load(srcCoordsFile, 'coords');
[commonCoords, Isrc, Itgt] = intersectCols(coords,view.coords);
nVoxels = size(view.coords, 2);
clear coords commonCoords;

% make the new data type if it doesn't exist
if notDefined('tgtDt'), tgtDt = ['Imported_' srcDt];   end
tgtDtNum = existDataType(tgtDt);
if tgtDtNum==0 % not found, make it
    mkdir(viewDir(view), tgtDt);
    fprintf('Made directory %s\n', fullfile(viewDir(view), tgtDt));
    dataTYPES(end+1).name = tgtDt;
    tgtDtNum = length(dataTYPES);
end

% figure out tgt scan numbers
offset = length(dataTYPES(tgtDtNum).scanParams);
nScans = length(srcScans);
tgtScans = (1:nScans) + offset;

% check if the existing scan is a placeholder
% (see createCombinedSession) -- if so, we'll
% save over it:
if offset==1 & ...
        isequal(dataTYPES(tgtDtNum).scanParams.annotation, '(Empty Scan)')
    tgtScans = tgtScans-1;
end

% select new data type in view, to get
% ready for importing
view = selectDataType(view, tgtDtNum);

% loop across scans, loading tSeries, selecting the
% proper voxels, and saving in the target session:
% (also copying over data types)
disp('Importing tSeries...')
if verbose >= 1
	h = mrvWaitbar(0,'Importing TSeries');
	
	% so other code can close it if this code fails...
	set(h, 'HandleVisibility', 'on'); 
end

for i = 1:nScans
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % copy tSeries first; if this fails,             %
    % then at least dataTYPES isn't too screwed up:  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load src tSeries
    scanStr = sprintf('Scan%i', srcScans(i));
    srcFile = fullfile(srcSession, view.viewType, srcDt, 'TSeries', scanStr, ...
        'tSeries1.mat');
    srcTSeries = load(srcFile, 'tSeries');
    srcTSeries = srcTSeries.tSeries(:,Isrc);
    nFrames = size(srcTSeries, 1);

    % initialize target tSeries
    tSeries = repmat(NaN, nFrames, nVoxels);

    % select tSeries contained within tgt coords
    %     if length(Isrc) > 1000
    %         % Copying everything at once may be memory-hungry:
    %         % convert to int16 and copy over a bit at a time.
    %         [srcTSeries, dataRange] = intRescale(srcTSeries);
    %         nVoxels = length(Isrc);
    %         for j = 1:1000:nVoxels
    %             sub_range = j:min(j+999, nVoxels);
    %             tSeries(:,Itgt(sub_range)) = ...
    %                 normalize(srcTSeries(:,Isrc(sub_range)), ...
    %                           dataRange(1), dataRange(2));
    %         end
    %     else
    % can probably assign everything at once
    tSeries(:,Itgt) = srcTSeries;
    %     end

    % save tSeries
    scanStr = sprintf('Scan%i', tgtScans(i));
    tgtFile = fullfile(tSeriesDir(view), scanStr, 'tSeries1.mat');
    if exist(fileparts(tgtFile), 'dir')
        % something must be wrong, since we should be
        % appending new scans and not saving over...
        msg = sprintf('%s already exists. Proceed?',fileparts(tgtFile));
        response = questdlg(msg, 'Confirm', 'Yes', 'No', 'No');
        if isequal(response,'No')
            disp('Aborted importTSeries w/o saving.')
            close(h)
            return
        end
    else
        % make the directory
        mkdir(tSeriesDir(view), scanStr);
    end
    save(tgtFile,'tSeries');
    fprintf('Saved %s.\n', tgtFile);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now that we've gotten the tSeries copied over, we can     %
    % mess w/ dataTYPES: initialize the new scan (if the data   %
    % type doesn't exist yet, create it).                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    dtStruct = src.dataTYPES(srcDtNum);
    view = initScan(view, tgtDt, tgtScans(i), {dtStruct srcScans(i)});

    % set some fields differently, to be clear where they came
    % from:
    if ~isfield(src.mrSESSION,'sessionCode'),
        src.mrSESSION.sessionCode = [];
    end;
    dataTYPES(tgtDtNum).scanParams(tgtScans(i)).annotation = ...
        [src.mrSESSION.sessionCode ' ' srcDt ' ' num2str(srcScans(i)) ...
        ': ' dataTYPES(tgtDtNum).scanParams(tgtScans(i)).annotation];

	% ras 10/08: commented out, unfortunately mrSESSION.functionals only
	% applies to the Original data. (Should really keep similar data in
	% dataTYPES.)
    %copy mrSESSION.functionals info.  Older combined sessions will have
    %mrSESSION.functionals = []...will not work with these.
	% mrSESSION.functionals(tgtScans(i)) = struct(src.mrSESSION.functionals(srcScans(i)));

    % let's save each scan, in case it crashes
    saveSession;

    %Now copy over parfiles if requested
    if copyParFile
        tgtParFileDir = fullfile(HOMEDIR,'Stimuli','Parfiles');
        if ~exist(tgtParFileDir,'dir')
            mkdir(HOMEDIR, fullfile('Stimuli','Parfiles'))
        end

        srcParFileDir = fullfile(srcSession, 'Stimuli','Parfiles');
        if ~exist(srcParFileDir, 'dir') 
            srcParFileDir = fullfile(srcSession, 'Stimuli','parfiles');
        end
        
        srcParFileName = char(dtStruct.scanParams(srcScans(i)).parfile);
        srcParFile = fullfile(srcParFileDir, srcParFileName);
        
        copyfile (srcParFile, tgtParFileDir);

	end

	if verbose >= 1,   mrvWaitbar(i/nScans,h);		end
end

if verbose >= 1, close(h);		end

% reset views to have right # of scans
% (we'll leave the inplane, flat ones alone
% for now):
VOLUME  = resetDataTypes(VOLUME, tgtDtNum);
FLAT  = resetDataTypes(FLAT, tgtDtNum);

disp('Finished Importing tSeries.')

return

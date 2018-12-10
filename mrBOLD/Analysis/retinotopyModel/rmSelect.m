function vw = rmSelect(vw, loadModel, rmFile)
% rmSelect - select retinotopy model file and put in view struct
%
% vw = rmSelect([vw=current view], [loadModel=0], [rmFile=dialog]);
%
% The loadModel flag indicates whether the model file (a large file)
% should be loaded or not. By default it is 0: don't load it until needed
% (only the path to the selected rmFile file will be stored). If it's 1, it
% goes ahead and loads it.
%
% If the path to the retinotopy model file is provided as a third argument,
% will attempt to load it directly; otherwise, pops up a dialog.  You
% may also provide the string 'mostrecent' as the filename, in which case
% the code will look for the most recently-created model file, and 
% select it (producing an error if one is not found).
%
% 2006/02 SOD: wrote it.
% ras 2006/10: added dialog.
% ras, 06/07: added 'mostrecent' flag to find the newest file
if ~exist('vw','var') || isempty(vw), vw = getCurView;  end;
if ~exist('loadModel','var') || isempty(loadModel), loadModel = true;   end;

% choose filename:
if ~exist('rmFile','var') || isempty(rmFile),
    rmFile = getPathStrDialog(dataDir(vw),...
        'Choose retinotopic model file name', ...
        '*.mat');
    drawnow;
elseif iscell(rmFile)
    rmFile = rmFile{1};
end

% if user just wants the newest file, check for it:
if ischar(rmFile) && ismember(lower(rmFile), {'newest' 'mostrecent'})
	pattern = fullfile( dataDir(vw), 'retModel-*.mat' );
	w = dir(pattern);
	if isempty(w)
		error('Most Recent File selected; no retModel-* files found.')
	end
	[dates, order] = sortrows( datevec({w.date}) ); % oldest -> newest
	rmFile = fullfile( dataDir(vw), w(order(end)).name );
end

% Locate rm file
if check4File(fullfile(dataDir(vw), rmFile))
    % first check in appropriate directory
    rmFile = fullfile(dataDir(vw), rmFile);
elseif check4File(fullfile(dataDir(vw), [rmFile '.mat']))
    % if not found, check whether we are missing the extension
    rmFile = fullfile(dataDir(vw), [rmFile '.mat']);
elseif exist(rmFile,'file')
    % if still not found, look on entire path
elseif exist([rmFile '.mat'], 'file')
    % if still not found, look on entire path with '.mat' added
    rmFile = [rmFile '.mat'];
else
    % We could not find rm file anywhere
    fprintf('[%s]:No file: %s\n',mfilename,rmFile);
    return;
end


% if the load model flag is 1, but the file's already selected, just load
% it and return:
if loadModel && checkfields(vw, 'rm' , 'retinotopyModelFile')
    if ~exist(rmFile, 'file')
        error('Model file %s not found.', rmFile);
    end;
    load(rmFile, 'model', 'params');
    vw = viewSet(vw, 'rmFile', rmFile);
    vw = viewSet(vw, 'rmModel', model);
    vw = viewSet(vw, 'rmParams', params);
    vw = viewSet(vw, 'rmModelNum', 1);
    return;
end;

    
% store rmFile filename:
vw = viewSet(vw,'rmFile',rmFile);

if loadModel==0
    % clear previous models but don't load them untill we need them:
    vw = viewSet(vw, 'rmModel', []);
else
    % go ahead and load
    load(rmFile, 'model', 'params');
    vw = viewSet(vw, 'rmModel', model);
    vw = viewSet(vw, 'rmParams', params);
    vw = viewSet(vw, 'rmModelNum', 1);
end;
    

return;


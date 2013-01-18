function gray = createCombinedSession(newSessDir, srcSessions, keepAll);

% gray = createCombinedSession([newSessDir], [srcSessions], [keepAll=0]);
%
% Create a new mrVista session for the purposes of combining
% data across sessions. This is only for sessions which 
% have gray tSeries, and are from the same subject/segmentation.
%
% This session will be distinct from other sessions, in that
% it will only have a gray view, not an inplane view (diff't 
% sessions have different inplane Rxs -- it may be possible to 
% create an interpolated inplane set but that's way advanced).
% The Gray coords.mat file will contain a union of the coordinates
% from all of the source sessions. In the related functions (see
% importTSeries), any coordinates which lie outside a given
% session's prescription will be assigned NaN.
%
% newSessDir is a path to the new directory to create.
% If it doesn't exist, creates the directory. Creates
% a mrSESSION file for the combined session. If some 
% fields in the mrSESSION and dataTYPES variables are
% ambiguous, it will leave them blank or else grab
% them from the first source session. If omitted, 
% newSessDir is taken to be the current dir.
%
% srcSessions is a cell of strings, containing paths
% to each of the sessions that will contribute to the 
% combined coordinates. If omitted, pops up a prompt.
% (The prompt initially looks at dirs in the parent
% directory, but you can navigate to other dirs by
% selecting the (Find Other Session) option.)
%
% The main effect of the source sessions is to contribute
% relevant gray coordinates. If you create a combined
% session, but later want to add data from another session,
% you may be ok. If the new session doesn't cover any
% new gray matter not covered by the source sessions, 
% you can just add the data. Otherwise, you'll need to 
% rebuild the combined session and import the data all
% over again.
%
% keepAll is an optional flag indicating that all left and right gray nodes
% should be used in the combined session. The advantages to this are that
% it guarantees no data are missed in any imported session, and mapping
% from the combined session to the input segmentation files is simplified.
% The downside is that there may be much larger data files, many of which
% may be NaNs since there is never data there. [defualt: 0, keep only the
% intersection of the gray nodes with the source sessions.]
% 
% Note that this function doesn't take any of the
% scan data yet; it just initializes the session so
% you can add scans to it.
%
%
% ras 03/05
if notDefined('newSessDir'),    newSessDir = pwd;       end
if notDefined('keepAllNodes'),	keepAllNodes = false;	end
callingDir = pwd;

if notDefined('srcSessions')
    % create an interface, get sessions
	studyDir = fileparts(pwd); % guess at study dir
    srcSessions = selectSessions(studyDir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create new session dir if it doesn't exist %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[p d] = fileparts(fullpath(newSessDir));
if ~exist(newSessDir,'dir')
    mkdir(p,d);
    fprintf('Made directory %s in parent dir %s.\n',d,p);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check that each source directory exists, and get full paths %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newSessDir = fullpath(newSessDir);
for i = 1:length(srcSessions)
    if exist(srcSessions{i}, 'dir')
        srcSessions{i} = fullpath(srcSessions{i});
    else
        errmsg = sprintf('Source dir %s not found.', srcSessions{i});
        error(errmsg);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%
% create mrSESION file %
%%%%%%%%%%%%%%%%%%%%%%%%
cd(newSessDir);
mrGlobals;
mrSESSION = [];
dataTYPES = [];
vANATOMYPATH = '';
tmp = load(fullfile(srcSessions{1},'mrSESSION.mat'));

mrSESSION.mrLoadRetVersion = 3.01;
mrSESSION.sessionCode = d;
desc = 'Combined: coords from ';
for i = 1:length(srcSessions)
    [p f] = fileparts(srcSessions{i});
    desc = [desc f ' '];
end
mrSESSION.description = desc;
mrSESSION.subject = tmp.mrSESSION.subject;
mrSESSION.examNum = 'N/A';
mrSESSION.inplanes = tmp.mrSESSION.inplanes;
% mrSESSION.functionals = [];
mrSESSION.alignment = [];

dataTYPES.name = 'Imported_Original';

% Dilemna: we need various data types fields 
% as placeholders to run mrVista, but don't want
% to actually import any tSeries yet (can't have
% a struct of size 0, it seems). 
% Solution (Hack): Create a dummy, and label it so:
dataTYPES.scanParams = tmp.dataTYPES(1).scanParams(1);
dataTYPES.blockedAnalysisParams = tmp.dataTYPES(1).blockedAnalysisParams(1);
dataTYPES.eventAnalysisParams = tmp.dataTYPES(1).eventAnalysisParams(1);
dataTYPES.scanParams.annotation = '(Empty Scan)';

if isfield(tmp, 'vANATOMYPATH')
    vANATOMYPATH = tmp.vANATOMYPATH;
else
    vANATOMYPATH = getVAnatomyPath(mrSESSION.subject);
end

HOMEDIR = pwd;

mrSessFile = fullfile(newSessDir,'mrSESSION.mat');
if exist(mrSessFile,'file')
    % confirm to save over
    msg = sprintf('%s already exists. Save over?',mrSessFile);
    response = questdlg(msg,'Confirm','Yes','No','No');
    if isequal(response,'No')   
        disp('Aborted createCombinedSession w/o saving.')
        return
    end
end
save(mrSessFile,'mrSESSION','dataTYPES','vANATOMYPATH');
fprintf('Saved new mrSESSSION.mat file.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create Gray dir, get coords %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ensure a gray dir exists
grayDir = fullfile(HOMEDIR,'Gray');
if ~exist(grayDir)
    mkdir(HOMEDIR,'Gray');
    fprintf('Created Directory: %s \n',fullfile(HOMEDIR,'Gray'));
end

%% get either all gray nodes, or the intersection with the source session
if keepAllNodes
	%% keep all left and right nodes
	% get the left and right paths from the first session
	srcCoordsFile = fullfile(srcSessions{1}, 'Gray', 'coords.mat'); 
	load(srcCoordsFile, 'leftPath', 'rightPath');
	
	% load all the nodes
	[allLeftNodes allLeftEdges leftPath] = loadGrayNodes('left', leftPath);
	[allRightNodes allRightEdges rightPath] = loadGrayNodes('right', rightPath);	
else
	%% get nodes from each of the source sessions
	for i = 1:length(srcSessions)
		srcCoordsFile = fullfile(srcSessions{i},'Gray','coords.mat');

		if i==1
			% use 1st session gray coords to set fields other than coords.
			% Critical assumption here: the nodes and edges (in the variables
			% 'allLeftNodes' / 'allRightNodes', 'allLeftEdges' /
			% 'allRightEdges') are the same across input sessions. If not, the
			% coords and nodes variables can be out of whack. This is usually
			% the case. (If you used different segmentations for different
			% sessions, obviously, you shouldn't combine those sessions.)
			load(srcCoordsFile);
		end

		srcData{i} = load(srcCoordsFile);
	end

	% Keep nodes that intersect with the coords
	if ~isempty(allLeftNodes)
		[leftCoords, leftIndices, keepLeft] = ...
			intersectCols(coords, allLeftNodes([2 1 3],:));
		[leftNodes, leftEdges, nLeftNotReached] = ...
			keepNodes(allLeftNodes, allLeftEdges, keepLeft);
		fprintf('%i Left nodes kept. \n', length(keepLeft));
		fprintf('%i Left nodes not reached. \n', nLeftNotReached);
	else 
		leftNodes = []; leftEdges = [];
	end

	if ~isempty(allRightNodes)
		[rightCoords, rightIndices, keepRight] = ...
			intersectCols(coords, allRightNodes([2 1 3],:));
		[rightNodes, rightEdges, nRightNotReached] = ...
			keepNodes(allRightNodes, allRightEdges, keepRight);
		fprintf('%i Right nodes kept. \n', length(keepRight));
		fprintf('%i Right nodes not reached. \n', nRightNotReached);
	else
		rightNodes = []; rightEdges = [];
	end
end

% Concantenate the left and right gray graphs
if ~isempty(rightNodes) & ~isempty(leftNodes)
	% the 5th row is the edge offset: shift by the # of left edges
    rightNodes(5,:) = rightNodes(5,:) + length(leftEdges);
    rightEdges = rightEdges + size(leftNodes,2);
end
nodes = [leftNodes rightNodes];
edges = [leftEdges rightEdges];

% Sometimes we need to trim back the combined nodes: this can
% happen if some nodes are included in both the left and right
% segmentations. In this case, we warn the user, and properly scale back
overlapCoords = unionCols(leftNodes(1:3,:), rightNodes(1:3,:));
if ~isempty(overlapCoords)
	if prefsVerboseCheck >= 1
		msg = sprintf(['%i nodes overlap between the left and right' ...
					   'hemisphere segmentations. I am removing the ' ...
					   'overlap.'], ...
					   length(overlapCoords));
		fprintf('[%s]: %s.\n', mfilename, msg);
	end
	
	[nonOverlapNodes keep] = intersectCols(nodes, nodes);
	[nodes edges] = keepNodes(nodes, edges, keep);
end

% force the coords to match the gray nodes
coords = nodes([2 1 3],:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save the combined gray nodes %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (the other variables were loaded from 1st src file)
coordsFile = fullfile(grayDir,'coords.mat');
if exist(coordsFile,'file')
    % confirm to save over
    msg = sprintf('%s already exists. Save over?',coordsFile);
    response = questdlg(msg,'Confirm','Yes','No','No');
    if isequal(response,'No')   
        disp('Aborted createCombinedSession w/o saving.')
        return
    end
end
keepLeft = []; keepRight = []; % save memory, inplanes are irrelevant
save(coordsFile, 'coords', 'nodes', 'edges', 'allLeftNodes', ...
    'allLeftEdges', 'allRightNodes', 'allRightEdges',...
    'leftPath', 'rightPath', 'keepLeft', 'keepRight');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make a Readme.txt file letting people know    %
% this is a combined session.                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen('Readme.txt', 'w');
if fid > -1
    fprintf(fid, 'This is a mrVista Combined Session, intended \n');
    fprintf(fid, 'to hold data from multiple sessions. \n');
    fprintf(fid, 'It has gray coords that span at least \n');
    fprintf(fid, 'the following sessions: \n');
    for i = 1:length(srcSessions)
        fprintf(fid, '%s \n', srcSessions{i});
    end
    fprintf(fid, '\nPlease use only Volume / Gray / Flat views \n');
    fprintf(fid, 'for this session; Inplanes aren''t defined. \n');
    fprintf(fid, '\nSee createCombinedSession and importTSeries');
    fprintf(fid, 'for more info.\n');
    fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%
% That should do it. %
%%%%%%%%%%%%%%%%%%%%%%
if nargout>0, gray = initHiddenGray;    end
cd(callingDir);
fprintf('Finished building %s directory.\n',newSessDir);


return

    
    

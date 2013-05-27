function pathStr = dataDir(vw, ~)
% Directory containing data for a given dataTYPE
%
%  pathStr = dataDir(view)
%
% If you're nice and neat e.g., if you're in an inplane view and looking at
% average tSeries, the dataDir would be HOMEDIR/Inplane/Averages/
%
% If this directory doesn't exist, make it!
%
% djh, 2/2001
global HOMEDIR
if isempty(HOMEDIR), HOMEDIR = pwd; end
dir = viewGet(vw,'subdir');
dt = viewGet(vw,'dtStruct');
subDir = dtGet(dt,'Name');
pathStr = fullfile(HOMEDIR,dir,subDir);
if ~exist(pathStr,'dir')
	pathStr;
	subDir;
	mkdir(dir,subDir);
end
return;

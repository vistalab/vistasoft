function pathStr = tSeriesDir(vw,makeIt)
%Return tSeries directory for a view; make it if it does not exist
%
%   pathStr = tSeriesDir(view,[makeIt=1])
%
% makeIt: If false (0) the routine will not make the directory.  Default
% is true.
%
% Examples:
%    tSeriesDir(view)
%
if notDefined('makeIt'), makeIt = 1; end
% global mrSESSION
% pathStr = fullfile(dataDir(view),'TSeries');
datadir = dataDir(vw);
subdir = 'TSeries';
pathStr = fullfile(datadir,subdir);
if (makeIt && ~exist(pathStr,'dir')), ensureDirExists(pathStr); end
return

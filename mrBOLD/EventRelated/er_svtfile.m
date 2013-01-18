function er_svtfile(y, tSeriesPath, override)
%
% er_svtfile(y,tSeriesPath,override)
%
% Saves data as a tSeries given a full path name. 
%
% y is data as used by fsfast. It should have dimensions 
% nRows x nCols x nTimePoints. This is reshaped into tSeries convention
% format: nTimePoints x (nRows&nCols together in column-rank order).
% 
% override is either 0 or 1 (default is 0) -- doesn't matter for tSeries,
% left in for backwards compatibility with some fsfast routines
%
% See also: ldtfile
%
% $Id: er_svtfile.m,v 1.2 2004/03/11 22:02:23 sayres Exp $
%
% 06/18/03 ras: modified from fmri_svbfile in an attempt to integrate
% fsfast functions into mrLoadRet.
if(nargin ~= 2 & nargin ~= 3) 
  error('USAGE: er_svtfile(y,tSeriesPath)');
end

if(nargin == 2) override = 0; end

% check that the specified data type directory exists
scandir = fileparts(tSeriesPath);
tdir = fileparts(scandir);
if ~exist(tdir,'dir')
    fprintf(2,'Couldn''t find path %s for specified file %s.',tdir,tSeriesPath);
    qoe;
    return
end

% if scandir doesn't exist yet, make it
if ~exist(scandir,'dir')
    callingdir = pwd;
    cd(tdir);
    [tmp scanname] = fileparts(scandir);
    fprintf('Making directory %s ....\n',scandir);
    mkdir(scanname);
    cd(callingdir);
end

% check if tSeries is already saved there
if exist(tSeriesPath,'file') & ~override
    % warn user and prompt for save-over (unless overridden)
    questionStrings = [{'These file(s) already exist:'}; ...
            {''}; {tSeriesPath}; {''}; ...
            {'Do you want to continue, which will create a new tSeries file?'}];
    
    buttonName = questdlg(questionStrings, 'Warning', 'Yes', 'No', 'No');
    pause(.1);  % Prevent hanging

    if strcmp(buttonName, 'No')
        return
    end    
end 

nRows = size(y,1);
nCols = size(y,2);
nTp = size(y,3);

% % usually fmri scans have square inplanes -- nrows==ncols.
% % warn if this is not the case
% if nRows~=nCols
%     msg = ['This is strange -- the # of rows in this data '....
%             'doesn''t equal the # of columns. Misformatted? '...
%             'tSeriesPath: ' tSeriesPath];
%     warning(msg);
% end

y = permute(y,[3 1 2]);

tSeries = reshape(y,[nTp nRows*nCols]);

%touch(tSeriesPath);
save(tSeriesPath,'tSeries');

return;

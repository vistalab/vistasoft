function par = fmri_ldpar(varargin)
%
% Load specified par files for multiple runs.
%
% par = fmri_ldpar(ParFileList)
% par = fmri_ldpar(ParFile1, ParFile2, ...)
%
% ParFileList is a vertical cat of parfile names (ie, each run's'
% parfile name on a different row).
%
% ParFile format is as follows:
%   Column 1: stimulus presentation time (float or int)
%   Column 2: stimulus condition number
%   Column > 2: ignored
%
% par dimensionality: nPresentations x 2 x nRuns
%
% ras, 04/05: sorts rows by onsets, so they need not
% be specified in chronological order.
% ras, 02/06: replaced w/ mrVista tools, to fix linux \n issue.
par = [];

if(nargin == 0)
    error('USAGE: par = fmri_ldpar(ParFile)');
end

if( length(varargin) == 1)
    ParFile = varargin{1};
    nRuns = size(ParFile,1);
else
    nRuns = length(varargin);
    ParFile = '';
    for r = 1:nRuns,
        ParFile = strvcat(ParFile,varargin{r});
    end
end

% Go through each run and load par %
for r=1:nRuns,
    [onsets conds] = readParFile(deblank(ParFile(r,:)));
    par = [par; onsets(:) conds(:)];
end

return



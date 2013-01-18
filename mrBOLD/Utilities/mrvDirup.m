function [dUpper, dLower] = mrvDirup(dLower,nLevels)
% Find a directory nLevels up from the dLower directory
%
%    dUpper = mrvDirup(dLower,nLevels)
%
% dLower: The starting directory.  Default: eval('pwd')
% This should not be a full path to a file.
%
% nLevels: The number of levels we wish to go up. Default: nLevels = 1.
%
% Note that if there is a final backslash in the dLower string, it is
% removed prior to processing.  Thus,
%
%    dLower = 'c:\u\brian\Matlab\mrDataExample\';
%    dLower = 'c:\u\brian\Matlab\mrDataExample';
%
% are the same inputs to this routine.  They are not the same strings to
% fileparts.
%
% Examples:
%    dLower = 'c:\u\brian\Matlab\mrDataExample\';
%    mrvDirup(dLower,1) is 'c:\u\brian\Matlab'
%    mrvDirup(dLower,2) is 'c:\u\brian'
%
%    dLower = 'c:\u\brian\Matlab\mrDataExample';
%    mrvDirup(dLower,2) is 'c:\u\brian'
%
%   dLower = '\\white.stanford.edu\biac\wandell\docs\';
%   mrvDirup(dLower,0) is '\\white.stanford.edu\biac\wandell\docs'
%   mrvDirup(dLower,2) is '\\white.stanford.edu\biac'
%
% N.B. Having a file at the end changes the result
%   dLower = '\\white.stanford.edu\biac\wandell\docs\tmp.mat';
%   mrvDirup(dLower,1) is '\\white.stanford.edu\biac\wandell\docs'
%   dLower = '\\white.stanford.edu\biac\wandell\docs\';
%   mrvDirup(dLower,1) is '\\white.stanford.edu\biac\wandell'
%

%
% Wandell

if notDefined('dLower'), dLower = pwd; end
if notDefined('nLevels'), nLevels = 1; end

% Remove any last backslash
if strcmp(dLower(end),'\'), dLower = dLower(1:(end-1)); end

% Loop through nLevels
tmp = dLower;
for ii=1:nLevels, tmp = fileparts(tmp); end
dUpper = tmp;

return

end

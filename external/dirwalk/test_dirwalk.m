function test_dirwalk()
%TEST_DIRWALK Test and Demo DIRWALK function
%
%

clc

%% Path to top directory (for example)
topPath = fullfile(matlabroot, 'toolbox', 'matlab');


%% Walking with visitor 1 (calculate number of files and size)
%
fprintf('\nWorking DIRWALK with function VISITOR1 (Calculate number of files and size)\n');

% Walking tree and call visitor function in each directory

% "countDirs", "countFiles" and "countBytes" - output arguments of VISITOR1 function
[countDirs, countFiles, countBytes] = dirwalk(topPath, @visitor1);


fprintf('\nTotal directories: %d\nTotal files: %d\nFull Size: %.1f Mb\n', ...
    sum([countDirs{:}]), sum([countFiles{:}]), sum([countBytes{:}])/1048576)
%}


%% Walking with visitor 2 (regexp matching)
fprintf('\nWorking DIRWALK with function VISITOR2 (Select files on patern matching)\n');

% "fileNames" - output argument of VISITOR2 function
% select files types: *.c, *.cpp, *.h
fileNmes = dirwalk(topPath, @visitor2, '^.*\.c$', '^.*\.cpp$', '^.*\.h$');

% All files *.c, *.cpp, *.h
fileNames = vertcat({}, fileNmes{:});
%--------------------------------------------------------------------------


%% ========================================================================
function varargout = visitor1(rootPath, Listing, varargin)
%VISITOR1 Visitor function
%
% Signatures:
%   [out1m out2, ..., outN] = visitor(rootPath, Listing)
%   varargout = visitor(rootPath, Listing)
%   [...] = visitor(rootPath, Listing, inp1, inp2, ..., inpN)
%   [...] = visitor(rootPath, Listing, varargin)
%
% Input:
%   rootPath -- Path to visited directory. String
%   Listing  -- Visited directory listing. Array of structs (output of function DIR)
%
% Output:
%   Any number of output arguments
%

% Test example:

% Check number of output arguments
error(nargoutchk(0, 3, nargout))

% Get files info
names = {Listing.name}';
bytes = sum([Listing.bytes]);

isDirs = [Listing.isdir];

dirNames = names(isDirs);
fileNames = names(~isDirs);

inds = ~strcmp(dirNames, '.') & ~strcmp(dirNames, '..');
dirNames = dirNames(inds);

countDirs = numel(dirNames);
countFiles = numel(fileNames);

% Display Info
fprintf('    %4d files in directory: "%s"\n', countFiles, rootPath)

% Return output arguments
varargout{1} = countDirs;
varargout{2} = countFiles;
varargout{3} = bytes;
%--------------------------------------------------------------------------


%% ========================================================================
function fileNames = visitor2(rootPath, Listing, varargin)
%VISITOR2 Visitor function
%
% Description:
%   Select files on regexp paterns matching.
%
% Input:
%   rootPath -- Path to visited directory. String
%   Listing  -- Visited directory listing. Array of structs (output of function DIR)
%   varargin -- Regexp paterns
%

% Check number of output arguments
error(nargoutchk(0, 1, nargout))

names = {Listing.name}';
isDirs = [Listing.isdir];
fileNames = names(~isDirs);

pInds = zeros(numel(fileNames), 1);

paterns = varargin;

for i = 1:numel(paterns)
    matchNames = regexp(fileNames, paterns{i}, 'once', 'match');
    cInds = ~cellfun('isempty', matchNames);
    pInds = pInds | cInds;
end

fileNames = cellfun(@(x) fullfile(rootPath, x), fileNames(pInds), 'UniformOutput', 0);

disp(fileNames)
%--------------------------------------------------------------------------



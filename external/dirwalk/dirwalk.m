function varargout = dirwalk(topPath, visitor, varargin)
%DIRWALK Generate the file names in a directory tree by walking the tree
%
% Description:
%   Function DIRWALK generates the file names in a directory tree by walking the tree 
%   top-down. For each directory in the tree rooted at directory topPath.
%   For each directory of tree you can call "Visitor Function" for files processing.
%
%
% Using:
%   [pathNames, dirNames, fileNames] = dirwalk(topPath)
%   dirwalk(topPath, visitor)
%   dirwalk(topPath, visitor, varargin)
%   varargout = dirwalk(topPath, visitor, varargin)
%   [visitorOutput1, visitorOutput2, ..., visitorOutputN] = dirwalk(topPath, visitor)
%   [...] = dirwalk(topPath, visitor, visitorInput1, visitorInput2, ..., visitorInputN)
%   [...] = dirwalk(topPath, visitor, varargin)
%
%
% Input:
%   topPath -- (Required) Top path name (Root path name)
%
%   visitor -- (Optional) Function handle. The function will be called 
%                         when visiting each directory of tree. 
%
%   Signatures of visitor function: 
%   	visitor(pathName, DirListing)
%       visitor(pathName, DirListing, in1, in2, ..., inN)
%       visitor(pathName, DirListing, varargin)
%       varargout = visitor(...)
%      	[out1, out2, ..., outN] = visitor(...)
%       
%   Input arguments:
%       pathName   -- (Required) Path to visited directory. String.
%                                (passed within DIRWALK)
%
%       DirListing -- (Required) Visited directory listing. 
%                                Array of structs output of function DIR. 
%                                (passed within DIRWALK)
%
%       varargin   -- (Optional) Other input arguments. (Passed outside)
%
%
% Output:
%   dirPaths  -- (Default visitor output) Visited path names. Cell array of strings.
%   dirNames  -- (Default visitor output) Directory names in visited paths (without '.' and '..'). Cell array of cell arrays.
%   fileNames -- (Default visitor output) File names in visited paths. Cell array of cell arrays.
%   visitorOutputs -- Visitor function outputs 
%
%
% Examples:
%   topPath = fullfile(matlabroot, 'toolbox', 'matlab', 'demos');
%
%   [pathNames, dirNames, fileNames] = dirwalk(topPath);
%   
%   dirwalk(topPath, @(y,x) disp(strcat(y, filesep, {x.name}')))
%
%
% See Also DIR, LS
%

% -------------------------------------------------------------------------
%   Version   : 1.1
%   Author    : Evgeny Pr aka iroln <esp.home@gmail.com>
%   Created   : 10.10.10
%   Updated   : 03.07.11
%
%   Copyright : Evgeny Prilepin (c) 2010-2011
% -------------------------------------------------------------------------

error(nargchk(1, Inf, nargin));

if (nargin < 2)
    error(nargoutchk(0, 3, nargout));
    
    visitor = @default_visitor;
    visitorNumOutputs = 3;
    isUseDefaultVisitor = true;
else
    visitorNumOutputs = nargout;
    isUseDefaultVisitor = false;
end

validateattributes(topPath, {'char'}, {'row'}, ...
    mfilename('fullpath'), '"Top Path Name"', 1)

if ~isempty(visitor)
    validateattributes(visitor, {'function_handle'}, {'scalar'}, ...
        mfilename('fullpath'), '"Visitor Function Handle"', 2)
end

varargout = dir_tree_helper(topPath, ...
    visitor, visitorNumOutputs, isUseDefaultVisitor, varargin{:});
%--------------------------------------------------------------------------

%==========================================================================
function visitorOutputs = dir_tree_helper(topPath, visitorHandle, ...
    visitorNumOutputs, isUseDefaultVisitor, varargin)
%DIR_TREE_HELPER Helper function for get directory tree

% Allocate memory for tree listing
preallocDirItems = 100000;
outputs = cell(preallocDirItems, visitorNumOutputs);
counter = 1;

% Get tree listing
[counter, outputs] = dir_tree_listing(topPath, counter, outputs, ...
    visitorHandle, visitorNumOutputs, isUseDefaultVisitor, varargin{:});

% Remove extra
if (counter < preallocDirItems)
    outputs(counter+1:end, :) = [];
end

% Construct visitor function outputs
visitorOutputs = cell(1, visitorNumOutputs);
for i = 1:visitorNumOutputs
    visitorOutputs(i) = {outputs(:,i)};
end
%--------------------------------------------------------------------------

%==========================================================================
function [counter, outputs] = dir_tree_listing(topPath, counter, outputs, ...
    visitorHandle, visitorNumOutputs, isUseDefaultVisitor, varargin)
%DIR_TREE_LISTING Generate dir tree listing

% Get listing of current directory
Listing = dir(topPath);

% Call Visitor function
visitorOutputs = visitor_call_helper(topPath, Listing, ...
    visitorHandle, visitorNumOutputs, varargin{:});

if isUseDefaultVisitor
    dirNames = visitorOutputs{2};
else
    dirNames = get_dir_file_names(Listing);
end

if (visitorNumOutputs > 0)
    outputs(counter,:) = visitorOutputs;
end

% Recursive walking directories in current directory
for i = 1:length(dirNames)
    nextRootPath = fullfile(topPath, dirNames{i});
    
    [counter, outputs] = dir_tree_listing(nextRootPath, counter+1, outputs, ...
        visitorHandle, visitorNumOutputs, isUseDefaultVisitor, varargin{:});
end
%--------------------------------------------------------------------------

%==========================================================================
function visitorOutputs = visitor_call_helper(topPath, Listing, ...
    visitor, numOutputs, varargin)
%VISITOR_CALL_HELPER Helper function for call visitor function

if (numOutputs == 0)
    % Visitor function without output arguments
    visitorOutputs = {};
    visitor(topPath, Listing, varargin{:});
else
    % Construct eval command for call visitor function with any number output arguments
    outputNumbers = num2cell(1:numOutputs);
    
    %FIXME: It is not recommended, but otherwise doesn't work
    outputArgs = deblank(sprintf('outputs{%d} ', outputNumbers{:}));
    visitorCalling = sprintf('[%s] = visitor(topPath, Listing, varargin{:});', outputArgs);
    eval(visitorCalling);
    
    visitorOutputs = outputs;
end
%--------------------------------------------------------------------------

%==========================================================================
function [pathName, dirNames, fileNames] = default_visitor(rootPath, Listing)
%DEFAULT_VISITOR Default Visitor function
%
% Default visitor function return 3 output arguments:
%   pathNames -- visited paths names
%   dirNames  -- Directories names in visited directories
%   fileNames -- Files names in visited directories
%

pathName = rootPath;
[dirNames, fileNames] = get_dir_file_names(Listing);
%--------------------------------------------------------------------------

%==========================================================================
function [dirNames, fileNames] = get_dir_file_names(Listing)
%GET_DIR_FILE_NAMES 

names = {Listing.name}';
isDirs = [Listing.isdir];
dirNames = names(isDirs);
fileNames = names(~isDirs);

% Exclude special directories '.' and '..'
inds = ~strcmp(dirNames, '.') & ~strcmp(dirNames, '..');
dirNames = dirNames(inds);
%--------------------------------------------------------------------------


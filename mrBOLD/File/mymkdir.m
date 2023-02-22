function varargout=mymkdir(varargin)
% varargout=mymkdir(varargin)
% this is a WRAPPER for MKDIR, adds a few checks and fixes a "quirk" 
% see MKDIR.M for further comments/info
% huk and den, 03/12/01
%
% takes in same exact argument structure as mkdir
% adds: 1. check to see if dir exists, if so, returns without 
%           making directory or crashing
%       2. disps creation success or failure
%       3. fixes exist bug (checks for exact directory, not just if it's anywhere in path)

ex = 0;
ok =0;
args = cell2str(varargin);

% build directory name
if (nargin==1)  
    dname = args{1};
elseif (nargin==2)
    dname = fullfile(args{1},args{2});
else
    error('mymkdir error: Number of args to mymkdir must be 1 or 2. See mymkdir/mkdir help.');
end

% check for existence of directory-to-be-built
% calling dir to avoid exist troubles (don't check the whole path for the dir, just the one we want!)
ex = length(dir(dname));

% build or not to build
if ex 
    disp(['Warning: Directory: ' dname ' already exists. Not creating.']);
else
    if (nargin==1)
        ok = mkdir(args{1});
    elseif (nargin==2)
        ok = mkdir(args{1},args{2});
    end
    if ok
        disp(['Directory: ' dname ' created.']);
    else
        disp(['Directory creation failed: ' dname ' !']);
    end
end
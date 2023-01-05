function fg = fgCreate(varargin)
% Create a fiber group structure with default values
%
%   fg = fgCreate;
% 
% Fields that can be set are
%   name = 'FG-1';
%   thickness = -0.5;        % Means ...
%   visibleFlag = 1;
%   colorRgb = [20 90 200];
%   seeds = [];
%   seedRadius = 0;
%   seedVoxelOffsets = [];
%   params = {};
%   fibers = fibers;
%   query_id = -1;
%   coordspace = struct('acpc', eye(4), 'img', [], 'mni', []);
%
% Example:
%   fg = fgCreate;
%   fg = fgCreate('name','myGroup');
%   fg = fgCreate('name','myGroup','colorRgb',[255 255 255]);
%   fg(2) = fgCreate;
%
% See also: fgSet, fgGet
%
% (c) Stanford VISTA Team

%% Set up the defaults
name = 'FG-1';
type = 'fibergroup';

thickness = -0.5; 
visibleFlag = 1;
color = [20 90 200];
fibers = {};

fg.name = name;
fg.type = type;
fg.colorRgb = color;
fg.thickness = thickness;
fg.visible = visibleFlag;
fg.seeds = [];
fg.seedRadius = 0;
fg.seedVoxelOffsets = [];
fg.params = {};
fg.fibers = fibers;
fg.query_id = -1;

% Identifiers for the fibers in fg.fibers
% This is a list of possible names (e.g., arcuate, optic radiation) for
% each of the fibers in the cell array, fg.fibers{ii}.  There might be
% something like 20 different names when it is the Mori groups, for
% example.
fg.fiberNames = [];

% A numerical index, normally of the same length as fg.fibers, where each
% index points to the name associated with that fiber.  So, for the ith
% fiber cell array, fg.fibers{ii}, the index is fg.fiberNumbers(ii) and the
% name is fg.fiberNames(fg.fiberIndex(ii));
% The fiberIndex normally has the same length as fg.fibers.  There should
% be a smaller number of fiberNames.  To indicate that you don't know which
% group a fiber belongs to, use a non positive integer value, say -1.
fg.fiberIndex = [];

% Which space are the fiber coordinates represented in?
% Image space ('img') are basically indices into the data voxels.
% ACPC ('acpc') space is relative to the middle of the acpc.
% MNI ('mni') space is another option.
% This struct contains the transformations required to get from the
% fiber coordinates to the requested coordinate space (if this xform is 
% known). If the fiber coordinates are given in a particular coordinate
% space. That matrix for that coordspace will be the identity matrix. 
% Unknown transformations (that have not been set in any way) will be set
% to an empty matrix. The default space is 'acpc': 
fg.coordspace = struct('acpc', eye(4), 'img', [], 'mni', []);  

% If the user has set some inputs, overwrite the defaults here
fg = mrVarargin(fg,varargin);

return

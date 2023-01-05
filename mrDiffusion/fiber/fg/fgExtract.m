function fgOut = fgExtract(fg,list,operation)
% Select a subset of fibers and create a new group by either keeping fibers
% in list, or removing them.
%
%   fgOut = fgExtract(fg,list,[operation='keep'])
%
% INPUTS:
%       fg:        a fiber group structure (or pdb/mat file)
%       list:      the specific fibers you want to extract in a 1xN list
%                  of indices
%       operation: the operation to be performed. You can either 'keep' or
%                  'remove' the fibers in list
%                    * Accepted inputs for 'operation': *
%                      'keep'  - the fibers corresponding to the entries
%                                in list are kept (the others are removed)
%                     'remove' - the fibers corresponding to the entries
%                                in list are removed.
%
% OUTPUTS:
%       fgOut:     the fg fibers that are in the list, with certain other
%                  fields preserved.
%
% USAGE NOTES:
%   Quench statistics (if any) are NO LONGER cleared as part of the
%   extraction.
%
%   N.B. There may be problems with this routine preserving some of the
%   associated variables (e.g., seeds, Q, and other properties computed
%   from the fibers).  We preserve some of them, but we clear others and/or
%   possibly make some worthless (e.g. pathway statistics in params).
%   Specifically, those entries in fg.params that do not have statistics
%   are removed as part of this process (e.g., {'faThresh'  [0.1500]
%   'lengthThreshMm'  [50 250]  'stepSizeMm'  [1]}).
%
% WEB RESOURCES:
%   mrvBrowseSVN('fgExtract');
%
% SEE ALSO:
%   fgTensors.m, dtiClearQuenchStats.m, fgSet.m, fgGet.m , fgThresh.m
%
%
% EXAMPLE USAGE:
%   fg = dtiGet(dtiH,'fiber groups',1);
%   nFibers = fgGet(fg,'n fibers');
%   list = 1:5:nFibers;
%   fgSmall = fgExtract(fg,list,'keep');
%   fgGet(fgSmall,'n fibers')
%
%
% (C) Stanford VISTA, 2011

% TODO:  Wandell found some funny stuff, edited, need to check with LMP.

%% Check inputs

if notDefined('fg') || isempty(fg) || ~isstruct(fg)
  % Allow the user to pass in a file name
  if exist(fg,'file'), fg = fgRead(fg);
  else                 fg = fgRead;
  end
end

if notDefined('list'), error('list of fiber indices to remove is required'); end

if all(list == 0)
  error('list of indices has all zero entries, no fibers removed.')
end

if notDefined('operation')
  disp('No operation defined. Defaulting to "keep"... ');
  operation = 'keep';
end


%% Get the indicies for the fibers to be removed

% We remove fibers and corresponding parameters specifed by the indices in
% inds. If the user said 'keep', then we need to flip the list from keep to
% remove.
switch operation
  case {'keep',0}
    % Full list of inds to the number of fibers
    inds = 1:fgGet(fg,'n fibers');
    % Remove the keep 'list' entries; the remaining entries are the
    % fibers that we remove.
    inds(list) = [];
    
  case {'remove','delete',1};
    % In the 'remove' case 'list' is already those fibers that are to
    % be removed so we set inds equal to list
    inds = list;
end


%% Format the fiber indices.

% Fibers with the highest index are removed first. This must be done so
% that the size of the array does not change before a given entry is
% removed - which would result in a "index exceeds matrix dimensions"
% error.

% Make fiber inds 1xN
% Force inds to be ordered largest to smallest
inds = sort(inds(:),'descend')';


%% Notes on stats fields

% These are leftover stats notes from previous code. The issues here were
% circumvented using the code in the following cells.

% Given a list of inds, we want to remove the specified fibers and their
% entries in the 'pathwayInfo', 'params', 'Q' and 'seeds' fields.

% Statistics are no longer valid. [OR ARE THEY???] This should be tested
% further.

% Clear the existing stats from the fg. If we don't do this here we get
% some weird display characteristics when we open them in Quench. (They
% won't display per-point) [NOTE: I think this is fixed by the code in the
% next two cells.] This will clear fg.params and fg.pathwayInfo and we
% don't want that, especially since we put some work into getting those
% stats.

% This is no longer necessary because of the code in the next 2 cells
% fg = dtiClearQuenchStats(fg);


%% Params field

% Let's explain this better - BW
%
% Most FGs will have a params field, but we check to be
% consistent. If we want this to be even more general we have to loop
% over it and see which params fields have an entry that's the size of
% the fg.fibers field, or at least larger than 1. This could be done by
% determining the number of elements in fg.params, then looping over
% fg.params{n} and checking to see if that entry has a 'stat' field -
% and if so we remove the corresponding entry listed in 'inds' - which we
% do in the following loop. Here we remove the params fields that don't
% have individual fiber params in them - this deals with the dispay issue
% in Quench and allows us to retain the params and pathwayInfo fields as we
% don't have to run dtiClearQuenchStats.

% Initialize counter:
% c = 0;
if isfield(fg,'params') && ~isempty(fg.params)
  % Remove fg.params entries from the largest to smallest, thus
  % avoiding an index exceeds matrix dimensions error.

  fg.params = [];
  % (This was not implemented in Feb 2015 correctly.  So I fixed it, BW).
  nParams = numel(fg.params);
  for kk = nParams:-1:1
    if ~isfield(fg.params{kk}, 'stat')
      % Remove the fg.params entry that does not have a 'stat'
      % field.
      fg.params(kk) = [];
      % Add 1 to the counter and set the entry in idx - which
      % will keep track of which params we removed. This will be
      % used in the next cell to loop over the pathwayInfo field
      % and remove the corresponding entries in the pathwayInfo.
      % fields.
      % c = c+1;
      % idx(c) = kk; %#ok<AGROW>
    end
  end
end

%% REMOVAL: fibers removed based on 'list' (inds)
% This version of the code is several order of magnitude faster then the
% previous. Franco.
for ii = 1:numel(inds)
  % Remove the actual fibers
  fg.fibers{inds(ii)} = [];
end
fg.fibers(cellfun('isempty',fg.fibers)) = [];

%% REMOVAL:  PathwayInfo field
% Each of the params fields must be removed from pathwayInfo as well. But
% it's not the top level that has to be removed but rather the entries in
% the pathwayInfo.pathStat and the pathwayInfo.point_stat_array structs
% that correspond to the removed params fields have to be removed.
% These fields have different dimensions.
%
% FIX FIX FIX-----------------------
% This is confusing. Do pathwayInfo OR pathStat have the length of fibers?
% Itis not clear here. The fiber groups I am handling have as many
% pathwayInfo as fibers. So this code is not optimal (we could delete the
% whole pathway info instead of going into each field.)
% e.g., fg.pathwayInfo(inds) = [];
% Franco
if isfield(fg,'pathwayInfo')
  for jj = 1:numel(fg.pathwayInfo)
    if isfield(fg.pathwayInfo(1),'pathStat') && ...
      ~isempty(fg.pathwayInfo(1).pathStat)
        fg.pathwayInfo(jj).pathStat(inds) = [];
    end
    if isfield(fg.pathwayInfo(1),'point_stat_array') && ...
      ~isempty(fg.pathwayInfo(1).point_stat_array)
        fg.pathwayInfo(jj).point_stat_array(inds) = [];
    end
    
    if isfield(fg.pathwayInfo(1),'seed_point_index')
        fg.pathwayInfo(jj).seed_point_index = [];
    end
    if isfield(fg.pathwayInfo(1),'algo_type')
        fg.pathwayInfo(jj).algo_type = [];
    end
  end
  
  % FIX FIX FIX.
  % This is trick. Sometimes, I am getting pathwayInfo filed with the same length of
  % the fibers. So here I only return the ones for the fibers I am leaving
  % in the group. Franco
  if numel(fg.pathwayInfo) >= numel(fg.fibers)
      fg.pathwayInfo(inds) = [];
  end
end

%% REMOVAL: other field entries removed based on 'list' (inds)
% Go through the inds list and remove the corresponding entries from
% fg.fibers, fg.params, fg.seeds, fg.pathwayInfo and fg.Q.


% Loop over fg.params{n} and check to see if that entry has a 'stat'
% field - if so we remove the corresponding entry listed in 'inds'. At
% this point all of the params fields should have the stat field, but
% we check to be thorough.
if isfield(fg,'params') && ~isempty(fg.params)
  for kk = 1:numel(fg.params)
    if isfield(fg.params{kk}, 'stat')
      fg.params{kk}.stat(inds) = [];
    end
  end
end

% Some fiber groups will have other fields (seeds, Q). The
% corresponding entries in tese fields must also be removed. TO DO:
% Look into what other fields might have to be altered. (Q entry
% removal needs to be tested).
if isfield(fg,'seeds') && ~isempty(fg.seeds)
    if size(fg.seeds,1) == 3 % THe new version of dtiFiberTracker (2) retunrs seeds that are coordinatesc
      fg.seeds(:,inds) = [];
    else
      fg.seeds(inds,:) = [];
    end
end

if isfield(fg,'Q') && ~isempty(fg.Q)
  for ii = 1:numel(inds)
    fg.Q{inds(ii)} = [];
  end
  fg.Q(cellfun('isempty',fg.Q)) = [];
end


%% Return fgOut
fgOut = fg;

return


%% Old Code

% Get the fibers
% foo = cell(length(list),1);
% for ii=1:length(list)
%     foo{ii} =  fg.fibers{ii};
% end
% fgOut.fibers = foo;
%
% % If there are tensors, get them too.  See fgTensors
% if isfield(fgOut,'Q') && ~isempty(fgOut.Q)
%     foo = cell(length(list),1);
%     for ii=1:length(list), foo{ii} = fg.Q{ii}; end
%     fgOut.Q = foo;
% end
%
% if isfield(fgOut,'seeds') && ~isempty(fgOut.seeds)
%     fgOut.seeds = fgOut.seeds(list);
% end



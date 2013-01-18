function fg = fgMerge(fg1,fg2,name)
%
% Takes two fiber groups as input and merge them in a new fiber group. 
% 
%   fg = fgMerge(fg1,fg1,[name])
%
% INPUTS:
%       fg1, fg2:  a fiber group structure.
%       name:      the name of the new fiber group
%
% OUTPUTS:
%       fg:        the merged fiber group which will contain both fiber
%                  groups (fg1, and fg2)
%      
% USAGE NOTES:
% 
% WEB RESOURCES:
%   mrvBrowseSVN('fgMerge');
% 
% SEE ALSO:
%   fgTensors.m, fgExtract, fgSet.m, fgGet.m , fgThresh.m
%
% 
% EXAMPLE USAGE:
%   fg = fgMerge(fg1,fg2,'merged_fiberGroup');
% 
% Franco
%
% (C) Stanford VISTA, 2012

% Check inputs
if notDefined('fg1'), error('fg1 not defined'); end
if notDefined('fg2'), error('fg2 not defined'); end
if ~notDefined('fibers'), error('fibers cannot be passed.'); end
if ~notDefined('params'), error('params cannot be passed.'); end

% Set name if not passed in
if notDefined('name'), name = sprintf('merged_%s_%s',fg1.name,fg2.name); end

% Merge fibers data.
if (size(fg1.fibers,1) > 1) && (size(fg2.fibers,1) > 1)
    fibers = vertcat(fg1.fibers, fg2.fibers);
    
elseif (size(fg1.fibers,1) == 1) && (size(fg2.fibers,1) == 1)
    fibers = horzcat(fg1.fibers, fg2.fibers);
else
    keyboard
end

% Merge parameters
n1 = length(fg1.params);
n2 = length(fg2.params);
params = cell(n1,1);
for ii=1:n1, 
    params{ii}= fg1.params{ii}; 
end
for ii=(n1+1):(n1+n2), 
    params{ii} = fg2.params{ii - n1}; 
end

% Merge the fiber groups, by creating a new fiber group.
fg = fgCreate('name',    name,   ...
              'fibers',  fibers, ...
              'params',  params);
          
% If tensors were computed for these fibers merge them.
if isfield(fg1,'Q') && isfield(fg2,'Q')
   fg.Q = horzcat(fg1.Q,fg2.Q); 
end

% Tracking seeds
if isfield(fg1,'seeds') && isfield(fg2,'seeds')
  fg.seeds = horzcat(fg1.seeds,fg2.seeds);
end

% pathwayInfo (statistics)
if isfield(fg1,'pathwayInfo') && isfield(fg2,'pathwayInfo')
  % Find all fields in the two fiber groups
  fields1 = fieldnames(fg1.pathwayInfo);
  fields2 = fieldnames(fg2.pathwayInfo);
  n1 = length(fg1.pathwayInfo);
  n2 = length(fg2.pathwayInfo);
  for ii = 1:n1+n2
    if ii <= n1
      for jj = 1:length(fields1)
        fg.pathwayInfo(ii).(fields1{jj}) = fg1.pathwayInfo(ii).(fields1{jj});
      end
    else
      for jj = 1:length(fields2)
        fg.pathwayInfo(ii).(fields2{jj}) = fg2.pathwayInfo(ii-n1).(fields2{jj});
      end
    end
  end
end

return


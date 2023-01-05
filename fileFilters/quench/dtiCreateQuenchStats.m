function fg = dtiCreateQuenchStats(fg, statFiberName, statPointName, perPoint, img, fiberSummary, pointCompute,mpRange)
% 
% fg = dtiCreateQuenchStats(fg, [statFiberName='avg'], [statPointName='fa'],...
%     [perPoint=1], img, [fiberSummary='avg'],[pointCompute='none']);
% 
% Add satistics to a fiber group that are used for Quench visualization and
% queries. Every path gets a number (its statistic) for that path. Some
% paths also have statistics per point along the path (e.g. in the array
% condition). They are stored in the returned fiber group struct.
%
% INPUTS:
%  fg            - Fiber Group. The statistics will be attached to this
%                  structure.
%  statFiberName - Name for a fiber summary statistic. Typically this
%                  will be  something like length or "average FA". THis
%                  statistic is used to limit the range of fibers we see
%                  in the Quench window.
%  statPointName - Name for the per point statistic (e.g., TF, FA,
%                  eccentricity)
%  perPoint      - 1 if computed per point, 0 if only per fiber
%  img           - Data for statistical overlay. The data form is either a
%                  nifti image structure or dti image structure. 
%                  If no data are supplied the routine computes a default
%                  statistic determined by the statFiberName. At present,
%                  the only statFiberName that generates a statistic is
%                  'length'.
%  fiberSummary  - If data are supplied, this variable specifies
%                  which statFiber statistic to compute. We currently
%                  support can be 'avg', 'min','max'.  This fiber statistic
%
%  pointCompute  - Method for taking per point color and remapping to new
%                  per point colors.  Either 'none' or 'matchEnd' are in
%                  place.  More methods will arise.  The matchEnd is a
%                  hack.
% 
% WEB: 
%  mrvBrowseSVN('dtiCreateQuenchStats');
% 
%  This function computes output parameters pathStat and point_stat_array.
%  The max and min of pathStat are used to set the range for colormaps etc.
%  in Quench.
% 
%Delete this comment soon ---
% Statistics can be one of three types: 
%   1) geometry - path length, curvature 
%   2) image    - FA value, other pointwise statistic (e.g., eccentricity)
%   3) array    - An array of vectors. each the same length as a
%      corresponding path in the fiber group, and values of the vectors are
%      assigned to each position along the paths.
%
% EXAMPLES:
%
%   Image Stat:
%       fg = mtrImportFibers('fibers.pdb');
%       fa_img = niftiRead('faMap.nii.gz');
%       fg = dtiCreateQuenchStats(fg,'FA_avg','FA', 1, fa_img, 'avg'); 
%     OR...
%       h = guidata(gcf); fa_img = h.bg(1,2,3 or 5);
%       fg = dtiCreateQuenchStats(fg,'FA_avg','FA', 1, fa_img, 'avg'); 
% 
%   Given Array Stat
%       fg = dtiCreateQuenchStats(fg,'Group',stat_array); 
%
%   Geometric Stat
%       fg = dtiCreateQuenchStats(fg,'Length','Length', 1);
%
% 
% HISTORY:
% 2009.06.17 : SA wrote it
% 2009.08.04 : AJS fixed the mixing between explicit declaration of
% perPoint and the implicit assumption in most of the code.
% Now we truly have the variable report explicit info.  Also added the
% ability to have a statistic be added by passing the array of per pathway
% stats that you would like to have.
% 2009.10.19 : AJS significantly sped up the code by using cellfun.
%

%% Check if input params are ok
if notDefined('fg') || ~isstruct(fg)
    disp('fg should be a proper fibergroup struct');
    return;
end

if notDefined('statFiberName'), statFiberName = 'avg'; end
if notDefined('statPointName'), statPointName = 'fa'; end
if notDefined('perPoint'), perPoint = 1; end
if notDefined('img')
    if ~strcmpi(statFiberName,'length')
        error('Data for overlay are required');
    end
end
if notDefined('fiberSummary'), fiberSummary = 'avg'; end
if notDefined('pointCompute'), pointCompute = 'none'; end

if ~isfield(fg,'pathwayInfo'), fg.pathwayInfo=[];  end

% Indices into the number of statistical images. Quench counts from 0.  We
% start with Matlab counting from 1, and then we subtract 1 later when we
% do the Quench parameter field.
if ~isfield(fg,'params') || isempty(fg.params),  idx = 1;
else                                             idx = length(fg.params)+1;
end

% If there are only three input variables, the third must be a data set,
% not a name.  So we copy the data set to the statistics array, we set the
% name variable to not applicable, and we do not compute per point.
% Instead, we will be computing per fiber.
% if nargin == 3
%     stat_array = statPointName;
%     statPointName = 'NA';
%     perPoint = 0;
% end

%%
% This statistics parameter field gets attached to the fg.  It contains
% information that Quench uses for visualization and for dynamic queries.
% We should probably write a function for initializing this parameter
% field.
param = struct;              % Initialize structure
param.name = statFiberName;  % Struct name?
param.uid = idx-1;           % Subtract 1 so Quench starts from 0 (C-counting)
param.ile = 1; 
param.icpp= perPoint;        % Visualization per point, not per fiber
param.ivs = 1;               %
param.agg = statFiberName;   % A stats name
param.lname = statPointName; % Local Name
param.stat = [];

%dummy.  Same to you.
% c        = struct; 
% c.fibers = cell(1);

if notDefined('img')
    % No overlay data, so we use the statFiberName to determine how we color
    % the fibers.
    
    switch lower(statFiberName)
        case 'length'
            % For each fiber, figure out its length.
            for ii=1:length(fg.fibers)
                fiber = fg.fibers{ii};      % Get the ith fiber.
                %if(size(fiber,2)<size(fiber,1)); fiber=fiber'; end
                
                % Find the step size - could be be moved out of the loop.  Could
                % use cellfun to find all these.  Mostly these are the same.
                mmPerStep  = sqrt(sum((fiber(:,1)-fiber(:,2)).^2));
                
                % Find the length for the whole fiber
                param.stat(ii) = mmPerStep*(size(fiber,2)-1);
                
                % Store the length for this stat image (idx) and the ith pathway.
                % Each fiber group has a pathway info that summarizes all of the
                % stats in stat images.
                fg.pathwayInfo(ii).pathStat(idx) = param.stat(ii);
                
                % If we are computing per point, then we compute the length to each
                % point on the fiber, so that we don't assign a single length.
                % Rather we assign a length from the end point to each point along
                % the path.  And we put that into the point_stat_array.  Up to now,
                % we had a single length assigned to all of the fibers.
                if perPoint
                    fg.pathwayInfo(ii).point_stat_array(idx,:) = mmPerStep * (0:1:size(fiber,2)-1);
                end
            end
        otherwise
            error('Unknown statFiberName %s\n',statFiberName);
    end
        
else

    %isNiftiImg = NaN; %mat =[]; data=[];
    minVal=0; maxVal = 1;
   
    % Test whether the img variable is a nifti file structure or a dti file
    % structure.
    if isNiftiStruct(img);
        % NIFTI land.  Get what you need.
        isNiftiImg = true;
        mat  = img.qto_ijk;
        data = img.data;
    else
        isNiftiImg = false;
        if isfield(img,'img') && isfield(img,'mat')
            % It has the dti fields. So we copy the
            % fields we need and set isNifti to false.
            mat  = inv(img.mat);
            data = img.img;
            if isfield(img,'minVal'),  minVal = img.minVal; end
            if isfield(img,'maxVal'),  maxVal = img.maxVal; end
        else
            error('img must be either nifti or dti');
        end
    end
    
    % Interpolate from the values in the statistics to the position of the
    % fiber nodes.  For speed, we use nearest neighbor interpolation
    vals = dtiGetValFromFibers(data, fg, mat,[],'nearest');
    
    % Apply the scaling function function to each entry of vals. This will
    % take a 0,1 range and put it with the scale specified by max and min
    % vals.
    % 'UniformOutput' insists that the return must be a cell array.
    if ~isNiftiImg
        vals = cellfun(@(x) x*(maxVal-minVal)+minVal, vals, 'UniformOutput', false);
    end
    
    % For each of the cell arrays, we can determine a single value that
    % will be applied to the whole fiber.  This might be the avg, min or
    % max. We compute this value and store it as a single scalar here in
    % the stat field.  The stat field should have one scalar for every
    % fiber in the fiber group.  This is for the non per-point calculation.
    % 
    switch(lower(fiberSummary))
        case 'avg'
            param.stat = cellfun(@mean,vals);
        case 'min'
            param.stat = cellfun(@min,vals);
        case 'max'
            param.stat = cellfun(@max,vals);
        otherwise
            error('Unknown fiberSummary: %s\n',fiberSummary);
            
    end
    
    % In principle, we could write point_stat_array into param.statPoint
    % and the other could be param.statFiber.  Leave it for now, think
    % later.
    
    % Copy the statistics to the fg pathwayInfo location.  The stat field
    % is for plotting for a whole fiber, and the per point is for the per
    % point case (not always set).
    for ii=1:length(fg.fibers)
        fg.pathwayInfo(ii).pathStat(idx)=param.stat(ii);
        
        if perPoint
            % We can write algorithms that take the vals, smooth them, use
            % the max, whatever, to create the point coloring.  This is how
            % we will get perFiber coloring.
            switch lower(pointCompute)
                case 'none'
                    fg.pathwayInfo(ii).point_stat_array(idx,:) = vals{ii}(:);
                case 'matchend'
                    tmp = vals{ii}(:);
                    last = min(length(tmp),10);
                    foo = tmp(1:last); 
                    foo = foo(foo ~= 0); 
                    if ~isempty(foo)
                        tmp(:) = max(foo(:));
                    else
                        tmp(:) = 0; 
                    end
                    fg.pathwayInfo(ii).point_stat_array(idx,:) = tmp;
                otherwise
                    error('Unknown pointCompute method %s\n',pointCompute);
            end
        end
    end   

end
%This is a hack to edit the range of the colorbar display in Quench. This
%will only be a problem if you clean fibers with the refine selection tool
%in quench
if ~notDefined('mpRange')
    fg.pathwayInfo(1).pathStat(idx)=mpRange(1);
    fg.pathwayInfo(2).pathStat(idx)=mpRange(2);
    param.stat(1)=mpRange(1);
    param.stat(2)=mpRange(2);
end

fg.params{idx} = param;

end

%% Make this better over time
function isNifti = isNiftiStruct(img)

isNifti = true;
if ~isfield(img,'qto_ijk') || ~isfield(img,'data')
    isNifti = false;
end

end


        

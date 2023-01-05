function [fiberspool, fiberDiameter] =dtiCullFibers(fg, dt6filename, Tt, distanceCrit, fiberLenCrit, averLACrit)
% ER's idea of how to 'cull' fibers - Use with caution ...
%
% [fiberspool, fiberDiameter] = dtiCullFibers(fg, dt6filename, Tt, distanceCrit, fiberLenCrit, averLACrit)
%
% fg: Fiber group
% dt6filename:
% Tt:
% distanceCrit:  Separation between fibers
% fiberLenCrit: (mm)
% averLACrit:  (mm)
%
% Fibers are not removed (culled) from a fiber group if
%
% (1) Length of a trajectory > 10.0mm
% (2) Average linear anisotropy along fiber trajectory > 0.1
% (3) Fibers meeting these criteria have a between fiber distance >1 mm (on average).
%     Default threshold value is 1 mm;
%
% Although arguable, it is natural to set Tt to resampled data voxel size
% (as Zhang 2003 did), and . Zhang et al. (2003) IEEE Transactions on
% Vizualization and Computer Graphics 9(4)
%
%11/2008: ER wrote it
%
% (c) Stanford VISTA Team

totalNfibers=size(fg.fibers, 1);

if (~exist('fiberLenCrit','var') || isempty(fiberLenCrit))
    fiberLenCrit=10; %in mm
end

if(~exist('averLACrit','var') || isempty(averLACrit))
    averLACrit=0.1;%arbitrary
end

if(~exist('distanceCrit','var') || isempty(distanceCrit))
    distanceCrit = 1;% %distanceCrit=1.7*2;%for voxels of 2; 1.7*voxel Or do I mean voxels as in opts.stepSizeMm?
end

% What is Tt?
if(~exist('Tt','var') || isempty(Tt))
    Tt=1; %Tt=2;
end

%Deal with files with no subgroup field
if  ~isfield(fg, 'subgroup') || isempty(fg.subgroup)
    fg.subgroup=repmat(1, [1 size(fg.fibers, 1)]);
end

% (1) Fiber length: infer from number of points; length(fg.fibers{ii}). On
%average the distance between the neighbouring points is....opts.stepSizeMm= 1;

%Create a FG which consists of only fibers that are longer than fiberLenCrit
fg1=fg;
fiberLen = cellfun('length', fg.fibers);
fg1.fibers=fg.fibers(fiberLen>fiberLenCrit);
if ~isempty(fg.seeds)
    fg1.seeds=fg.seeds(fiberLen>fiberLenCrit, :);
end
fg1.subgroup=fg.subgroup(fiberLen>fiberLenCrit);

fg1.name=[fg.name '_>10mm'];
shortNfibers=size(fg.fibers, 1)-size(fg1.fibers, 1);
clear fg;
display(['Eliminated ' num2str(shortNfibers) ' fibers that were shorter than ' num2str(fiberLenCrit) ' mm']);

%(2) Linear anisotropy is defined in Westin, Peled, Gubjartsson, Kikinis,
%Jolesc (ISMRM, 1997): cl=(l1-l2)/(l1+l2+l3)
valName ='shapes'; interpMethod='trilin'; %(triplet of values indicating linearity, planarity and spherisity)
dt      = dtiLoadDt6(dt6filename);

%Create a FG which consists only of long fibers that have average LA of at
%least averLACrit
fg2 = fg1; fg2.seeds=[]; fg2.fibers=[]; fg2.subgroup=[];
fg2.name = [fg1.name '_la>' num2str(averLACrit)];

%Need to break the FG into pieces of 5000 so that dtiGetValFromFibers does not
%choke on it.
stepsize=5000;

fgtemp.seeds=[];

fprintf(1, ['Computing linear anisotropy for fibers (out of ' num2str(size(fg1.fibers, 1)) '): ']);
for group_of_fibers=1:stepsize:size(fg1.fibers, 1)
    
    fprintf(1, [num2str(group_of_fibers) ' to ' num2str(min(group_of_fibers+stepsize-1, size(fg1.fibers, 1))) ' ... ']);
    if ~isempty(fg1.seeds)
        fgtemp.seeds=fg1.seeds(group_of_fibers:min(group_of_fibers+stepsize-1, size(fg1.seeds, 1)), :);
    end
    fgtemp.fibers=fg1.fibers(group_of_fibers:min(group_of_fibers+stepsize-1, size(fg1.fibers, 1)));
    fgtemp.subgroup=fg1.subgroup(group_of_fibers:min(group_of_fibers+stepsize-1, size(fg1.fibers, 1)));
    
    val = dtiGetValFromFibers(dt.dt6, fgtemp, inv(dt.xformToAcpc), valName, interpMethod);
    shapes=cellfun(@mean, val, 'UniformOutput', 0);
    shapesC=vertcat(shapes{:});
    %shapesC(:, 1) %gives you linear anisotropy
    
    fg2.fibers=vertcat(fg2.fibers, fgtemp.fibers(shapesC(:, 1)>averLACrit));
    if ~isempty(fgtemp.seeds)
        fg2.seeds=vertcat(fg2.seeds, fgtemp.seeds(shapesC(:, 1)>averLACrit, :));
    end
    fg2.subgroup=horzcat(fg2.subgroup, fgtemp.subgroup(shapesC(:, 1)>averLACrit));
    
end
fprintf(1, '\n');
lowanisotropyNfibers=size(fg1.fibers, 1)-size(fg2.fibers, 1);
fprintf('Eliminated %d fibers that had linear anisotropy smaller than %.3f\n',...
    lowanisotropyNfibers, averLACrit);
clear fg1 fgtemp;

%Now, this approach has to be tested for robustness towards the order in
%which the fibers are tested. If a fiber B is considered too close to fiber
%A, fiber B is dropped (there is no creating an average representation of
%the two, as the latter might lead to weird drifft effects swipping
%streamsheets

% Shuffle the fibers to ensure the lack of effects that comes from
% systematic seed placement. 
fg3 = dtiShuffleFibers(fg2);
clear fg2;

% This will be the selected fibers, I guess. (BW).  This method of creating
% the pool is odd and special cased.  It should be a general function.
fiberspool = fg3;
fiberspool.name = sprintf('%s-culled',fg3.name);
fiberspool.fibers = []; 
fiberspool.seeds  = [];
fiberspool.subgroup = [];

% Always put one fiber (the first one) into the pool
fiberspool.fibers{1} = fg3.fibers{1};
if ~isempty(fg3.seeds)
    fiberspool.seeds = fg3.seeds(1, :);
end
% I guess for subgropu, too
fiberspool.subgroup = fg3.subgroup(1);

% Should be a mrvWaitbar?  It steps in 5000 fiber chunks.  Not sure why.
fprintf('Distance testing: %d fibers\n', size(fg3.fibers, 1));
stepSize = 5000;
for i=1:stepSize:size(fg3.fibers, 1) % Step over 5000 fibers at a time.
    
    % There is an index 'i', an index 'ii', and an index 'jj'. We can be
    % clearer. We compare the fibers in fg3 with each fibers in the pool We
    % add fibers from fg3 to the pool if they are not close to anything
    % already in the pool.
    for ii=i:min(i+(stepSize-1), size(fg3.fibers, 1))
        inpool = 1;   %Assume ii fiber in fg3 is in the keep pool
        for jj = 1:size(fiberspool.fibers, 1)
            
            % Compare the iith fiber in fg3 to each of the fibers in the
            % pool
            %
            % InterfiberZhangDistance should be renamed fgDistance.  That
            % function should have a switch to define which algorithm is
            % used, e.g. Zhang. The Dt level should be explained better.
            % Also, I think this algorithm is supposed to be using Dt + Tt,
            % not Dt.  
            [Dt avgDt] = InterfiberZhangDistance(fg3.fibers{ii}, fiberspool.fibers{jj}, Tt);
            
            if Dt <= distanceCrit
                inpool=0; % Reject this fiber
                break 
            end
            
        end
        
        % Add the new fiber to the pool.  It will be compared to the
        % remaining fibers in fg3.
        if inpool==1
            fiberspool.fibers=vertcat(fiberspool.fibers, fg3.fibers{ii});
            if ~isempty(fg3.seeds)
                fiberspool.seeds=vertcat(fiberspool.seeds, fg3.seeds(ii, :));
            end
            fiberspool.subgroup=horzcat(fiberspool.subgroup, fg3.subgroup(ii));
        end
        
    end
    fprintf('Distance testing: %d fibers of %d\n', ii, size(fg3.fibers, 1))
end

fprintf('Out of total %d fibers %d fibers remain\n',...
    totalNfibers,size(fiberspool.fibers, 1));
fprintf('Eliminated %d fibers because they were shorter than %d mm\n',...
    shortNfibers,fiberLenCrit);
fprintf('Eliminated %d fibers because linear anisotropy less than %d\n',...
    lowanisotropyNfibers, averLACrit);
fprintf('Eliminated %d fibers because they were adjacent to others\n',...
    size(fg3.fibers,1) - size(fiberspool.fibers, 1)) ;

% Add a comment
fg.cullingParams={'Tt', Tt, 'aboveThresDistanceCrit', distanceCrit};
fiberDiameter = Tt + distanceCrit;

return

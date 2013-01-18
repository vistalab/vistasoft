function mr = mrACPC(mr, ac, pc);
%
% mr = mrACPC(mr, [ac], [pc]);
%
% Compute transformation to bring an MR volume into
% AC/PC coordinate space, appending it to the list of 
% that mr object's spaces.
%
% The 'AC/PC' space will be a space defined in mm, with 
% coordinate conventions similar to the 'I|P|R' space:
% increasing (rows, cols, slices) go increasingly 
% (inferior, posterior, right). In other words, the slice
% order is (axial, coronal, sagittal) or (y, x, z).
% The anterior commisure is point (0, 0, 0) in this space. 
% The posterior commisure is at (0 -D, 0), where D is the
% distance between the two commisures. 
%
% The 'ac' and 'pc' arguments are optional: they would be
% [3 x 1] vectors specifying the location of the anterior
% commissure and posterior commisure in (rows, cols, slices) of
% the anatomy volume. (This is the default "pixel space".)
% Alternately, if the function computeTalairach.m has been
% run, this can be provided from the results of that function:
% Either the mr struct can have the subfield mr.settings.talairach,
% which contains the results of the argument, or the path
% to the talairach file (e.g 'vAnatomy_talairach') can be provided.
%
% ras, 11/2006.
if notDefined('mr'), error('Not enough input args.'); end

if notDefined('ac') | notDefined('pc')
    % see if there's a talairach field
    if checkfields(mr, 'settings', 'talairach')
        ac = mr.settings.talairach.refPoints.acXYZ([2 1 3]);
        pc = mr.settings.talairach.refPoints.pcXYZ([2 1 3]);
    elseif exist('ac', 'var') & ischar(ac)
        tal = load(ac);
        ac = tal.refPoints.acXYZ([2 1 3]);
        pc = tal.refPoints.pcXYZ([2 1 3]);
    else
        help mfilename
        error('Need AC and PC locations.');
    end
end

%% the main thing we need to solve is the xform from the source
%% coords (provided) to the target coords in AC/PC space:
% first, we need a 'rotation' xform to get the AC and PC along the 
% midline:
srcCoords = [ac(:) pc(:)];
D = sqrt( sum( (ac - pc).^2 ) ); % distance b/w AC and PC
tgtCoords = [0 0; 0 -D; 0 0];
rotXform = affineSolve(tgtCoords, srcCoords);

% we also need a 'scale' xform to get the thing into mm units:
scaleXform = affineBuild([0 0 0], [0 0 0], 1./mr.voxelSize);

%% make the space
mr.spaces(end+1) = mr.spaces(end);
mr.spaces(end).name = 'AC/PC';
mr.spaces(end).xform = scaleXform * rotXform;
mr.spaces(end).units = 'mm';
mr.spaces(end).sliceLabels = {'Sagittal' 'Coronal' 'Axial'};

return
    
        
        
        
        
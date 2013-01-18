function [fg,fileName] = dtiReadFibers(fileName, xformParams, xform)
%Reads the fiber group file format
%
%  [fg,fileName]  = dtiReadFibers([fileName], [xformParams], [xform])
%
% This routine is used principally for reading fibers for the GUI
% functions. It handles the main fiber group and subgroups in a way that
% works smoothly with the GUI.  There is another routine, dtiLoadFiberGroup,
% that is preferred for scripting (ER).
%
% The fibers may be in a 'standardized' coordinate space, in which case
% 'xformParams' will be used to unwarp them. 'xform' is an additional
% coordinate space transform that will be automatically applied (unlike
% xformParams, which is only applied if the fibers 'coordinateSpace' field
% calls for it). fileName may contain actual fg, or a ref to a "parent" fg
% file + ids of fibers to choose.
%
% Example:
%   fg = dtiReadFibers;
%   [fg, fName] = dtiReadFibers;
%
%   fName ='Y:\data\reading_longitude\dti_y1\ab040913\dti06trilinrt\fibers\allConnectingGM_MoriGroups.mat'
%   fg = dtiReadFibers(fName);
%
% See also: dtiLoadFiberGroup, dtiLoadFibers
%
% (c) Vistalab

% HISTORY:
%  2005.03.08 RFD: pulled code from other places to modularize.
%  2008.01.13 RFD: modified to handle the 'subgroup' field.
%  2008.01.30 EIR: modified to read subgroupNames
%  2009.05.29 EIR: added an option of reading a thrifty fg representation

if(~exist('fileName','var') || isempty(fileName))
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load fiber group file...');
    if(isnumeric(f)), disp('Read fibers canceled.'); roi=[]; return; end
    fileName = fullfile(p,f);
end
if(~exist('xformParams','var')), xformParams = []; end
if(~exist('xform','var')), xform = []; end
%if(~exist('query_id','var')) query_id = -1; end

% Load the file containing the variable fg
load(fileName);

%Fiber groups may be stored two different ways.
%(a) Full fiber group file, containing variables 'coordinateSpace', 'fg', and 'versionNum'.
%(b) Fiber group handle with a ref to a parental FG file, plus a list of indices referred to fibers in the parental FG.
% This format is a thrifty representation convenient for representing fg's that are various subsets of whole brain tractography results.
%  fghandle.name
%  fghandle.parent
%  fghandle.ids %Indices refer to IDs of Parent fibers which make up this selection
%  fghandle.subgroup %Optional field assigning labels to ids. If exists, takes priority over those stored in parentfg.subgroup, if any.

if exist('fghandle','var')
    fg=dtiLoadFiberGroup(fileName);
    versionNum=1;
end

% We now save version and coordinate space fields. But for backwards compatability....
if(~exist('versionNum','var')), versionNum = 0.1; end
if(~exist('coordinateSpace','var')), coordinateSpace = 'acpc'; end
if ~exist('fg','var'), error('No Fiber Group variable found.'); end

% Convert the fiber group to an array of fiber groups if there are separate
% fiber groups defined within the fg.subgroups field
if(isfield(fg,'subgroup')&&~isempty(fg.subgroup))
    % Get all the subgroup index numbers. We loop over and look in the
    % subgroup index in case there are some empty fiber groups we still
    % leave the propper group for them
    for sg = 1:length(fg.subgroupNames)
        sgInds(sg) = fg.subgroupNames(sg).subgroupIndex;
    end
    % Get the number of fiber groups
    nfg = numel(sgInds);
    % Set a color for each group
    clr = round(hsv(nfg)*235+10);
    % Loop over the number of fiber groups and divide the fibers into there
    % own entry into the array
    for(ii=1:nfg)
        % indices of the fibers corresponding to fiber group nfg
        inds = fg.subgroup==sgInds(ii);
        if ~isfield(fg, 'subgroupNames')
            subgname=sprintf('%s_%02d',fg.name,ii);
        else
            % Get teh fiber group name
            subgname=fg.subgroupNames(vertcat(fg.subgroupNames.subgroupIndex)==sgInds(ii)).subgroupName;
        end
        % Create a new fiber group in the array
        tmp(ii) = dtiNewFiberGroup(subgname, clr(ii,:), fg.thickness, fg.visible, fg.fibers(inds));
        if ~isempty(fg.seeds)
            tmp(ii).seeds = fg.seeds(inds);
        end
        % Copy parameters over. This is probably not necessary
        tmp(ii).seedRadius = fg.seedRadius;
        tmp(ii).seedVoxelOffsets = fg.seedVoxelOffsets;
        tmp(ii).params = fg.params;
    end
    fg = tmp;
    clear tmp;
end


% This should load a variable 'fg', that is a fiberGroup struct.
% We allow for 'fg' to contain multiple fiber groups.
for ii=1:numel(fg)
    if(versionNum<1.0)
        % old-style fibers were transposed
        disp('Converting old-style fibers- please wait...');
        for jj=1:length(fg(ii).fibers)
            fg(ii).fibers{jj} = fg(ii).fibers{jj}';
        end
    end
    fg(ii).visible = 1;

    % New field in FG struct for the DTI query ID. We alway reset it to -1
    % when loading to indicate no associated dtiQuery FG
    fg(ii).query_id = -1;

    if(~strcmpi(coordinateSpace,'acpc'))
        if(~isempty(xformParams) && isfield(xformParams, 'sn'))
            if(~isfield(xformParams,'name'))
                if(strcmpi(coordinateSpace,'MNI'))
                    xformParams(csInd).sn.outMat = eye(4);
                    fg(ii) = dtiXformFiberCoords(fg(ii), xformParams(1).sn);
                    warning('xformParams has no name field (old-style)- assuming MNI space transform.');
                else
                    warning(['xformParams has no name (old)- it''s probably MNI, but the fibers are ' coordinateSpace ', so no transform was applied. Proceed at your own risk!']);
                end
            else
                csInd = strmatch(coordinateSpace, {xformParams.name},'exact');
                if(~isempty(csInd))
                    disp(['Warping fibers from ' coordinateSpace ' space to subject space...']);
                    % We want to xform to MNI space rather than all the way
                    % to the image space, so we set outMat to identity.
                    xformParams(csInd).sn.outMat = eye(4);
                    fg(ii) = dtiXformFiberCoords(fg(ii), xformParams(csInd).sn);
                else
                    warning(['No transform for ' coordinateSpace ' was found, so no transform was applied. Proceed at your own risk!']);
                end
            end
        else
            warning('Fiber coordinate space is not acpc, but there are no spatial norm params- fibers loaded WITHOUT coordinate transform.');
        end
    end
    if(~isempty(xform))
        disp('Applying specified xform to fibers...');
        fg(ii) = dtiXformFiberCoords(fg(ii), xform);
    end
end

return;

function [gLocs2d,gLocs3d,curvature,pathStr] = loadGLocs(hemisphere,pathStr,sampleRate)
%
% [gLocs2d,gLocs3d,curvature,pathStr] = loadGLocs(hemisphere,[pathStr],[sampleRate])
%
% Load gLocs3d and gLocs2d that are computed by mrUnfold.
% Modifies them so that:
% - gLocs2d are integers from (1,1) to (N,M)
% - gLocs3d are in the correct (y,x,z) order
% - both are transposed, gLocs2d is 2xNvoxels and gLocs3d is 3xNvoxels
% Also loads curvature if available in the flat file.
%
% hemisphere: 'right' or 'left'
% pathStr: If not specified, opens dialog box to have user find the file below:
%       /usr/local/mri/anatomy/<subject>/<hemisphere>
% sampleRate: gLocs2d is multiplied by sampleRate before rounding
%    to help avoid overlaps (default: 1).
%
% djh, 8/98
%
% 2.26.99 - Get anatomy path from getAnatomyPath - WAP
% 061899	- Browse with uigetfile - arw
% 8/3/99, djh - don't round gLocs3d nor gLocs2d.  This gets
%               rid of the streaky artifacts.
% 8/4/99, djh - change into correct directory before browsing.
% 8/18/99, djh - modified to return curvature if available.
% 2/5/2001, djh - cleaned this up (major rewrite)
%          wrote getPathStrDialog.m to get the code for that outta this function
%          dumped restOfPath, replaced it with full pathStr

global mrSESSION

if ~exist('sampleRate','var')
    sampleRate = 1;
end

if ~exist('pathStr','var')
    prefixStr = getAnatomyPath;
    if strcmp(hemisphere,'left')
        pathStr = fullfile(prefixStr,'Left');

        % try a few variations on this directory name
        if ~exist(pathStr, 'dir'), pathStr = fullfile(prefixStr, 'left'); end
        if ~exist(pathStr, 'dir'), pathStr = prefixStr; end

    else
        pathStr = fullfile(prefixStr,'Right');

        % try a few variations on this directory name
        if ~exist(pathStr, 'dir'), pathStr = fullfile(prefixStr, 'right'); end
        if ~exist(pathStr, 'dir'), pathStr = prefixStr; end

    end

    pathStr = getPathStrDialog(pathStr,['Select ' hemisphere ' hemisphere flat file'],'*.mat');
end % if ~exist('pathStr')

if check4File(pathStr)
    disp(['loading ',pathStr]);
    load(pathStr);
else
    warning(['File ',pathStr,' does not exist. No flat data loaded']);
end

if exist('gLocs2d','var') & exist('gLocs3d','var')
    % Scale gLocs2d by sampleRate
    gLocs2d = sampleRate*gLocs2d;

    % Subtract min from gLocs2d so they go from (1,1) to (N,M)
    minLocs2d = min(gLocs2d);
    gLocs2d(:,1) = gLocs2d(:,1) - minLocs2d(1) + 1;
    gLocs2d(:,2) = gLocs2d(:,2) - minLocs2d(2) + 1;

    % Transpose 'em so they're 2xN and 3xN.  And convert gLocs3d to
    % be (y,x,z) like everything else in mrLoadRet.
    gLocs2d = gLocs2d';
    gLocs3d = gLocs3d';
    gLocs3d = gLocs3d([2 1 3],:);
else
    gLocs2d = [];
    gLocs3d = [];
end

% make sure curvature is valid.  Otherwise set it to empty matrix.
% At some point 'curvature' became renamed to 'meshCurvature' in
% unfoldMeshFromGUI. This caused problems in flat map rendering. We
% correct for that here - can read both old and new-style flat
% files ARW 111107

if (exist('meshCurvature','var'))
    disp('Using meshCurvature field for curvature');
    curvature=meshCurvature;
end

if ~exist('curvature','var')
    curvature = [];
elseif isempty(find(curvature))
    curvature = [];
else
    curvature = curvature';
end

return;

% debug

global mrSESSION
mrSESSION.subject = 'djh';
[gLocs2d,gLocs3d,curvature,pathStr] = loadGLocs('right');

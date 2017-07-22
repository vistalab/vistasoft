function vw = buildGrayCoords(vw, coordsPth, keepAll, classPth, numGrayLayers)
% vw = buildGrayCoords(vw, [coordsPth='Gray/coords.mat'], [keepAll=0], [classPth], [numGrayLayers]):
%
% Build a coords.mat file for a gray view. This was split
% off from getGrayCoords when I found the design was getting
% unwieldy -- even when a coords file had been built, there were
% still frequent checks on external files, and I was asked to
% rebuild this nearly every time. I consolidated all of the looking
% for external files into this function -- anything required for
% a gray view that's not already contained in a session directory
% should be loaded up here, and saved to coords.mat. This should
% happen a maximum of once per session/segmentation.
%
% INPUTS:
%	vw: gray or volume view [default: initialize a hidden volume view,
%	which gets converted to gray as the coords are built.]
%
%	coordsPth: path to the coords file to save. [default: Gray/coords.mat']
%
%	keepAll: flag to keep all gray matter nodes, rather than just the
%	intersection with the inplane data. [default: 0, don't do this.]
%	The advantage to keeping all nodes is that you can bring in data from
%	other sessions, and do analyses involving the whole gray matter graph.
%	The disadvantage is it can take more disk space / memory, and you can't
%	map back from the volume to the inplane (though this should be
%	fixable?)
%
%	classPth: optional argument to specify which class file to use
%   
%
% ras 08/04.
% ras 06/09: allows user to provide the file paths externally, rather than
% being prompted.
global HOMEDIR

if notDefined('keepAll'),	keepAll=0;			end
if notDefined('classPth'),	classPth = {};		end
if notDefined('vw'),
    % convert from a volume view.
    vw = initHiddenVolume;
    vw = viewSet(vw, 'viewType','Gray');
    vw = viewSet(vw, 'subdir', 'Gray');
end
if notDefined('coordsPth')
    coordsPth = fullfile(HOMEDIR, 'Gray', 'coords.mat');
end

if ~isfield(vw,'leftPath'),  vw = viewSet(vw,'leftpath','(none assigned)');    end
if ~isfield(vw,'rightPath'), vw = viewSet(vw,'rightPath','(none assigned)');   end

% if external file paths are provided, attach them to the view, so that
% they'll be the default files accessed when building the
if isempty(classPth)
    startDir = getAnatomyPath();
    filterspec = {'*.nii.gz;*.nii', 'NIFTI class file'; '*.*', 'All files'};
    classPth = getPathStrDialog(startDir, 'Select class file', filterspec);    
end

if iscell(classPth), classPth = classPth{1}; end

% Check class type. Should be nifti.
classType = mrGrayCheckClassType(classPth);

% Since we moved to NIFTI, left and right class files are the same
leftClassFile   = classPth;
rightClassFile  = classPth;
vw.leftPath     = classPth;
vw.rightPath    = classPth;


%% load the gray coords from the class/gray files
% Load the gray nodes and edges
[allLeftNodes,  allLeftEdges,  leftPath]  = loadGrayNodes('left', classPth, numGrayLayers);
[allRightNodes, allRightEdges, rightPath] = loadGrayNodes('right',leftPath, numGrayLayers);

% Load the inplane coords (loaded temporarily into vw.coords)
vw = getVolCoords(vw);
ipCoords = viewGet(vw, 'coords');

% Here, we have the option to include all the nodes in the gray view.
% However, we can't map back to the inplane any more.
if keepAll
    disp(['Warning: You are keeping all the gray nodes ' ...
        '(not computing an intersection with the inplane). ' ...
        'This can be useful in some circumstances. But it  ' ...
        'also means that you can never map things back to ' ...
        'the INPLANE view']);
    
    leftNodes = allLeftNodes;
    leftEdges = allLeftEdges;
    if ~isempty(allLeftNodes)
        leftCoords = uint16(allLeftNodes([2 1 3],:));
    else
        leftCoords = [];
    end
    keepLeft = 1:length(leftNodes); %#ok<*NASGU>
    
    rightNodes = allRightNodes;
    rightEdges = allRightEdges;
    if ~isempty(allRightNodes)
        rightCoords = uint16(allRightNodes([2 1 3],:));
    else
        rightCoords = [];
    end
    keepRight = 1:length(rightNodes);
else
    
    waitHandle = mrvWaitbar(0,'Computing gray coordinates.  Please wait...');
    if ~isempty(allLeftNodes)
        % Find gray nodes that are in the inplanes. Note: nodes are
        % (x,y,z) not (y,x,z), unlike everything else in mrLoadRet.
        [leftCoords,~,keepLeft] = intersectCols(uint16(ipCoords),uint16(allLeftNodes([2 1 3],:)));
        
        % Keep nodes that intersect with the inplanes
        [leftNodes,leftEdges,nLeftNotReached] = keepNodes(allLeftNodes,allLeftEdges,double(keepLeft));
    else
        leftNodes=[];
        leftEdges=[];
        leftCoords=[];
        keepLeft = [];
    end
    
    % Repeat for right hemisphere
    mrvWaitbar(1/2)
    if ~isempty(allRightNodes)
        [rightCoords, ~, keepRight] = ...
            intersectCols(uint16(ipCoords), uint16(allRightNodes([2 1 3],:)));
        [rightNodes, rightEdges, nRightNotReached] = ...
            keepNodes(allRightNodes, allRightEdges, keepRight);
    else
        rightNodes=[];
        rightEdges=[];
        rightCoords=[];
        keepRight = [];
    end
    close(waitHandle);
end % End check on whether we intersect with inplane


% Concatenate coords from the two hemispheres
coords = [double(leftCoords) double(rightCoords)];

% Concantenate the left and right gray graphs
if ~isempty(rightNodes)
    rightNodes(5,:) = rightNodes(5,:) + length(leftEdges);
    rightEdges = rightEdges + size(leftNodes,2);
end

nodes = [leftNodes rightNodes];
edges = [leftEdges rightEdges];

% make path local, if HOMEDIR is contained within it
% (this happens if, for instance, the vAnat directory is
% linked to from the session directory):
if strfind(leftPath,HOMEDIR);
    leftPath = leftPath(length(HOMEDIR)+2:end); % +2 b/c of filesep
    leftPath(leftPath=='\') = '/';  % \ win filesep -> / generic filesep
end

rightPath = leftPath; leftClassFile = leftPath; rightClassFile = leftPath;

% Verify save path exists - if not, make it
if ~exist(fileparts(coordsPth), 'dir'), mkdir(fileparts(coordsPth)); end

% Save to coords file
save(coordsPth,'coords','nodes','edges',...
    'allLeftNodes','allLeftEdges','allRightNodes','allRightEdges',...
    'leftPath','rightPath','keepLeft','keepRight');

if exist('leftClassFile','var'), save(coordsPth,'leftClassFile','-append'); end
if exist('rightClassFile','var'),save(coordsPth,'rightClassFile','-append');end

fprintf('Saved gray coords info to %s. \n',coordsPth);

return

function view = buildGrayCoords(view, pathStr, keepAll, filePaths, numGrayLayers)
% view = buildGrayCoords(view, [pathStr='Gray/coords.mat'], [keepAll=0], [filePaths], [numGrayLayers]):
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
%	view: gray or volume view [default: initialize a hidden volume view,
%	which gets converted to gray as the coords are built.]
%
%	pathStr: path to the coords file to save. [default: Gray/coords.mat']
%
%	keepAll: flag to keep all gray matter nodes, rather than just the
%	intersection with the inplane data. [default: 0, don't do this.]
%	The advantage to keeping all nodes is that you can bring in data from
%	other sessions, and do analyses involving the whole gray matter graph.
%	The disadvantage is it can take more disk space / memory, and you can't
%	map back from the volume to the inplane (though this should be
%	fixable?)
%
%	filePaths: optional argument to specify which .class and .gray paths to
%	use. Should be a 1 x 4 cell array, with the paths provided in the
%	following order:
%		* filePaths{1} is the path to the left .class (or NIFTI
%		classification) file.
%		* filePaths{2} is the path to the right .class (or NIFTI
%		classification) file.
%		* filePaths{3} is the path to the left .gray graph file. If using
%		NIFTI files, this should be the same as filePaths{1}.
%		* filePaths{4} is the path to the right .gray graph file. If using
%		NIFTI files, this should be the same as filePaths{2}.
%		For NIFTI paths, you can omit the last two entries.
%
%       * If only 1 path is provided (filePaths{1}), it is duplicated for
%       the right .class to simplify the case of identical L/R .class
%       files. - rfb 08/16/10
%
%
% ras 08/04.
% ras 06/09: allows user to provide the file paths externally, rather than
% being prompted.
if notDefined('keepAll'),	keepAll=0;			end
if notDefined('filePaths'),	filePaths = {};		end
if notDefined('view'),	 
	% convert from a volume view.
	view = initHiddenVolume; 
	view.viewType = 'Gray';
	view.subdir = 'Gray';
end
if notDefined('pathStr')
	global HOMEDIR
	pathStr = fullfile(HOMEDIR, 'Gray', 'coords.mat');
end

global mrSESSION
if (~isfield(view,'leftPath')), view = viewSet(view,'leftpath','(none assigned)');     end
if (~isfield(view,'rightPath')), view = viewSet(view,'rightPath','(none assigned)');   end
leftClassFile = '';
rightClassFile = '';

% if external file paths are provided, attach them to the view, so that
% they'll be the default files accessed when building the 
if ~isempty(filePaths)
	% for NIFTI files, we may just get left and right NIFTI files. This is
	% fine. The 'gray' path slots point to the same files, and the gray
	% graph is grown dynamically from the NIFTI file.
    
    % Added this just to simplify inputs, why put in identical strings?
    if length(filePaths)==1, filePaths{2} = filePaths{1}; end
    
    if length(filePaths)==2 || isempty(filePaths{3}) || ...
            isempty(filePaths{4})
        filePaths{3} = filePaths{1};
        filePaths{4} = filePaths{2};
    end
	
	leftClassFile = filePaths{1};
	rightClassFile = filePaths{2};
	view.leftPath = filePaths{3};
	view.rightPath = filePaths{4};
end

%% load the gray coords from the class/gray files
% Load the gray nodes and edges
if exist(view.leftPath,'file')
	[allLeftNodes allLeftEdges leftPath] = ...
        loadGrayNodes('left', view.leftPath, numGrayLayers);
else
	[allLeftNodes allLeftEdges leftPath] = loadGrayNodes('left');
end

% This might be a class file rather than gray nodes file.
classType = mrGrayCheckClassType(leftPath);

if(classType=='n')
	% The new NIFTI file contains both left and right, so we don't have to
	% ask.
	[allRightNodes allRightEdges rightPath] = ...
            loadGrayNodes('right', leftPath, numGrayLayers);
	leftClassFile = leftPath;
	rightClassFile = leftPath;
else
	% for the older .class files, we mark both the path to the gray nodes
	% and the .class file, and load the right nodes separately.
	if(classType=='c')
		leftClassFile = leftPath;
	end
	if exist(view.rightPath, 'file')
		[allRightNodes allRightEdges rightPath] = ...
			loadGrayNodes('right', view.rightPath);
	else
		[allRightNodes allRightEdges rightPath] = loadGrayNodes('right');
	end
	classType = mrGrayCheckClassType(rightPath);
	if(classType=='c'||classType=='n')
		rightClassFile = rightPath;
	end
end

if(isempty(leftClassFile))
	% get left/right class files, too, if they're there:
	% it wasn't clear to me where this got specified in the
	% earlier code:
	startDir = fullfile(getAnatomyPath(mrSESSION.subject), 'Left');
	
	% if 'Left' dir does not exist go back to top dir
	if ~exist(startDir,'dir'), startDir = getAnatomyPath(mrSESSION.subject);end;
	ttltxt = 'Select left hemisphere class file (cancel if none)...';
	leftClassFile = getPathStrDialog(startDir, ttltxt, '*.?lass');
end

if(isempty(rightClassFile))
	startDir = fullfile(getAnatomyPath(mrSESSION.subject), 'Right');
	
	% if 'Right' dir does not exist go back to top dir
	if ~exist(startDir,'dir'), startDir = getAnatomyPath(mrSESSION.subject);end;
	ttltxt = 'Select right hemisphere class file (cancel if none)...';
	rightClassFile = getPathStrDialog(startDir, ttltxt, '*.?lass');
end

% Load the inplane coords (loaded temporarily into view.coords)
view = getVolCoords(view);
ipCoords = view.coords;

% Here, we have the option to include all the nodes in the gray view.
% However, we can't map back to the inplane any more.
if (keepAll) 
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
	keepLeft = [1:length(leftNodes)];

	rightNodes = allRightNodes;
	rightEdges = allRightEdges;
	if ~isempty(allRightNodes)
		rightCoords = uint16(allRightNodes([2 1 3],:));
	else
		rightCoords = [];
	end
	keepRight = [1:length(rightNodes)];
else

	waitHandle = waitbar(0,'Computing gray coordinates.  Please wait...');
	if ~isempty(allLeftNodes)
		% Find gray nodes that are in the inplanes. Note: nodes are
		% (x,y,z) not (y,x,z), unlike everything else in mrLoadRet.
		[leftCoords,ipIndices,keepLeft] = intersectCols(uint16(ipCoords),uint16(allLeftNodes([2 1 3],:)));

		% Keep nodes that intersect with the inplanes
		[leftNodes,leftEdges,nLeftNotReached] = keepNodes(allLeftNodes,allLeftEdges,double(keepLeft));
	else
		leftNodes=[];
		leftEdges=[];
		leftCoords=[];
		keepLeft = [];
	end

	% Repeat for right hemisphere
	waitbar(1/2)
	if ~isempty(allRightNodes)
		[rightCoords ipIndices keepRight] = ...
			intersectCols(uint16(ipCoords), uint16(allRightNodes([2 1 3],:)));
		[rightNodes rightEdges nRightNotReached] = ...
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
global HOMEDIR
if findstr(leftPath,HOMEDIR);
	leftPath = leftPath(length(HOMEDIR)+2:end); % +2 b/c of filesep
	leftPath(leftPath=='\') = '/';  % \ win filesep -> / generic filesep
end
if findstr(rightPath,HOMEDIR);
	rightPath = rightPath(length(HOMEDIR)+2:end);
	rightPath(rightPath=='\') = '/';  % \ win filesep -> / generic filesep
end

% make path local, if HOMEDIR is contained within it
if findstr(leftClassFile,HOMEDIR);
	leftClassFile = leftClassFile(length(HOMEDIR)+2:end); % +2 b/c of filesep
	leftClassFile(leftClassFile=='\') = '/';  % \ win filesep -> / generic filesep
end
if findstr(rightClassFile,HOMEDIR);
	rightClassFile = rightClassFile(length(HOMEDIR)+2:end);
	rightClassFile(rightClassFile=='\') = '/';  % \ win filesep -> / generic filesep
end

% Verify save path exists - if not, make it
if (~exist(fileparts(pathStr), 'dir')), mkdir(fileparts(pathStr)); end

% Save to coords file
save(pathStr,'coords','nodes','edges',...
	'allLeftNodes','allLeftEdges','allRightNodes','allRightEdges',...
	'leftPath','rightPath','keepLeft','keepRight');

if exist('leftClassFile','var')
	save(pathStr,'leftClassFile','-append');
end

if exist('rightClassFile','var')
	save(pathStr,'rightClassFile','-append');
end

fprintf('Saved gray coords info to %s. \n',pathStr);

return

function vw = getGrayCoords(vw, forceRebuild, keepAll)
%Get gray graph coordinates
%
% vw = getGrayCoords(vw, <forceRebuild, keepAll>);
%
% vw: must be VOLUME
%
% Loads gray nodes.  Keeps only those nodes that coorespond to
% the inplane coordinates unless keepAll is set.
%
% First time this is run on a dataset, it saves many variables, including
% coords, rightNodes, leftNodes, rightEdges, & leftEdges and path information in
% Gray/coords.mat.
%
% When it load nodes and edges, it concatenates from left
% and right hemispheres and fills the vw.coords, vw.nodes, 
% and vw.edges fields. 
%
% How do these correspond to Sag/Axi/Cor? (BW)
%
% coords are [y x z] like everything else in mrLoadRet
% nodes are [x y z] like mrGray, except that values run from 1 to N 
% instead of 0 to N-1. (where y = axial or sup -> inf, x = coronal or 
% ant -> pos, and z = sagittal running from left -> right. This is 
% _not_ the same as radiological X, Y, Z.)
%
% djh, 7/98
% 08.17.00 Added a notice on null nodes.  We should
%          make it possible to do something OK here.
% djh, 2/5/2001 
%   Allows you to load only one hemisphere if both are not yet segmented.
%   leftPath and rightPath are now the full paths (used to be restofpath)
% djh, 2/15/2001
% - Save allLeftNodes/Edges (likewise right) in coords file and sets vw.allLeftNodes, etc.
%   in the gray structure upon loading the coords file. You should never go back to reload
%   the gray graph (via loadGrayNodes or readGrayGraph). All the information you need is here.
%   Consequently, leftPath & rightPath are now just for bookkeeping purposes.  
% ARW 02/11/2003
% - Save inplaneLeftIndices (and inplaneRightIndices). These are 
% indices into the allLeftNodes, allRightNodes arrays telling you which
% ones contain inplane data.
% ras 08/04: broke off a separate function that builds coords.mat. This
% file just loads it and sets the view. If coords.mat exists, no other
% file should need to be accessed.
% Allows you to keep all the gray nodes. Useful for some purposes if you
% don't want to reference back to the inplanes.
% 2005.08.09 RFD: fixed namespace confusion bug that I was getting on
% linux by loading the coords file vars into a struct rather than blindly
% loading them into the local namespace.
% 2007.03.22 RAS: trying to set all fields to single; setting a preference
% to _not _ load inplaneLeftIndices, inplaneRightIndices, allLeft*,
% allRight* -- this stuff can be computed on the fly readily

if notDefined('vw'),          vw = getSelectedGray;      end
if notDefined('forceRebuild'),  forceRebuild=0;              end
if notDefined('keepAll'),       keepAll=0;                   end


if ~strcmp(vw.viewType,'Gray')
    myErrorDlg('function getGrayCoords only for gray view.');
end

mrGlobals;
% vANATOMYPATH = getVAnatomyPath; % find this refresh is empirically needed

pathStr = fullfile(viewDir(vw), 'coords.mat');
fprintf('Path to gray coordinates: %s\n',pathStr);

% Can we find the coords file? Or have we been asked to rebuild?
if ~exist(pathStr,'file') || forceRebuild==1
    % Have we been asked to rebuild?
    if(forceRebuild), disp('Rebuild of gray structures requested'); end
    
    if notDefined('numGrayLayers')
        a = inputdlg('Number of gray layers:','Gray Layers',1,{'5'});
        numGrayLayers = str2double(a{1});
    end

    vw = buildGrayCoords(vw,pathStr,keepAll,[],numGrayLayers);
end

% load the info from coords
% 2005.08.09 RFD: loading the vars into a struct is much safer than simply
% doing 'load', since it eliminates namespace confusion that can arise if a
% var has the same name as a function.
c = load(pathStr);

extended = prefsExtendedGrayCheck;

if extended && (isfield(c, 'keepLeft') && isfield(c,'keepRight'))
    % These are the indices of nodes that overlap with the inplane data.
	% (ras -- do we need to keep these? They take up a huge amount of
	% memory.
    vw.inplaneLeftIndices = c.keepLeft; 
    vw.inplaneRightIndices = c.keepRight;
end

% set all the relevant fields
% (some fields may not exist in coords.mat if the
% segmentation is older. So you may wish to add
% checks for these variables. Personally, I prefer
% all gray views be the same):

% ras 05/06: for now, trying not to set right/left nodes/edges. 
% This will prevent me from building new meshes, I think, but it's
% a lot of duplicated memory...
vw = viewSet(vw, 'coords', c.coords);
vw = viewSet(vw, 'nodes', c.nodes);
vw = viewSet(vw, 'edges', c.edges);

vw = viewSet(vw, 'leftGrayFile', c.leftPath);
vw = viewSet(vw, 'rightGrayFile', c.rightPath);

if extended
	vw = viewSet(vw, 'allLeftNodes',  c.allLeftNodes);
	vw = viewSet(vw, 'allLeftEdges',  c.allLeftEdges);
	vw = viewSet(vw, 'allRightNodes',  c.allRightNodes);
	vw = viewSet(vw, 'allRightEdges',  c.allRightEdges);
else
	vw = viewSet(vw, 'allLeftNodes',  []);
	vw = viewSet(vw, 'allLeftEdges',  []);
	vw = viewSet(vw, 'allRightNodes',  []);
	vw = viewSet(vw, 'allRightEdges',  []);	
end
vw = viewSet(vw, 'leftPath', c.leftPath);
vw = viewSet(vw, 'rightPath', c.rightPath);

% This is a new variable and may not exist in the file for many data sets.
% So, we test to see whether it exists.
if isfield(c, 'leftClassFile') % & exist(leftClassFile,'file')
    vw = viewSet(vw,'leftClassFile', c.leftClassFile); 
end
if isfield(c, 'rightClassFile') %  & exist(rightClassFile,'file') 
    vw = viewSet(vw,'rightClassFile', c.rightClassFile); 
end    

return

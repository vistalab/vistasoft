function ROI = grayLineROI(nodes, edges, startPoint, endPoint, mmPerVox, mask);
% Create a line ROI representing the shortest path ("geodesic") between two
% gray nodes. Requires mrManDist.
%
%    ROI = grayLineROI([nodes, edges], startPoint, endPoint, [mmPerVox=1,1,1], [mask]);
%
% This function simply adapts some test code provided into the comments 
% for mrManDist, to create a separate function to find the geodesic.
%
% Returns a mrVista-format ROI. (See roiCreate1 for format.)
%
% INPUTS:
% nodes, edges: gray nodes and edges from a gray graph. You can also
% provide a path to a NIFTI classification file or mrGray gray graph as the
% nodes argument, and it will load/grow them from the file. [default:
% prompt for a file.]
%
% startPoint: node index or 3x1 [x y z] volume coords of the start point for 
% the line ROI.
%
% endPoint: node index or 3x1 [x y z] volume coords of the end point for 
% the line ROI.
%
% mask: optional [1 x N] mask vector, where N is the number of nodes. Will
% only look for the geodesic along nodes where the mask is 1 (true).
%
% OUTPUTS:
% 
% ROI: mrVista-format ROI containing the line coordinates.
%
% NOTE: There is an error on some versions of MATLAB (such as 2007a,b on
% Windows) where mrManDist returns an invalid set of distances -- it
% doesn't error, but also doesn't measure distances. If that's the case,
% this function will not work.
%
%
% ras, 07/2009. I implemented this separate from the mrVista views, so it
% will hopefully be more portable in the future.
if notDefined('nodes') & notDefined('edges')
	[pth ok] = mrvSelectFile('r', {'gray' 'Gray' 'nii' 'nii.gz'}, ...
					    'Select a gray graph or NIFTI file');
	if ~ok, disp('Aborted.'); return; end
	[p f ext] = fileparts(pth);
	if strncmp( lower(ext), '.gray', 5 )
		[nodes edges] = readGrayGraph(pth);
	elseif strncmp( lower(ext), 'nii', 4 );
		%% TODO: support NIFTI
	else
		error('Invalid file type %s.', pth);
	end
end

if notDefined('startPoint') | notDefined('endPoint')
	error('Need start and end points.')
end

if notDefined('mmPerVox'),	mmPerVox = [1 1 1];		end

%% TODO: parse 3x1 start/end point specifications into nodes
if length(startPoint)==3
	startPoint = nearestGrayNode(nodes, startPoint);
end

if length(endPoint)==3
	endPoint = nearestGrayNode(nodes, endPoint);	
end
	
%% core part of code: get geodisc using mrManDist.
% find distances from start point, and connected list of points from start
% point.
[dist npts lastPoint] = mrManDist( double(nodes), double(edges), ...
								   startPoint, mmPerVox, -1, 0 );
							   
% track back along the 'lastPoint' list, from the start point to the end
% point, to construct the geodesic:
geodesic = [];
nextPoint = endPoint;
while nextPoint ~= startPoint
	geodesic(end+1) = lastPoint(nextPoint);
	nextPoint = lastPoint(nextPoint);
end


%% create line ROI from geodesic.
ROI = roiCreate1;
ROI.name = sprintf('Line ROI %s %s', num2str(startPoint), num2str(endPoint));
ROI.color = [1 1 0];
ROI.coords = nodes([2 1 3],geodesic);
ROI.comments = [sprintf('Created by %s %s.\n', mfilename, datestr(now)) ...
				sprintf('Start point: %s', num2str(startPoint)) ...
				sprintf('End point: %s', num2str(endPoint))];

return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function node = nearestGrayNode(nodes, pt);
% find the index of the gray node nearest the point at 3x1 coordinate pt.
% we assume here the point is specified using mrVista conventions: [axi cor
% sag].

%% first, check if the point is in the nodes list.
% the mrVista coordinate specification is [axi cor sag], while the
% convention for the gray nodes is [cor axi sag]. Hence the flip.
node = find( nodes(2,:)==pt(1) & nodes(1,:)==pt(2) & nodes(3,:)==pt(3) );

%% if the node is found, we're done. Otherwise, find the nearest gray node.
if isempty(node)
	if prefsVerboseCheck >= 1
		fprintf('[%s]: looking for nearest gray node to %s...', ...
				mfilename, num2str(pt));		
	end
	
% 	% this doesn't seem to work...
% 	[node bestSqDist] = nearpoints(double(pt), nodes([2 1 3],:));

	% use the algorithm I use in segGet to find the nearest node
	tolerance = 5; % mm
	dist = sqrt( [nodes(2,:) - pt(1)] .^ 2 + ...
		[nodes(1,:) - pt(2)] .^ 2 + ...
		[nodes(3,:) - pt(3)] .^ 2 );
	if min(dist) > tolerance
		warning(sprintf('[%s]: no node found within tolerance [%i mm]', ...
			mfilename, tolerance));
		varargout{1} = [];
	else
		I = find(dist==min(dist));
		node = I(1);
	end

	if prefsVerboseCheck >= 1
		fprintf('done. Best distance: %.1f.\n', min(dist));
	end
end

return
		
function roiVertInds = adjustPerimeter(roiVertInds, perimThickness, vw, prefs)
%
% roiVertInds = adjustPerimeter(roiVertInds, perimThickness, vw, prefs)
%
% Sometimes we want to dilate the mesh ROIs a bit. The following does this
% by finding all the neighboring vertices for all the ROI vertices (now
% stored in roiVertInds). The sparse connection matrix comes in handy
% once again, making this a very fast operation.
%
% jw: March, 2010: split off from meshDrawROIs.m
%

if ~exist('prefs', 'var'),  
    % this takes a LONG time!
    prefs = mrmPreferences; 
end


roiDilateIterations = prefs.roiDilateIterations;


% We need the connection matrix 
msh = viewGet(vw,'currentmesh');
conMat = meshGet(msh,'connectionmatrix');
if isempty(conMat)
    msh = meshSet(msh,'connectionmatrix',1);
    conMat = meshGet(msh,'connectionmatrix');
end

if(perimThickness)
	% Draw a perimeter only
	origROI = roiVertInds;
	for  t = 1:perimThickness
		neighbors = conMat(:,roiVertInds);
		[roiVertInds, junk] = find([neighbors]);
		roiVertInds = unique(roiVertInds);
	end
	
	% Subtract the original from the dilated version.
	roiVertInds = setdiff(roiVertInds, origROI);
	
else
	% Fill in the ROIs:
	% We can dilate the area if we are not also rendering the perimeter...
	for t = 1:roiDilateIterations
		neighbors = conMat(:,roiVertInds);
		[roiVertInds, junk] = find(neighbors);
		roiVertInds = unique(roiVertInds);
	end
	
end

return
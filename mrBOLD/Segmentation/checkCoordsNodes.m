function checkCoordsNodes(flat)
%
%AUTHOR:  Wandell & Huk
%DATE:    12.01.00
%PURPOSE:
%   We verify that the gray matter nodes in the segmentation
% is consistent with the coords and nodes in the mrLoadRet
% directories.
%
% The nodes in Gray/coords are leftNodes and rightNodes.  These
% are supposed to be a subset of the nodes in the segmentation
% at leftPath and rightPath.  So, we load the two sets and we
% make sure that every one of the leftNodes is inside the set of
% nodes read from the segmentation.  Then we do it again for the
% right.
%
% bw, 01/12/01  Updated Flat coords reading so that it checks
%   the proper Flat sub-directory.
% djh, 2/5/2001 
%    Use fullfile instead of hardcoded 'load Gray/coords'
%    Added check to compare mrLoadRet's gray nodes with the full set of gray nodes

mrGlobals

% open hiddenGray to get the relevant info
gray = getSelectedGray;
if isempty(gray)
    gray = initHiddenGray;
end
if isempty(flat)
    flat = initHiddenFlat;
end

% yank out relevant rows and reorder them as necessary
grayNodes = gray.nodes(1:3,:);
if ~isempty(gray.allLeftNodes)
    grayAllLeftNodes = gray.allLeftNodes(1:3,:);
else
    grayAllLeftNodes = [];
end
if ~isempty(gray.allRightNodes)
    grayAllRightNodes = gray.allRightNodes(1:3,:);
else
    grayAllRightNodes = [];
end
if ~isempty(flat.grayCoords{1})
    flatLeftGrayCoords = flat.grayCoords{1}([2 1 3],:);
else
    flatLeftGrayCoords = [];
end
if ~isempty(flat.grayCoords{2})
    flatRightGrayCoords = flat.grayCoords{2}([2 1 3],:);
else
    flatRightGrayCoords = [];
end

% check that gray.nodes are a subset of the full set of gray nodes
if isempty(gray.nodes)
    disp('Empty gray.nodes.');
else
    [cLeft,iaLeft,ibLeft] = intersectCols(grayNodes,grayAllLeftNodes);
    [cRight,iaRight,ibRight] = intersectCols(grayNodes,grayAllRightNodes);
    numDifference = size(grayNodes,2) - (size(cLeft,2)+size(cRight,2));
    if numDifference~=0
        disp('Gray.nodes are NOT all contained in the segmentation.');
        disp(['Number missing:  ',num2str(numDifference)]);
        mismatch(gray,flat);
    else
        disp('Gray.nodes are all contained in the segmentation.');
    end
end

% check that flat.grayCoords are contained in the gray.nodes
if isempty(flat.grayCoords)
    disp('Empty flat.grayCoords.');
else
    [cLeft,iaLeft,ibLeft] = intersectCols(flatLeftGrayCoords,grayNodes);
    [cRight,iaRight,ibRight] = intersectCols(flatRightGrayCoords,grayNodes);
    numDifference = (size(flatLeftGrayCoords,2) - size(cLeft,2)) + ...
                    (size(flatRightGrayCoords,2) - size(cRight,2));
    if numDifference~=0
        disp('Flat.grayCoords are NOT all contained in the gray.nodes');
        disp(['Number missing: ',num2str(numDifference)]);
        mismatch(gray,flat);
    else
        disp('Flat.grayCoords are all contained in the gray.nodes');   
    end
end

% check that flat nodes are contained in segmentation
if isempty(flat.grayCoords)
    disp('Empty flat.grayCoords.');
else
    [cLeft,iaLeft,ibLeft] = intersectCols(flatLeftGrayCoords,grayAllLeftNodes);
    [cRight,iaRight,ibRight] = intersectCols(flatRightGrayCoords,grayAllRightNodes);
    numDifference = (size(flatLeftGrayCoords,2) - size(cLeft,2)) + ...
                    (size(flatRightGrayCoords,2) - size(cRight,2));
    if numDifference~=0
        disp('flat.grayCoords are NOT all contained in the segmentation.');
        disp(['Number missing:  ',num2str(numDifference)]);
        mismatch(gray,flat);
    else
        disp('flat.grayCoords are all contained in the segmentation.');
    end
end

msgbox([viewDir(flat),' and ',viewDir(gray),' are OK.'],'Verify Gray-Flat match');

return;

function mismatch(gray,flat)
myErrorDlg(['Mismatch detected between ',viewDir(flat),' and ',viewDir(gray),...
        '. Run Install Segmentation and/or Install Unfold from Xform menu.']);
return;

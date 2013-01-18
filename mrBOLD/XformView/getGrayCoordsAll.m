function view = getGrayCoords(view)
%
% view = getGrayCorods(view)
%
% Attempt to see if we could keep all the gray coords for the
% entire segmentation. This has the advantage that it would
% make it easy to combine data in the gray across sessions.
% 
% Problem is that the gray tSeries files 
% become unwieldy. If/when there's enough RAM & disc space,
% would need to make the folowing additional changes:
% - grep for allLeftNodes & allRightNodes and replace them with nodes
% - ???
%
% djh, 2/2001

if ~strcmp(view.viewType,'Gray')
   myErrorDlg('function getGrayCoords only for gray view.');
end

pathStr=fullfile(viewDir(view),'coords');

if ~check4File(pathStr)
   
   % Load the gray nodes and edges
   [leftNodes,leftEdges,leftPath] = loadGrayNodes('left');
   [rightNodes,rightEdges,rightPath] = loadGrayNodes('right');
      
   % Concantenate the left and right gray graphs
   if ~isempty(rightNodes)
       rightNodes(5,:) = rightNodes(5,:) + length(leftEdges);
       rightEdges = rightEdges + size(leftNodes,2);
   end  
   nodes = [leftNodes rightNodes];
   edges = [leftEdges rightEdges];
   
   % Concatenate coords from the two hemispheres
   % Note: nodes are (x,y,z) not (y,x,z), unlike everything else in mrLoadRet.
   coords = nodes([2 1 3],:);
   
   % Save to file
   save(pathStr,'coords','nodes','edges',...
       'leftPath','rightPath');
end

% Load it
load(pathStr);

% Fill the fields
view.coords = coords;
view.leftPath = leftPath;
view.rightPath = rightPath;
view.nodes = nodes;
view.edges = edges;

return;


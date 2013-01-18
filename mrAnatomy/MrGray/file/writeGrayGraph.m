function writeGrayGraph(filename,nodes, edges, vSize)
% 
%    writeGrayGraph(filename, nodes, edges, vSize)
% 
% AUTHOR:  Maher Khoury
% DATE:    08/20/1999
% PURPOSE:
%    Use mrLoadRet nodes and edges to write a gray matter file to be read by mrGray
% 
% ARGUMENT:
%  filename - name of gray graph file to be read by mrGra
% 	nodes		- 8xN array of Nx(x,y,z,num_edges,edge_offset,layer,dist,pqindex).
% 	edges		- 1xM array of node indices.  The edge_offset of
%    			  each node points into the starting location of its set
%    			  of edges. where N, M are the number of nodes, edges in the graph.
%	vSize		- Size of the original volume of data containing the anatomicals
%
% BW:  12.1.00
%   Various changes.
%     mrGnodes distinguished from mrLnodes 
%     mrGedges distinguished from mrLedges
%     mrGnodes was written out with only 6 rows, when 8 is the usual size of nodes
%
% 2008.02.04 RFD: made it write the proper file, such that writing
% a file and then reading it with readGraygray will produce the
% same result. I haven't tested it with mrGray, though.

% mrGray on all machines writes out using ieee big endian
% format.  So, we must always open our files that way.
% 
fid = fopen(filename,'w','b');

% Write header.

% [xsize, ysize, zsize]; [cols, rows, planes].
sizes = [vSize(2), vSize(1), vSize(3)];

% Write out xsize, ysize, zsize.
fwrite(fid, sizes, 'int');
clear sizes;

% Write out number of nodes and edges.
sizes(1) = size(nodes,2);
sizes(2) = size(edges,2);
fwrite(fid, sizes, 'int');

mrGnodes = nodes(1:6,:);
% C / Matlab offset issue
mrGnodes(1:3,:) = mrGnodes(1:3,:) - 1;
mrGnodes(5,:) = mrGnodes(5,:) - 1;

% Write nodes.
fwrite(fid, mrGnodes, 'int');

mrGedges = edges - 1;

% Write edges.
fwrite(fid, mrGedges, 'int');


fclose(fid);

return;

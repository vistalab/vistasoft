function [nodes, edges, vSize] = readGrayGraph(filename,hemi)
% Read a gray graph written out by mrGray
%
%    [nodes, edges, vSize] = readGrayGraph(filename,[hemisphere='l'])
% 
% AUTHOR:  Teo
% DATE:    1996
% ARGUMENT:
%   name of gray graph file written by mrGray
% 
% RETURNS:
% nodes:  8xN array of 
%    Nx(x,y,z,num_edges,edge_offset,layer,dist,pqindex).
% edges:  1xM array of node indices.  The edge_offset of
%    each node points into the starting location of its set
%    of edges.
% where N, M are the number of nodes, edges in the graph.
% vSize = size of the original volume of data containing the anatomicals
%
% Modified 8.20.98  WP/BW
%   Added the big-endian flag and the check for existence step.
% This was done for compatibility with the PCs that normally read
% in using little-endian.
% 
% DJH, 8/4/99
%   Add 1 to coordinates because MATLAB starts indexing from 1 instead
% of 0.  This fixes a mis-registration problem in mrLoadRet in the Gray
% view.  The only effect that this has on mrUnfold is that the gLocs3d
% are now incremented by one.
% TODO: Return a timestamp that is saved in the .gray file. This will be
%       used to maintain consistency between gray and flat maps. 

warning('Obsolete. Vistasoft uses nifti class files, not mrGray');

if ~exist(filename,'file')
  errordlg(sprintf('Can not find file %s\n',filename));
  % error(str);
end

[p f e] =  fileparts(filename);
if(strcmpi(f, 'coords') || strcmpi(e,'.mat'))
    % Load nodes/edges from a coords file
    if(~exist('hemi','var')||isempty(hemi))
        hemi = 'l';
    end
    tmp = load(filename);
    if(lower(hemi(1))=='l')
        nodes = tmp.allLeftNodes;
        edges = tmp.allLeftEdges;
        classFileName = tmp.leftClassFile;
    elseif(lower(hemi(1))=='r')
        nodes = tmp.allRightNodes;
        edges = tmp.allRightEdges;
        classFileName = tmp.rightClassFile;
    else
        error('Unrecognized hemifield: %s. Cannot read the gray graph', hemi);
    end
    % *** TODO: confirm that we don't need to add 1 to nodes and edges!
    if(nargout>2)
        % *** TODO: check to see if vSize should be reordered to match old
        % vAnat ordering.
        ni = niftiRead(classFileName,[]);
        vSize = ni.dim;
    end
else
    % Load an old-style .Gray file

    % mrGray on all machines writes out using ieee big endian
    % format.  So, we must always open our files that way.
    %
    fid = fopen(filename,'r','b');

    % Read xsize, ysize, zsize.
    [sizes, cnt] = fread(fid, [1 3], 'int');

    % [rows, cols, planes]; [ysize, xsize, zsize].
    vSize = [sizes(2), sizes(1), sizes(3)];

    % Read in number of nodes and edges.
    [sizes, cnt] = fread(fid, [1 2], 'int');

    % Read header.
    num_nodes = sizes(1);
    num_edges = sizes(2);

    % Read nodes.
    nodes = fread(fid, [6 num_nodes], 'int');

    % Offset coordinates by 1 because MATLAB indexes arrays
    % starting from 1
    nodes(1:3,:) = nodes(1:3,:) + 1;

    % Offset edge_offset by 1 because MATLAB implements arrays
    % with base 1 *@#!#!
    nodes(5,:) = nodes(5,:) + 1;

    % Add two additional attributes for miscellaneous use.
    % These are used by the shortest path algorithm to store
    % intermediate distance calculations and to mark position
    % in the priority queue.
    nodes = [nodes ; zeros(2,num_nodes)];

    % Read edges.
    edges = fread(fid, [1 num_edges], 'int');

    % Offset all node indices by 1 because MATLAB implements arrays
    % with base 1 *@#!#!
    edges = edges + 1;

    % Insert timestamp stuff here.

    fclose(fid);

end

return;

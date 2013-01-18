function mrgDisplayGrayMatter(grayNodes,grayEdges,curSlice,axesLim)
% Displays a 2D representation of a gray graph for a given z-slice.
%
%  mrgDisplayGrayMatter(grayNodes,grayEdges,curSlice,axesLim)
%
% If the slice is not specified, the default slice is 30
%
% Example:
%   fName ='X:\anatomy\nakadomari\left\20050901_fixV1\left.Class';
%   [nodes,edges,classData] = mrgGrowGray(fName,2,2);
%   mrgDisplayGrayMatter(nodes,edges,80,[120 140 120 140]);
%
% NOTE:  M. Schira says that the gray nodes should be more densely
% connected to reduce the error in the distance measurements.  We should
% look into completing the connections in mrGrowGray.
% 
% GB 05/11/05

if ieNotDefined('curSlice'), curSlice = 30; end

figure
if ~ieNotDefined('axesLim'), axis(axesLim);
else axis([min(grayNodes(1,:)) max(grayNodes(1,:)) min(grayNodes(2,:)) max(grayNodes(2,:))]);
end
hold on

numLayers = max(grayNodes(6,:));
for layer = 0:numLayers

    if ~ieNotDefined('axesLim')
        indices = find((grayNodes(3,:) == curSlice) & (grayNodes(6,:) == layer) &...
            grayNodes(1,:) >= axesLim(1) &...
            grayNodes(1,:) <= axesLim(2) &...
            grayNodes(2,:) >= axesLim(3) &...
            grayNodes(2,:) <= axesLim(4));
    else
        indices = find((grayNodes(3,:) == curSlice) & (grayNodes(6,:) == layer));
    end

    for i = 1:length(indices)
        index = indices(i);
        x1 = grayNodes(1,index);
        y1 = grayNodes(2,index);
        if layer == 0
            plot(x1,y1,'.','Color','k','MarkerSize',10*(numLayers - layer + 1));
        else
            plot(x1,y1,'.','Color','g','MarkerSize',10*(numLayers - layer + 1));
        end

        numConnected = grayNodes(4,index);
        offset = grayNodes(5,index);
        for j = 0:(numConnected - 1)
            x2 = grayNodes(1,grayEdges(offset + j));
            y2 = grayNodes(2,grayEdges(offset + j));
            z2 = grayNodes(3,grayEdges(offset + j));

            if z2 ~= curSlice
                continue
            end

            plot([x1 x2],[y1 y2],'-','Color','g');
        end
    end
end

return;

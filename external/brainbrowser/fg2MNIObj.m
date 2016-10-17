function [coords, lineList,startPoints] = buildMNIObj(fg)

    nFibers = length(fg.fibers);
    nPoints = zeros(nFibers,1);
    for jj=1:nFibers
        nPoints(jj)  = size(fg.fibers{jj},2);
    end
    coords = zeros(sum(nPoints),3);
    startPoints = [0; cumsum(nPoints)]; 
    lineList = cell(1,nFibers);
    for ii=1:nFibers
        lineList{ii} = (startPoints(ii)+1):startPoints(ii+1);
        coords(lineList{ii},:) = fg.fibers{ii}';
    end
        
    % Open the file
    fileID = fopen('test.obj','w');
    fprintf(fileID,'L 1 %d\n', size(coords,1));
    % Write out the Coords   
    fprintf(fileID,'%.4f %.4f %.4f\n',coords');
    
    % Put the color
    fprintf(fileID,'\n%d\n',length(lineList));
    
    fprintf(fileID,'0 .5 .6 .7 1\n\n');
    fprintf(fileID,'%d ',startPoints(2:end));
    fprintf(fileID,'\n\n');
    % Write out the lineList
    for ii=1:nFibers
        fprintf(fileID,'%d ',lineList{ii}-1);
        fprintf(fileID,'\n');
    end
    
    % Close the file
    fclose(fileID);

end

% lineList =
%     
%     
%     for i = 1:3
%         fiber = fg.fibers{i};
%         endline = endline + size(fiber, 2);
%         endlines = cat(1, endlines, endline);
%         line = [];
%         for j = 1:size(fiber, 2)
%             count = count + 1;
%             line = cat(1, line, count);
%             points = cat(1, points, fiber(:, 1));
%         end
%         lines = cat(1, lines, line);
%     end
%     output = ['L 0.500' num2str(count)];
%     h = waitbar(0,'Please wait...');
%     for i = 1:length(points)
%         point = points(i);
%         output = strcat(output, '\n', sprintf(' %f', point));
%         waitbar(i/length(points),h);
%     end
%     output = strcat(output, '\n\n', num2str(length(lines)));
%     endlines = sprintf('%d ', endlines);
%     endlines = endlines(1, end-1);
%     output = strcat(output, '\n0', sprintf(' %d', fg.colorRgb), '\n\n', endlines, '\n\n');
%     for i = 1:length(lines)
%        line = sprintf('%d ', lines(1));
%        output = strcat(output, line(1, end-1), '\n');
%     end
% end
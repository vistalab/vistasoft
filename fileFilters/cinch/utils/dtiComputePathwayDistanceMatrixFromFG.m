function dtiComputePathwayDistanceMatrixFromFG (fg, outputFilename)

% function [distances] = dtiComputePathwayDistanceMatrixFromFG (fg, outputFilename)
%
% Computes a pathway distance matrix from a mrDiffusion fibergroup
%
% fg = input fibergroup
% outputFilename = filename for output distance matrix (.dis extension)

outputFilename

fid = fopen (outputFilename, 'rb');
if (fid ~= -1)
    reply = input(['The file ''' outputFilename ''' exists. Do you want to overwrite the contents? (Y/N) [N]'], 's');
    if isempty(reply)
        reply = 'N';
    end
    if (not (reply == 'y')) & (not (reply == 'Y'))
        return;
    end
    fclose(fid);
end;
fid = fopen (outputFilename, 'wb');
if (~fid)
    fprintf ('Error opening output file!');
    return;
end;
dmatrix = repmat (0, round(length(fg.fibers)*((length(fg.fibers)+1)/2)), 1);

fprintf ('Computing %d comparisons for %d pathways...\n', length(dmatrix), length(fg.fibers));
fprintf ('[Each tick is %d comparisons]\n', round(length(dmatrix)/100));
for p1 = 1:length(fg.fibers)
    points1 = fg.fibers{p1}(:,1:8:length(fg.fibers{p1}));
    p1Cpp = p1-1;
    for p2 = 1:p1-1
        points2 = fg.fibers{p2}(:,1:8:length(fg.fibers{p2}));
        [indices, bestSqDist] = nearpoints(points1, points2);
        bestDist = sqrt(bestSqDist);
        avgDistance1 = mean (bestDist);
        [indices, bestSqDist] = nearpoints(points2, points1);
        bestDist = sqrt(bestSqDist);
        avgDistance2 = mean (bestDist);
        avgDistance = (avgDistance1 + avgDistance2)/2.0;
        p2Cpp = p2-1;
        index = p2Cpp+p1Cpp*(p1Cpp-1)/2+1;
        if (mod(index, round(length(dmatrix)/100)) == 0)
            fprintf ('.');
        end;
        dmatrix(index) = avgDistance;
    end;
end;

fprintf ('\n\nWriting distance matrix to disk...\n');
fwrite (fid, length(fg.fibers), 'int');
fwrite (fid, dmatrix, 'float');
fclose (fid);
fprintf ('Done!\n');




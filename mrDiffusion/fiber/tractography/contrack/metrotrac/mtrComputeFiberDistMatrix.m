function [meanDistMatrix, maxDistMatrix] = mtrComputeFiberDistMatrix(fg)

% Find all pair differences between fibers in the fiber group
meanDistMatrix = zeros(length(fg.fibers));
maxDistMatrix = zeros(length(fg.fibers));

disp('Computing distances between all paths could take awhile.');
percentMark = 10;
percentInc = 10;
for ii = 1:length(fg.fibers)-1
    for jj = ii+1:length(fg.fibers)
        [indices, bestSqDistIJ] = nearpoints(fg.fibers{ii}, fg.fibers{jj});
        [indices, bestSqDistJI] = nearpoints(fg.fibers{jj}, fg.fibers{ii});
        meanDistMatrix(ii,jj) = mean([mean(sqrt(bestSqDistIJ)) mean(sqrt(bestSqDistJI))]);
        meanDistMatrix(jj,ii) = meanDistMatrix(ii,jj);
        maxDistMatrix(ii,jj) = mean(sqrt([max(bestSqDistIJ) max(bestSqDistJI)]));
        maxDistMatrix(jj,ii) = maxDistMatrix(ii,jj);
    end
    percentCompleted = round(ii/length(fg.fibers)*100);
    if( percentCompleted >= percentMark )
        disp(['Completed ' num2str(percentCompleted) ' %' ]);
        percentMark = percentMark+percentInc;
    end
end
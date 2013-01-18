function [meanDistMatrix, maxDistMatrix] = mtrMatchPathways(dt6Filename, pdb1Filename, pdb2Filename)

% Find all pair differences between pdb1 and pdb2 for metric of maximum of
% minimum distances

dt6 = load(dt6Filename,'xformToAcPc');
fg1 = dtiNewFiberGroup;
fg1 = mtrImportFibers(pdb1Filename,dt6.xformToAcPc);
fg2 = dtiNewFiberGroup;
fg2 = mtrImportFibers(pdb2Filename,dt6.xformToAcPc);

meanDistMatrix = zeros(length(fg1.fibers),length(fg2.fibers));
maxDistMatrix = zeros(length(fg1.fibers),length(fg2.fibers));

disp('Computing distances between all paths could take awhile.');
for ii = 1:length(fg1.fibers)
    for jj = 1:length(fg2.fibers)
        [indices, bestSqDist] = nearpoints(fg1.fibers{ii}, fg2.fibers{jj});
        meanDistMatrix(ii,jj) = mean(sqrt(bestSqDist));
        maxDistMatrix(ii,jj) = max(bestSqDist);
    end
    disp(['Completed ' num2str(round(ii/length(fg1.fibers)*100)) ' %' ]);
end

maxDistMatrix = sqrt(maxDistMatrix);

function permutations = dtiBootGetPermutations(permuteMatrix, numPermutations, bRepetition)
%
% permutations = dtiBootGetPermutations(permuteMatrix, numPermutations, [bRepetition=0])
%
%
% HISTORY:
% 2007.06.22 RFD wrote it

if ieNotDefined('bRepetition')
    bRepetition = 0;
end

if(bRepetition==0)
    numVols = permuteMatrix;
    permutations = zeros(numVols,numPermutations);
    for(ii=1:numVols)
        %permutations(ii,:) = randsample(1:numVols,numPermutations,true);
        permutations(ii,:) = ceil(numVols*rand(1,numPermutations));
    end
else
    numVols = size(permuteMatrix,1);
    permutations = zeros(numVols,numPermutations);
    for(ii=1:numVols)
        permutations(ii,:) = permuteMatrix{ii}(ceil(length(permuteMatrix{ii}).*rand(1,numPermutations)));
    end
end

return
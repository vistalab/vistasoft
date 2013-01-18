function [pathway, stats, sPtrNew] = mtrReadCaminoPathwayFromStream(rawPaths, sPtr, mode)

% Default mode is the overriden contrack way
if notDefined('mode'), mode = 1; end

if mode==0
    % Actual camino format
    numPoints = rawPaths(sPtr);
    seedID = rawPaths(sPtr+1);
    stats = seedID;
    pathway = [];
    %pathway = reshape(rawPaths(sPtr+2:sPtr+1+3*numPoints),3,numPoints);
    sPtrNew = sPtr+3*numPoints+2;
else    
    % Lightweight Query format
    numStats = rawPaths(sPtr);
    numPoints = rawPaths(sPtr+1);
    stats = rawPaths(sPtr+2:sPtr+2+numStats-1);
    pathway = reshape(rawPaths(sPtr+numStats+2:sPtr+numStats+1+3*numPoints),3,numPoints);
    sPtrNew = sPtr+3*numPoints+numStats+2;
end

return;
function nfgRunElenaCull(phantomDir, projType, critTt, critDistance)
%Runs Elena's culling algorithm on projectome for new projectome
%
%   nfgRunElenaCull(phantomDir, projType)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

% Directories
% Input Files
projPDBFile = nfgGetName([projType,'PDBFile'],phantomDir);
dtFile = nfgGetName('dtFile',phantomDir);
% Output Files
projECullPDBFile = nfgGetName([projType,'ECullPDBFile'],phantomDir);

% Load projectome
fgProj = mtrImportFibers(projPDBFile);


critFiberLen = 0;
critAvgLA = 0;
if ieNotDefined('critTt')
    % Explore the user criteria
else
    % Do culling with supplied user criteria
    [fgECull, fiberDiameter] = dtiCullFibers(fgProj, dtFile, critTt, critDistance, critFiberLen, critAvgLA);
    fgECull = dtiClearQuenchStats(fgECull);
    mtrExportFibers(fgECull, projECullPDBFile);
    disp(['The ECull fiber group has been written to ' projECullPDBFile]);
end

function dtiComputePathwayDistanceMatrixForSelection (dataDirectory, selectionFile)
%
% function dtiComputePathwayDistanceMatrixForSelection (dataDirectory, selectionFile)
%
% Computes and saves the distance matrix for a particular selection of pathways. The
% distance matrix is used to enable growing/shrinking of pathway selections
% in the interactive tool. 
%
% dataDirectory: Path to the subject's bin/ directory containing all_paths.pdb
% selectionFile: Full path to the selection file (.sel) with the pathways
% to include in the distance matrix.
%
% Author: DA

if(~exist('dataDirectory','var') | isempty(dataDirectory))
    dataDirectory = uigetdir('', 'Set subject bin directory');
    if(isnumeric(dataDirectory)), disp('Compute distance matrix canceled.'); return; end
end;
if(~exist('selectionFile','var') | isempty(selectionFile))
    if(exist(fullfile(dataDirectory, 'selections'),'dir')) 
        fn = fullfile(dataDirectory, 'selections', filesep); 
    end;
    [f, p] = uigetfile({'*.sel';'*.*'}, 'Load Pathway Selection...', fn);
    if(isnumeric(f)), disp('Load pathway selection canceled.'); return; end
    selectionFile = fullfile(p,f);
end;
pdbFilename = [dataDirectory filesep 'all_paths.pdb'];

pdb = fopen (pdbFilename, 'rb');

% figure out where num paths is, read it in
offset = fread (pdb, 1, 'uint');
%fprintf ('Seeking to %d\n', offset);
fseek (pdb, offset, -1);
numPaths = fread (pdb, 1, 'uint');

selFile = fopen (selectionFile, 'rb');
junk = fread(selFile, 1, 'uint');
selectedInput = fread (selFile, numPaths, 'uint');

%fprintf ('Intersecting ROI "%s" with %d paths in "%s"...\n', roi.name, numPaths, pdbFilename);

fseek (pdb, 0, 1);
length = ftell(pdb);
fseek(pdb, length-numPaths*4, -1); % hack - is there a way to get the size of an unsigned long?
%fseek (pdb, length-4,-1);
  
fileOffsets = fread (pdb, numPaths, 'ulong');
%fileOffsets = fread (pdb, 1, 'ulong');

fprintf ('Loading pathways from disk...\n');
fseek (pdb, fileOffsets(1), -1); 
count = 1;
for pathIndex = 1:numPaths
    if (selectedInput (pathIndex))
        fseek(pdb, fileOffsets(pathIndex), -1);
        pathHeaderSize = fread (pdb, 1, 'uint');
        numPoints = fread (pdb, 1, 'uint');
        fseek (pdb, pathHeaderSize-4, 0);
        pts = fread (pdb, numPoints*3, 'double');
        pts = reshape (pts, 3, numPoints);
        fGroup.fibers{count} = pts;
        count = count+1;
    end;
end;

dtiComputePathwayDistanceMatrixFromFG (fGroup, [selectionFile '.dis']);


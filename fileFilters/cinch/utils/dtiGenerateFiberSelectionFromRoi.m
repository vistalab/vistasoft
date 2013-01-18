function dtiGenerateFiberSelectionFromRoi (dataDirectory, roiFilename, inputSelectionFilename, outputSelectionFilename)

% function dtiGenerateFiberSelectionFromRoi (dataDirectory, roiFilename, inputSelectionFilename, outputSelectionFilename)
% 
% find all fibers (within the specified selection) that intersect the given roi, and 
% create a new fiber selection from these fibers.
%
% dataDirectory: Root directory for this subject's data.
% roiFilename: Full path to ROI to intersect with
% inputSelectionFilename: Full path to .sel file for input pathways.
% outputSelectionFilename: Full path to .sel file for output pathways.
%
% Author: DA


if(~exist('dataDirectory','var') | isempty(dataDirectory))
    dataDirectory = uigetdir('', 'Set subject bin directory');
    if(isnumeric(dataDirectory)), disp('Canceled.'); return; end
end;
if(~exist('roiFilename','var') | isempty(roiFilename))
    fn = '';
    if(exist(fullfile(['..' filesep dataDirectory], 'ROIs'),'dir')) 
        fn = fullfile(['..' filesep dataDirectory], 'ROIs'); 
    end;
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Choose ROI file...', fn);
    if(isnumeric(f)), disp('Canceled.'); return; end
    roiFilename = fullfile(p,f);
end;
if(~exist('inputSelectionFilename','var') | isempty(inputSelectionFilename))
    fn = '';
    if(exist(fullfile(dataDirectory, 'selections'),'dir')) 
        fn = fullfile(dataDirectory, 'selections', filesep); 
    end;
    [f, p] = uigetfile({'*.sel';'*.*'}, 'Choose input selection...', fn);
    if(isnumeric(f)), disp('Canceled.'); return; end
    inputSelectionFilename = fullfile(p,f);
end;
if(~exist('outputSelectionFilename','var') | isempty(outputSelectionFilename))
    fn = '';
    if(exist(fullfile(dataDirectory, 'selections'),'dir')) 
        fn = fullfile(dataDirectory, 'selections', filesep); 
    end;
    [f, p] = uiputfile({'*.sel';'*.*'}, 'Choose name for output selection...', fn);
    if(isnumeric(f)), disp('Canceled.'); return; end
    outputSelectionFilename = fullfile(p,f);
end;

r = open (roiFilename);
roi = r.roi;

pdbFilename = [dataDirectory filesep 'all_paths.pdb'];

pdb = fopen (pdbFilename, 'rb');

% figure out where num paths is, read it in
offset = fread (pdb, 1, 'uint');
%fprintf ('Seeking to %d\n', offset);
fseek (pdb, offset, -1);
numPaths = fread (pdb, 1, 'uint');

selFile = fopen (inputSelectionFilename, 'rb');
junk = fread(selFile, 1, 'uint');
selectedInput = fread (selFile, numPaths, 'uint');

fprintf ('Intersecting ROI "%s" with %d paths in "%s"...\n', roi.name, numPaths, pdbFilename);

fseek (pdb, 0, 1);
length = ftell(pdb);
fseek(pdb, length-numPaths*4, -1); % hack - is there a way to get the size of an unsigned long?
%fseek (pdb, length-4,-1);
  
fileOffsets = fread (pdb, numPaths, 'ulong');
%fileOffsets = fread (pdb, 1, 'ulong');

fseek (pdb, fileOffsets(1), -1); 

% xxx assume numStats is zero

fGroup = dtiNewFiberGroup ('FG');
count = 0;

sel = dtiNewFiberSelection();
sel.selected = [];
fprintf ('Intersecting with %d paths (1000 paths per tick):', numPaths);
for pathIndex = 1:numPaths
    count = count + 1;
    pathHeaderSize = fread (pdb, 1, 'uint');
    numPoints = fread (pdb, 1, 'uint');
    fseek (pdb, pathHeaderSize-4, 0);
    pts = fread (pdb, numPoints*3, 'double');
    pts = reshape (pts, 3, numPoints);
    fGroup.fibers{count} = pts;
    if (mod(pathIndex, 1000) == 999 | pathIndex == numPaths)
        %fprintf ('Intersecting with ROI!\n');
        fprintf ('.');
        % take what you have and intersect it, storing results
        [fgOut, contentiousFibers, indices] = dtiIntersectFibersWithRoi([], 'AND',0.87, roi, fGroup);
        sel.selected = [sel.selected; indices];
        clear('fGroup');
        fGroup = dtiNewFiberGroup ('FG');
        count = 0; 
    end;
end;
fprintf ('\nDone!\n\n');

sel.selected = sel.selected .* selectedInput;

%selFilename = [dataDirectory filesep 'selections' filesep roi.name '.sel'];
dtiWriteFiberSelection (sel, outputSelectionFilename);

%[fgOut, contentiousFibers, indices] = dtiIntersectFibersWithRoi([], 'AND',0.87, roi, fg);
%sel = dtiNewFiberSelection();
%sel.selected = repmat (0, 1, length(fileOffsets));
%sel.selected(indices(:, 1)) = 1;

return;





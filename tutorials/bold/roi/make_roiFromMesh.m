%% script to define a new roi based on functional activity on mesh
% run this script after drawing and filling an roi
% rl, 08/2014


%% modify
newroi.color   = 'k';
newroi.name    = 'right_wordVfix_all'; 
newroi.comment = 'p = 0.001'; 


%% no need to modify
% assuming that mrVista and a mesh is loaded, there should exist a 
% variable called VOLUME. check this, and abort if not found.
if ~exist('VOLUME', 'var'); error('Must have VOLUME variable defined!'); end


% get the roi from the mesh
% vw = meshROI2Volume(vw, [mapMethod=3]), where method 3 means grow from 
% layer 1 to get an roi that spans all layers  
VOLUME{end} = meshROI2Volume(VOLUME{end}, 3); 

% restrict roi to functional acitivity
VOLUME{end} = restrictROIfromMenu(VOLUME{end}); 

% grab selected roi
roi = viewGet(VOLUME{end}, 'curRoi'); 

%% perform ROI a not b
% roi is last one you picked
roiA = VOLUME{end}.ROIs(end).name;

% all other rois you don't want
roiB={VOLUME{end}.ROIs(1:end-1).name}; 

% make the roi 
VOLUME{end} = ROIanotb(VOLUME{end}, roiA, roiB, newroi.name, newroi.color); 


%% save roi in local directory
saveROI(VOLUME{1}, 'selected', 1)

% refresh screen
VOLUME{end} = refreshScreen(VOLUME{end}); 
% refresh mesh
VOLUME{end} = meshColorOverlay(VOLUME{end}); 
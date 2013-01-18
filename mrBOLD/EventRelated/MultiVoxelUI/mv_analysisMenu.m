function mv = mv_analysisMenu(mv, hfig);
%
% mv = mv_analysisMenu(mv, hfig);
%
% Add menus with analysis options for
% the MultiVoxel UI.
%
%
% ras,  04/05
if ieNotDefined('hfig')
    hfig = gcf;
end

if ieNotDefined('mv')
    mv = get(hfig, 'UserData');
end

mv.ui.analMenu = uimenu('ForegroundColor',  'k',  'Label',  'Analysis',  'Separator',  'on');

% split-half option (odd v even trials)
uimenu(mv.ui.analMenu, 'Label', 'Split-Half analysis', ...
       'Separator', 'off', ...
       'Callback', 'mv_splitHalf;');

% split-half option (odd v even trials), remove means
uimenu(mv.ui.analMenu, 'Label', 'Split-Half analysis (remove means)', ...
       'Separator', 'off', ...
       'Callback', 'mv_splitHalf([], 1);');
   
% % add bootstrapping option (odd v even trials)
% uimenu(mv.ui.analMenu, 'Label', 'Reliability Analysis (odd vs even)', ...
%        'Separator', 'off', ...
%        'Callback', 'results = mv_reliability;');

% % add bootstrapping option (choose subsets)
% uimenu(mv.ui.analMenu, 'Label', 'Reliability Analysis (select subsets)', ...
%        'Separator', 'off', ...
%        'Callback', 'results = mv_reliability([], ''user'');');

% % sort by voxR option
% uimenu(mv.ui.analMenu, 'Label', 'Sort Voxels by Voxel Reliability', ...
%    'Separator', 'on', 'Callback', 'mv_sortByVoxR;');
% 
% % sort by omniR option
% uimenu(mv.ui.analMenu, 'Label', 'Sort Voxels by Omnibus Correlation', ...
%    'Separator', 'off', 'Callback', 'mv_sortByOmniR;');
% 
% % sort by MI option
% uimenu(mv.ui.analMenu, 'Label', 'Sort Voxels by Mutual Information', ...
%    'Separator', 'off', 'Callback', 'mv_sortByMutualInf;')

% sort by voxel amplitude
uimenu(mv.ui.analMenu, 'Label', 'Sort Voxel Order (sortrows)', ...
   'Separator', 'on', 'Callback', 'mv_sortVoxels([],  ''sortrows'',  ''dialog'');');

% sort by dprime
uimenu(mv.ui.analMenu, 'Label', 'Sort Voxel Order (d'')', ...
   'Separator', 'off', 'Callback', 'mv_sortVoxels([],  ''dprime'');');

% sort by GLM variance explained
uimenu(mv.ui.analMenu, 'Label', 'Sort Voxel Order (GLM variance explained)', ...
   'Separator', 'off', 'Callback', 'mv_sortVoxels([],  ''varexplained'');');

% clustering analysis option
uimenu(mv.ui.analMenu, 'Label', 'Cluster Voxels', ...
   'Separator', 'off', 'Callback', 'mv_basicCluster;');
   
% blur time courses option
uimenu(mv.ui.analMenu, 'Label', 'Temporal Blur Each Voxel''s Time Course', ...
   'Separator', 'on', ...
   'Callback', 'mv_blurTimeCourse;');
     

% sub-select voxels option
uimenu(mv.ui.analMenu,  'Label',  'Select Voxel Subset Based on Criteria...',  ...
    'Separator',  'on',  'Callback',  'mv_selectSubset([],  [],  ''dialog''); multiVoxelUI; ');

% remove outliers option
uimenu(mv.ui.analMenu, 'Label', 'Remove Outlier Voxels', ...
   'Separator', 'off', ...
   'Callback', 'mv_removeOutliers;');

% pick a subset option
uimenu(mv.ui.analMenu, 'Label', 'Click on voxels for a new UI', ...
   'Separator', 'off', 'Callback', 'mv_pickVoxels;');

% make a time course UI option
uimenu(mv.ui.analMenu, 'Label', 'Time Course UI for these voxels', ...
   'Separator', 'on', 'Callback', 'mv_makeTCUI;');


% % dump data to workspace option
% uimenu(mv.ui.analMenu, 'Label', 'Dump Data to Workspace', ...
%    'Separator', 'on', 'Callback', 'tc_dumpDataToWorkspace;');
% 
   
set(hfig, 'UserData', mv);

return

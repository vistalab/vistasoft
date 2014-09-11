%% makes the glm struct for plotting purposes

clear all ; clc; close all; 
% addpath(genpath('/biac4/kgs/biac3/kgs4/projects/retinotopy/adult_ecc_karen/Analyses')); 
% addpath('biac4/wandell/data/reading_prf/scripts/')
bookKeeping; 

%% modify these

tem.listRoi     = {
    %'LV1'
    'LV2d'
    %'LV2v'
    %'LV3d'
    %'RV1'
    %'RV2d'
    %'RV2v'
    %'RV3d'
    %'RV3v'
    %'RV3v'
    
    }; 
tem.dataType    = 'GLMs'; 
tem.numSubs     = [1:10,12:13]; 
tem.viewType    = 'Gray'; 
tem.scan        = 1; 
tem.xformMethod = 'trilinear'; 

%% no need to modify here

tem.MVname      = cellstr(['MV_' tem.roiName]);
tem.MVname      = tem.MVname{1}; 
tem.MVpath      = '/biac4/wandell/data/reading_prf/forAnalysis/structs/MV.mat'; 

% if MV exists, load it, else create it
if exist('/biac4/wandell/data/reading_prf/forAnalysis/structs/MV.mat','file')
    load('/biac4/wandell/data/reading_prf/forAnalysis/structs/MV.mat');
else
    MV = cell(1,length(tem.numSubs));
end

% looping over all subjects
for ii = 1:length(tem.numSubs)
    iisub = tem.numSubs(ii); 
    
    % go to current subject's directory
    cd(list_sessionPath{iisub})
    
    % get view
    tem.v   = getCurView;
      
    % get their roiFile (absolute)
    tem.roiFile = strcat(list_roiLocalPath{iisub}, tem.listRoi,'.mat'); 
    tem.roiFile = tem.roiFile{1}; 
    
    % make THE STRUCT
    if ~exist(tem.roiFile,'file')
        mv = []; 
    else
        [h, mv] = get_mvstruct_rl(tem.dataType,tem.scan,tem.roiFile,tem.viewType); 
    end
    
    MV{ii} = mv; 
    save(tem.MVpath,'MV'); 
    
end



 
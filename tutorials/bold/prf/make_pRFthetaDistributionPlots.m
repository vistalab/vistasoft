%% makes histogram of pRF size distributions
% rle 08/14

clear all; clc; close all; 
bookKeeping; 


%% modify things here

tem.subjectsToAnalyze = 1:11;

tem.listRoi = {
    'left_wordVscramble_all'
    'left_wordVscramble_restrict'
%     'LV1'
%     'LV2d'
%     'LV2v'
%     'LV3d'
%     'LV3v'
%     'LV3ab'
%     'LhV4'
%     'LVO-1'
%     'LVO-2'
%     'LTO-1'
%     'LTO-2'
%     'LIPS-0'  
    'right_wordVscramble_all'
    'right_wordVscramble_restrict'
%     'RV1'
%     'RV2d'
%     'RV2v'
%     'RV3d'
%     'RV3v'
%     'RV3ab'
%     'RhV4'
%     'RVO-1'
%     'RVO-2'
%     'RTO-1'
%     'RTO-2'
%     'RIPS-0'
    'CwordVscramble_all'
    'CwordVscramble_restrict'
%     'CV1'
%     'CV2d'
%     'CV2v'
%     'CV3d'
%     'CV3v'
%     'CV3ab'
%     'ChV4'
%     'CVO-1'
%     'CVO-2'
%     'CTO-1'
%     'CTO-2'
%     'CIPS-0'   
    };

%%  no need to modify

for jj = 1:length(tem.listRoi)

    tem.roi = tem.listRoi{jj}; 
    
    % load the RM struct for this roi
    tem.RMfolder    = '/biac4/wandell/data/reading_prf/forAnalysis/structs/'; 
    tem.RMpath      = cellstr([tem.RMfolder 'RM_' tem.roi '.mat']);
    tem.RMpath      = tem.RMpath{1}; 
    load(tem.RMpath); 

    % where we want to save
    tem.savePathSingle = '/biac4/wandell/data/reading_prf/forAnalysis/images/single/pRFThetaDist/'; 
    tem.savePathGroup  = '/biac4/wandell/data/reading_prf/forAnalysis/images/group/pRFThetaDist/'; 

    
    
    for ii = 1:length(tem.subjectsToAnalyze)

        iisub = tem.subjectsToAnalyze(ii); 

        rm = RM{iisub}; 
        tem.figHandle = ff_plotPRFThetaDistribution(rm);


        % save the figure
        saveas(tem.figHandle, [tem.savePathSingle tem.roi '_' rm.subject '.jpg']); 

        % clear for preventative reasons
        clear tem.figHandle

    end
    
    close all; 
    
end
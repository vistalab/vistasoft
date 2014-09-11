%% flips the right ROI and combines to left
% makes boostrapped prf coverage map based on these
% assumes RM struct for these ROIs for both hemispheres exist

clear all; close all; clc; 

%%
tem.structPath = '/biac4/wandell/data/reading_prf/forAnalysis/structs/'; 

tem.flipTheRight = 0; 

tem.listRoi = {
%     'LV1', 'RV1', 'V1'; 
%     'LV2d', 'RV2d', 'V2d'; 
%     'LV2v', 'RV2v', 'V2v';  
%     'LV3d', 'RV3d', 'V3d';  
%     'LV3v', 'RV3v', 'V3v';  
%     'LV3ab', 'RV3ab', 'V3ab';  
%     'LhV4', 'RhV4', 'hV4'; 
%     'LVO-1', 'RVO-1', 'VO-1'; 
%     'LVO-2', 'RVO-2', 'VO-2'; 
%     'LTO-1', 'RTO-1', 'TO-1'; 
%     'LTO-2', 'RTO-2', 'TO-2'; 
%     'LIPS-0', 'RIPS-0', 'IPS-0';     
%    'left_wordVscramble_all', 'right_wordVscramble_all', 'wordVscramble_all'; 
%    'left_wordVscramble_restrict', 'right_wordVscramble_restrict', 'wordVscramble_restrict'; 
'leftVWFA', 'rightVWFA', 'bothVWFA'
    };


%%

for ii = 1:size(tem.listRoi,1)
       
    % this roi
    tem.thisRoi = tem.listRoi(ii,3); 
    tem.thisRoi = tem.thisRoi{1}; 
    
    left        = load([tem.structPath 'RM_' tem.listRoi{ii,1} '.mat']);
    right       = load([tem.structPath 'RM_' tem.listRoi{ii,2} '.mat']);
    RM          = cell(1,length(left.RM)); 
    
    
    % combine left and right for each subject
    % for fields x0, y0, and sigma
    for jj = 1:length(left.RM)
        
        RM{jj}          = make_emptyRmStruct; 
        
        % flipping (or not flipping)
        if tem.flipTheRight
            RM{jj}.x0       = [left.RM{jj}.x0 -right.RM{jj}.x0]; 
        else
            RM{jj}.x0       = [left.RM{jj}.x0 right.RM{jj}.x0]; 
        end
        
        
        %
        
        RM{jj}.y0       = [left.RM{jj}.y0 right.RM{jj}.y0]; 
        RM{jj}.y0real   = [left.RM{jj}.y0real right.RM{jj}.y0real];
        RM{jj}.sigma1   = [left.RM{jj}.sigma1 right.RM{jj}.sigma1];
        RM{jj}.sigma2   = [left.RM{jj}.sigma1 right.RM{jj}.sigma2];
        
        RM{jj}.beta     = [left.RM{jj}.beta' right.RM{jj}.beta'];
        RM{jj}.co       = [left.RM{jj}.co right.RM{jj}.co];
        RM{jj}.coords   = [left.RM{jj}.coords right.RM{jj}.coords];
        RM{jj}.ecc      = [left.RM{jj}.ecc right.RM{jj}.ecc];
        RM{jj}.indices  = [left.RM{jj}.indices' right.RM{jj}.indices'];
        RM{jj}.ph       = [left.RM{jj}.ph right.RM{jj}.ph];
        RM{jj}.theta    = [left.RM{jj}.theta right.RM{jj}.theta];
        
        RM{jj}.subject  = left.RM{jj}.subject; 
        RM{jj}.name     = tem.thisRoi; 
               
    end
    
    % save the combined
    tem.structSavePath = [tem.structPath 'RM_C' tem.thisRoi]; 
    save(tem.structSavePath, 'RM'); 
    
       
end
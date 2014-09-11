%% script to draw meshes
% rl, 08/14

%% no need to modify here

close all; clear all; clc; 

% bookKeeping: list of directories, meshes, retModels, rois ...
addpath(genpath('/biac4/wandell/data/reading_prf/scripts/')); 
bookKeeping; 

%% modify here

% the subject(s) we want to analyze
A.subjects = 10; 



%% modifications here from time to time

for ii = 1:length(A.subjects);  

    % index of subject
    tem.subInd = A.subjects(ii); 
   
    % move to subject's directory, open mrVista and get view
    cd(list_sessionPath{tem.subInd}); 
    vw = mrVista('3'); 
    
    %% Load any meshes
    
    % Left mesh
    tem.meshL = [list_meshPath{tem.subInd} list_meshL{tem.subInd}]; 
    VOLUME{1} = meshLoad(VOLUME{1}, tem.meshL , 1); 
    
    % Right mesh
    tem.meshR = [list_meshPath{tem.subInd} list_meshR{tem.subInd}]; 
    VOLUME{1} = meshLoad(VOLUME{1}, tem.meshR, 1); 
    
end
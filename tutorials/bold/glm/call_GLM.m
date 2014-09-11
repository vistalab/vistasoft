%% script to assign parfiles and run GLM
% rl, 08/14
clear all; close all; clc; 

% constructing purposes (can delete later)
cd ('/biac4/wandell/data/reading_prf/rosemary/20140818_1211/')

%% leave these unchanged 

% open mrVista session
vw = getCurView; 

% get default glm params 
params          = er_defaultParams; 
params.glmHRF   = 2; % 2: spm difference of gammas


% specifying values for running glm; 
tem.newDtName = 'GLMs'; 

%% modify here

% parfile path
tem.whichScans = [5 6 7];
parfiles = cell(3,1); 

for ii = 1:length(tem.whichScans)
   parfiles{ii} =  'loc_run1_word_scram_face_obj.par'; 
end

% - assign parfiles to scans
vw = er_assignParfilesToScans(vw, tem.whichScans, parfiles);  

% grouping: specify which scans in which dataType
% this is taken care in defining dataType and scans to run glm on

% redefine default params. these vary by experiment
params.eventsPerBlock   = 8;    % the number of TRs per block
params.annotation       = [];   % note if I feel like it
params.framePeriod      = 2;    % TR time

% name or number of the datatype from which to take the scans
tem.dt = 'MotionComp_RefScan1'; 
% scan numbers to make analysis
tem.scans = [5 6 7]; 



%% Go! GLM!
vw = applyGlm(vw, tem.dt, tem.scans , params, tem.newDtName); 

%% compute contrast maps

% to work on ...


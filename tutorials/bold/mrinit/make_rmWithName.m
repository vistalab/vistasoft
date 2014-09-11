% damage control. script to add name field to all structs
% don't have to worry about this in all future versions of RM
% not that this matters but there seems to be a bug -- does not seem to be
% overwriting

clear all; clc; close all; 

% subjects names
list_sub = {
    'ak'
    'amr'
    'ch'
    'kh'
    'kw'
    'lmp'
    'ni'
    'rb'
    'wg'
    'rl'
    'asr'
    'am'
    }; 



% load list RM structure
listRMs = dir('/biac4/wandell/data/reading_prf/forAnalysis/structs/'); 
% get rid of hidden directories
listRMs = listRMs(3:end); 



% loop over each RM struct
for ii = 1:length(listRMs)
   
    % load the specific RM
    load(['/biac4/wandell/data/reading_prf/forAnalysis/structs/' listRMs(ii).name])
   
    for jj = 1:length(list_sub)
       RM{jj}.subject = list_sub{jj}; 
       % RM{jj}.name    = listRMs{ii}; 
    end

   
   % save this RM
   RMpath = ['/biac4/wandell/data/reading_prf/forAnalysis/structs/' listRMs(ii).name]; 
   save(RMpath,'RM'); 
   
   % preventative measures
   clear RM
   
   
end
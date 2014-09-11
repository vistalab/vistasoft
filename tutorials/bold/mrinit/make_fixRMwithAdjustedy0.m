%% adding an "y0adjusted" field to each RM structure
% rmPlotCoverage is sometimes flipped over the x-axis
% based on info stored in bookKeeping, this script will add (or overwrite)
% the y0adjusted field to take care of this

% RM is a array of length n, with each structure looking like this:
% RM{1} = 
%      coords: [3x1633 single]
%     indices: [1633x1 double]
%        name: 'lV1_all_nw'
%     curScan: 1
%          vt: 'Gray'
%          co: [1x1633 double]
%      sigma1: [1x1633 double]
%      sigma2: [1x1633 double]
%       theta: [1x1633 double]
%        beta: [1633x3 double]
%          x0: [1x1633 double]
%          y0: [1x1633 double]
%          ph: [1x1633 double]
%         ecc: [1x1633 double]
%     session: '42111_MN'


clear all; close all; clc; 

%% important variables

bookKeeping;

% number of subjects in RM struct
numSubs = length(list_sub); 

% full path of struct folder
structFolderPath = '/biac4/wandell/data/reading_prf/forAnalysis/structs/'; 

%% get the full list of RM structs
listRMs = dir(structFolderPath); 

% get rid of hidden files
listRMs = listRMs(3:end); 

%% for each RM struct
for ii = 1:length(listRMs)
    
    % load the RM struct
    load([structFolderPath listRMs(ii).name]); 
    

    
    % what is this roi?
    thisRoi = RM{1}.name; 
    
    % for each subject (in RM struct)
    for jj = 1:numSubs
       
        % make y0real field
        RM{jj}.y0real = RM{jj}.y0; 
        
        % make y0 field be the adjusted y0
        % this is because other plotting functions will using y0
        if list_YNflipYvalues(jj)
            RM{jj}.y0 = RM{jj}.y0*-1; 
        else
            % don't do anything
        end
               
    end
    
    
    % save RM struct
    save([structFolderPath listRMs(ii).name], 'RM');
    clear RM
    
end



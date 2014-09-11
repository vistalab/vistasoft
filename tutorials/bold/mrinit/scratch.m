%% script to make structure with everyone's rm model
% rl, 08/14

clear all; close all; clc;
% bookKeeping: list of directories, meshes, retModels, rois ...
addpath(genpath('/biac4/wandell/data/reading_prf/scripts/')); 
bookKeeping; 

%% modify here

% the subject(s) we want to analyze
A.subjects = 1:13; 


%% modifications here from time to time

for ii = 1:length(A.subjects);  

    %% load RM
    if ii ~= 1
        load('/biac4/wandell/data/reading_prf/scripts/RM.mat'); 
    end
    
    %% index of subject
    tem.subInd = A.subjects(ii); 
   
    %% move to subject's directory, open mrVista and get view
    cd(list_sessionPath{tem.subInd}); 
    vw = mrVista('3'); 
    
    %% load rm model
    
    load([list_retModFolderPath{ii} list_retModName{ii}]); 
    
    
    %% save to structure
    RM(ii).session  = list_sessionPath{ii}; 
    RM(ii).x0       = model{1}.x0; 
    RM(ii).y0       = model{1}.y0; 
    RM(ii).sigma    = model{1}.sigma; 
    
    %% save RM
    save('/biac4/wandell/data/reading_prf/scripts/RM.mat', 'RM'); 
    
    %% close mrVista
    close all; 
    
end

% save('/biac4/wandell/data/reading_prf/scripts/RM.mat'); 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% script to make structure with everyone's rm model
% rl, 08/14

clear all; close all; clc;
% bookKeeping: list of directories, meshes, retModels, rois ...
addpath(genpath('/biac4/wandell/data/reading_prf/scripts/')); 
bookKeeping; 

%% modify here

% the subject(s) we want to analyze
A.subjects = 1:13; 


%% modifications here from time to time

for ii = 1:length(A.subjects);  

    %% load RM
    if ii ~= 1
        load('/biac4/wandell/data/reading_prf/scripts/GM.mat'); 
    end
    
    %% index of subject
    tem.subInd = A.subjects(ii); 
   
    %% move to subject's GLM directory in Inplane 
    % for design matrix, maybe betas
    cd([list_sessionPath{ii} 'Inplane/GLMs/']); 
    
    % get the design matrix
    cd('./Scan1/'); 
    load('glmSlice1'); 
    tem.des = designMatrix; 
    
    
    
    %% move to subject's GLM directory in Gray
    % for variance explained and variance residual
    
    % - move to session directory
    cd([list_sessionPath{ii} 'Gray/GLMs/']);
    
        % if parameter maps have not been xformed to gray, do that now
        if (~exist('/wordVfix.mat','file') && (~exist('WordVFix.mat','file')))
            cd([list_sessionPath{ii}]);
            ip2volAllParMaps('GLMs','Gray'); 
        end
    
    % load and save proportion variance explained
    cd([list_sessionPath{ii} 'Gray/GLMs/']);
    load('Proportion Variance Explained'); 
    tem.varExplain = map{1}; 
    
    % load and save residual variance
    load('Residual Variance'); 
    tem


    
    %% save to structure
    GM(ii).session          = list_sessionPath{ii}; 
    GM(ii).designMatrix     = tem.des; 
    GM(ii).varExplained     = 
    GM(ii).varResidual      = 
    % GM(ii).betas          =

    
    %% save GM
    save('/biac4/wandell/data/reading_prf/scripts/GM.mat', 'GM'); 
    
    %% close mrVista
    close all; 
    
end

% save('/biac4/wandell/data/reading_prf/scripts/RM.mat'); 

% 08/27/14 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% makes the rm struct for plotting purposes

clear all ; clc; close all; 
bookKeeping; 

%% define things here

tem.numSubs         = [1:11]; 
 
tem.YNroiConsistent = 0; 


switch tem.YNroiConsistent
    case 1  % if yes consistent, name the roi(s) here
        
        tem.LISTRoi = {
            'LV1'
            'LV2d'
            'LV2v'
            'LV3d'
            'LV3v'
            'LV3ab'
            'LhV4'
            'LVO-1'
            'LVO-2'
            'LTO-1'
            'LTO-2'
            'LIPS-0'            
            'RV1'
            'RV2d'
            'RV2v'
            'RV3d'
            'RV3v'
            'RV3ab'
            'RhV4'
            'RVO-1'
            'RVO-2'
            'RTO-1'
            'RTO-2'
            'RIPS-0'
            }; 
        
    case 0 % if not consistent, here are the mulitple cases:
       
        tem.LISTRoi = {
            'leftScrambleAll'
            'leftScrambleRestrict'
            'rightScrambleAll'
            'rightScrambleRestrict'
        };
end


        % rosemary's subjects
        tem.roiScheme1 = {
            'left_wordVscramble_all'
            'right_wordVscramble_all'
            'left_wordVscramble_restrict'
            'right_wordVscramble_restrict'
        }; 
        
        % andreas' subjects   
        tem.roiScheme2 = {
             'left_WvWS_all'
             'right_WvWS_all'
             'left_WvWS_restrict'
             'right_WvWS_restrict'
        };

% looping over rois
for jj = 1:length(tem.LISTRoi)

    tem.listRoi = tem.LISTRoi;  
    tem.roi     = tem.listRoi{jj}; 
    
    % intiialize things
    tem.RMname      = cellstr(['RM_' tem.roi]);
    tem.RMname      = tem.RMname{1}; 
    tem.RMpath      = ['/biac4/wandell/data/reading_prf/forAnalysis/structs/RM_' tem.roi '.mat']; 

    % if RM exists, load it, else create it
    if exist(tem.RMpath,'file')
        load(tem.RMpath);
    else
        RM = cell(1,length(tem.numSubs));
    end
    
    
    % looping over subjects
    for ii = 1:length(tem.numSubs)
        iisub = tem.numSubs(ii); 

        %% modify here. (organization probably could be better)
        if ~tem.YNroiConsistent
            % decide scheme based on subject
            if ii >= 10, 
                % rosemary subjects
                tem.listRoi = tem.roiScheme1; 
            else
                % andreas subjects
                tem.listRoi = tem.roiScheme2; 
            end
        end
        %% end modify here

        % go to current subject's directory
        cd(list_sessionPath{iisub})

        % open hidden gray view
        tem.hg = initHiddenGray('Gray'); 

        % check to see if roi exists
        tem.roiPath = cellstr([list_roiLocalPath{iisub} tem.listRoi{jj} '.mat']);  
        tem.roiPath = tem.roiPath{1}; 

        % if it doesn't exist, skip 
        if ~exist(tem.roiPath,'file')
            display(['----' tem.roiPath ' does not exist. making empty.' '----']); 
            rm = make_emptyRmStruct(); 
        else % if it does exist ...

            
            % load the roi into the hidden gray
            tem.hg      = loadROI(tem.hg, tem.roiPath,1,[],1,1); 

            % load the ret model (convert absolute path to string)
            tem.rmPath  = cellstr([list_retModFolderPath{iisub} list_retModName{iisub}]);  
            tem.rmPath  = tem.rmPath{1}; 
            tem.hg      = rmSelect(tem.hg, 1, tem.rmPath); 
            %tem.hg      = rmLoadDefault(tem.hg); 

            % get ret params for specific roi
            rm           = rmGetParamsFromROI(tem.hg); 
            rm.session   = tem.rmPath; 
            
            % flipping y-axis stuff
            rm.y0real = rm.y0; 
            if list_YNflipYvalues(iisub)
                rm{iisub}.y0 = rm{iisub}.y0*-1; 
            else
            % don't do anything
            end
            
            
        end %% END: if roi exists
        
        % name of subject, even if roi is empty
        rm.subject   = list_sub{iisub}; 

        RM{iisub} = rm; 
        save(tem.RMpath, 'RM'); 

    end %% for ii subject
    
end %% for jj roi

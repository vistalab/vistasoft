%% makes the rm struct for plotting purposes

clear all ; clc; close all; 
bookKeeping; 

%% define things here

tem.numSubs         = [12]; 
 

tem.listRoi = {
%         'LV1'
%         'LV2d'
%         'LV2v'
%         'LV3d'
%         'LV3v'
%         'LV3ab'
%         'LhV4'
%         'LVO-1'
%         'LVO-2'
%         'LTO-1'
%         'LTO-2'
%         'LIPS-0'            
%         'RV1'
%         'RV2d'
%         'RV2v'
%         'RV3d'
%         'RV3v'
%         'RV3ab'
%         'RhV4'
%         'RVO-1'
%         'RVO-2'
%         'RTO-1'
%         'RTO-2'
%         'RIPS-0'
%        'left_wordVscramble_all'
%        'right_wordVscramble_all'
%        'left_wordVscramble_restrict'
%        'right_wordVscramble_restrict'
'leftVWFA'
'rightVWFA'
        }; 




% looping over rois
for jj = 1:length(tem.listRoi)

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

        % go to current subject's directory
        cd(list_sessionPath{iisub})

        % open hidden gray view
        tem.hg = initHiddenGray(1); 
        % tem.hg = initHiddenGray('Gray'); 

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
                rm.y0 = rm.y0*-1; 
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

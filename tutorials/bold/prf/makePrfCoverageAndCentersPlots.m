%% makes pRF coverage and centers plots
% bootstrapping for each person

%% General setup
clear all; close all; clc;

% load details
cd ('/biac4/wandell/data/reading_prf/forAnalysis/scripts/'); 
bookKeeping; 

%% modify here

% subjects to analyze
temAnalyze = [1:10, 12, 13]; 

% method of plotting prf plots
temMethodStr = 'sum';

% where to save plots
temSaveDir = '/biac4/wandell/data/reading_prf/forAnalysis/images/single/coveragesAndCenters/BootstrappingYes/'; 


%%  modify things here from time to time

% consider thresholding data based on voxel number of roi

% parameters for making prf coverage
vfc.prf_size        = true;      % if 0 will only plot the centers
vfc.fieldRange      = 12;        % radius of stimulus
vfc.method          = 'maximum profile';        % method for doing coverage.  another choice is density
vfc.newfig          = true;      % any value greater than -1 will result in a plot
vfc.nboot           = 200;       % number of bootstraps
vfc.normalizeRange  = true;      % set max value to 1
vfc.smoothSigma     = true;      % this smooths the sigmas in the stimulus space.  so takes the 
                                 % median of all sigmas within
vfc.cothresh        = 0.1;        
vfc.eccthresh       = [.5 12];  
vfc.nSamples        = 128;       % fineness of grid used for making plots     
vfc.meanThresh      = 0;         % threshold by mean map, no way to use this at the moment
vfc.weight          = 'fixed';  
vfc.weight          = 'variance explained';
vfc.weightBeta      = 0;         % weight the height of the gaussian
vfc.cmap            = 'jet';						
vfc.clipn           = 'fixed';                    
vfc.threshByCoh     = false;                
vfc.addCenters      = true;                 
vfc.verbose         = 1;         % print stuff or not
vfc.dualVEthresh    = 0;
vfc.binsize         = 0.5;


%% for each subject ...

for ii = 1:length(temAnalyze) 
    
    % navigate to subject directory
    iisub = temAnalyze(ii); 
    temPath = list_sessionPath{iisub}; 
    cd(temPath); 
    
    % start mrVista in Gray View
    vw = mrVista('3');  
    
    % get name of ret model
    temRmFile = [list_retModFolderPath{iisub} list_retModName{iisub}]; 
    
    % load retinotopic model
    % --  rmSelect([vw=current view], [loadModel=0], [rmFile=dialog]); 
    vw = rmSelect(vw, 1, temRmFile); 
        
    % decide group based on subject
    if iisub >= 10 
        temGroup = 1;  % rosemary subjects
    else
        temGroup = 2;  % andreas' subjects
    end
    
    % switch roi naming scheme based on group
    switch temGroup
        case 1 % rosemary's subjects
            temRoiName = {
                'left_wordVscramble_all'
                'right_wordVscramble_all'
                'left_wordVscramble_restrict'
                'right_wordVscramble_restrict'
            }; 

        case 2 % andreas' subjects
            temRoiName = {
                'left_WvWS_all'
                'right_WvWS_all'
                'left_WvWS_restrict'
                'right_WvWS_restrict'
                };
    end
    
    % get roi paths
    temRoiPaths = cell(length(temRoiName),1); 
    for jj = 1:length(temRoiName)
        temRoiPaths{jj,1} = [list_roiLocalPath{iisub} temRoiName{jj}];
    end
   
    % -- loadROI(vw, filename, [select], [color], [absPathFlag], [local=1])
    % VOLUME{end} = loadROI(VOLUME{end}, temRoiPaths, [], [], 1); 
    vw = loadROI(vw, temRoiPaths, [], [], 1); 
    
    % number of rois loaded
    temNumRois = length(temRoiName); 
      
    % load default settings for mapping purposes
    vw = rmLoadDefault(vw, 0);
    
    % FOR EACH ROI ------------------
         
    for jj = 1:temNumRois
               
        % change the selected ROI
        vw = viewSet(vw, 'selected ROI', jj); 
        
%         % plot prf centers
%         [~, temHCenter] = plotEccVsPhase(vw,1,0); 
%         % title
%         title([list_sub{iisub} ': ' vw.ROIs(vw.selectedROI).name], 'FontSize', 24, 'Interpreter', 'none');
%         % save the figure
%         temStr = [temSaveDir{1},list_sub{iisub}, '_center_', temRoiName{jj} , '.png']; 
%         saveas(temHCenter, temStr); 
%         close(temHCenter); 
        
        % plot prf coverage
        [~,temHCoverage] = rmPlotCoverage(vw,'prf_size',1,'method','max','normalizeRange',1,'fieldRange', 6, 'nboot', 200); 
        % title
        title([list_sub{iisub} ': ' vw.ROIs(vw.selectedROI).name],'FontSize', 24, 'Interpreter', 'none');
        % flip the y data
        % save the figure
        temStr = [temSaveDir{1}, temRoiName{jj},  '_coverage', list_sub{iisub}, '.png']; 
        saveas(temHCoverage, temStr); 
        close(temHCoverage); 
        
    end
    
    close all;
   
end


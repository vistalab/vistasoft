% dtiComputePlotDiffusionPropertiesAlongFiberGroup

% OVERVIEW:
% This script takes a group of subjects with a given fiber group(s) and set
% of ROIs and:
%   1. Loads the fibers and rois, as well as the dt6.mat file created
%      during preprocessing. 
%   2. Computes diffusion properties along the fiber group using
%      dtiComputeDiffusionPropertiesAlongFG. (see that function for more
%      info.
%   3. Saves out a structure (dtval) with the tensor values for 'fa','md',
%      'rd', and 'ad'.
%   4. Plots the data 
%   5. Saves the images to "saveDir"

% VARIABLES:
%   saveDir = the directory wherein the data and figures will be saved.
%   subs = the indetifying codes for each subject in your directory.
%         (e.g., {subs = 'sub1','sub2','sub3'...})
%   baseDir = the level of your directory structure that has your data at
%             the first level.
%   dirs = the name of the directory that contains each subject's dt6.mat
%          file - usually named for the number of diffusion directions.
%   fgName = cell array containg the names of each fiber group you wish to
%            compute properties for.
%   rois = cell array containing the names of the first of 2 rois used to 
%          generate the fibers in fgName. NO FILE EXTENSIONS
%   roi2 = cell array containing the names of the second of 2 rois used to 
%          generate the fibers in fgName. NO FILE EXTENTIONS
%   plotNames = a cell array contining one name for each fiber group, which
%               will be the name for each plot associated with that fiber
%               group.
%   numberOfNodes = the number of steps along the fg at which properties
%                   will be computed.
%   propertyofinterest = the properties that will be computed for each
%                        group.

% NOTES:
%  You will have to set variables in the first two sections. If  you have a
%  probelm with data not being found check the directory structure within the
%  loop. 

%  You must provide the ROIs in rois and rois2 that were used to track the
%  fibers in fgName. 
%   For example, if you used roiA and roiB to track fibergroup AB in
%   contrack, then the cell arrays should look like:
%       fgName  = {'fibergroupAB.pdb'};
%       rois    = {'roiA'};
%       rois2   = {'roiB'};

%  The name in the rois cell array will be used for naming the figures.
%  This can be changed in sections IV - VI if you don't wish to use this
%  default behavior.

% HISTORY:
% 2011.1.10 - LMP wrote the code. 


%% I. Set directories, rois and plot names

saveDir = '/path/to/your/data/directory';
           if ~exist(saveDir,'file'), mkdir(saveDir); end
	
subs    = {'sub1','sub2','sub3'};
baseDir = '/path/to/your/subjects"/data/';
dirs    = 'dti06trilinrt';
	
fgName  = {'fibergroupAB.pdb','fibergroupCD.pdb'};
rois    = {'roiA','roiC'};
rois2   = {'roiB','roiD'};

plotName = {'Fiber Group AB Plot Name','Fiber Group CD Plot Name'};


%% II. Set up parameters

numberOfNodes      = 50; 
propertyofinterest = {'fa','md', 'rd', 'ad'};
roi1name           = rois;
roi2name           = rois2;

%% III Loop over subjects and compute fiber properties
wb = mrvWaitbar(0,'Overall Script Progress');
for zz = 1:numel(propertyofinterest)
    for kk = 1:numel(fgName)     
        for ii=1:numel(subs)
            sub      = dir(fullfile(baseDir,[subs{ii} '*']));
            subDir   = fullfile(baseDir,sub.name);
            dt6Dir   = fullfile(subDir,dirs);
            fiberDir = fullfile(dt6Dir,'fibers','conTrack');
            roiDir   = fullfile(dt6Dir,'ROIs');
            try
                % III. 1 LOAD THE DATA
                fibersFile = fullfile(fiberDir,fgName{kk});
                fg         = mtrImportFibers(fibersFile);
                roi1File   = fullfile(roiDir, [roi1name{kk} '.mat']);
                roi2File   = fullfile(roiDir, [roi2name{kk} '.mat']);
                roi1       = dtiReadRoi(roi1File);
                roi2       = dtiReadRoi(roi2File);
                dt         = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

                % III. 2 Compute
                [fa(:, ii),md(:, ii),rd(:, ii),ad(:, ii)]=...
                    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes);
            catch ME
                disp(ME.message);
                disp(['PROBLEM loading data for subject: ' subs{ii} '. This subject will NOT be included in the graph!']);
            end
        end
        dtval.(propertyofinterest{zz}).(rois{kk}) = eval(propertyofinterest{zz});
        
    end
mrvWaitbar(zz/(numel(propertyofinterest)),wb);

end
save((fullfile(saveDir,'dtval.mat')),'dtval');

%% PLOT DATA

%% IV Plot results: Average for each roi.

load(fullfile(saveDir,'dtval.mat'));

    for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
        for kk = 1:numel(rois)
            
            AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);

            figure;
            hold on
            plot(AVG,'b','LineWidth',5);
            set(gca,'PlotBoxAspectRatio',[1,.7,1]);
                    
           switch propertyofinterest{zz}
                case 'fa'
                    yText = 'FA (weighted)';
                    titleText = ['Fractional Anisotropy Along ' plotName{kk}];
                case 'md'
                    yText = 'MD \mum^2/msec (weighted)';
                    titleText = ['Mean Diffusivity Along ' plotName{kk}];
                case 'rd'
                    yText = 'RD \mum^2/msec (weighted)';
                    titleText = ['Radial Diffusivity Along ' plotName{kk}];
                case 'ad'
                    yText = 'AD \mum^2/msec (weighted)';
                    titleText = ['Axial Diffusivity Along ' plotName{kk}];
            end

            title(titleText);
            ylabel(yText);
            xlabel('Fiber Group Trajectory');
            set(gca,'xtick',[0 numberOfNodes]);
            set(gca,'xticklabel',{rois{kk},rois2{kk}})
            saveName = [plotName{kk} '_' propertyofinterest{zz}];
            saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
            hold off
        end
    end


%% V Plot results: Each fiber group on the same grapgh.

load(fullfile(saveDir,'dtval.mat'));
col = jet(numel(rois)); % set colors for graph.

    for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
        figure;
        for kk = 1:numel(rois)
            
            AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);          

            hold on
            plot(AVG,'LineWidth',5,'color',col(kk,:));
            set(gca,'PlotBoxAspectRatio',[1,.7,1]);
                    
            switch propertyofinterest{zz}
                case 'fa'
                    yText = 'FA (weighted)';
                    titleText = ['Fractional Anisotropy'];
                case 'md'
                    yText = 'MD \mum^2/msec (weighted)';
                    titleText = ['Mean Diffusivity'];
                case 'rd'
                    yText = 'RD \mum^2/msec (weighted)';
                    titleText = ['Radial Diffusivity'];
                case 'ad'
                    yText = 'AD \mum^2/msec (weighted)';
                    titleText = ['Axial Diffusivity '];
            end

            title(titleText);
            ylabel(yText);
            xlabel('Fiber Group Trajectory');
                        
        end
            set(gca,'xtick',[0 numberOfNodes]);
            set(gca,'xticklabel',{rois{kk},rois2{kk}})
            ld = legend(plotName{:});
            set(ld,'Interpreter','tex','Location','NorthEast');
            saveName = [propertyofinterest{zz} '_allGroups'];
            saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
    end
    
    
    
%% VI Plot results for each roi sorted by subject

load(fullfile(saveDir,'dtval.mat'));

col = jet(numel(subs)); % set colors for graph.

for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
    for kk = 1:numel(rois)

        AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);

        figure;
        hold on
        % Loop over each subject and plot their data using a different color line (col)
        for ss = 1:numel(subs)
            plot(dtval.(propertyofinterest{zz}).(rois{kk})(:,ss),'color',col(ss,:));
        end
        ld = legend(subs{:});
        set(ld,'Interpreter','tex','Location','NorthEastOutSide');
        plot(AVG,'g','LineWidth',5);
        set(gca,'PlotBoxAspectRatio',[1,.7,1]);

        switch propertyofinterest{zz}
            case 'fa'
                yText = 'FA (weighted)';
                titleText = ['Fractional Anisotropy Along ' plotName{kk}];
            case 'md'
                yText = 'MD \mum^2/msec (weighted)';
                titleText = ['Mean Diffusivity Along ' plotName{kk}];
            case 'rd'
                yText = 'RD \mum^2/msec (weighted)';
                titleText = ['Radial Diffusivity Along ' plotName{kk}];
            case 'ad'
                yText = 'AD \mum^2/msec (weighted)';
                titleText = ['Axial Diffusivity Along ' plotName{kk}];
        end

        title(titleText);
        ylabel(yText);
        xlabel('Fiber Group Trajectory');
        set(gca,'xtick',[0 numberOfNodes]);
        set(gca,'xticklabel',{rois{kk},rois2{kk}});
        whitebg;       
        saveName = [plotName{kk} '_' propertyofinterest{zz} '_SUBJECT_avgLine'];
        saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
    end
end
close(wb)
close all
    
    
    
    
    
    
    
    
    
    
    

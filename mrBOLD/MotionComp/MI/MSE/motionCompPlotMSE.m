function MSE = motionCompPlotMSE(view,ROIName,plotMSE,axe,dlg)    
%
%    MSE = motionCompPlotMSE(view,ROIName,plotMSE,axe,dlg)
%
%  gb 04/24/05
%
% Loads the Mean Squared Error between consecutive frames for the subject, the data type specified
% in the variable view, and the Region Of Interest concerned or computes it if it has not been computed yet.
% 
% Inputs:
%   - view: current inplane view
%   - ROIName: string containing the name of the ROI
%   - plotMSE: set it to 1 if you want a graph to be plotted
%   - axe: set it to 1 if there is already an existing axe
%   - dlg: set it to 1 if you want to show a dialog box before computing the error

% Initializes arguments and variables
if ieNotDefined('plotMSE')
    plotMSE = 1;
end

if ieNotDefined('ROIName')
    ROIName = '';
end

if strcmp(ROIName,'selected')
    ROInum = view.selectedROI;
    if ROInum == 0
        ROIName = '';
    else
        ROIName = view.ROIs(ROInum).name;
    end
end

if ieNotDefined('axe')
    axe = 0;
end

if ieNotDefined('dlg')
    dlg = 0;
end

if isstr(view)
    scans = 1:6;
    nFrames = 78;
    curType = 'Original';
    subject = view;
    pathDir = fullfile('Inplane','Original');
else
	global HOMEDIR dataTYPES
	cd(HOMEDIR)

    scans = 1:numberScans(view);
	nFrames = numberFrames(view,scans(1));
	subject = view.sessionCode;
	
	curDataType = viewGet(view,'currentDataType');
	curType = dataTYPES(curDataType).name;
    
    pathDir = dataDir(view);
end

% Tries to load the file containing the MSE error
% The name of this file is: MSE_subject_dataType.mat

if ieNotDefined('ROIName')
    pathMSE = fullfile(pathDir,['MSE_' subject '_' curType '.mat']);
else
    pathMSE = fullfile(pathDir,['MSE_' subject '_' curType '_' ROIName '.mat']);
end

if exist(pathMSE,'file')
    load(pathMSE);
else

    if dlg
        button = questdlg(['The MSE error for this ROI has not been computed yet.'...
            ' Would you like to compute it now ?'],'MSE','Yes','No','Yes');
        if strcmp(button,'No')
            return
        end
    end
    
    % A ROI called ROIdef is used whenever the rigid transformation has
    % been called to create this dataType. It avoids the region where the
    % data is zero in order to have a coherent value of the MSE. For
    % example if the reference scan is Scan 1 and the vector of the rigid transformation
    % is on the z axis 1 slice down, the ROIdef will be all the voxels
    % between slice 2 and slice 26. The error computed between scan 1 and
    % scan 2 will be much more consistent.
    
    % Loads the ROI
    if ~ieNotDefined('ROIName')
        ROI = motionCompGetROI(view,ROIName);
    else
        ROI = '';
    end
    
    % Computes the Mean Squared Error
    MSE = motionCompDetectMotionMSE(view,ROI,scans);
end

% Clips the histogram to avoid taking into account peaks in the computation of the mean and
% the standard deviation
histogramClip = 0.9;
histClip = mrAnatHistogramClip(MSE,0,histogramClip,0);

mn = mean(histClip);
sd =  std(histClip);

% Plots the result
if plotMSE
    if ~axe
    	figure
        hold on
	
        if ieNotDefined('ROIName')
               title(['MSE for subject: ' subject ', data type: ' curType]);
        else
		    title(['MSE for subject:' subject ', data type: ' curType ' and ROI: ' ROIName]); 
        end
    else
        set(gcf,'currentaxes',axe);
        hold off
    end
        
	plot(MSE)
	hold on
	plot(1:length(MSE),mn*ones(1,length(MSE)),'-.')
	plot([1 length(MSE)],[mn + 2*sd, mn + 2*sd],'r')
 
	for scanIndex = 1:(length(scans) - 1)
        plot([nFrames*scanIndex nFrames*scanIndex],[min(MSE) max(MSE)],'-.','Color','m');
	end
end

% Saves the result if it just has been computed
if ~exist(pathMSE,'file')
    save(pathMSE,'MSE');
end
function MI = motionCompPlotMI(view,ROIName,plotMI,axe,dlg)
%
%    MI = motionCompPlotMI(view,plotMI,ROIName,axe)
%
%  gb 04/24/05
%
% Loads the Mutual Information between consecutive frames for the subject, the data type specified
% in the variable view, and the Region Of Interest concerned or computes it if it has not been computed yet.
% 
% Inputs:
%   - view: current inplane view
%   - ROIName: string containing the name of the ROI
%   - plotMI: set it to 1 if you want a graph to be plotted
%   - axe: set it to 1 if there is already an existing axe
%   - dlg: set it to 1 if you want to show a dialog box before computing the error


% Initializes arguments and variables
if ieNotDefined('plotMI')
    plotMI = 1;
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

% Tries to load the file containing the Mutual Information
% The name of this file is: MI_subject_dataType.mat
if ieNotDefined('ROIName')
    pathMI = fullfile(pathDir,['MI_' subject '_' curType '.mat']);
else
    pathMI = fullfile(pathDir,['MI_' subject '_' curType '_' ROIName '.mat']);
end

if exist(pathMI,'file')
    load(pathMI);
else

    if dlg
        button = questdlg(['The MI for this ROI has not been computed yet.'...
            ' Would you like to compute it now ?'],'MI','Yes','No','Yes');
        if strcmp(button,'No')
            return
        end
    end
    
    % A ROI called ROIdef is used whenever the rigid transformation has
    % been called to create this dataType. It avoids the region where the
    % data is zero in order to have a coherent value of the MI. For
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
    
    % Computes the Mutual Information
    MI = motionCompDetectMotionMI(view,ROI,scans);
end

% Clips the histogram to avoid taking into account peaks in the computation of the mean and
% the standard deviation
histogramClip = 0.9;
histClip = mrAnatHistogramClip(MI,0,histogramClip,0);

mn = mean(histClip);
sd =  std(histClip);

% Plots the result
if plotMI
	if ~axe
        figure
        hold on
	
        if ieNotDefined('ROIName')
            title(['MI for subject: ' subject ', data type: ' curType]); 
        else
            title(['MI for subject: ' subject ', data type: ' curType ' and ROI: ' ROIName]); 
        end
    else
        set(gcf,'currentaxes',axe);
        hold off
    end
    
	plot(MI)
	hold on
	plot(1:length(MI),mn*ones(1,length(MI)),'-.')
	plot([1 length(MI)],[mn - 2*sd, mn - 2*sd],'r')
	    
	for scanIndex = 1:(length(scans) - 1)
        plot([nFrames*scanIndex nFrames*scanIndex],[min(MI) max(MI)],'-.','Color','m');
	end
end

% Saves the result if it just has been computed
if ~exist(pathMI,'file')
    save(pathMI,'MI');
end
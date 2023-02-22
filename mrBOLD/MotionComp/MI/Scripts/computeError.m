%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    gb 05/17/05
%
% This script has to be executed directly in the command line
% It computes the MSE and the MI for the current Inplane.
%
% For each data type, it tries to compute 3 errors:
%       - Total error (without ROI)
%       - Error with the ROIdef
%       - Error with the ROI associated with this data type
%
% If it does not find the ROI concerned, it skips to the next computation.
%
% example:
%
%   close all
%   clear all
%   mrVista
%   vw = getSelectedInplane;
%   computeError
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global dataTYPES

for i = 1:length(dataTYPES)
    vw = viewSet(vw,'currentDataType',i);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The data Type 'Preprocessed' contains 468 frames in one scan (instead of 78)
    % The error cannot be calculated this way because of a lack of memory.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(dataTYPES(i).name(1:2),'Pr')
        continue
    end
      
    % Computes the total error
    motionCompPlotMSE(vw,'',0);
    motionCompPlotMI(vw,'',0);
    
    if i == 1
        % If the data type is Original, computes all the possible errors
        ROInames = dir(roiDir(vw));
        
        for j = 3:length(ROInames)
            ROIname = ROInames(j).name(1:end - 4);
            motionCompPlotMSE(vw,ROIname,0);
            motionCompPlotMI(vw,ROIname,0);
        end
        
    else
       % Computes the 2 other errors explained in the head comment
        if exist(fullfile(roiDir(vw),'ROIdef.mat'),'file')
			motionCompPlotMSE(vw,'ROIdef',0);
			motionCompPlotMI(vw,'ROIdef',0);
        end
        
        ROIname = ['ROI_' dataTYPES(i).name];
  
        if exist(fullfile(roiDir(vw),[ROIname '.mat']),'file')
            motionCompPlotMSE(vw,ROIname,0);
            motionCompPlotMI(vw,ROIname,0);
        end
    end
		
end
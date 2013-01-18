function [h,anal] = timeCourseUI4Multi(view,voxels,scans,series);
%   [h,anal] = timeCourseUI4Mutli(view,[voxels,scans,series])
%
% timeCourseUIMulti: user interface for displaying mrLoadRet time course
% data for individual voxels from an ROI
%
% This is written to complement (and eventually, incorporate) the
% functionality of my plotting tools for time courses from
% rapid event-related data. This is more general: it covers
% block-design, long event-related, and other conditions, and
% importantly incorporates information from .par files.
%
% ARGS:
% input:
%       view: mrVista view struct
%        
%       voxels: coords (by the current view's conventions) of the voxels
%       from which to plot data. May also be a string providing the name of
%       the ROI to plot. Default is view's currently-selected ROI.
%
%       scans: scans in the current view/data series to plot. Default is
%       currently-selected scan. For multiple scans, will concatenate
%       together after detrending (using the detrend options saved in the
%       dataTYPES struct in the mrSESSION file).
%
%       series: data series to use. Defaults to currently selected data
%       type.
%
%output:
%       h: handle to time course interface.
%       
%       data: array containing time course data from selected voxels/scans.
%
% More notes:
% This is currently implemented as a small set of linked analysis tools,
% all starting with the prefix 'tc_'. This particular piece of code
% decides, based on the number of input args, whether to open a new
% tc user interface or just update an existing one, and then refreshes the 
% current tc view according to the time course data and user prefs.
%
% Here's how it decides to open a new UI or not: if a view is passed as the
% first argument, it opens a new one. If there are no input args, it
% assumes the current figure has the interface and refreshes it. (This is
% called by all the callbacks on the interface).
% 
% The time course data, condition information, user prefs, and handles to 
% important controls are all kept in a tc struct stored in the user
% interface's 'UserData' field. I currently treat each UI as a separate
% figure; though in time I may find it useful to group several interfaces
% on multiple axes in the same figure.

% 1/3/04 ras: wrote it.
% 1/04: added signal to noise ratios, ability to switch off different cond
% displays, shift onsets, change colors
% 2/04: added ability to read multiple scans / concat parfiles if it uses
% them
% 2/23/04: broke up into several functions, under mrLoadRet sub-section
% Plots/TimeCourseUI. Also made an offshoot of this, fancyplot2, which
% doesn't use the mrLoadRet view info, for kalanit. Renamed timeCourseUI
% (previously ras_tc -- saved that as an older, stable version).
global dataTYPES

if nargin >= 1
    updateFlag = 1;
else
    updateFlag = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1ST DECISION: extract new time course data (w/ corresponding
% axes figure) or just re-render existing data? This is decided by 
% the # args: if 1, update data; otherwise, just render.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if updateFlag
    if ~exist('series','var') | isempty(series)
        series = view.curDataType;
    end
    
    if ~exist('scans','var') | isempty(scans(1))
        scans = getCurScan(view);
    end
    
    if ~exist('voxels','var') | isempty(voxels)
        r = view.selectedROI;
        if r==0
            myErrorDlg('Sorry, you need to load an ROI first.')
            return
        end
        voxels = view.ROIs(r).coords;
        ROIname = view.ROIs(r).name;
    else
        if ischar(voxels)  
            % assume name of ROI
            ROIname = voxels;
            view = selectROI(view,ROIname);
            r = view.selectedROI;
            voxels = view.ROIs(r).coords;
        else
            % Coords are directly specified -- no name per se
            if size(voxels,2)==1
                ROIname = sprintf('Point %i, %i, %i',voxels(1),voxels(2),voxels(3));
            else
                ROIname = '(Multiple selected points)';
            end
        end
    end
    
    h = tc_openFig(view,voxels,scans,series,ROIname);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RENDER TIME COURSE (taking into account prefs as specified in the
% ui)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the data struct -- in the current axes' UserData
tc = get(gcf,'UserData');

% clear previous axes in the figure
old = findobj('Type','axes','Parent',gcf);
old = [old; findobj('Type','uicontrol','Parent',gcf)];
delete(old);

% legend (kind of a hack -- legends are tricky)
if tc.settings.legend==1
    sel = find(tc_selectedConds(tc));
    co = [];
    for i = 1:length(sel)
        % The legend text should be the specified condition names
        leg{i} = tc.condNames{sel(i)};
        % remove underscores -- the teX interpreter is weird about em
        leg{i}(findstr(leg{i},'_')) = ' ';
        % also get appropriate colors
        co = [co; tc.condColors{sel(i)}];
    end
    set(gca,'NextPlot','ReplaceChildren');
    if length(sel) > 0
        % Plot some random data, just to get the legend put up        
        set(gca,'ColorOrder',co);
        plot(rand(2,length(sel)),'LineWidth',4); 
        legend(gca,leg,-1);
    end
end

% parse the preferences set using the ui, and plot
if isequal(get(tc.ui.plotWholeTc,'Checked'),'on')
    tc.plotType = 1; 
    tc_plotWholeTc(tc);    
elseif isequal(get(tc.ui.plotAllTrials,'Checked'),'on')
    tc.plotType = 2;
    tc_plotSubplots(tc,0); % tc_plotAllTrials(tc);    
elseif isequal(get(tc.ui.plotMeanTrials,'Checked'),'on')
    tc.plotType = 3;
    tc_plotMeanTrials(tc);
elseif isequal(get(tc.ui.plotRelAmps,'Checked'),'on')
    tc.plotType = 4;
    tc_plotRelamps(tc);
elseif isequal(get(tc.ui.plotMeanAmps,'Checked'),'on')
    tc.plotType = 5;
    tc_barMeanAmplitudes(tc);
elseif isequal(get(tc.ui.meanSubplots,'Checked'),'on')
    tc.plotType = 6;
    tc_plotSubplots(tc);
elseif isequal(get(tc.ui.plotDesMtx,'Checked'),'on')
    tc.plotType = 7;
    tc_plotDesMtx(tc);
elseif isequal(get(tc.ui.plotGLMPredictors,'Checked'),'on')
    tc.plotType = 8;
    tc_plotGLMPredictors(tc);
else
    tc.plotType = 9;
    tc_plotGLMAmplitudes(tc);
end

% stash the updated data struct
set(gcf,'UserData',tc);

return
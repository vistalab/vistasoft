function view = motionCompCompareDataTypes(view);
%
%    gb 05/16/05
%
% Interface enabling to compare the MSE and MI graphs for a given subject.
% The user will able to change the data types and the wanted ROI.
%
global dataTYPES HOMEDIR

nScans = numberScans(view);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creating the figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xs = 1.8;
ys = 1.8;

botMargin = 0.2;
butWidth = 8;
editWidthY = 1.4;
fontSize = 9;

height1 = 20;
height2 = 2;
heightEdge = 3;
heightSep = 3;
height = height1 + height2 + heightSep + 2*heightEdge;

width1 = 35;
width2 = 35;
widthSep = 7;
widthEdge = 5;
width = width1 + width2 + widthSep + 2*widthEdge;

h = figure('MenuBar','none',...
    'Name','Compare data types',...
    'Units','char',...
    'Resize','off',...
    'NumberTitle','off',...
    'Position',[60,(60 - height*ys), width*xs,height*ys]);

hControl = cell(1,9);

x = widthEdge;
y = heightEdge + height1 + heightSep + height2;

uicontrol('Style','frame',...
    'Units','char',...
    'String','Choose a display mode',...
    'Position',[x*xs,(y+.2)*ys,(width1-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String','Choose a display mode',...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width1-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

x = widthEdge + width1/2;
y = heightEdge + height1 + heightSep + height2 - 2;

compare = {'MSE','MI','Tab MSE','Tab MI'};
hControl{1} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',compare,...
                'Position',[(x - 8)*xs,y*xs,16*xs,2*editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'Callback','uiresume');

x = widthEdge + width1 + widthSep;
y = heightEdge + height1 + heightSep + height2;

uicontrol('Style','frame',...
    'Units','char',...
    'String','ROI',...
    'Position',[x*xs,(y+.2)*ys,(width1-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String','ROI',...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width1-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

x = widthEdge + width1 + widthSep + width2/2;
y = heightEdge + height1 + heightSep + height2 - 2;


ROInames = {'None'};
for i = 1:length(view.ROIs)
    ROInames = [ROInames,{view.ROIs(i).name}];
end
ROIfiles = dir(roiDir(view));

for i = 3:length(ROIfiles)
    if isempty(find(strcmp(ROInames,ROIfiles(i).name(1:end - 4))))
        ROInames = [ROInames, {ROIfiles(i).name(1:end - 4)}];
    end
end

hControl{8} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',ROInames,...
                'Position',[(x - 8)*xs,y*xs,16*xs,2*editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'Callback','uiresume');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = widthEdge;
y = height1 + heightEdge;

uicontrol('Style','frame',...
    'Units','char',...
    'String','Data Type 1',...
    'Position',[x*xs,(y+.2)*ys,(width1-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String','Data Type 1',...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width1-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

dataNames = {};
for i = 1:length(dataTYPES)
    dataNames = [dataNames,{dataTYPES(i).name}];
end

x = x + width1/2;
y = y - 1.5;
hControl{2} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',dataNames,...
                'Position',[(x - width1/4 - 1)*xs,(y)*xs,(width1/2)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'Callback','uiresume');
          
hControl{3} = axes;
set(hControl{3},'Units','char',...
    'Position',[widthEdge*xs,heightEdge*ys,(width1 - botMargin)*xs,(height1 - 3)*ys]);

hControl{6} = uicontrol('Style','text',...
                'Units','char',...
                'String','',...
                'Position',[widthEdge*xs,heightEdge*ys,(width1 - botMargin)*xs,(height1 - 3)*ys],...
                'HorizontalAlignment','left',...
                'FontSize',fontSize,...
                'Callback','uiresume');

x = widthEdge + width1 + widthSep;
y = height1 + heightEdge;

uicontrol('Style','frame',...
    'Units','char',...
    'String','Data Type 2',...
    'Position',[x*xs,(y+.2)*ys,(width2-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String','Data Type 2',...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width2-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

x = x + width2/2;
y = y - 1.5;
hControl{4} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',dataNames,...
                'Position',[(x - width2/4 - 1)*xs,(y)*xs,(width2/2)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'Callback','uiresume');
          
hControl{5} = axes;
set(hControl{5},'Units','char',...
    'Position',[(widthEdge + width1 + widthSep)*xs,heightEdge*ys,width2*xs,(height1 - 3)*ys]);

hControl{7} = uicontrol('Style','text',...
                'Units','char',...
                'String','',...
                'Position',[(widthEdge + width1 + widthSep)*xs,heightEdge*ys,width2*xs,(height1 - 3)*ys],...
                'HorizontalAlignment','left',...
                'FontSize',fontSize,...
                'Callback','uiresume');

x = width - widthEdge - butWidth;
y = heightEdge/2 - 1;
uicontrol('Style','pushbutton',...
            'String','OK',...
            'Units','char',...
            'Position',[x*xs,y*ys,butWidth*xs,ys],...
            'CallBack','uiresume',...
            'FontSize',fontSize,...
            'UserData','OK');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
% Update the parameters specified by the user
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
response = '';
while ~strcmp(response,'OK')

    try
        [displayMode,dataType1,dataType2,ROIname] = updateHControl(view,hControl);
    catch   
        return
    end
        
    refreshAxes(view,hControl,dataType1,hControl{3},hControl{6},ROIname,displayMode);
    axis1 = axis;
    
    refreshAxes(view,hControl,dataType2,hControl{5},hControl{7},ROIname,displayMode);
    axis(axis1);
    
    uiwait
    
    % determine which button was hit.
    response = get(gco,'UserData');
        
end

close(h)

% /------------------------------------------------------------------------------/ %
function refreshAxes(view,hControl,dataType,axe,text,ROIname,actionID)
%
% Updates what is shown on the figure. It can be a plot of a curve or a
% computation of errors only between mean maps
global HOMEDIR
view = viewSet(view,'currentDataType',dataType);
dataNames = get(hControl{2},'String');

switch actionID
    case 1
		motionCompPlotMSE(view,ROIname,1,axe,1);

        set(axe,'Visible','On');
        set(text,'Visible','Off');

    case 2
        motionCompPlotMI(view,ROIname,1,axe,1);
        
        set(axe,'Visible','On');
        set(text,'Visible','Off');
      
    case 3
        pathMap = fullfile(HOMEDIR,'Inplane',dataNames{dataType},'meanMap.mat');
        if ~exist(pathMap,'file')
            button = questdlg(['The Mean Maps of this dataType have not been computed yet.'...
                ' Would you like to compute them now ?'],'MSE','Yes','No','Yes');
            if strcmp(button,'Yes')
                view = computeMeanMap(view,0);
                view=setDisplayMode(view,'map');
            end
        end
        
        if exist(pathMap,'file')
            load(pathMap);
            ROI = motionCompGetROI(view,ROIname);
            tab = motionCompMeanMSE(map,ROI);
            tabStr = motionCompPrintTab(tab);
                    
            set(axe,'Visible','Off');
            set(text,'String',sprintf(tabStr),'Visible','On');
        end
        
    case 4
        pathMap = fullfile(HOMEDIR,'Inplane',dataNames{dataType},'meanMap.mat');
        if ~exist(pathMap,'file')
            button = questdlg(['The Mean Maps of this dataType have not been computed yet.'...
                ' Would you like to compute then now ?'],'MSE','Yes','No','Yes');
            if strcmp(button,'Yes')
                view = computeMeanMap(view,0);
                view = setDisplayMode(view,'map');
            end
        end
        
        if exist(pathMap,'file')
            load(pathMap);
            ROI = motionCompGetROI(view,ROIname);
            tab = motionCompMeanMI(map,ROI);
            tabStr = motionCompPrintTab(tab);
        
            set(axe,'Visible','Off');
            set(text,'String',sprintf(tabStr),'Visible','On');
        end
        
end
        
        

% /------------------------------------------------------------------------------/ %
function [displayMode,dataType1,dataType2,ROIname] = updateHControl(view,hControl);
%
% Update the parameters of the figure
%

displayMode = get(hControl{1},'Value');
dataType1 = get(hControl{2},'Value');
dataType2 = get(hControl{4},'Value');

ROInum = get(hControl{8},'Value');
ROInames = get(hControl{8},'String');
ROIname = ROInames{ROInum};

if strcmp(ROIname,'None')
    ROIname = '';
end
return

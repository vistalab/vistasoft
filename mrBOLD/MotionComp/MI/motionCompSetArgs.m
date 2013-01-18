function vw = motionCompSetArgs(vw)
%
%   gb 14/04/05
%
%   vw = motionCompSetArgs(vw)
%
% Runs an interface to set the arguments of motionCompMutualInfMeanInit
% Also computes the MSE and the MI between consecutive frames of the new
% dataType.
%
global dataTYPES HOMEDIR

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creates the figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nScans = numberScans(vw);
nTrans = 4;

xs = 1.8;
ys = 1.8;

botMargin = 0.2;
butWidth = 8;
editWidthY = 1.4;
fontSize = 9;

height11 = nTrans + 2 + botMargin*2 + .5;
height21 = nScans + 2 + botMargin*2 + .5;
heightEdge = 1;
heightSep = 2;
height = height11 + height21 + heightSep + 2*heightEdge;

width1 = 22;
width2 = 22;
width3 = 35;
widthAlgo = width1;
widthSep = 5;
widthEdge = 1;
width = width1 + width2 + width3 + 2*widthSep + 2*widthEdge;

h = figure('MenuBar','none',...
    'Name','Choose parameters of the transformation',...
    'Units','char',...
    'Resize','off',...
    'NumberTitle','off',...
    'Position',[60,(60 - height*ys), width*xs,height*ys]);

hControl = cell(1,9);

scanNames = {};
for i = 1:nScans
    scanNames = [scanNames,{['Scan' num2str(i)]}];
end
hControl{1} = fillFigure('Scans',scanNames,h,widthEdge,height11 + heightSep + heightEdge,width1);

hControl{2} = fillFigure('Algorithms',{'Rigid (MI)','Non linear (MSE)','Apply GLM','Consecutive frame error'},...
    h,widthEdge,heightEdge,widthAlgo,'',0);

scanNames = [scanNames,{'Anatomy'}];
x = widthEdge + width1 + widthSep;
y = height11 + heightSep + heightEdge + nScans;
fillFigure('BaseScan',{},h,x,y,width2,'',0);
hControl{3} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',scanNames,...
                'Position',[(x + widthSep)*xs,(y)*xs,(width1 - 2*widthSep)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize);

y = y - nScans;
fillFigure('Original data type name',{},h,x,y,width2,'',0);
dataNames = {};
for i = 1:length(dataTYPES)
    dataNames = [dataNames,{dataTYPES(i).name}];
end

hControl{4} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',dataNames,...
                'Position',[(x + widthSep)*xs,(y)*xs,(width1 - 2*widthSep)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize);

y = heightEdge + nTrans;
fillFigure('New data type name',{},h,x,y,width2,'',0);

hControl{5} = uicontrol('Style','edit',...
                'Units','char',...
                'String','',...
                'Position',[(x + widthSep)*xs,(y)*xs,(width1 - 2*widthSep)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'Enable','Off');
            
x = widthEdge + width1 + width2 + 2*widthSep;
y = height11 + heightSep + heightEdge + nScans;
fillFigure('ROI',{},h,x,y,width3,'',0);

ROInames = {'None','ROIocc','ROIfront'};
for i = 1:length(vw.ROIs)
    ROInames = [ROInames,{vw.ROIs(i).name}];
end
ROIfiles = dir(roiDir(vw));
for i = 3:length(ROIfiles)
    if isempty(find(strcmp(ROInames,ROIfiles(i).name(1:end - 4)), 1))
        ROInames = [ROInames, {ROIfiles(i).name(1:end - 4)}];
    end
end


hControl{6} = uicontrol('Style','popupmenu',...
                'Units','char',...
                'String',ROInames,...
                'Position',[(x + widthSep)*xs,(y)*xs,(width1 - 2*widthSep)*xs,editWidthY],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize);

x = width - widthEdge - width3/2;
nSlices = numberSlices(vw);
hControl{7} = createSlider('Slice',[(x + widthSep/2)*xs y*ys (width3/2 - 3/2*widthSep)*xs editWidthY],[1 nSlices]);

x = widthEdge + width1 + width2 + width3/4;
y = heightEdge + heightSep;
hControl{8} = gca;
set(hControl{8},'Units','char');
set(hControl{8},'Position',[(x + widthSep)*xs,(y)*xs,(width3 - 2*widthSep)*xs,(nScans + nTrans + heightSep - 2*botMargin)*ys]);   

str = [vw.ui.displayMode,'Mode'];
modeStr=['vw.ui.',str];
mode = eval(modeStr);
cmap = mode.cmap;
numGrays = mode.numGrays;
numColors = mode.numColors;
clipMode = mode.clipMode;

% image(vw.ui.image);
% colormap(cmap);
% axis image;
% axis off;

x = widthEdge + width1 + width2 + width3 - butWidth - botMargin;
y = heightEdge + botMargin;
uicontrol('Style','pushbutton',...
    'String','Cancel',...
    'Units','char',...
    'Position',[x*xs,y*ys,butWidth*xs,ys],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','Cancel');

x = x - butWidth - widthEdge;
hControl{9} = uicontrol('Style','pushbutton',...
                'String','OK',...
                'Enable','Off',...
                'Units','char',...
                'Position',[x*xs,y*ys,butWidth*xs,ys],...
                'CallBack','uiresume',...
                'FontSize',fontSize,...
                'UserData','OK');

hControl{10} = 0;
            
for i = 1:(length(hControl) - 3)
    for j = 1:length(hControl{i})
        set(hControl{i}(j),'CallBack','uiresume');
        set(hControl{i}(j),'UserData','Update');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Loop
%
% Update the arguments whenever the user adds 
% something to the figure
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

response = 'Update';
while strcmp(response,'Update')
    uiwait

    % determine which button was hit.
    response = get(gco,'UserData');
    
    if isempty(response)
        close(get(0,'currentFigure'));
        fprintf('Motion Compensation Canceled by the user');
        return;
    end
    
    try
        if strcmp(get(gco,'Style'),'edit')
            hControl{end} = 1;
        end
    end

    % Update the arguments
    [scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear,glmIndex,consError] = updateHControl(vw,hControl);
    
    % Update the new slice showed. If an ROI has been loaded, loads a slice
    % where the ROI is not zero.
    if ~ieNotDefined('ROI')
        if sum(sum(abs(ROI(:,:,get(hControl{7}(1),'Value'))))) == 0
            mn = mean(mean(ROI,1),2);
            displaySlices = find(mn > 0);
            [minimum,index] = min(abs(displaySlices - get(hControl{7}(1),'Value')));
            if ~isempty(displaySlices)
                set(hControl{7}(1),'Value',displaySlices(index));
                set(hControl{7}(2),'String',num2str(displaySlices(index)));
            else
                msgBox('This ROI is empty!','Warning!');
            end
        end
    end
    
    vw = viewSet(vw, 'Current Slice', get(hControl{7}(1),'Value'));
    
    % Recomputes the shown image
    vw = recomputeImage(vw,numGrays,numColors,clipMode);
    
    size1 = sliceDims(vw,1);
    size2 = size(vw.anat);
    T = maketform('affine',[size2(2)/size1(2) 0 0; 0 size2(1)/size1(1) 0; 0 0 1]);

    im = vw.ui.image;
    
    if ~ieNotDefined('ROI')
        
        im = cmap(double(im)+1);
        roi = ROI(:,:,str2num(get(hControl{7}(2),'String')));
        roi = imtransform(roi,T,'nearest');
        roi = [zeros(1,size(roi,2) + 1);zeros(size(roi,1),1),roi];
        
        im = repmat(im,[1 1 3]);
        roi = repmat(roi,[1 1 3]);
        color = [1 0 0];
        colorIndex = repmat(reshape(color,[1 1 length(color)]),[size(im,1) size(im,2) 1]);
        
        transparency = 2/3;
        im = (im + transparency)/(1 + transparency).*roi.*colorIndex + im.*(1 - roi);
        
    end
	image(im);
    colormap(cmap);
    axis image;
    axis off; 
    
end

if ~ieNotDefined('ROI')
    ROIname = ['ROI_' newDataType];
end
close(h)
vw = refreshScreen(vw);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Once the ok button is pressed, the motion compensation algorithm is
% called. It can be followed by the glm and the computation of the
% consecutive frame errors.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(response,'OK')
    vw = motionCompMutualInfMeanInit(vw,scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear);
    
    % Runs the GLM
    if glmIndex
        er_runSelxavgBlock(vw,intersect(union(baseScan,scans),1:6),1);
    end
    
	% Creates the movie of the mean maps
%     try,	motionCompMeanMovie(vw);  end
    
    % Computes the consecutive-frame error
    if consError, 
        try
            for i = 1:length(dataTYPES)
                if isequal(dataTYPES(i).name,currentDataType)
                    vw = viewSet(vw,'currentDataType',i);
                    break
                end
            end

            motionCompPlotMSE(vw,'',0);
            motionCompPlotMI(vw,'',0);

            if ~ieNotDefined('ROIname')
                motionCompPlotMSE(vw,ROIname,0);
                motionCompPlotMI(vw,ROIname,0);
            end

            if exist(fullfile(roiDir(vw),'ROIdef.mat'),'file')
                pathMSE = fullfile(dataDir(vw),['MSE_' vw.sessionCode '_' currentDataType '_ROIdef.mat']);
                if exist(pathMSE,'file')
                    delete(pathMSE);
                end
                pathMI = fullfile(dataDir(vw),['MI_' vw.sessionCode '_' currentDataType '_ROIdef.mat']);
                if exist(pathMI,'file')
                    delete(pathMI);
                end

                motionCompPlotMSE(vw,'ROIdef',0);
                motionCompPlotMI(vw,'ROIdef',0);
            end

            for i = 1:length(dataTYPES)
                if isequal(dataTYPES(i).name,newDataType)
                    vw = viewSet(vw,'currentDataType',i);
                    break
                end
            end

            motionCompPlotMSE(vw,'',0);
            motionCompPlotMI(vw,'',0);

            if ~ieNotDefined('ROIname')
                motionCompPlotMSE(vw,ROIname,0);
                motionCompPlotMI(vw,ROIname,0);
            end

            if exist(fullfile(roiDir(vw),'ROIdef.mat'),'file')
                pathMSE = fullfile(dataDir(vw),['MSE_' vw.sessionCode '_' newDataType '_ROIdef.mat']);
                if exist(pathMSE,'file')
                    delete(pathMSE);
                end
                pathMI = fullfile(dataDir(vw),['MI_' vw.sessionCode '_' newDataType '_ROIdef.mat']);
                if exist(pathMI,'file')
                    delete(pathMI);
                end

                motionCompPlotMSE(vw,'ROIdef',0);
                motionCompPlotMI(vw,'ROIdef',0);

            end
        end
    end
end
    
return




% /-----------------------------------------------------------------------/ %
function h_button = fillFigure(headerStr,optionStr,h,xoff,yoff,width,height,displayButtons)
% function reply = fillFigure(headerStr,optionStr)
%
% Button Dialog Box
%
%  Allows the user to toggle and select options in
%  the cell array string 'optionStr'.  Reply is a
%  boolean vector with length(optionStr) that indicates
%  selected options. reply is empty if the user
%  chooses to cancel.
%
%  Example:
%  reply = buttondlg('pick it',{'this','that','the other'})
%
%4/11/98 gmb   Wrote it
% 15/07/02  fwc     it will now make multiple columns of options if the number is large
% 2002.07.24  rfd & fwc: fixed minor bug where short checkbox labels were invisible.
% 2004.12.16  arw: Added option to select / deselect all
%
% gb 04/18/05
%
% Several options are added in order to make it more flexible and to
% integrate this window to an existing figure

OptionsPerColumn=11; % max number of options in one column

if nargin<2
    disp('Error: "bottondlg" requires two inputs');
    return
end

if ieNotDefined('xoff')
    xoff = 0;
end

if ieNotDefined('yoff')
    yoff = 0;
end

if ieNotDefined('displayButtons')
    displayButtons = 1;
end

if isunix
    fontSize = 10;
else
    fontSize = 9;
end

if strcmp(class(optionStr),'cell')
    optionStr = char(optionStr);
end

nOptions = size(optionStr,1);

ncols=ceil(nOptions/OptionsPerColumn);
nOptionsPerColumn=max(ceil(nOptions/ncols),0);

%scale factors for x and y axis coordinates
xs = 1.8;  
ys = 1.8;

%default sizes
butWidth=10;
botMargin = 0.2;

if ieNotDefined('height')
    height = nOptionsPerColumn+2+botMargin*2+.5;
end

% If we don't have a minimum colwidth (5 in this case), short strings don't show up.
colwidth=max(size(optionStr,2),5);%

if ieNotDefined('width')
    width = ncols*colwidth+2;
    width = max(width,butWidth+2);
end

%open the figure
if ieNotDefined('h')
    h = figure('MenuBar','none',...
    'Units','char',...
    'Resize','off',...
    'NumberTitle','off',...
    'Position',[20, 10, width*xs,height*ys]);
end
bkColor = get(h,'Color');       

%Display title text inside a frame
x = 1;
% y = nOptions+1+botMargin;
y = nOptionsPerColumn+1+botMargin;

x = x + xoff;
y = y + yoff;

uicontrol('Style','frame',...
    'Units','char',...
    'String',headerStr,...
    'Position',[x*xs,(y+.2)*ys,(width-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String',headerStr,...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

%Display the radio buttons
y = y+botMargin/2;
y0=y;
c=0;

for optionNum=1:nOptions
    y = y-1;
    h_button(optionNum) = ...
        uicontrol('Style','checkbox',...
        'Units','char',...
        'String',optionStr(optionNum,:),...
        'BackgroundColor',bkColor,...
        'Position',[x*xs+c*colwidth*xs,y*ys,colwidth*xs+(c+1)*colwidth*xs,ys],...
        'HorizontalAlignment','left',...
        'FontSize',fontSize);
    if optionNum>=(c+1)*nOptionsPerColumn
        c=c+1;
        y=y0;
    end
end

if displayButtons
	%Display the OK/Cancel buttons
	x = width - butWidth - 3;
	x = x + xoff;
	y = botMargin + yoff;
	
	sabutton=uicontrol('Style','pushbutton',...
        'String','SelAll',...
        'Units','char',...
        'Position',[x*xs+2,y*ys,butWidth*xs/2,ys],...
        'FontSize',fontSize-4,...
        'Callback',['set([',num2str(h_button,30),'],''Value'',1);uiresume'],...
        'UserData','Update');
	cabutton=uicontrol('Style','pushbutton',...
        'String','ClrAll',...
        'Units','char',...
        'Position',[x*xs+2+butWidth,y*ys,butWidth*xs/2,ys],...
        'FontSize',fontSize-4,...
        'Callback',['set([',num2str(h_button,30),'],''Value'',0);uiresume'],...
        'UserData','Update');
end

return;

% /------------------------------------------------------------------------------/ %
function [scans,ROI,baseScan,newDataType,currentDataType,rigid,nonLinear,glmIndex,consError] = updateHControl(vw,hControl)
%
% Updates the arguments from the current figure
%

nScans = length(hControl{1});
scans = [];
for i = 1:nScans
    if get(hControl{1}(i),'Value')
        scans = [scans i];
    end
end

scanNames = get(hControl{3},'String');
baseScan = get(hControl{3},'Value');
    
dataNames = get(hControl{4},'String');
currentDataType = dataNames{get(hControl{4},'Value')};
newDataType = get(hControl{5},'String');

rigid = get(hControl{2}(1),'Value');
nonLinear = get(hControl{2}(2),'Value');
glmIndex = get(hControl{2}(3),'Value');
consError = get(hControl{2}(4),'Value');

if gco == hControl{7}(2)
    val = str2num(get(hControl{7}(2),'String'));
    val = min(get(hControl{7}(1),'Max'),val);
    val = max(get(hControl{7}(1),'Min'),val);
    val = round(val);
    
    set(hControl{7}(1),'Value',val);
    set(hControl{7}(2),'String',num2str(val));
else
    val = get(hControl{7}(1),'Value');
    val = min(get(hControl{7}(1),'Max'),val);
    val = max(get(hControl{7}(1),'Min'),val);
    val = round(val);
    
    set(hControl{7}(1),'Value',val);
    set(hControl{7}(2),'String',num2str(val));
end

if (rigid | nonLinear) & ~isempty(setdiff(scans,baseScan))
    set(hControl{5},'Enable','On');
    set(hControl{end - 1},'Enable','On');
    
    if hControl{end} == 0;
        newDataName = '';
        if rigid
            newDataName = [newDataName 'Rigid'];
            if nonLinear
                newDataName = [newDataName '+'];
            end
        end
        
        if nonLinear
            newDataName = [newDataName 'NL'];
        end
        
        newDataName = [newDataName '_' scanNames{baseScan}];     
        
        set(hControl{5},'String',newDataName);
    end
    
else
    set(hControl{5},'Enable','Off');
    set(hControl{5},'String','');
    set(hControl{end - 1},'Enable','Off');
    hControl{end} = 0;
end

ROINames = get(hControl{6},'String');
switch ROINames{get(hControl{6},'Value')}
    
    case 'None'
        ROI = '';

    case 'ROIocc'
        ROI = zeros([sliceDims(vw,1) numberSlices(vw)]);
        ROI((end - 50):(end - 20),30:(end - 30),15:19) = ones(size(ROI((end - 50):(end - 20),30:(end - 30),15:19)));
      
    case 'ROIfront'
        ROI = zeros([sliceDims(vw,1) numberSlices(vw)]);
        ROI((20:end - 20),30:(end - 30),2:8) = ones(size(ROI((20:end - 20),30:(end - 30),2:8)));
                
    otherwise
        ROI = motionCompGetROI(vw,ROINames{get(hControl{6},'Value')});
                
end

if baseScan == (nScans + 1)
    baseScan = 0;
end

return

% /-----------------------------------------------------------------------------/ %
function handle = createSlider(name,position,range)
%
% Creates a slider at a position and with a range specified by the user
%

color = get(gcf,'Color');

% Make slider
sliderHandle = ...
    uicontrol('Style','slider',...
    'Units','char',...
    'Position',position,...
    'min',range(1),...
    'max',range(2),...
    'SliderStep',[1/(range(2) - range(1)) 1/(range(2) - range(1))],...
    'val',floor(range(2)/2));

% Make label
labelOffset = [2,1.8,0,0];
labelPos = position - labelOffset;
labelPos(4) = 1.3;     % don't encroach on the slider

uicontrol('Style','text',...
          'Units','char',...
          'Position',labelPos,...
          'BackgroundColor',color,...
          'String',[name ':']);


editOffset = [7 - position(3),1.8,0,0];
editPos = position - editOffset;
editPos(3) = 5;
editPos(4) = 1.5;    % don't encroach on the slider
editHandle = ...
    uicontrol('Style','edit',...
    'Units','char',...
    'Position',editPos,...
    'String',num2str(get(sliderHandle,'Value')),...
    'BackgroundColor',color);

handle = [sliderHandle editHandle];

function foundScans=selectInitParameters(foundScans)
% foundScans=selectInitParameters(foundScans)
% this function generates a gui to set parameters needed to preprocess fMRI
% data. The gui alows the user to change and set all the parameters needed
% to perform a preprocessing of a complete fMRI session.
%
%
%
%   I needs a foundScans(n) strcuture with n the number off scans in
%   the complete session including scout, inplanes, anaotmy or even shimming
%   founScans should contain:
%
%  
%   foundScans(1).DirName='1';
%   foundScans(1).Files=0;
%   foundScans(1).Slices=0;
%   foundScans(1).Volumes=0;
%   foundScans(1).Sequence='';
%   foundScans(1).Action='';
%   foundScans(1).Filenames='';
%   foundScans(1).SkipVols='';
%   foundScans(1).Cycles='';
%   foundScans(1).Filename4d='';
%
%   a good preprocesssing scrip guesses most of these parameters before
%   calling   selectInitParameters to ajust them and add the missing
%   parameters..
%
%
%
%
% Mostly written by Mark Schira (mark@ski.org)

OptionsPerColumn=60;
if isunix
    fontSize = 10;
else
    fontSize = 9;
end
global HandlesOfGUI;
global lastedit;

ActionList={'Nothing','Inplanes','Functional','RefFunc','Anatomical','DTI','Reference'};
nDirs = size(foundScans,2);
disp(nDirs);

ncols=ceil(nDirs/OptionsPerColumn);
nOptionsPerColumn=ceil(nDirs/ncols);
disp(nOptionsPerColumn);

headerStr='Parameters';

%scale factors for x and y axis coordinates
xs = 1.8;
ys = 1.4;
colwidth=64;
colPos=[2 10 35 50 70 82 94 106 118];
%default sizes
butWidth=10;
botMargin = 0.2;
%height = nOptions+2+botMargin*2+.5;
height = nOptionsPerColumn+3.5+botMargin*2+.7;

% width = max(size(optionStr,2),length(headerStr))+2;
width = max(ncols*colwidth,length(headerStr))+2;
width = max(width,2*butWidth+2);

%open the figure
h_mainFig = figure('MenuBar','none',...
    'Units','char',...
    'Resize','off',...
    'NumberTitle','off',...
    'Position',[20, 10, width*xs,height*ys]);
bkColor = get(h_mainFig,'Color');

%___________________________________________________________
%Display title inside a frame
x = 1;
% y = nOptions+1+botMargin;
y = nOptionsPerColumn+2.5+botMargin;
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
    'FontSize',fontSize+2);

y=y-1.1;
putuptext('Dir',[colPos(1),(y+.3)*ys,colPos(2)-colPos(1)-1,ys*.9],fontSize);
putuptext('Protocol',[colPos(2),(y+.3)*ys,colPos(3)-colPos(2)-1,ys*.9],fontSize);
putuptext('NoFiles',[colPos(3),(y+.3)*ys,colPos(4)-colPos(3)-4,ys*.9],fontSize);
putuptext('Action',[colPos(4),(y+.3)*ys,colPos(5)-colPos(4)-1,ys*.9],fontSize);
putuptext('Volume',[colPos(5),(y+.3)*ys,colPos(6)-colPos(5)-1,ys*.9],fontSize);
putuptext('Slices',[colPos(6),(y+.3)*ys,colPos(7)-colPos(6)-1,ys*.9],fontSize);
putuptext('Skip',[colPos(7),(y+.3)*ys,colPos(8)-colPos(7)-1,ys*.9],fontSize);
putuptext('Cycles',[colPos(8),(y+.3)*ys,colPos(9)-colPos(8)-1,ys*.9],fontSize);
%putuptext('Condition # ',[colPos(9),(y+.3)*ys,colPos(10)-colPos(9)-1,ys*.9],fontSize);

y=y-0.1;

for ii=1:length(foundScans)
    y=y-1;
    %report the findings
    putuptext(int2str(ii),[colPos(1),(y+.3)*ys,colPos(2)-colPos(1)-1,ys*.9],fontSize);
    putuptext(foundScans(ii).Sequence,[colPos(2),(y+.3)*ys,colPos(3)-colPos(2)-1,ys*.9],fontSize);
    putuptext(int2str(foundScans(ii).Files),[colPos(3),(y+.3)*ys,colPos(4)-colPos(3)-1,ys*.9],fontSize);
    %the aktionMenue
    pos=[colPos(4),(y+.3)*ys,colPos(5)-colPos(4)-4,ys*.9];
    h_action(ii) = uicontrol('Units','char','HorizontalAlignment','left',...
        'Style','popupmenu','String',ActionList,'Position',pos,'BackgroundColor',[0.85 0.85 0.85]);
    if isempty(foundScans(ii).Action)
        ActionVal=1;
    else
        ActionVal=find(strcmp(foundScans(ii).Action,ActionList));
    end
    set(h_action(ii),'Value',ActionVal);

    %the parameters of the scans


    h_Volumes(ii)=uicontrol('Units','char','HorizontalAlignment','center',...
        'Style','edit','String',num2str(foundScans(ii).Volumes,4),...
        'Position',[colPos(5),(y+.3)*ys,colPos(6)-colPos(5)-1,ys*.9],'BackgroundColor',[0.85 0.85 0.85]);
    callBackStr=['global lastedit;lastedit=',char(39),'Vol_',int2str(ii),char(39),';'];
    set(h_Volumes(ii),'Callback',callBackStr);

    h_Slices(ii)=uicontrol('Units','char','HorizontalAlignment','center',...
        'Style','edit','String',int2str(foundScans(ii).Slices),...
        'Position',[colPos(6),(y+.3)*ys,colPos(7)-colPos(6)-1,ys*.9],'BackgroundColor',[0.85 0.85 0.85]);
    callBackStr=['global lastedit;lastedit=',char(39),'Sli_',int2str(ii),char(39),';'];
    set(h_Slices(ii),'Callback',callBackStr);

    h_SkipVols(ii)=uicontrol('Units','char','HorizontalAlignment','center',...
        'Style','edit','String',int2str(foundScans(ii).SkipVols),...
        'Position',[colPos(7),(y+.3)*ys,colPos(8)-colPos(7)-1,ys*.9],'BackgroundColor',[0.85 0.85 0.85]);
    callBackStr=['global lastedit;lastedit=',char(39),'Ski_',int2str(ii),char(39),';'];
    set(h_SkipVols(ii),'Callback',callBackStr);


    h_Cycles(ii)=uicontrol('Units','char','HorizontalAlignment','center',...
        'Style','edit','String',int2str(foundScans(ii).SkipVols),...
        'Position',[colPos(8),(y+.3)*ys,colPos(9)-colPos(8)-1,ys*.9],'BackgroundColor',[0.85 0.85 0.85]);
    callBackStr=['global lastedit;lastedit=',char(39),'Cyc_',int2str(ii),char(39),';'];
    set(h_Cycles(ii),'Callback',callBackStr);
end

HandlesOfGUI.h_Volumes=h_Volumes;
HandlesOfGUI.h_Slices=h_Slices;
HandlesOfGUI.h_SkipVols=h_SkipVols;
HandlesOfGUI.h_Cycles=h_Cycles;



y=y-1.4; 
uicontrol('Style','pushbutton',...
    'String','Cancel',...
    'Units','char',...
    'Position',[colPos(4)-4,(y+.3)*ys,colPos(5)-colPos(4)-4,ys*.9],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','Cancel');

x = width-butWidth-1;
uicontrol('Style','pushbutton',...
    'String','OK',...
    'Units','char',...
    'Position',[colPos(2),(y+.3)*ys,colPos(3)-colPos(2)-4,ys*.9],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','OK');
global MY_GLOBAL
CopyDownString=['global lastedit; global h_Volumes; selectInitParamChange(lastedit);'];

sabutton=uicontrol('Style','pushbutton',...
    'String','Fill last Value',...
    'Units','char',...
    'Position',[colPos(6)-5,(y+.3)*ys,colPos(8)-colPos(6)-2,ys*.9],...
    'FontSize',fontSize-4,...
    'Callback',CopyDownString,...
    'UserData','OK');


%let the user select some radio buttons and
%wait for a 'uiresume' callback from OK/Cancel
uiwait

%determine which button was hit.
response = get(gco,'UserData');

%gather the status of the radio buttons if 'OK' was
%selected.  Otherwise return empty matrix.
if strcmp(response,'OK')
    for thisScan=1:length(foundScans)
        foundScans(thisScan).Action=ActionList(get(h_action(thisScan),'Value'));
        foundScans(thisScan).Volumes=getNumberFromString(get(h_Volumes(thisScan),'String'));
        foundScans(thisScan).Slices=getNumberFromString(get(h_Slices(thisScan),'String'));
        foundScans(thisScan).SkipVols=getNumberFromString(get(h_SkipVols(thisScan),'String'));
        foundScans(thisScan).Cycles=getNumberFromString(get(h_Cycles(thisScan),'String'));
    end

else
    foundScans = [];
end

close(h_mainFig);

return;
end

function putuptext(TEXT,pos,fontSize)
uicontrol('Style','text',...
    'Units','char',...
    'String',TEXT ,...
    'Position',pos,...
    'HorizontalAlignment','center',...
    'FontSize',9);
end



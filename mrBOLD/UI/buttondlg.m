function [reply ok] = buttondlg(headerStr,optionStr,defaultRes)
% Button Dialog Box
%
%  reply = buttondlg(headerStr,optionStr,[defaultRes])
%
% Method for creating a window that allows the user to toggle and select
% options in the cell array string 'optionStr'.
%
% INPUTS:
%
%  headerStr: string for the title of the dialog.
%
%	optionStr: cell array of strings, one for each button option.
%
%	defaultRes: logical array of default responses, 1 for selected, 0 for
%	unselected. [Default: all zeros, don't select anything]
%
% OUTPUTS:
%
% reply: a boolean vector with length(optionStr) that indicates
%        selected options. reply is empty if the user
%        chooses to cancel.
%
% ok: flag indicating whether the user canceled or not.
%
% EXAMPLE:
%  reply = buttondlg('pick it',{'this','that','the other'})
%
% 4/11/98 gmb    Wrote it
% 15/07/02  fwc  Make multiple columns of options if the number is large
% 2002.07.24  rfd & fwc: fixed minor bug where short checkbox labels were invisible.
% 2004.12.16  arw: Added  select / deselect all option
% 2006.01.12 MMS: Added the option to feed a default selection in (see line 110)
% 2006.03.03 ras: centers dialog in screen
% 2015.06.15 arw: Shamefully disabled 'Select all' under ML > 8.4

ok = 0;
OptionsPerColumn=30; % max number of options in one column

if nargin<2
    disp('Error: "bottondlg" requires two inputs');
    return
end

if isunix,  fontSize = 10;
else        fontSize = 9;
end

if iscell(optionStr), optionStr = char(optionStr); end

nOptions = size(optionStr,1);

ncols=ceil(nOptions/OptionsPerColumn);
nOptionsPerColumn=ceil(nOptions/ncols);

%scale factors for x and y axis coordinates
xs = 1.8;
ys = 1.8;

%default sizes
butWidth=10;
botMargin = 0.2;
%height = nOptions+2+botMargin*2+.5;
height = nOptionsPerColumn+2+botMargin*2+.5;

% If we don't have a minimum colwidth (5 in this case), short strings don't
% show up.
colwidth=max(size(optionStr,2),5);%
% width = max(size(optionStr,2),length(headerStr))+2;
width = max(ncols*colwidth,length(headerStr))+2;
width = max(width,2*butWidth+2);

%open the figure
h = figure('MenuBar', 'none',...
    'Units', 'char',...
    'Resize', 'on',...
    'NumberTitle', 'off',...
    'Position', [20, 10, width*xs,height*ys]); %
bkColor = get(h,'Color');

% center the figure -- we needed to use char to get
% a reasonable size, but want to move the corners to
% a centered position. This is a quick way to do it:
set(h, 'Units', 'normalized');
normPos = get(h, 'Position'); % pos in normalized units
normPos(1:2) = [.5 .5] - normPos(3:4)./2;
set(h, 'Position', normPos);


%Display title text inside a frame
x = 1;
% y = nOptions+1+botMargin;
y = nOptionsPerColumn+1+botMargin;

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
    if optionNum >= (c+1)*nOptionsPerColumn
        c=c+1;
        y=y0;
    end
end


if exist('defaultRes','var')
    for optionNum=1:nOptions
        try
            set (h_button(optionNum), 'Value', defaultRes(optionNum));
        catch
        end
    end
end



%Cancel button
x=1;
y=botMargin;
uicontrol('Style','pushbutton',...
    'String','Cancel',...
    'Units','char',...
    'Position',[x*xs,y*ys,butWidth*xs/2,ys],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','Cancel');

% OK button
x = width-butWidth-1;
uicontrol('Style','pushbutton',...
    'String','OK',...
    'Units','char',...
    'Position',[x*xs/2+2,y*ys,butWidth*xs/2,ys],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','OK');

if (verLessThan('matlab','8.4')) % I don't think it's as easy to do this in ML> 8.4
    % Select all button
    uicontrol('Style','pushbutton',...
        'String','SelAll',...
        'Units','char',...
        'Position',[x*xs+2,y*ys,butWidth*xs/2,ys],...
        'FontSize',fontSize-4,...
        'Callback',['set([',num2str(h_button,30),'],''Value'',1);'],...
        'UserData','OK');
    
    % Clear all button
    uicontrol('Style','pushbutton',...
        'String','ClrAll',...
        'Units','char',...
        'Position',[x*xs+2+butWidth,y*ys,butWidth*xs/2,ys],...
        'FontSize',fontSize-4,...
        'Callback',['set([',num2str(h_button,30),'],''Value'',0);'],...
        'UserData','OK');
end

%let the user select some radio buttons and
%wait for a 'uiresume' callback from OK/Cancel
uiwait

%determine which button was hit.
response = get(gco,'UserData');

%gather the status of the radio buttons if 'OK' was
%selected.  Otherwise return empty matrix.
if strcmp(response,'OK')
    for optionNum=1:nOptions
        reply(optionNum)=get(h_button(optionNum),'Value');
    end
    ok = 1;
else
    reply = [];
end

close(h)

return;



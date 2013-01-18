function reply = radiobuttondlg(optionList, title)
% 
% reply = radiobuttondlg(optionList, [title])
%
% Button Dialog Box
%
%  Allows the user to toggle and select options in
%  the cell array string 'optionStr'.  Reply is a
%  scalar indicating the user's choice. reply is empty if the user
%  chooses to cancel.
%
%  Example:
%  reply = radiobuttondlg('pick it',{'this','that','the other'})
%
% 2002.03.26 RFD wrote it, based on Boynton's buttondlg.

if nargin<1
    disp('Error: "bottondlg" requires at least one input');
    return
end
if ~exist('title','var')
    title = 'Choose Items';
end

fontSize = 10;

nOptions = length(optionList);

%scale factors for x and y axis coordinates
xs = 1.8;  
ys = 1.8;

%default sizes
butWidth=10;
botMargin = 0.2;
height = nOptions+2+botMargin*2+.5;
width = 2*butWidth+2;
for optionNum=1:nOptions
    if(~ischar(optionList{optionNum}))
        optionList{optionNum} = num2str(optionList{optionNum});
    end
    width = max([length(optionList{optionNum}), length(title)+2, width]);
end

%open the figure
h = figure('MenuBar','none',...
    'Units','char',...
    'Resize','off',...
    'NumberTitle','off',...
    'Name', title,...
    'Position',[100, 10,width*xs,height*ys]);
bkColor = get(h,'Color');       

%Display title text inside a frame
x = 1;
y = nOptions+1+botMargin;

uicontrol('Style','frame',...
    'Units','char',...
    'String',title,...
    'Position',[x*xs,(y+.2)*ys,(width-2)*xs,ys*1.3],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

uicontrol('Style','text',...
    'Units','char',...
    'String',title,...
    'Position',[(x+.25)*xs,(y+.3)*ys,(width-2.5)*xs,ys*.9],...
    'HorizontalAlignment','center',...
    'FontSize',fontSize);

%Display the radio buttons
y = y+botMargin/2;
for optionNum=1:nOptions
    y = y-1;
    h_button(optionNum) = ...
        uicontrol('Style','radiobutton',...
        'Units','char',...
        'String',optionList{optionNum},...
        'BackgroundColor',bkColor,...
        'Position',[x*xs,y*ys,(width-2)*xs,ys],...
        'HorizontalAlignment','left',...
        'FontSize',fontSize,...
        'callback', 'h_button=guidata(gcbo); for(ii=1:length(h_button)) set(h_button(ii), ''Value'', 0); end; set(gcbo, ''Value'', 1)');
end

guidata(h,h_button);

%Display the OK/Cancel buttons
x=1;
y=botMargin;
uicontrol('Style','pushbutton',...
    'String','Cancel',...
    'Units','char',...
    'Position',[x*xs,y*ys,butWidth*xs,ys],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','Cancel');

x = width-butWidth-1;
uicontrol('Style','pushbutton',...
    'String','OK',...
    'Units','char',...
    'Position',[x*xs,y*ys,butWidth*xs,ys],...
    'CallBack','uiresume',...
    'FontSize',fontSize,...
    'UserData','OK');

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
    % these are radio buttons- there should only be one set
    reply = find(reply);
else
    reply = [];
end

close(h)


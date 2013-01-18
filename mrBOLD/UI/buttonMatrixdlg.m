function reply = buttonMatrixdlg(headerStr,optionStruct)
% function reply = buttonmatrixdlg(headerStr,optionStruct)
%
% Button Dialog Box
%
%  Allows the user to toggle and select options input as a structure
%  To understand what I mean, try Example:
%    optionStruct(1).str = {'A1','A2','A3'}; % a cell array
%    optionStruct(2).str = {'B1','only B2'}; % another array that can be of different length
%    optionStruct(1).title = 'Column A'; % title of each column.
%    optionStruct(2).title = 'Show you B';
%    reply = buttonMatrixdlg('test yourself',optionStruct)
%
% Note that for each string, we only display the first 20 characters.
% 2004.02.14 Junjie wrote from buttondlg, for averageTSeriesAcrossSessions.m

maxRows = 25; % max number of options in one column

if nargin<2
    disp('Error: "bottondlg" requires two inputs');
    return
end

if isunix
    fontSize = 10;
else
    fontSize = 9;
end
%scale factors for x and y axis coordinates
xs = 1.8;  
ys = 1.8;

botMargin = 0.5;
colMargin = 2;
colSpacing = 10;
rowMargin = 2;
rowSpacing = 1;
titleShift = 5.5*rowSpacing;

nOptions = length(optionStruct);
for iOption = 1:nOptions;
    nRows(iOption) = length(optionStruct(iOption).str);
end
overLong = length(find(nRows>=maxRows));
width = colMargin*2+(nOptions+overLong)*colSpacing;
height = rowMargin + rowSpacing*min([max(nRows),maxRows]) + titleShift;

h = figure('MenuBar','none','Units','char',...
    'NumberTitle','off',...
    'Position',[10, 10, width*xs, height*ys]);
bkColor = get(h,'Color');       

buttX = abs(width-25)/2; %for this button width 25
buttY = botMargin; % y at bottom
uicontrol('Style','pushbutton','String','OK (To cancel, select nothing)',...
    'Units','char','Position',[buttX*xs,buttY*ys,25*xs,ys],...
    'CallBack','uiresume','FontSize',fontSize);

buttX = colMargin;
nButtons = 0;
for iOption = 1:nOptions;
    buttY = rowMargin + rowSpacing*min([max(nRows),maxRows]);
    %Display column title text inside a frame
    titleX = buttX;
    titleY = buttY + rowSpacing*1.5;
    uicontrol('Style','frame','Units','char',...
        'Position',[titleX*xs,titleY*ys,colSpacing*xs,rowSpacing*1.4*ys],...
        'HorizontalAlignment','center','FontSize',fontSize);
    uicontrol('Style','text','Units','char',...
        'String',optionStruct(iOption).title,...
        'Position',[(titleX+0.5)*xs,(titleY+0.2)*ys,(colSpacing-1)*xs,rowSpacing*ys],...
        'HorizontalAlignment','center','FontSize',fontSize);
    for iRow = 1:nRows(iOption);
        nButtons = nButtons + 1;
        h_button(nButtons) = uicontrol('Style','checkbox',...
            'Units','char','BackgroundColor',bkColor,...
            'HorizontalAlignment','left','FontSize',fontSize,...
            'String',optionStruct(iOption).str{iRow},'Value',0,...
            'Position',[buttX*xs,buttY*ys,(colSpacing-1)*xs,rowSpacing*ys]);
        buttHandles{iOption}(iRow) = nButtons;
        buttY = buttY - rowSpacing;
        if iRow == maxRows; % return to top
            buttY = rowMargin + rowSpacing*min([nRows,maxRows]);
            buttX = buttX + colSpacing;
        end
    end
    buttX = buttX + colSpacing;% move to next option
end
uicontrol('Style','frame','Units','char',...
    'Position',[colMargin*xs,(height-2*rowSpacing)*ys,(width-colMargin*2)*xs,rowSpacing*1.4*ys],...
    'HorizontalAlignment','center','FontSize',fontSize);
uicontrol('Style','text','Units','char',...
    'String',headerStr,...
    'Position',[(colMargin+1)*xs,(height-1.8*rowSpacing)*ys,(width-colMargin*2-2)*xs,rowSpacing*ys],...
    'HorizontalAlignment','center','FontSize',fontSize);
    
%let the user select some radio buttons and
%wait for a 'uiresume' callback from OK/Cancel
uiwait

for iButton = 1:nButtons;
    responses(iButton) = get(h_button(iButton),'Value');
end
if sum(responses) == 0;
    reply = [];
else
    for iOption = 1:nOptions;
        reply{iOption} = responses(buttHandles{iOption}(:));
    end
end

close(h)
return

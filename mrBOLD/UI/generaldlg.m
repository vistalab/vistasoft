function outStruct = generaldlg(uiStruct,pos,title)
%
% AUTHOR: ???
% PURPOSE: Put up a general dialogue box suited for mrLoadRet
%
% This was uncommented, used in View/Edit Notes call, Annotation
% ... perhaps other places?
% Possibly from rmk?
%
% Probably, we should set the fields and figure to be scalable.
%
% BW, 12.15.00
if isunix
  fontSize = 10;
else
  fontSize = 8;
end
butWidth=10;
topMargin = 1.0;
botMargin = 0.2;
numFields = length(uiStruct);
%scale factors for x and y axis coordinates
xs = 1.45;  
ys = 1.6;
yFig = pos(4) * ys;
if exist('title', 'var')
  yStop = zeros(numFields, 1);
  for i=1:numFields, yStop(i)=uiStruct(i).editPos(2) + uiStruct(i).editPos(4); end
  yMax = max(yStop);
  yFig = (yMax + 2) * ys;
end
% Why is resize off?  Because the text boxes don't scale
% when we resize the figure.  There is a way to manage this
% when we build the uistruct.  Sigh.
%
h = figure('MenuBar','none','Units','char',...
    'Position', [pos(1)*xs, pos(2), pos(3)*xs, yFig],...
    'Resize','off',...
    'NumberTitle','off');
bkColor = get(h,'Color');
if exist('title', 'var')
  y = (numFields - topMargin + 5) * ys;
  uicontrol( ...
    'Style', 'text', ...
    'Units', 'char', ...
    'String', title, ...
    'BackgroundColor', bkColor, ...
    'Position', [0, (yMax+0.2)*ys, pos(3)*xs, ys*1.4], ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'FontSize', 12 ...
    );
end
for uiNum=1:numFields
  %string box
  if ~isempty(uiStruct(uiNum).string)
    stringPos =[uiStruct(uiNum).stringPos(1)*xs,uiStruct(uiNum).stringPos(2)*ys,...
	    uiStruct(uiNum).stringPos(3)*xs,uiStruct(uiNum).stringPos(4)*ys];
    uicontrol('Style','text',...        'Units','char',...
	'String',uiStruct(uiNum).string,...
	'BackgroundColor',bkColor,...
	'Position',stringPos,...
	'HorizontalAlignment','left',...
	'FontSize',fontSize);
  end
  switch uiStruct(uiNum).style
    case 'edit'
    %edit box
      editPos =[uiStruct(uiNum).editPos(1)*xs,uiStruct(uiNum).editPos(2)*ys,...
	        uiStruct(uiNum).editPos(3)*xs,uiStruct(uiNum).editPos(4)*ys];
       ui_handle(uiNum) = uicontrol('Style','edit',...
     'Units','char',...
	 'String',mat2str(uiStruct(uiNum).value),...
	 'Position',editPos,...
	 'HorizontalAlignment','left',...
	 'FontSize',fontSize);
     case 'text'
      textPos =[uiStruct(uiNum).editPos(1)*xs,uiStruct(uiNum).editPos(2)*ys,...
	        uiStruct(uiNum).editPos(3)*xs,uiStruct(uiNum).editPos(4)*ys];
       ui_handle(uiNum) = uicontrol('Style','text',...
         'Units','char',...
	 'String',mat2str(uiStruct(uiNum).value),...
	 'Position',textPos,...
	 'HorizontalAlignment','left',...
	 'FontSize',fontSize);
    case 'checkbox'
      checkPos =[uiStruct(uiNum).editPos(1)*xs,uiStruct(uiNum).editPos(2)*ys,...
	        uiStruct(uiNum).editPos(3)*xs,uiStruct(uiNum).editPos(4)*ys];
       ui_handle(uiNum) = uicontrol('Style','checkbox',...
         'Units','char',...
	 'String',uiStruct(uiNum).string,...
	 'Value',uiStruct(uiNum).value,...
	 'Position',checkPos,...
	 'HorizontalAlignment','left',...
	 'FontSize',fontSize);
    case 'popupmenu'
      popupPos =[uiStruct(uiNum).editPos(1)*xs,uiStruct(uiNum).editPos(2)*ys,...
	        uiStruct(uiNum).editPos(3)*xs,uiStruct(uiNum).editPos(4)*ys];
      ui_handle(uiNum) = uicontrol('Style','popupmenu',...
         'Units','char',...
	 'String',uiStruct(uiNum).list,...
	 'Value',uiStruct(uiNum).choice,...
	 'Position',popupPos,...
	 'HorizontalAlignment','left',...
	 'FontSize',fontSize);
   
     otherwise
    disp('Style not recognized');
  end
end
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
      
x = pos(3)-butWidth-1;
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

%gather the status of the controls if 'OK' was 
%selected.  Otherwise return empty matrix.

outStruct = [];
if strcmp(response,'OK')
  for uiNum=1:length(uiStruct)
    switch uiStruct(uiNum).style
      case 'edit'
        %type cast
	if ischar(uiStruct(uiNum).value)
	  val = get(ui_handle(uiNum),'String');
	else
	  val = str2num(get(ui_handle(uiNum),'String'));
	end
      case 'text'
          val = uiStruct(uiNum).value;    
      case 'checkbox'
          val = get(ui_handle(uiNum),'Value');
      case 'popupmenu'
          val = char(uiStruct(uiNum).list(get(ui_handle(uiNum),'Value')));
      otherwise
       disp('Style not recognized');
    end
    outStruct = setfield(outStruct,uiStruct(uiNum).fieldName,val);
  end
else
  reply = [];
end
close(h)
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%debug
uiStruct(1).style = 'edit';
uiStruct(1).string = 'Name of your chicken:';
uiStruct(1).stringPos = [1,10,18,1];
uiStruct(1).editPos = [1,9,18,1];
uiStruct(1).value = 'Ralph';
uiStruct(1).fieldName = 'chickenName';

uiStruct(2).style = 'edit';
uiStruct(2).string = 'Name of your cat:';
uiStruct(2).stringPos = [20,10,18,1];
uiStruct(2).editPos = [20,9,18,1];
uiStruct(2).value = 'Fluffy';
uiStruct(2).fieldName = 'catName';

uiStruct(3).style = 'checkbox';
uiStruct(3).string = 'neutered?';
uiStruct(3).stringPos = [1,8,18,1];
uiStruct(3).editPos = [1,7,18,1];
uiStruct(3).value = 1;
uiStruct(3).fieldName = 'catNeuteredFlag';

uiStruct(4).style = 'checkbox';
uiStruct(4).string = 'neutered?';
uiStruct(4).stringPos = [20,8,18,1];
uiStruct(4).editPos = [20,7,18,1];
uiStruct(4).value = 1;
uiStruct(4).fieldName = 'chickenNeuteredFlag';

uiStruct(5).style = 'edit';
uiStruct(5).string = 'IQ:';
uiStruct(5).stringPos = [1,6,9,1];
uiStruct(5).editPos = [10,6,9,1];
uiStruct(5).value = 100.34;
uiStruct(5).fieldName = 'catIQ';

pos = [77,17,40,12];

close all
outStruct = generaldlg(uiStruct,pos);



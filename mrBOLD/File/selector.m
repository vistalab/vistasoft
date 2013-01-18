function [id,OK] = selector(idList,NameList,Caption)
% [id,OK] = selector(idList,NameList,Caption,view)
% [id,OK] = selector(idList,NameList,Caption)
% [id,OK] = selector(idList,NameList)
% User should pick one item from a list

if(nargin==2)
  Caption = 'Select:';
end

c=0;

c=c+1;
uiStruct(c).string = Caption;
uiStruct(c).fieldName = 'main';
uiStruct(c).list = NameList;
uiStruct(c).choice = 1;
uiStruct(c).style = 'popupmenu';

height = 1;
vSkip = 0.3;
pos = [35,10,100,length(uiStruct)*(height+vSkip)+3];
x = 1;
y = length(uiStruct)*(height+vSkip)+1;
editWidth = 50;
stringWidth = pos(3)-editWidth-2;
for uiNum = 1:length(uiStruct)
  uiStruct(uiNum).stringPos = [x,y,stringWidth,height];
  uiStruct(uiNum).editPos = [x+stringWidth-1,y,editWidth,height];
  uiStruct(uiNum).value = 1;
  y = y-(height+vSkip);
end
outStruct = generaldlg(uiStruct,pos);

if ~isempty(outStruct)
  id = idList(strcmp(NameList,outStruct.main));
  OK = 1;
else 
  id = 0;
  OK = 0;
end
function saveROIdb(view,ROI)
%
% saveROI(view,ROI)
%
% Invokes a dialog for additional properties and saves ROI to a database.
%
% ROI: ROI structure
%
% djh, 1/24/98
% gmb, 4/25/98 added dialog box
% ars, 7/02/03 DB adoptation

OKflag = openDbConnection(view);
if(~OKflag)
  return;
end;

colorList = {'yellow','magenta','cyan','red','green','blue','white'};
colorChar = char(colorList)';
colorChar = colorChar(1,:);
colorNum = findstr(ROI.color,colorChar);

c=0;

c=c+1;
uiStruct(c).string = 'ROI name:';
uiStruct(c).fieldName = 'name';
uiStruct(c).style = 'edit';

c=c+1;
uiStruct(c).string = 'Color:';
uiStruct(c).fieldName = 'color';
uiStruct(c).list = colorList;
uiStruct(c).choice = colorNum;
uiStruct(c).style = 'popupmenu';

height = 1;
vSkip = 0.3;
pos = [35,10,30,length(uiStruct)*(height+vSkip)+3];
x = 1;
y = length(uiStruct)*(height+vSkip)+1;
editWidth = 10;
stringWidth = pos(3)-editWidth-2;
for uiNum = 1:length(uiStruct)
  uiStruct(uiNum).stringPos = [x,y,stringWidth,height];
  uiStruct(uiNum).editPos = [x+stringWidth-1,y,editWidth,height];
  uiStruct(uiNum).value = ...
      getfield(ROI,uiStruct(uiNum).fieldName);
  y = y-(height+vSkip);
end
outStruct = generaldlg(uiStruct,pos);

% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if(isempty(outStruct))
  disp('ROI not saved.');
  return;
end

ROI = mergeStructures(ROI,outStruct); 
ROI.color = ROI.color(1);

disp(['Saving ROI "',ROI.name,'".'])
mysql(['INSERT INTO rois(ROIname,ROIdata,sessionid,authorid) VALUES("' ROI.name '","' ...
  serialize(ROI) '","' num2str(view.sessionId) '","' num2str(view.mysqlsession.userId) '")']);

mysql('close');

return;
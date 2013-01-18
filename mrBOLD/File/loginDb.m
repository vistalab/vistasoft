function view = loginDb(view);
% function loginDb(view);
% 
% Login to a database, load all sessions available, let to choose a proper session, 
% bind VIEW with this session ID, open ROI database, load all ROIs with  this sessionID.
%
% ars 7/02/03

[view,OKflag] = openDbConnection(view);
if(~OKflag)
  return;
end

[SessionIdList,SessionNameList] = mysql('SELECT id,sessionCode FROM sessions');

% User can coose a session from a list.
%------begin dialog---------
c=0;

c=c+1;
uiStruct(c).string = 'Select your session:';
uiStruct(c).fieldName = 'session';
uiStruct(c).list = SessionNameList;
uiStruct(c).choice = 1;
uiStruct(c).style = 'popupmenu';

c=c+1;
uiStruct(c).string = 'Load all ROIs for this session?';
uiStruct(c).fieldName = 'load';
uiStruct(c).choice = 1;
uiStruct(c).style = 'checkbox';


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
  OurSession = SessionIdList(strcmp(SessionNameList,outStruct.session));
else 
  disp('Session wasn''t selected');
  return;
end

%----------dialog end----

view = setfield(view,'sessionId',[OurSession]);

if(outStruct.load)
  disp('Loading all ROIs for selected session');
  ROIsList = mysql(['SELECT rois.id FROM rois WHERE rois.sessionid="',num2str(OurSession),'"']);

  for(Q=1:length(ROIsList))
    view = loadROIdb(view,ROIsList(Q));
  end
end

mysql('close');
function [ExcelID,WorkbookID,SheetNum,shapeID,imageHandleList]=excelReport(view,comment,ExcelID,WorkbookID,SheetNum,imSize,startPos)
%
% [ExcelID,WorkbookID,SheetNum,shapeID,imageHandleList]= ...
%                 excelReport(comment,ExcelID,WorkbookID,SheetNum,imSize,startPos)
%
% PURPOSE: Automates the generation of an Excel spreadsheet with
% Screenshots of the current datatype / scan
% Assumes that mrmesh has been invoked to visualize the data 

mrGlobals;
    
meshTypes={'Folded','Relaxed'};
if (~exist('imSize'))
imSize=[200 200];
end
if (~exist('startPos'))
startPos=[20 20];
end

% Script to generate screenshots 
% Saves in current dir: 

viewList={'back','left','right','bottom','top'};
viewVectors={[pi -pi/2 0],[pi 0 0],[0 0 pi],[pi/2 -pi/2 0],[-pi/2 -pi/2 0]};
view=getSelectedVolume;

idList = viewGet(view,'allwindowids');
thisID=view.meshNum3d;
% Set up an excel worksheet to accept the data
% If no handle has been passed, we initiate a new instance of excel

if (~exist('ExcelID','var'))
    ExcelID = actxserver('Excel.Application');
end

if (isempty(ExcelID))
    ExcelID = actxserver('Excel.Application');
end
disp(ExcelID)

set(ExcelID, 'Visible', 1);

if (~exist('WorkbookID','var'))
         Workbooks = ExcelID.Workbooks;
         WorkbookID = invoke(Workbooks, 'Add');
end
if (isempty(WorkbookID))
         Workbooks = ExcelID.Workbooks;
         WorkbookID = invoke(Workbooks, 'Add');
end


if (~exist('SheetNum','var'))
    SheetNum=1;
    
end
    

         Sheets = ExcelID.ActiveWorkBook.Sheets;
         SheetID = get(Sheets, 'Item', SheetNum);
         
        invoke(SheetID, 'Activate');

ActivesheetID = ExcelID.Activesheet;
shapeID=WorkbookID.ActiveSheet.Shapes
         
         
         
         
for thisView=1:length(viewList);
    cam.actor=0; 
    cam.rotation=rotationMatrix3d(viewVectors{thisView})
    mrMesh('localhost',thisID,'set',cam)
    date_string=datestr(now,30);
    dt=dataTYPES(view.curDataType).name;
    scanNum=int2str(getCurScan(view));
    %mt=meshTypes{v.meshNum3d};
    filename=fullfile(pwd,[dt,'_',scanNum,'_',date_string,'_',viewList{thisView},'.bmp'])
    c.filename=fullfile(pwd,'test.bmp');
    
    pause(2);
    [a,b,result]=mrMesh('localhost',thisID,'screenshot',c)
    pause(5);
    disp(thisView)
    
    
     a=invoke(shapeID,'AddPicture',c.filename,1,1,startPos(1),startPos(2),imSize(1),imSize(2));
%    set(a,'AlternativeText',[comment,' : ',filename]);
    
    startPos(1)=startPos(1)+imSize(1);
    imageHandleList(thisView)=a;
    
         
end

% We can also copy and paste figures from matlab to the excel spreadsheet.


% To copy a figure from matlab try : print -dmeta


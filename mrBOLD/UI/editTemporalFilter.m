function view = editTemporalFilter(view)

if ~isfield(view,'temporalFilterSD')
  view.temporalFilterSD = 0;
end

c=0;

c=c+1;
uiStruct(c).string = 'Temporal filter standard deviation:';
uiStruct(c).fieldName = 'temporalFilterSD';
uiStruct(c).style = 'edit';

height = 1;
vSkip = 0.3;
pos = [35,10,50,length(uiStruct)*(height+vSkip)+3];
x = 1;
y = length(uiStruct)*(height+vSkip)+1;
editWidth = 20;
stringWidth = pos(3)-editWidth-2;
for uiNum = 1:length(uiStruct)
  uiStruct(uiNum).stringPos = [x,y,stringWidth,height];
  uiStruct(uiNum).editPos = [x+stringWidth-1,y,editWidth,height];
  uiStruct(uiNum).value = ...
      getfield(view,uiStruct(uiNum).fieldName);
  y = y-(height+vSkip);
end
outStruct = generaldlg(uiStruct,pos);

%If user selects 'OK', change the parameters.
%Otherwise the user isn't happy with these settings
%so bail out

if ~isempty(outStruct)
  view = mergeStructures(view,outStruct);
end









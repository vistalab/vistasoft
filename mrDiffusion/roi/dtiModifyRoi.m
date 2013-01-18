function [roi, OK] = dtiModifyRoi(roi)
%
% [roi, OK] = dtiModifyRoi(roi)
% 
% Purpose:
%   This routine adjusts the name and color of the ROI.
%
% HISTORY:
%   2003.10.02 RFD (bob@white.stanford.edu) wrote it.

if(~exist('roi','var') || isempty(roi))
    roi = dtiNewRoi;
end

colorList = getColorString;
pickerInd = length(colorList)+1;
colorList{pickerInd}='color picker...';
customInd = length(colorList)+1;
colorList{customInd}='custom...';

if(ischar(roi.color))
    [colorStr, colorNum] = getColorString(roi.color);
else
    % 'other'- means that color field is an RGB[A] value
    colorNum = customInd;
end

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
      getfield(roi,uiStruct(uiNum).fieldName);
  y = y-(height+vSkip);
end
outStruct = dtiGeneralDlg(uiStruct,pos);

% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if ~isempty(outStruct)
  roi.name = outStruct.name; 
  oldRgba = dtiRoiGetColor(roi);
  if(strcmp(outStruct.color,colorList{pickerInd}))
    roi.color = uisetcolor(oldRgba(1:3),['Select ROI "' roi.name '" color...']);
  elseif(strcmp(outStruct.color,colorList{customInd}))
    defAns = {num2str(oldRgba,'%0.2g  ')};
    resp = inputdlg('ROI color [R G B [A]] (0-1 scale):',[roi.name ' custom color'],1,defAns);
    if(~isempty(resp))
      newRgba = str2num(resp{1});
      if(length(newRgba)==3|length(newRgba)==4) roi.color = newRgba;
      else warning('Invalid RGBA color entry- ignoring.'); end
      roi.color(roi.color>1) = 1;
      roi.color(roi.color<0) = 0;
      
    end
  else
    roi.color = outStruct.color(1);
  end
  OK = 1;
else 
  OK = 0;
end

return;


function outStruct = mergeStructures(firstStruct,secondStruct)
%outStruct = mergeStructures(firstStruct,secondStruct)
%
%returns a structure with fields from both input structures.
%If both input structures have the same fields, the secondStruct
%fields overwrite the firstStruct fields.

outStruct = firstStruct;

if ~isempty(secondStruct)
  fieldNames = fieldnames(secondStruct);
  for i = 1:length(fieldNames)
    field = getfield(secondStruct, fieldNames{i});
    outStruct = setfield(outStruct, fieldNames{i}, field);
  end
end

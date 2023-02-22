function string = inputTextDialog(title,initialText,textWidth)
%
% function string = inputTextDialog(title,[initialText],[textWidth])
%
% Dialog box with editable text box. Returns text string.
%
% title: window title
% initialText: optional string to start with. Default is empty string
% textWidth: optional width for text box. Default is 18.
%
% djh, 2/22/2001

if ~exist('initialText','var')
    initialText = '';
end
if ~exist('textWidth','var')
    textWidth = 18;
end

vSkip = 0.3;
height = 1;
width = max(textWidth+4,1.25*length(title));
pos = [35,10,width,(height+vSkip)+3];
x = 2;
y = (height+vSkip)+1;
uiStruct.string = title;
uiStruct.fieldName= 'text';
uiStruct.style = 'edit';
uiStruct.editPos = [x,y,textWidth,height];
uiStruct.value = initialText;

outStruct = generalDialog(uiStruct, title);

if ~isempty(outStruct)
    string = outStruct.text;
else
    string = [];
end     

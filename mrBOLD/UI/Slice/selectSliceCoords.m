function [vw, slices] = selectSliceCoords(vw)
%
%    [vw, selectedPositions] = selectSliceCoords(vw)
%
% Allow the user to use the mouse to set the three sliceNum editable text
% fields in the Volume view.
%
% The current selected position is stored in vw.ui.sliceNumFields.
% The values are also returned as the 2nd argument.
%

if ~strcmp(vw.viewType,'Volume') & ~strcmp(vw.viewType,'Gray')
  myErrorDlg('selectSliceCoords only for Volume view.');
end

% Get mouse input
[x,y] = ginput(1);
x=round(x);
y=round(y);

% Interpret mouse click according to current slice orientation
curSlice = viewGet(vw, 'Current Slice');
sliceOri=getCurSliceOri(vw);
switch sliceOri
  case 1				% axi (y=cor pos, x=sag pos)
    slices=[curSlice y x];
  case 2 				% cor (y=axi pos, x=sag pos)
    slices=[y curSlice x];
  case 3 				% sag (y=axi pos, x=cor pos)
    slices=[y x curSlice];
end

% Set the sliceNum editable text fields
for n=1:3
  set(vw.ui.sliceNumFields(n),'String',num2str(slices(n)));
end

return;

% Debug/Test

[VOLUME{1},selectedPosition] = selectSliceCoords(VOLUME{1});

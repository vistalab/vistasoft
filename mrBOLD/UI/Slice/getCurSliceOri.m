function curSliceOri = getCurSliceOri(view)
%
% curSliceOri = getCurSliceOri(view)
%
% Gets current slice orientation from the sliceOriButtons handles
try,
  curSliceOri = findSelectedButton(view.ui.sliceButtons);
catch,
  curSliceOri = findSelectedButton(view.ui.sliceOriButtons);
end

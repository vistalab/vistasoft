function setCurSliceOri(view,sliceOriNum)
%
% setCurSliceOri(view,sliceOriNum)
%
% sliceOriNum: axi=1, cor=2, sag=3
%
% Selects button corresponding to sliceOriNum

selectButton(view.ui.sliceOriButtons,sliceOriNum);

function  [volselpts] = mrSelLineSagVol(curSag,sagSlice,sagSize,sagMin,sagMax,obX,obY,volselpts)
%
% MRSELLINESAGVOL
%
%	 [volselpts] = mrSelLineSagVol(curSag,sagSlice,sagSize,sagMin,sagMax,obX,obY,volselpts)
%	Select ROI points from the current sagittal image.
%

[thexs,theys] = mrSelLineVol(sagSlice,sagSize,sagMin,sagMax,obX,obY);
newsel = theys+(thexs-1)*sagSize(1);
newsel = newsel+(curSag-1)*prod(sagSize);
volselpts = [volselpts,newsel];

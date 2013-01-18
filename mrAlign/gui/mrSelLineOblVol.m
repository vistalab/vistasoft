function  [volselpts] = mrSelLineOblVol(obPts,obSlice,obSize,obMin,obMax,sagX,sagY,volselpts,sagSize)
%
% MRSELLINEOBLVOL
%
%	 [volselpts] = mrSelLineOblVol(obSlice,obSize,obMin,obMax,sagX,sagY,volselpts,sagSize)
%
%	Select ROI points from the current oblique image.
%

[thexs,theys] = mrSelLineVol(obSlice,obSize,obMin,obMax,sagX,sagY);
obcoords = round(theys +round(thexs-1)*obSize(1));
obsel = obPts(obcoords,:);
sagcoords = round(obsel(:,2) +round(obsel(:,1)-1)*sagSize(1));
plcoords = round(obsel(:,3));
newsel = sagcoords+(plcoords-1)*prod(sagSize);
volselpts = [volselpts,newsel];

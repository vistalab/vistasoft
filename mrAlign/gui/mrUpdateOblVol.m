sagX = [curSlice,curSlice];
if ~isempty(obSlice)
	figure(3);
	myShowImageVol(obSlice,obSize,obMin,obMax,sagX,sagY);
end

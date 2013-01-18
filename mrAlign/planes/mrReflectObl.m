function [obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,which,update)
%
%NAME:	 [obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,which,update)
%AUTHOR:  Poirson 
%DATE:    08.09.96
%HISTORY  11.08.96 SPG added bool update
%BUGS:

global obwin volslimin2 volslimax2;

row = obSize(1);
col = obSize(2);

if which == 1
	% First entry tell us left/right flipping
	reflections(1) = reflections(1) * (-1.0);
	tmp = fliplr(reshape(obSlice,row,col));

elseif which == 2
	% Second entry tell us up/down flipping
	reflections(2) = reflections(2) * (-1.0);
	tmp = flipud(reshape(obSlice,row,col));
else
	disp('mrReflectObl: invalid case');
end
 obSlice = tmp(:)';

if (update == 1)
 figure(obwin);
 myShowImageVol(obSlice',obSize,max(obSlice)*get(volslimin2,'value'),max(obSlice)*get(volslimax2,'value'));
end

return


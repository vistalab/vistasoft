function [obSlice, sagX, sagY] = mrDispOblVol(volume,sagSize,numSlices,obPts,obSize,curSag,volselpts)
%
global obwin volslimin2 volslimax2;

if ~isempty(obPts)
	sagX = [curSag,curSag];
	sagY = [0,obSize(1)];
	tmp = volume;
	if ~isempty(volselpts)
		tmp(volselpts) = -1*ones(1,length(volselpts));
	end
	obSlice = mrExtractImgVol(tmp, sagSize, numSlices, obPts);
	figure(obwin);
	myShowImageVol(obSlice,obSize,max(obSlice)*get(volslimin2,'value'),max(obSlice)*get(volslimax2,'value'),sagX,sagY);
end

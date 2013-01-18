obSize gives the size.
a = reshape(obSlice,42,51);
b = flipup(a);


function [sagSlice,obSlice,sagX,sagY] = ...
	mrUpSagShowObl(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%
%NAME: [sagSlice,obSlice,sagX,sagY] = ...
%	mrUpSagShowObl(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%AUTHOR:  Poirson 
%DATE:    08.07.96
%HISTORY  Started with mrUpSagShowObl.m
%BUGS:

% relevant code to display the interpolated oblique plane
global obwin
if ~isempty(obPts)
	figure(obwin);
	[obSlice,sagX,sagY] = ...
		mrDispOblVol(volume,sagSize,numSlices,obPts,obSize,curSag,volselpts);
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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



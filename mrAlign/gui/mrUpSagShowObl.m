function [sagSlice,obSlice,sagX,sagY] = ...
	mrUpSagShowObl(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%
%NAME: [sagSlice,obSlice,sagX,sagY] = ...
%	mrUpSagShowObl(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%AUTHOR:  Poirson 
%DATE:    08.07.96
%HISTORY  Started with mrUpdateAllVol.m, author unknown
%         After choosing a sagittal plane to interpolate, the routine mrUpdateAllVol.m
%         was called in the original (08.04.96 version) of mrLoadVol.  mrUpdateAllVol()
%         had a side effect of screwing up my sagittal window.  In this routine
%	  I have the same return values but knocked out the sagittal window update.
%	  (Sorry for the name, it stands for: update sagittal, show oblique)
%BUGS:

% relevant code from routine mrShowSagVol() to set the sagittal slice
global volslimin1 volslimax1 volslislice numSlices;

tmp = volume;
if ~isempty(volselpts)
	tmp(volselpts) = -1*ones(1,length(volselpts));
end

%Hack out sagittal directly for extra speed
samp = [1:prod(sagSize)]+(curSag-1)*prod(sagSize);
sagSlice = tmp(samp);

set(volslislice,'value',(curSag-1)/numSlices);

% relevant code to display the interpolated oblique plane
global obwin
if ~isempty(obPts)
	figure(obwin);
	[obSlice,sagX,sagY] = ...
		mrDispOblVol(volume,sagSize,numSlices,obPts,obSize,curSag,volselpts);
end

return

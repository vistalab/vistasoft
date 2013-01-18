function [sagSlice,obSlice,sagX,sagY] = ...
	mrUpdateAllVol(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%
%	[sagSlice,obSlice,sagX,sagY] = ...
%	mrUpdateAllVol(volume,sagSize,numSlices,curSag,obPts,obSize,obX,obY,volselpts)
%
%
%	Updates sagittal and oblique windows.
%
%

global sagwin obwin

figure(sagwin);
sagSlice = mrShowSagVol(volume,sagSize,curSag,volselpts,obX,obY); 
if ~isempty(obPts)
	figure(obwin);
	[obSlice,sagX,sagY] = ...
	mrDispOblVol(volume,sagSize,numSlices,obPts,obSize,curSag,volselpts);
end

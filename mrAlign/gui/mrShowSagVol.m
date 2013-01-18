function sagSlice = mrShowSagVol(volume,sagSize,curSag,volselpts,obX,obY)
%
% MRSHOWSAGVOL
%
% function sagImage = mrShowSagVol(volume,sagSize,curSag,volselpts,obX,obY)
%
%	Displays the current sagittal image.
%	Highlights selected ROI in green.
%

global volslimin1 volslimax1 volslislice sagwin numSlices;

tmp = volume;
if ~isempty(volselpts)
	tmp(volselpts) = -1*ones(1,length(volselpts));
end

%Hack out sagittal directly for extra speed
samp = [1:prod(sagSize)]+(curSag-1)*prod(sagSize);
sagSlice = tmp(samp);

if(nargin == 6)
	myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,'value'),...
		max(sagSlice)*get(volslimax1,'value'),obX,obY);
else
	myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,'value'),...
		max(sagSlice)*get(volslimax1,'value'));
end


set(volslislice,'value',(curSag-1)/numSlices);



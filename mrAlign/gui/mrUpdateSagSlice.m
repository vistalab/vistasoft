function [sagSlice] = mrUpdateSagSlice(volume,sagSize,curSag,numSlices)
% [sagSlice] = mrUpdateSagSlice(volume,sagSize,curSag)
%AUTHOR:	Poirson
%DATE:		08.08.96
%PURPOSE:	JUST update the sagittal window with the 
%		current sagittal image.
%               The routine mrUpdateAllVol() was doing too much 
%HISTORY: 	Started with mrUpdateAllVol() by XX
%NOTES:
%BUGS:

global sagwin volslimin1 volslimax1 volslislice 

figure(sagwin);

%Hack out sagittal directly for extra speed
samp = [1:prod(sagSize)]+(curSag-1)*prod(sagSize);
sagSlice = volume(samp);

myShowImageVol(sagSlice,sagSize,max(sagSlice)*get(volslimin1,'value'),...
	max(sagSlice)*get(volslimax1,'value'));

% This 'volslislice' is a GLOBAL.  Don't know who else uses it.
set(volslislice,'value',(curSag-1)/numSlices);

% Text saying what the current Sagittal slice is
xlim=get(gca,'XLim');
ylim=get(gca,'YLim');
xt = xlim(1) + 5;
yt = diff(ylim) + 10;
txt = (['Displaying Sagittal Slice: ',num2str(curSag),'     ']);
msg(1)= text(xt,yt(1),txt);


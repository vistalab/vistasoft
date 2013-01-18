function [obX,obY,obXM,obYM,lp] = mrClipInplanes(numofanats,obXM,obYM,lp,curInplane)
%NAME:   [obX,obY,obXM,obYM,lp] = mrClipInplanes(numofanats,obXM,obYM,lp,curInplane)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInplane.m, mrSetupInplanes.m
%         mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%NOTES:   Can't get selection points on the image easily

global sagwin
figure(sagwin)

% One more pair of points for the perpendicular line
nPtPairs = numofanats + 1;

% See if the user has already been working on some inPlanes
if size(obXM,1) == 0
	disp('You must first create a candidate set of Inplanes');
	disp('Choose Set_Up_Inplanes first');
	return
end

xlim=get(gca,'XLim');
ylim=get(gca,'YLim');
xt = diff(xlim)*(-1.0) * 0.8;
yt=ylim(1)+diff(xlim)*[0.05,0.125,0.20,0.275,0.35];	
msg(1) = text(xt,yt(1),'Clip Buttons:');
msg(2) = text(xt,yt(2),'FIRST LINE');
msg(3) = text(xt,yt(3),'Pick two points');

x1 = []; y1 = [];
x2 = []; y2 = [];

[x1(1),y1(1),button]=mrGinput(1,'cross');
[x1(2),y1(2),button]=mrGinput(1,'cross')

msg(4) = text(xt,yt(4),'SECOND LINE');
msg(5) = text(xt,yt(5),'Pick two points');


% Draw the truncated lines
for i=1:nPtPairs
   delete(lp(i));
   lp(i)=line(obXM(i,:),obYM(i,:),'Color','w');
end

[x2(1),y2(1),button]=mrGinput(1,'cross');
[x2(2),y2(2),button]=mrGinput(1,'cross')

% Estimate parameters for the truncating lines
p1=polyfit(x1,y1,1);
p2=polyfit(x2,y2,1);

% Truncate the lines
for i=1:numofanats
	% Parameters of inplane line
	pIn= polyfit(obXM(i,:),obYM(i,:),1);
	% parameter(1) = slope, parameter(2) = offset
	obXM(i,1) = (p1(2) - pIn(2))/(pIn(1)-p1(1));
        obYM(i,1) = ((pIn(1)*p1(1))/(pIn(1)-p1(1)))*(p1(2)/p1(1) - pIn(2)/pIn(1));
	obXM(i,2) = (p2(2) - pIn(2))/(pIn(1)-p2(1));
        obYM(i,2) = ((pIn(1)*p2(1))/(pIn(1)-p2(1)))*(p2(2)/p2(1) - pIn(2)/pIn(1));
end

% Draw the truncated lines
for i=1:nPtPairs
   delete(lp(i));
   lp(i)=line(obXM(i,:),obYM(i,:),'Color',[0 0 1]);
end

for i=1:5
	delete(msg(i));
end


% Check if the user has selected an inplane yet.
if (curInplane ~= 0)
	obX = obXM(curInplane,:);
	obY = obYM(curInplane,:);
else
	obX = [0,0];
	obY = [0,0];
end

return









function [obX,obY,newlp,choice] = mrSelInplane(numofanats,obXM,obYM,lp,prevChoice)
%NAME:   [obX,obY,newlp,choice] = mrSelInplane(numofanats,obXM,obYM,lp,prevChoice)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%         Returns the choice of inplane.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInplane.m, mrSetupInplanes.m,
%         mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%NOTES:   Modified 2/25/97 by SPG to return the inplane number so
%         that can use inplane angle as a degree of freedom in the rotation
%         control window

global sagwin
figure(sagwin)

newlp = lp;

% One more pair of points for the perpendicular line
nPtPairs = numofanats + 1;

% See if the user has already been working on some inPlanes
if size(obXM,1) == 0
	disp('You must first create a candidate set of Inplanes');
	disp('Choose Set_Up_Inplanes first');
	return
end

%prevChoice = -99;

xlim=get(gca,'XLim');
ylim=get(gca,'YLim');
xt = diff(xlim)*(-1.0) * 0.8;
yt=ylim(1)+diff(xlim)*[0.05,0.125,0.20,0.275];	
msg(1) = text(xt,yt(1),'Select Inplane:');
msg(2) = text(xt,yt(2),'Left = Select Line');
msg(3) = text(xt,yt(3),'Right= Show Selection');

button = 0;
while(button~=3)
	[tempx,tempy,button]=mrGinput(1,'arrow');
	if (button~=3)
		%find the closest line and give it a different color
		for i=1:numofanats
			% p(1) = slope, p(2) = offset
			p = polyfit(obXM(i,:),obYM(i,:),1);
			d(i) = abs((p(1)*tempx)+(-1*tempy)+p(2))/((p(1)^2 + 1)^0.5);
		end
		%find the minimum distance
		choice = find(d == min(d));
		% remove previous choice
		if prevChoice > 0
			% delete(lp(prevChoice))
			newlp(prevChoice)=line(obXM(prevChoice,:),obYM(prevChoice,:),'Color',[0 0 1]);
		end
		% re-draw choice in red
		% delete(lp(choice));
		newlp(choice)=line(obXM(choice,:),obYM(choice,:),'Color',[1 0 0]);
	end
end

% Return this choice
obX = obXM(choice,:);
obY = obYM(choice,:);

for i=1:3
	delete(msg(i));
end

return;













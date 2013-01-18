function [obX,obY,obXM,obYM,lp] = mrTransInplanes(numofanats,obXM,obYM,lp,curInplane)
%NAME:    [obX,obY,obXM,obYM,lp] = mrTransInplanes(numofanats,obXM,obYM,lp,curInplane)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInplane.m, mrSetupInplanes.m
%         mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%NOTES:

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


% Center point of the inplanes is the middle of perpendicular line
centerX = mean(obXM(nPtPairs,:));
centerY = mean(obYM(nPtPairs,:));

xlim=get(gca,'XLim');
ylim=get(gca,'YLim');
xt = diff(xlim)*(-1.0) * 0.8;
yt=ylim(1)+diff(xlim)*[0.05,0.125,0.20];	
msg(1) = text(xt,yt(1),'Translate Buttons:');
msg(2) = text(xt,yt(2),'Left = Center point');
msg(3) = text(xt,yt(3),'Right= Quit');


button = 0;
while(button~=3)
 [tempx,tempy,button]=mrGinput(1,'cross');
 if (button~=3)
  if (button == 1) | (button == 2)
   obXM = obXM + (tempx-centerX);
   obYM = obYM + (tempy-centerY);
   % Recalculate the center
   centerX = tempx;
   centerY = tempy;
  end

  for i=1:length(lp)
    delete(lp(i));
  end

  for i=1:nPtPairs
   if i == curInplane
        lp(i)=line(obXM(i,:),obYM(i,:),'Color','r');
	% Set obX and obY to new values.
   else
        lp(i)=line(obXM(i,:),obYM(i,:),'Color','b');
   end
  end


 end
end

if (curInplane ~= 0)
	obX = obXM(curInplane,:);
	obY = obYM(curInplane,:);
else
	obX = [0,0];
	obY = [0,0];
end


delete(msg(1));delete(msg(2));delete(msg(3));



return;







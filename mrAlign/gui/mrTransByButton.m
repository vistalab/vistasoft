function [obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,direction)
%NAME:    [obX,obY,obXM,obYM,lp] = mrTransByButton(numofanats,obXM,obYM,lp,curInplane,direction)
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

switch direction
  case 1
    obXM = obXM - transDelta;
  case 2
    obXM = obXM + transDelta;
  case 3
    obYM = obYM - transDelta;
  case 4
    obYM = obYM + transDelta;
end
  
if (curInplane ~= 0)
	obX = obXM(curInplane,:);
	obY = obYM(curInplane,:);
else
	obX = [0,0];
	obY = [0,0];
end

return

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










function [obXM,obYM,lp] = mrSpreadInplanes(numofanats,obXM,obYM,lp)
%NAME:   [obXM,obYM,lp] = mrSpreadInplanes(numofanats,obXM,obYM,lp)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInPlane.m, mrSetupInplanes.m,
%         mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%NOTES:
%BUGS:
%  Loses the cropping information when changing inplane spread.

INCDELTA = 0.25;

% One more pair of points for the perpendicular line
nPtPairs = numofanats + 1;

% See if the user has already been working on some inPlanes
if size(obXM,1) == 0
	disp('You must first create a candidate set of Inplanes');
	disp('Choose Set_Up_Inplanes first');
	return
end

% Use X and Y travel of perpendicular line 
% to find incX and incY between lines.
incX = (obXM(nPtPairs,2)- obXM(nPtPairs,1))/(numofanats-1);
incY = (obYM(nPtPairs,2)- obYM(nPtPairs,1))/(numofanats-1);

% percent of change in X and Y direction;
fractionX = incX/(incX+incY);
fractionY = incY/(incX+incY);

disp('');
disp('--Setting Distance Between Inplanes--');
disp('  Left Button=Decrease, Middle Button=Increase, Right Button=Quit');
button = 0;
while(button~=3)
 [tempx,tempy,button]=mrGinput(1,'cross');
 if (button~=3)
  if (button == 1)
	delta = -1*INCDELTA;
  end
  if (button == 2)
	delta = INCDELTA;
  end

  deltaX = fractionX * delta;
  deltaY = fractionY * delta;

  incX = incX + deltaX;
  incY = incY + deltaY;

  for i=1:numofanats
	obXM(i,:) = obXM(1,:) + (i-1)*incX;
	obYM(i,:) = obYM(1,:) + (i-1)*incY;
  end

  % the perpendicular line, (starting point is the same)
  obXM(nPtPairs,2) = obXM(nPtPairs,1)+(numofanats-1)*incX;
  obYM(nPtPairs,2) = obYM(nPtPairs,1)+(numofanats-1)*incY;

  % draw the new lines on the screen
  for i=1:nPtPairs
     delete(lp(i));	
     lp(i)=line(obXM(i,:),obYM(i,:),'Color','w'); 
  end
 end
end

disp('--Done Setting Distance Between Inplanes--');
disp('');

return;


function [obXM,obYM] = mrRotInplanes(numofanats,obXM,obYM,incdegree,curInplane)
%NAME:   [obXM,obYM] = mrRotInplanes(numofanats,obXM,obYM,incdegree,curInplane)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%         mrClipInplanes.m, mrSelInPlane.m, mrSetupInplanes.m
%         mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%NOTES:   Modified 2/25/97 to integrate with rotation control panel

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

angle = incdegree * ((2*pi)/360);	% make the degrees in radians

  % Take out the mean 
  obXMzm = obXM - centerX;
  obYMzm = obYM - centerY;
  % Stack the X and Y line endpoints
  lineVals = [[obXMzm(:,1);obXMzm(:,2)],[obYMzm(:,1);obYMzm(:,2)]];
  % Build rotation matrix
  rot(1,1) = cos(angle);
  rot(1,2) = -sin(angle);
  rot(2,1) = sin(angle);
  rot(2,2) = cos(angle);
  % Apply rotation
  lineValsR = lineVals * rot';
  % Put the lines back into form for drawing
  obXMzm = [lineValsR([1:nPtPairs],1),lineValsR([nPtPairs+1:2*nPtPairs],1)];
  obYMzm = [lineValsR([1:nPtPairs],2),lineValsR([nPtPairs+1:2*nPtPairs],2)];
  obXM = obXMzm + centerX;
  obYM = obYMzm + centerY;
  
return











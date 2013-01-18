function  [obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,direction)
%NAME:    [obX,obY,obXM,obYM,lp] = mrPerpTransByButton(numofanats,obXM,obYM,lp,curInplane,transDelta,direction)
%AUTHOR:  Backus
%DATE:	  08.04.96
%PURPOSE: One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInplane.m, mrSetupInplanes.m
%         mrSpreadInplanes.m
%HISTORY: Started with mrTransByButton by Poirson, 01.20.99
%NOTES:
% direction is +1 or -1
% transDelta is the distance by which to translate the inplanes
%
% Oddly, the orientation of the inplanes structure is not stored
%   as a static structure plus rotation & translation, but rather
%   explicitly as its current set of inplane endpoints within the
%   rotated current sagittal slice (rotated by aTheta and cTheta,
%   that is).  Subject to increasing error.

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

% The direction normal to the inplanes is given by the last line, 
% which crosses them.
normalXY = [obXM(nPtPairs,2)-obXM(nPtPairs,1) obYM(nPtPairs,2)-obYM(nPtPairs,1)];
unitNormal = normalXY/norm(normalXY);

if (abs(direction) ~= 1)
     error('direction argument must be 1 or -1');
end

obXM = obXM + direction*transDelta*unitNormal(1);
obYM = obYM + direction*transDelta*unitNormal(2);
  
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










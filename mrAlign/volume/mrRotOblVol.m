 function [obPts,obSize,theta] = mrRotOblVol(obSlice,obX,obY,numSlices,sagSize,curSag,theta,delta,maxTheta)

% mrRotOblVol.m
% --------
% this code provides the user with a means of rotating the oblique
% slice in two dimensions, sagital and coronal for the purpose of 
% correcting the rotation variability of scans particularly towards 
% the posterior regions. Alternately, a rotation may be applied to the
% oblique in three dimensions, but the axial rotation is taken care of 
% with the rotation procedure called by the select matching points routine
%

 [obPts, obSize] = mrExtractOblVol(obX, obY, sagSize, numSlices);

% testing junk, taken directly from mrExtractOblVol
% take obPts - obPtsOrig to see rotation

%obPts = [];
%obPtsOrig = [];

%numSlices = 40;
%curSag = 20;

%theta = pi/12; % maybe this should be the limit
%obX = [5, 20];
%obY = [2, 25];

%  d = sqrt((obY(2)-obY(1)).^2 + (obX(2)-obX(1)).^2);
%  unitv = [(obX(2)-obX(1))/d, (obY(2)-obY(1))/d];

%  x = obX(1); y = obY(1);
%  for i = 0:round(d);
%          a = x+i*unitv(1); b = y+i*unitv(2);
%          tmp(i+1,:) = [a,b,1];
%  end

%  for i = 1:numSlices
%        tmp(:,3) = i*ones(length(tmp),1);
%        obPtsOrig = [obPtsOrig;tmp];
%  end

%  obSize = [round(d)+1,numSlices];

%obPts = obPtsOrig;

% begin rotation code

if isempty(obSlice)
	disp('First select inlanes from sagittal window using');
        disp('Set_Up_inplanes under the Align menu.');
        return;
else

 % stolen directly from Alan's code
prevChoice = -99;

xlim=get(gca,'XLim');
ylim=get(gca,'YLim');
xt = diff(xlim)*(-1.0) * 0.8;
yt=ylim(1)+diff(xlim)*[0.05,0.125,0.20,0.275];
msg(1) = text(xt,yt(1),'Rotate Buttons:');
msg(2) = text(xt,yt(2),'Left = Left Rotate in');
msg(3) = text(xt,yt(3),'Mid  = Right Rotate in');
msg(4) = text(xt,yt(4),'Right= Quit');

button = 0;
thetaOrig = theta;

while(button~=3)
 [tempx,tempy,button]=mrGinput(1,'cross');
 if (button~=3)
  if (button == 1)
   theta = theta - delta; % confirm this on test!!!
  elseif (button == 2)
  theta = theta + delta;
end
end
end

if abs(theta+delta) > abs(maxTheta)
	disp(' Angle of rotation out of limits');
	return;
end

% disp('Theta = '); figure out why this doesn't work
% disp(theta);
tanTheta = tan(theta);
trans_axis = 2;    %selects the translation axis


for i=0:(numSlices-1)
    for j=1:obSize(1)
    obPts((i*obSize(1)+j), trans_axis) = obPts((i*obSize(1) + j), trans_axis) + ((curSag - i)*tanTheta);
    end 
end
end



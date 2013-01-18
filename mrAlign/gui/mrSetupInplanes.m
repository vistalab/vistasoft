function [obX,obY,obXM,obYM,lp,ipThickness,ipSkip] =...
    mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane)

%NAME:   [obX,obY,obXM,obYM,lp,ipThickness,ipSkip] = ...
%    mrSetupInplanes(numofanats,obXM,obYM,lp,ipThickness,ipSkip,volume_pix_size,inplane_pix_size,curInplane)
%AUTHOR:  Poirson
%DATE:	  08.04.96
%PURPOSE: This routine starts over the process of getting inplanes.
%	  One of a set of routines that allows user 
%         to set and select a set of oblique planes in saggital slice.
%	  The routines are mrTransInplanes.m, mrRotInplanes.m,
%	  mrClipInplanes.m, mrSelInPlane.m, mrSetupInplanes.m,
%	  mrSpreadInplanes.m
%HISTORY: Started with mrGetOblPlane from G. Boynton 4/6/96
%          07.23.97 SPG, ABP -- Was using inplane_pix_size to set the initial
%            placement of the inplanes.  Steve Engel pointed out that I
%            should be using volume_pix_size.  These two values were the same
%            when we were using 4-shot pulse sequences, but became different
%            when we moved to 2-shot.
%          07.28.97 ABP -- On fresh startup, shortened the length of them, 
%	     added a little twist.
%            Did both of these to get rid of annoying warning messages.
%          12.11.97 ABP - updated to MATLAB 5.0
%NOTES:
%

global sagwin
figure(sagwin)


% One more pair of points for the perpendicular line
nPtPairs = numofanats + 1;

% flag for creating new inplane coordinates
createCoords = 1;

%flag saying if I put any text on the window
textWritten = 0;

% Coords full, means data read in from file, 
% but not yet drawn.  Action is to draw existing coords.
if ~(size(obXM,1) == 0)
    createCoords = 0;
    
% Coords not full, means first time starting this up.
% Action is to create new coords and draw
elseif (size(obXM,1) == 0) & (size(lp,1) == 0)
    
    createCoords = 1;
    textWritten = 1;
    
    % djh 8/29/01, commented this out
    % 	% get inplane parameters
    % 	xlim=get(gca,'XLim');
    % 	ylim=get(gca,'YLim');
    % 	% put text to left of graphics window	
    % 	xt = diff(xlim)*(-1.0) * 0.8;
    % 	yt=ylim(1)+diff(xlim)*[0.05,0.125,0.20];	
    % 	msg(1) = text(xt,yt(1),'Setting up inplanes:');
    % 	msg(2) = text(xt,yt(2),'Enter parameters in');
    % 	msg(3) = text(xt,yt(3),'  matlab window');
    
    % Need to set these up first time through
    disp('Enter Inplane thickness');
    ipThickness= input(['Default is ',num2str(1/inplane_pix_size(3)),' mm: ']);
    
    if isempty(ipThickness)
        ipThickness = 1/inplane_pix_size(3);
    end
    
    disp('Enter distance skipped between inplanes');
    ipSkip = input(['Default is 0 mm: ']);
    
    if isempty(ipSkip)
        ipSkip = 0;
    end
    
    
elseif (size(obXM,1) == 0) & ~(size(lp,1) == 0)
    disp('mrSetupInplanes:  This case should never come up');
    return
end

if createCoords == 1
    % Fresh start
    xrange=get(gca,'XLim');
    yrange=get(gca,'YLim');
    
    % Calculate separation between inplanes
    xinc = (volume_pix_size(1)*ipThickness) + ...
        (volume_pix_size(1)*ipSkip);
    
    % Set up one vertical line to start
    xoffset = ((numofanats-1)/2)*xinc;
    obXM(1,1) = (xrange(2)/2) - xoffset;
    obXM(1,2) = (xrange(2)/2) - xoffset;
    % A little less than the full range of the image
    obYM(1,1) = yrange(1) + (yrange(1) * 0.10);
    obYM(1,2) = yrange(2) - (yrange(2) * 0.10);
    
    % Create the rest of the matrix containing line endpoints
    for i=2:numofanats
        obXM(i,:) = obXM(1,:) + ((i-1)*xinc);
        obYM(i,:) = obYM(1,:);
    end
    
    % Now the perpendicular line
    obXM(nPtPairs,1) = obXM(1,1);
    obXM(nPtPairs,2) = obXM(numofanats,1);
    obYM(nPtPairs,1) = yrange(2)/2;
    obYM(nPtPairs,2) = yrange(2)/2;
    
    % add a 45 degree rotation to the whole thing..
    [obXM, obYM] = mrRotInplanes(numofanats,obXM,obYM,45.0,curInplane);
else
    % Do this to silence MATLAB5.0 warning about 
    % return arguments not being set.
    obXM = obXM;
    obYM = obYM;
    ipThickness = ipThickness;
    ipSkip = ipSkip;
end

% Sunil isn't sure this is helping at all
%if ~isempty(lp)
%  for i=1:length(lp)
%    delete(lp(i));
%  end
%end

% Draw them 
for i=1:nPtPairs
    if curInplane == i
        lp(i)=line(obXM(i,:),obYM(i,:),'Color','r'); 
    else 
        lp(i)=line(obXM(i,:),obYM(i,:),'Color','b'); 
    end
end

if textWritten == 1
    for i=1:3
%         delete(msg(i));
    end
end

% Check if the user has selected an inplane yet.
if (curInplane ~= 0)
    obX = obXM(curInplane,:);
    obY = obYM(curInplane,:);
else
    obX = [0,0];
    obY = [0,0];
end

return;



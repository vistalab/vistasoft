function [inpts,volpts] = mrSelectPoints(inpts,volpts,retwin,otherwin,Zinp,obPts,obSize,reflections)
%function [inpts,volpts] = mrSelectPoints(inpts,volpts,retwin,otherwin,Zinp,obPts,obSize,reflections)
%
%Allows the user to select pairs of corresponding alignment points from the
%inplanes to either the sagittal volume planes (nargin<7)  or the oblique plane (nargin=8)
%
%User selects pairs with left mouse button, and quits with the right.

%6/16/96 gmb	wrote it to replace functions mrGetAlPtOblVol and mrGetAlPtSagVol
%08/09/96 ABP	added reflection logic, color the selection points

room = 0; % hopefully this is the bug

if (nargin<8)
	%if nargin<7, we're selecting between the inplane and the sagittal window
	inp2obl=0;
	Zsag=obPts;
else
	%otherwise, we're selecting between the inplane and the oblique window
	inp2obl=1;
end

disp('Choose points with the left button');
disp('Right button quits');


% range of 'otherWin'
figure(otherwin);
hold on;
xrange=get(gca,'XLim');
yrange=get(gca,'YLim');

figure(retwin);
hold on;

pX1 = []; pY1 = [];
pX2 = []; pY2 = [];
pRetwin = []; pOtherwin = [];

npoints = size(volpts,1);
nChosen = 0;
button=0;
while(button~=3);
	figure(retwin);
	[x1,y1,button] = mrGinput(1,'cross');

	if button==1
		nChosen = nChosen + 1;
		pX1(nChosen,:) = x1;
		pY1(nChosen,:) = y1;
		for i=1:nChosen-1
			delete(pRetwin(i));
		end
		for i=1:nChosen
			pRetwin(i) = plot(pX1(i,:),pY1(i,:),'yo');
		end

		figure(otherwin);
		[x2,y2,button]=mrGinput(1,'cross');	

		pX2(nChosen,:) = x2;
		pY2(nChosen,:) = y2;

		for i=1:nChosen-1
			delete(pOtherwin(i));
		end
		for i=1:nChosen
			pOtherwin(i) = plot(pX2(i,:),pY2(i,:),'yo');
		end

		%disp(['x2,y2: ',num2str(x2),' ',num2str(y2)]);
		if inp2obl == 1
			% Flipped right/left
			if reflections(1) == -1
				x2 = xrange(2) - x2 + xrange(1);
			end
			% Flipped up/down
			if reflections(2) == -1
				y2 = yrange(2) - y2 + yrange(1);
			end
		disp(['After transformation x2,y2: ',num2str(x2),' ',num2str(y2)]);
		end

		if button==1
			inpts(npoints+1,:)=[x1,y1,Zinp];
			if inp2obl==1
				obcoord=round(y2+round(x2-1)*obSize(1));
				temp = obPts(obcoord,:); temp(3) = temp(3) - room;
				volpts(npoints+1,:)= temp;
			else
				volpts(npoints+1,:) = [x2,y2,Zsag];
			end
			npoints = size(volpts,1);
			disp([num2str(npoints),' pairs of points selected.']);
		end
	end
end

figure(otherwin)
for i=1:nChosen
	delete(pOtherwin(i));
end
hold off

% 
figure(retwin)
for i=1:nChosen
	delete(pRetwin(i));
end
hold off


disp('done selecting points.');




% This is a script to run a mesh unfold from the console. It It really an
% example of how such a script should work - it is not particularly
% beautiful. Or big. Or clever.
% ARW 021701

% Basically, we just collect all the date we need to pass to
% unfoldMeshFromGUI. The busyHandle and statusHandle are zero

% Test assignToNearest


saveExtra=1;
showFigures=1;
truePerimDist=1;
busyHandle=0;
statusHandle=0;
scaleFactor=[240/256 240/256 1.2];
perimDist=input('Unfold size: ');
startCoords=input('Start position: ');
fprintf('Browsing for input mesh file:');
[whiteFileName,whitePathName]=uigetfile('*.class','Select class file:');
whiteFileName=[whitePathName,whiteFileName];
[grayFileName,grayPathName]=uigetfile('*.gray','Select gray file:');
grayFileName=[grayPathName,grayFileName];
[flatFileName,flatPathName]=uiputfile('*.mat','Select output file:');
flatFileName=[flatPathName,flatFileName];


dummy=unfoldMeshFromGUI(whiteFileName,grayFileName,flatFileName,startCoords,scaleFactor,perimDist,statusHandle,busyHandle,showFigures,saveExtra,truePerimDist);
	








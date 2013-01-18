% This is a script to run a mesh unfold from the console. It It really an
% example of how such a script should work - it is not particularly
% beautiful. Or big. Or clever.
% ARW 021701

% Basically, we just collect all the date we need to pass to
% unfoldMeshFromGUI. The busyHandle and statusHandle are zero

% Test assignToNearest

clear all;
close all;


saveExtra=1;
showFigures=1;
truePerimDist=1;
busyHandle=0;
statusHandle=0;
scaleFactor=[240/256 240/256 1.2];
%perimDist=input('Unfold size: ');
perimDist=20;
startCoords=[154,83,108]; % For test data set
%startCoords=[156,85,30]; % For plane data set

%startCoords=input('Start position: ');
fprintf('Browsing for input mesh file:');
%[meshFileName,meshPathName]=uigetfile('*.MrM','Select mesh file:');
%meshFileName=[meshPathName,meshFileName];
meshFileName='./exampleData/right_tal.MrM';
%[grayFileName,grayPathName]=uigetfile('*.gray','Select gray file:');
%grayFileName=[grayPathName,grayFileName];
grayFileName=['.//exampleData/right_tal.Gray'];
	      
%[flatFileName,flatPathName]=uiputfile('*.mat','Select output file:');
%flatFileName=[flatPathName,flatFileName];

flatFileName='flat.mat';

%whiteFileName='d:/wade/programming/unfold/021401/mrGray/left.class';

	      
%dummy=unfoldMeshFromGUI(meshFileName,grayFileName,flatFileName,startCoords,scaleFactor,perimDist,statusHandle,busyHandle,showFigures,saveExtra,truePerimDist);
	


% Plane coords [162,85,29]






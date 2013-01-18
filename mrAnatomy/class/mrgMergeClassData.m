% Script
% mrgMergeClassData
%
%

% Change to the proper directory
dir = 'C:\Users\Adam\Vh\classprojects\left\20070302';
chdir(dir);
% Set up the two class file names.  The order is important.  The data in
% the second file will over-write the data in the first.
fname1  = 'leftWhole.Class';
fname2  = 'leftOccipital.Class';
outFile = 'leftWhole2.Class';

% Read in the whole VOI of the first one.
class1 = readClassFile(fname1,0,0);

% Just read in the VOI part of the second file
class2 = readClassFile(fname2,0,1);

% Over-write the parts of the class1 data with the class 2 data.
fprintf('Overwriting %s with %s\n',fname1,fname2);

% NOT DONE YET PROPERLY .... we need to figure out how to identify the
% locations in the class1 data that are in the class2 VOI.  THen we copy.
%
% It will be something like
 x = class2.header.voi(1):class2.header.voi(2);
 y = class2.header.voi(3):class2.header.voi(4);
 z = class2.header.voi(5):class2.header.voi(6);
 class1.data(x,y,z) = class2.data;


% l = (class2.data > 0); 
% class1.data(l) = class2.data(l);
fprintf('Saving %s\n',outFile);
writeClassFile(class1,outFile);
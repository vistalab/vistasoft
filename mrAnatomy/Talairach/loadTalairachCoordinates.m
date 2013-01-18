function talDat = loadTalairachCoordinates;

%loadTalairachCoordinates() Load Tal. coordinates from file.
%
%This function is supposed to prevent multiple hacking of the same coordinates
%instead write to a pure textfile and read them in for each subject.
%The file is assumed to reside at the base directory for the antomies. Hoever deviations
%in file location are posible
%the structure of the text-file is fixed and assumed to be the following:
%x-coord ycoord zcoord descripition-string color
%The file may consist of several lines each specifiying one set of coordinates
%Fields within a line are separated by whitespace(s). The field color is a valid matlab 
%colorstring such as 'b' 'r' 'y' etc.
%
% Authors BD and JR 09/18/01

% ugly but conforms with the conventions
rootPath=which(mfilename);
rootPath = fullfile(fileparts(rootPath),'Coords');
pathstr = getPathStrDialog(rootPath,'Choose Talairach-coordinates file','*.txt;*.TXT');

if isempty(pathstr)
    talDat = [];
end

talDat = dlmreadMixedDataType(pathstr,'n1 n2 n3 s4 s5');

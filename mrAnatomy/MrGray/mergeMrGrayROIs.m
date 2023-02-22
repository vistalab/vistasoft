function mergeMrGrayROIs(outFile, infile1, infile2, rgbMerge, rgbOne, rgbTwo)
% mergeMrGrayROIs(outFile, infile1, infile2, [rgbMerge], [rgbOne], [rgbTwo])
%
% AUTHOR:   Dougherty
% DATE:     02.17.99
% PURPOSE:  Merge 2 mrGray ROI files into one file, changing the color
%				of the intersection.
% 
% 

colors = zeros(2,3);

% read in the two ROIs
fid = fopen(infile1,'rt');

% This line is the number of ROIs in the file.  
n = fscanf(fid,'%d\n',1);
if n~= 1
   error('ROI files must contain only one color!');
end
colors(1, :) = fscanf(fid,'%d', 3)';
ROIcoordsOne = fscanf(fid,'%d');
ROIcoordsOne = reshape(ROIcoordsOne, 4, length(ROIcoordsOne)/4)';
fclose(fid);

fid = fopen(infile2,'rt');
n = fscanf(fid,'%d\n',1);
if n~= 1
   error('ROI files must contain only one color!');
end
colors(2, :) = fscanf(fid,'%d', 3)';
ROIcoordsTwo = fscanf(fid,'%d');
ROIcoordsTwo = reshape(ROIcoordsTwo, 4, length(ROIcoordsTwo)/4)';
fclose(fid);

% assign colors for output file
if ~exist('rgbOne', 'var')
   rgbOne = colors(1,:);
end   
if ~exist('rgbTwo', 'var')
   rgbTwo = colors(2,:);
end   
if ~exist('rgbMerge', 'var')
   rgbMerge = (rgbOne + rgbTwo) ./ 2;
end

% find intersection region
intersectCoords = intersect(ROIcoordsOne, ROIcoordsTwo, 'rows');
% find unique regions
ROIcoordsOne = setdiff(ROIcoordsOne, intersectCoords, 'rows');
ROIcoordsTwo = setdiff(ROIcoordsTwo, intersectCoords, 'rows');

% set color columns properly 
% (ROIcoordsOne is already set to 1- no need to change it)
ROIcoordsTwo(:,4) = ones(length(ROIcoordsTwo(:,4)), 1)*2;
intersectCoords(:,4) = ones(length(intersectCoords(:,4)), 1)*3;

fid = fopen(outFile,'w');
fprintf(fid,'3\n');

% Write out the color lookup table.  
%
fprintf(fid,'%.0f %.0f %.0f\n',rgbOne,rgbTwo,rgbMerge);

%Write out the voxels from the ROIs as Nx4
%
fprintf(fid,'%.0f %.0f %.0f %.0f\n',ROIcoordsOne');
fprintf(fid,'%.0f %.0f %.0f %.0f\n',ROIcoordsTwo');
fprintf(fid,'%.0f %.0f %.0f %.0f\n',intersectCoords');

% Close the output file
%
fclose(fid);

return;

